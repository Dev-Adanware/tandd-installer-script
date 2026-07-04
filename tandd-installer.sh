#!/bin/bash

set -euo pipefail

#################################################
#               CONFIGURATION                   #
#################################################

INSTALL_DIR="/opt/amt-tandd"
DATA_DIR="${INSTALL_DIR}/tandd-data"
BACKUP_DIR="${DATA_DIR}/backups"
SSL_DIR="${INSTALL_DIR}/ssl-certs"
ENV_FILE="${INSTALL_DIR}/.env"
COMPOSE_FILE="${INSTALL_DIR}/docker-compose.yml"
LOG_FILE="${INSTALL_DIR}/install.log"

# Application version to deploy (use "latest" for latest release)
APP_VERSION="latest"

# PostgreSQL Database Settings (auto-generated if not set)
POSTGRES_DB="tandd"
POSTGRES_USER="tandd_user"
POSTGRES_PASSWORD=""  # Leave empty to auto-generate secure password

# SSL Certificate Information (for CSR generation)
SSL_HOSTNAME=""           # Leave empty to auto-detect
SSL_COUNTRY="SA"          # Two-letter country code
SSL_STATE="Riyadh"        # State or Province
SSL_CITY="Riyadh"         # City
SSL_ORGANIZATION="ADANWARE"

# Backup schedule (cron expression, default: daily at 02:00)
BACKUP_CRON="0 2 * * *"

# Backup retention (days)
BACKUP_RETENTION_DAYS=7

# Health check timeout (seconds)
HEALTH_CHECK_TIMEOUT=120
HEALTH_CHECK_INTERVAL=5

# GitHub defaults
GITHUB_USERNAME="Dev-Adanware"

#################################################
#              COLOR & LOGGING                  #
#################################################

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging helpers
log_info()  { echo -e "${BLUE}[INFO]${NC}  $1" | tee -a "$LOG_FILE"; }
log_ok()    { echo -e "${GREEN}[OK]${NC}    $1" | tee -a "$LOG_FILE"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC}  $1" | tee -a "$LOG_FILE"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE" >&2; }

# Initialize log file early (will be writable after INSTALL_DIR exists)
init_log() {
    if [ -d "$INSTALL_DIR" ]; then
        touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/tandd-install-$(date +%s).log"
        echo "=== AMT-T&D Installer Log — $(date -u '+%Y-%m-%d %H:%M:%S UTC') ===" >> "$LOG_FILE"
    fi
}

#################################################
#              CLEANUP & TRAP                   #
#################################################

TEMP_DIRS=()
SSL_RESTORED=false
SSL_BACKUP_DIR=""

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_error "Installer exited with code $exit_code"
        log_error "Check log file for details: $LOG_FILE"

        # Restore SSL if we backed it up during a failed run
        if [ "$SSL_RESTORED" = true ] && [ -n "$SSL_BACKUP_DIR" ] && [ -d "$SSL_BACKUP_DIR" ]; then
            log_info "Restoring backed-up SSL certificates…"
            cp "$SSL_BACKUP_DIR"/* "$SSL_DIR/" 2>/dev/null || true
            rm -rf "$SSL_BACKUP_DIR"
            SSL_RESTORED=false
        fi
    fi

    # Remove temp directories we created
    for tmpdir in "${TEMP_DIRS[@]}"; do
        [ -d "$tmpdir" ] && rm -rf "$tmpdir" 2>/dev/null || true
    done
}
trap cleanup EXIT

fail() {
    log_error "$1"
    show_final_message "fail" "$1"
    exit 1
}

#################################################
#              MESSAGE FUNCTIONS                #
#################################################

show_banner() {
    echo ""
    echo -e "${CYAN}=============================================${NC}"
    echo -e "${CYAN}        AMT-T&D Automated Deployment${NC}"
    echo -e "${CYAN}             Powered by ADANWARE${NC}"
    echo -e "${CYAN}=============================================${NC}"
    echo ""
}

show_final_message() {
    local status="$1"
    local reason="${2:-}"
    SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "<server-ip>")

    echo ""
    echo "============================================="
    if [ "$status" = "success" ]; then
        echo -e "  ${GREEN}Installation Successful${NC}"
        echo "============================================="
        echo ""
        echo "  Please open the AMT Dashboard in your browser:"
        echo "    http://${SERVER_IP}/"
        echo "    https://${SERVER_IP}/"
        echo ""
        echo "  Default credentials:"
        echo "    Username: admin"
        echo "    Password: (set by your administrator)"
        echo ""
        echo "  Services running:"
        echo "    · PostgreSQL Database (with automatic backups)"
        echo "    · T&D Data Server Application"
        echo ""
        echo "  Directories:"
        echo "    · Application data: ${DATA_DIR}"
        echo "    · Database backups: ${BACKUP_DIR}"
        echo "    · SSL certificates: ${SSL_DIR}"
        echo "    · Installer Log:     ${LOG_FILE}"
    else
        echo -e "  ${RED}Installation Failed${NC}"
        echo "============================================="
        echo ""
        echo "  The installation has failed."
        if [ -n "$reason" ]; then
            echo "  Reason: $reason"
        fi
        echo ""
        echo "  Please check the error messages and the log file:"
        echo "    ${LOG_FILE}"
        echo ""
        echo "  To start over cleanly:"
        echo "    cd ${INSTALL_DIR} && sudo docker compose down"
    fi
    echo "============================================="
    echo ""
}

#################################################
#              HELPER FUNCTIONS                 #
#################################################

# Retry a command with exponential backoff
# Usage: retry 3 5 "description" command args...
retry() {
    local max_attempts=$1
    local delay=$2
    local desc=$3
    shift 3

    local attempt=1
    while [ $attempt -le "$max_attempts" ]; do
        if "$@" 2>>"$LOG_FILE"; then
            return 0
        fi
        log_warn "$desc — attempt $attempt/$max_attempts failed, retrying in ${delay}s…"
        sleep "$delay"
        delay=$((delay * 2))
        attempt=$((attempt + 1))
    done
    return 1
}

# Generate a secure random password
generate_password() {
    local length="${1:-30}"
    head -c 64 /dev/urandom | base64 | tr -d '+=/' | cut -c1-"$length"
}

# Check if a command exists
has_command() {
    command -v "$1" &>/dev/null
}

# Wait for a container's healthcheck to pass
wait_for_healthy() {
    local container_name=$1
    local timeout=${2:-$HEALTH_CHECK_TIMEOUT}
    local interval=${3:-$HEALTH_CHECK_INTERVAL}
    local elapsed=0

    log_info "Waiting for ${container_name} to become healthy…"

    while [ $elapsed -lt "$timeout" ]; do
        local status
        status=$(sudo docker inspect --format='{{.State.Health.Status}}' "$container_name" 2>/dev/null || echo "unknown")

        if [ "$status" = "healthy" ]; then
            log_ok "${container_name} is healthy (took ~${elapsed}s)"
            return 0
        fi

        if [ "$status" != "starting" ] && [ "$status" != "unknown" ]; then
            log_error "${container_name} health status: $status"
            return 1
        fi

        sleep "$interval"
        elapsed=$((elapsed + interval))
    done

    log_error "${container_name} did not become healthy within ${timeout}s"
    return 1
}

# Validate that we're running as root or via sudo
require_root() {
    if [ "$(id -u)" -ne 0 ] && ! sudo -n true 2>/dev/null; then
        fail "This script requires root privileges. Run with sudo."
    fi
}

# Ensure docker compose is available (v2 plugin or standalone)
docker_compose() {
    sudo docker compose "$@"
}

#################################################
#              PREREQUISITE CHECKS              #
#################################################

check_prerequisites() {
    log_info "Checking system prerequisites…"

    # Check Linux
    if [[ "$(uname -s)" != "Linux" ]]; then
        fail "This script must run on Linux."
    fi
    log_ok "Linux OS verified ($(uname -r))"

    # Check RAM ≥ 2 GB
    local total_ram
    total_ram=$(free -m | awk '/Mem:/ {print $2}')
    if [ "$total_ram" -lt 2000 ]; then
        fail "Minimum 2 GB RAM required. Current: ${total_ram} MB"
    fi
    log_ok "RAM check passed (${total_ram} MB)"

    # Check Disk ≥ 5 GB
    local available_disk
    available_disk=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$available_disk" -lt 5 ]; then
        fail "Minimum 5 GB free disk space required. Available: ${available_disk} GB"
    fi
    log_ok "Disk space check passed (${available_disk} GB free)"

    # Check Docker installed
    if ! has_command docker; then
        fail "Docker is not installed or not in PATH."
    fi

    # Check Docker version ≥ 20.10
    local docker_version
    docker_version=$(docker --version | awk '{print $3}' | sed 's/,//')
    local required_version="20.10"
    if [[ "$(printf '%s\n' "$required_version" "$docker_version" | sort -V | head -n1)" != "$required_version" ]]; then
        fail "Docker 20.10+ required. Current version: $docker_version"
    fi
    log_ok "Docker version verified ($docker_version)"

    # Check Docker is running
    if ! sudo docker info &>/dev/null; then
        fail "Docker daemon is not running. Start it and try again."
    fi

    # Check docker compose (plugin or standalone)
    if ! docker_compose version &>/dev/null; then
        fail "Docker Compose (v2 plugin) is not installed."
    fi
    log_ok "Docker Compose available"

    # Check connectivity to GHCR
    if ! curl -sf --connect-timeout 10 https://ghcr.io > /dev/null; then
        fail "Cannot reach ghcr.io. Check firewall or outbound access."
    fi
    log_ok "Internet / GHCR connectivity verified"

    # Check openssl (for CSR generation)
    if ! has_command openssl; then
        fail "openssl is not installed. Required for certificate generation."
    fi
}

#################################################
#              INTERACTIVE PROMPTS              #
#################################################

prompt_config() {
    echo ""
    echo "---------------------------------------------"
    echo -e "${CYAN} SETUP CONFIGURATION${NC}"
    echo "---------------------------------------------"

    # NTP Server
    if [ -z "${NTP_SERVER:-}" ]; then
        read -rp "  NTP server IP or hostname [192.168.0.1]: " ntp_input
        NTP_SERVER="${ntp_input:-192.168.0.1}"
    fi
    log_info "NTP Server: $NTP_SERVER"

    # GitHub Token
    GITHUB_USERNAME="Dev-Adanware"
    echo ""
    log_info "GitHub credentials required to download the application."

    if [ -z "${GITHUB_TOKEN:-}" ]; then
        read -rsp "  GitHub Token: " GITHUB_TOKEN
        echo ""
    fi

    if [ -z "$GITHUB_TOKEN" ]; then
        fail "GitHub token is required."
    fi
    log_ok "GitHub credentials received"
    echo ""
}

#################################################
#              WORKING DIRECTORY                #
#################################################

setup_directories() {
    log_info "Creating working directory…"

    sudo mkdir -p "$DATA_DIR"
    sudo mkdir -p "$BACKUP_DIR"
    sudo mkdir -p "$SSL_DIR"
    sudo chmod 750 "$DATA_DIR" "$BACKUP_DIR" "$SSL_DIR"
    sudo chown -R "$(id -u):$(id -g)" "$INSTALL_DIR"
    cd "$INSTALL_DIR"

    init_log

    log_ok "Working directory ready: $INSTALL_DIR"
}

#################################################
#              SSL BACKUP / RESTORE             #
#################################################

backup_ssl_certs() {
    if [ -f "$SSL_DIR/cert.pem" ] && [ -f "$SSL_DIR/key.pem" ]; then
        SSL_BACKUP_DIR="/tmp/tandd-ssl-backup-$(date +%Y%m%d%H%M%S)"
        TEMP_DIRS+=("$SSL_BACKUP_DIR")
        mkdir -p "$SSL_BACKUP_DIR"
        cp "$SSL_DIR"/{cert.pem,key.pem} "$SSL_BACKUP_DIR/"
        [ -f "$SSL_DIR/server.key" ] && cp "$SSL_DIR/server.key" "$SSL_BACKUP_DIR/"
        [ -f "$SSL_DIR/server.csr" ] && cp "$SSL_DIR/server.csr" "$SSL_BACKUP_DIR/"
        SSL_RESTORED=true
        log_ok "Existing SSL certificates backed up: $SSL_BACKUP_DIR"
    else
        log_info "No existing SSL certificate found — will generate CSR"
    fi
}

restore_ssl_certs() {
    if [ "$SSL_RESTORED" = true ] && [ -n "$SSL_BACKUP_DIR" ] && [ -d "$SSL_BACKUP_DIR" ]; then
        log_info "Restoring backed-up SSL certificates…"
        cp "$SSL_BACKUP_DIR"/* "$SSL_DIR/" 2>/dev/null || true
        SSL_RESTORED=false
        log_ok "SSL certificates restored"
        return 0
    fi
    return 1  # Nothing to restore
}

#################################################
#              ENVIRONMENT FILE                 #
#################################################

create_env_file() {
    log_info "Creating environment configuration…"

    if [ -f "$ENV_FILE" ]; then
        log_info "Existing .env found — preserving database credentials"
        # Source existing values
        set -a
        source "$ENV_FILE"
        set +a
    else
        if [ -z "$POSTGRES_PASSWORD" ]; then
            POSTGRES_PASSWORD=$(generate_password 30)
            log_ok "Generated secure database password (30 chars)"
        fi

        cat > "$ENV_FILE" << EOF
# PostgreSQL Database Configuration
POSTGRES_DB=${POSTGRES_DB}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# Backup Configuration
BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS}
EOF

        chmod 600 "$ENV_FILE"
        log_ok "Environment file created"
    fi
}

#################################################
#              DOCKER COMPOSE FILE              #
#################################################

create_compose_file() {
    log_info "Generating Docker Compose configuration…"

    cat > "$COMPOSE_FILE" << EOF
services:
  postgres:
    image: postgres:16-alpine
    container_name: tandd-postgres
    environment:
      POSTGRES_DB: \${POSTGRES_DB:-tandd}
      POSTGRES_USER: \${POSTGRES_USER:-tandd_user}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 512M
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U \${POSTGRES_USER:-tandd_user} -d \${POSTGRES_DB:-tandd}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 15s
    networks:
      - tandd-net

  app:
    image: ghcr.io/dev-adanware/tanddsrv:${APP_VERSION}
    container_name: tandd-app
    environment:
      DATABASE_URL: postgresql://\${POSTGRES_USER:-tandd_user}:\${POSTGRES_PASSWORD:-changeme123}@postgres:5432/\${POSTGRES_DB:-tandd}
    volumes:
      - ${DATA_DIR}:/app/data
      - ${SSL_DIR}:/etc/nginx/ssl:ro
    ports:
      - "80:80"
      - "443:443"
      - "21:21"
      - "60000-60100:60000-60100"
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped
    networks:
      - tandd-net

  backup:
    image: postgres:16-alpine
    container_name: tandd-backup
    environment:
      POSTGRES_DB: \${POSTGRES_DB:-tandd}
      POSTGRES_USER: \${POSTGRES_USER:-tandd_user}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD}
      BACKUP_RETENTION_DAYS: ${BACKUP_RETENTION_DAYS}
      BACKUP_CRON: "${BACKUP_CRON}"
      BACKUP_DIR: /backups
    volumes:
      - ${BACKUP_DIR}:/backups
    depends_on:
      postgres:
        condition: service_healthy
    entrypoint: ["/bin/sh", "-c"]
    command:
      - |
        echo "Backup service started — schedule: \$$BACKUP_CRON (UTC)"
        while true; do
          # Calculate seconds until next scheduled run
          now=\$((\$(date +%s) % 86400))
          cron_hour=\$${BACKUP_CRON%% *}  # extract hour from "0 2 * * *"
          cron_sec=\$((cron_hour * 3600))
          wait_secs=\$(( (cron_sec - now + 86400) % 86400 ))
          [ "\$wait_secs" -eq 0 ] && wait_secs=86400
          echo "Next backup in \${wait_secs}s"
          sleep "\$wait_secs"

          echo "Running backup at \$(date -u)"
          PGPASSWORD=\$POSTGRES_PASSWORD pg_dump \
            -h postgres -p 5432 \
            -U \$POSTGRES_USER -d \$POSTGRES_DB \
            --no-owner --no-acl -Fc \
            > /backups/tandd_backup_\$(date +%Y%m%d_%H%M%S).dump

          find /backups -name "tandd_backup_*.dump" -type f \
            -mtime +\$BACKUP_RETENTION_DAYS -delete
          echo "Backup complete. Retention: \$BACKUP_RETENTION_DAYS days"
        done
    restart: unless-stopped
    networks:
      - tandd-net

volumes:
  postgres_data:

networks:
  tandd-net:
    driver: bridge
EOF

    log_ok "Docker Compose file generated"
}

#################################################
#              DOCKER LOGIN                     #
#################################################

docker_login() {
    log_info "Authenticating with GitHub Container Registry…"

    if echo "$GITHUB_TOKEN" | sudo docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin 2>>"$LOG_FILE"; then
        log_ok "Docker authenticated to GHCR"
    else
        fail "Docker authentication failed. Verify your GitHub token has read:packages scope."
    fi
}

#################################################
#              PULL & DEPLOY                    #
#################################################

pull_and_deploy() {
    log_info "Pulling latest images…"

    if ! retry 3 5 "Image pull failed" sudo docker compose pull 2>>"$LOG_FILE"; then
        fail "Failed to pull Docker images after retries."
    fi
    log_ok "Images pulled successfully"

    log_info "Starting services…"

    # Stop existing containers cleanly for a fresh deploy
    docker_compose down --remove-orphans 2>>"$LOG_FILE" || true

    # Start all services
    docker_compose up -d --remove-orphans

    log_ok "Containers started"
}

#################################################
#              HEALTH VERIFICATION              #
#################################################

verify_deployment() {
    log_info "Verifying deployment health…"

    # Wait for PostgreSQL
    if ! wait_for_healthy "tandd-postgres"; then
        log_warn "PostgreSQL healthcheck did not pass — checking status…"
        sudo docker ps --filter "name=tandd-postgres" --format "table {{.Names}}\t{{.Status}}"
    else
        log_ok "PostgreSQL is running and healthy"
    fi

    # Check app container
    local app_status
    app_status=$(sudo docker inspect --format='{{.State.Status}}' tandd-app 2>/dev/null || echo "missing")
    if [ "$app_status" = "running" ]; then
        log_ok "Application container is running"
    else
        fail "Application container is not running (status: $app_status)"
    fi

    # Check backup container
    local backup_status
    backup_status=$(sudo docker inspect --format='{{.State.Status}}' tandd-backup 2>/dev/null || echo "missing")
    if [ "$backup_status" = "running" ]; then
        log_ok "Backup service is running"
    else
        log_warn "Backup service is not running (non-critical)"
    fi

    # Wait for HTTP response
    log_info "Waiting for web application to respond…"
    local elapsed=0
    while [ $elapsed -lt "$HEALTH_CHECK_TIMEOUT" ]; do
        if curl -sf --connect-timeout 3 http://localhost/ > /dev/null 2>&1; then
            log_ok "Web application is responding (~${elapsed}s)"
            return 0
        fi
        sleep "$HEALTH_CHECK_INTERVAL"
        elapsed=$((elapsed + HEALTH_CHECK_INTERVAL))
    done

    log_warn "Application is running but not yet responding on HTTP — it may need more time to initialise"
}

#################################################
#              SSL CERTIFICATES                 #
#################################################

handle_ssl() {
    echo ""
    echo "---------------------------------------------"
    echo -e "${CYAN} SSL CERTIFICATE HANDLING${NC}"
    echo "---------------------------------------------"

    if [ "$SSL_RESTORED" = true ]; then
        restore_ssl_certs
        log_info "Restarting app to apply restored certificate…"
        docker_compose restart app
        sleep 5
        log_ok "App restarted with original SSL certificate"
        return
    fi

    log_info "Generating Certificate Signing Request (CSR)…"

    # Determine Common Name
    if [ -z "$SSL_HOSTNAME" ]; then
        CERT_CN=$(hostname -f 2>/dev/null || hostname -I | awk '{print $1}')
        log_info "Auto-detected hostname: $CERT_CN"
    else
        CERT_CN="$SSL_HOSTNAME"
        log_info "Using configured hostname: $CERT_CN"
    fi

    # Generate CSR and private key
    openssl req -new -newkey rsa:2048 -nodes \
        -keyout "$SSL_DIR/server.key" \
        -out "$SSL_DIR/server.csr" \
        -subj "/C=${SSL_COUNTRY}/ST=${SSL_STATE}/L=${SSL_CITY}/O=${SSL_ORGANIZATION}/CN=${CERT_CN}" \
        2>>"$LOG_FILE"

    # Generate a self-signed certificate for immediate use
    # (This allows HTTPS to work until IT provides a signed cert)
    openssl req -x509 -nodes -days 365 \
        -key "$SSL_DIR/server.key" \
        -out "$SSL_DIR/cert.pem" \
        -subj "/C=${SSL_COUNTRY}/ST=${SSL_STATE}/L=${SSL_CITY}/O=${SSL_ORGANIZATION}/CN=${CERT_CN}" \
        2>>"$LOG_FILE"

    # Copy key to the name nginx typically expects
    cp "$SSL_DIR/server.key" "$SSL_DIR/key.pem"

    chmod 600 "$SSL_DIR"/server.key "$SSL_DIR"/key.pem "$SSL_DIR"/cert.pem

    log_ok "SSL certificate and CSR generated"

    SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "<server-ip>")

    echo ""
    echo "  HTTPS is configured with a self-signed certificate."
    echo "  Browsers will show a security warning — this is expected."
    echo ""
    echo "  CSR file: $SSL_DIR/server.csr"
    echo ""
    echo "  After receiving a signed certificate from IT:"
    echo "    1. Replace $SSL_DIR/cert.pem with the signed certificate"
    echo "    2. Replace $SSL_DIR/key.pem with the matching private key"
    echo "    3. Restart: cd $INSTALL_DIR && sudo docker compose restart app"
    echo ""
}

#################################################
#              MAIN EXECUTION                   #
#################################################

main() {
    show_banner
    log_info "Starting AMT-T&D deployment (version: $APP_VERSION)"

    require_root
    check_prerequisites
    prompt_config
    setup_directories
    backup_ssl_certs
    create_env_file
    docker_login
    create_compose_file
    pull_and_deploy
    verify_deployment
    handle_ssl

    SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "<server-ip>")

    echo ""
    echo "---------------------------------------------"
    echo -e "${GREEN}Deployment Completed Successfully!${NC}"
    echo "---------------------------------------------"
    echo ""
    echo "  Access URLs:"
    echo "    HTTP:  http://${SERVER_IP}/"
    echo "    HTTPS: https://${SERVER_IP}/"
    echo ""
    echo "  Log file: ${LOG_FILE}"
    echo "---------------------------------------------"
    echo ""

    show_final_message "success"
}

main "$@"
