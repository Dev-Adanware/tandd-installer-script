#!/bin/bash

set -e

#################################################
#               USER VARIABLES                  #
#  These will be prompted interactively          #
#################################################

# Application version to deploy (use "latest" for latest release)
APP_VERSION="latest"

# PostgreSQL Database Settings (auto-generated if not set)
POSTGRES_DB="tandd"
POSTGRES_USER="tandd_user"
POSTGRES_PASSWORD=""  # Leave empty to auto-generate secure password

# SSL Certificate Information (for CSR generation)
# Leave empty to auto-detect server hostname
SSL_HOSTNAME=""           # e.g., "shf-tms-01" or "tandd.company.com"
SSL_COUNTRY="SA"          # Two-letter country code (SA = Saudi Arabia)
SSL_STATE="Riyadh"        # State or Province
SSL_CITY="Riyadh"         # City
SSL_ORGANIZATION="ADANWARE"  # Company name

#################################################
#              DO NOT EDIT BELOW                #
#################################################

echo "============================================="
echo "      AMT-T&D Automated Deployment"
echo "           Powered by ADANWARE"
echo "============================================="

### -------------------------------
### 1. INTERACTIVE SETUP PROMPTS
### -------------------------------

echo ""
echo "---------------------------------------------"
echo "📋 SETUP CONFIGURATION"
echo "---------------------------------------------"

# Prompt for NTP Server
if [ -z "${NTP_SERVER:-}" ]; then
    read -rp "🌐 Enter your NTP server IP or hostname [192.168.0.1]: " NTP_INPUT
    NTP_SERVER="${NTP_INPUT:-192.168.0.1}"
fi
echo "  ✓ NTP Server: $NTP_SERVER"

# Prompt for GitHub credentials
echo ""
echo "🔐 GitHub credentials required to download the application:"
read -rp "   GitHub Username [Dev-Adanware]: " GH_USER_INPUT
GITHUB_USERNAME="${GH_USER_INPUT:-Dev-Adanware}"
read -rp "   GitHub Token: " GITHUB_TOKEN
echo ""

if [ -z "$GITHUB_TOKEN" ]; then
    echo "❌ GitHub token is required. Please provide a valid token."
    exit 1
fi
echo "  ✓ GitHub credentials received"
echo ""

### -------------------------------
### 2. PREREQUISITE CHECKS
### -------------------------------

echo "Checking system prerequisites..."
# Check Linux
if [[ "$(uname -s)" != "Linux" ]]; then
    echo "❌ This script must run on Linux."
    exit 1
else
    echo "✅ Linux OS verified"
fi

# Check RAM ≥ 2GB
TOTAL_RAM=$(free -m | awk '/Mem:/ {print $2}')
if [ "$TOTAL_RAM" -lt 2000 ]; then
    echo "❌ Minimum 2GB RAM required. Current: ${TOTAL_RAM}MB"
    exit 1
else
    echo "✅ RAM check passed (${TOTAL_RAM}MB)"
fi

# Check Disk ≥ 20GB
AVAILABLE_DISK=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "$AVAILABLE_DISK" -lt 5 ]; then
    echo "❌ Minimum 5GB free disk space required. Available: ${AVAILABLE_DISK}GB"
    exit 1
else
    echo "✅ Disk space check passed (${AVAILABLE_DISK}GB free)"
fi

# Check Docker installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed."
    exit 1
fi

# Check Docker version ≥ 20.10
DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
REQUIRED_VERSION="20.10"

if [[ "$(printf '%s\n' "$REQUIRED_VERSION" "$DOCKER_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]]; then
    echo "❌ Docker 20.10+ required. Current version: $DOCKER_VERSION"
    exit 1
else
    echo "✅ Docker version verified ($DOCKER_VERSION)"
fi

# Check connectivity to GHCR
if ! curl -s https://ghcr.io > /dev/null; then
    echo "❌ Cannot reach ghcr.io. Check firewall or outbound access."
    exit 1
else
    echo "✅ Internet / GHCR connectivity verified"
fi

echo "---------------------------------------------"

### -------------------------------
### 3. CREATE WORKING DIRECTORY
### -------------------------------

echo "Creating working directory..."

sudo mkdir -p /opt/amt-tandd/tandd-data
sudo mkdir -p /opt/amt-tandd/tandd-data/backups
sudo mkdir -p /opt/amt-tandd/ssl-certs
sudo chown -R "$(id -u):$(id -g)" /opt/amt-tandd
cd /opt/amt-tandd

echo "✅ Working directory ready"
echo "ℹ️  Data directory: /opt/amt-tandd/tandd-data"
echo "ℹ️  Backups directory: /opt/amt-tandd/tandd-data/backups"
echo "ℹ️  SSL certificates directory: /opt/amt-tandd/ssl-certs"

### -------------------------------
### 3b. BACKUP EXISTING SSL CERTIFICATES
### -------------------------------

SSL_BACKUP_DIR="/tmp/tandd-ssl-backup-$(date +%Y%m%d%H%M%S)"
SSL_RESTORED=false

if [ -f /opt/amt-tandd/ssl-certs/cert.pem ] && [ -f /opt/amt-tandd/ssl-certs/key.pem ]; then
    echo "🔐 Existing SSL certificate found - backing up before deployment..."
    mkdir -p $SSL_BACKUP_DIR
    cp /opt/amt-tandd/ssl-certs/cert.pem $SSL_BACKUP_DIR/cert.pem
    cp /opt/amt-tandd/ssl-certs/key.pem $SSL_BACKUP_DIR/key.pem
    [ -f /opt/amt-tandd/ssl-certs/server.key ] && cp /opt/amt-tandd/ssl-certs/server.key $SSL_BACKUP_DIR/server.key
    [ -f /opt/amt-tandd/ssl-certs/server.csr ] && cp /opt/amt-tandd/ssl-certs/server.csr $SSL_BACKUP_DIR/server.csr
    SSL_RESTORED=true
    echo "✅ SSL certificates backed up to: $SSL_BACKUP_DIR"
else
    echo "ℹ️  No existing SSL certificate found - will generate CSR for IT department"
fi

### -------------------------------
### 4. DOCKER LOGIN (optional - only needed for private images)
### -------------------------------

echo "Authenticating with GitHub Container Registry..."
if echo "$GITHUB_TOKEN" | sudo docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin 2>/dev/null; then
    echo "✅ Docker authenticated successfully"
else
    echo "❌ Authentication failed! Check your GitHub username and token."
    exit 1
fi

### -------------------------------
### 5. CREATE ENVIRONMENT FILE
### -------------------------------

echo "Creating environment configuration..."

# Preserve existing .env on redeployment
if [ -f /opt/amt-tandd/.env ]; then
    echo "  ✓ Existing .env file found - preserving database credentials"
    source /opt/amt-tandd/.env
else
    # Generate secure password if not provided (first-time deploy only)
    if [ -z "$POSTGRES_PASSWORD" ]; then
        POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
        echo "✅ Generated secure database password"
    fi

    # Create .env file
    cat > /opt/amt-tandd/.env << EOF
# PostgreSQL Database Configuration
POSTGRES_DB=${POSTGRES_DB}
POSTGRES_USER=${POSTGRES_USER}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# Backup Configuration
BACKUP_RETENTION_DAYS=7
EOF

    echo "✅ Environment file created"
fi

### -------------------------------
### 6. CREATE DOCKER COMPOSE FILE
### -------------------------------

echo "Creating docker-compose configuration..."

cat > /opt/amt-tandd/docker-compose.yml << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:16-alpine
    container_name: tandd-postgres
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-tandd}
      POSTGRES_USER: ${POSTGRES_USER:-tandd_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-changeme123}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./tandd-data/backups:/backups
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-tandd_user} -d ${POSTGRES_DB:-tandd}"]
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    image: ghcr.io/dev-adanware/tanddsrv:APP_VERSION_PLACEHOLDER
    container_name: tandd-app
    environment:
      DATABASE_URL: postgresql://${POSTGRES_USER:-tandd_user}:${POSTGRES_PASSWORD:-changeme123}@postgres:5432/${POSTGRES_DB:-tandd}
    volumes:
      - ./tandd-data:/app/data
      - ./ssl-certs:/etc/nginx/ssl
    ports:
      - "80:80"
      - "443:443"
      - "21:21"
      - "60000-60100:60000-60100"
    depends_on:
      postgres:
        condition: service_healthy
    restart: unless-stopped

  backup:
    image: postgres:16-alpine
    container_name: tandd-backup
    environment:
      POSTGRES_DB: ${POSTGRES_DB:-tandd}
      POSTGRES_USER: ${POSTGRES_USER:-tandd_user}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-changeme123}
      BACKUP_RETENTION_DAYS: 7
    volumes:
      - ./tandd-data/backups:/backups
    depends_on:
      postgres:
        condition: service_healthy
    entrypoint: ["/bin/sh", "-c"]
    command:
      - |
        echo "Starting backup service..."
        while true; do
          echo "Running backup at $(date)"
          PGPASSWORD=$POSTGRES_PASSWORD pg_dump -h postgres -p 5432 -U $POSTGRES_USER -d $POSTGRES_DB --no-owner --no-acl | gzip > /backups/tandd_backup_$(date +%Y%m%d_%H%M%S).sql.gz
          find /backups -name "tandd_backup_*.sql.gz" -type f -mtime +$BACKUP_RETENTION_DAYS -delete
          echo "Next backup in 24 hours"
          sleep 86400
        done
    restart: unless-stopped

volumes:
  postgres_data:
EOF

# Replace version placeholder
sed -i "s/APP_VERSION_PLACEHOLDER/${APP_VERSION}/g" /opt/amt-tandd/docker-compose.yml

echo "✅ Docker Compose file created"

### -------------------------------
### 7. PULL IMAGES
### -------------------------------

echo "Pulling Docker images..."

sudo docker pull postgres:16-alpine

echo "✅ Images pulled successfully"

### -------------------------------
### 8. START SERVICES
### -------------------------------

echo "Starting services with Docker Compose..."

# Stop and remove old single container if exists
sudo docker stop tandd-app 2>/dev/null || true
sudo docker rm tandd-app 2>/dev/null || true

# Start all services
cd /opt/amt-tandd
sudo docker compose up -d

echo "✅ Services started (PostgreSQL + Application + Backup)"

### -------------------------------
### 9. VERIFY DEPLOYMENT
### -------------------------------

echo "Waiting for services to start..."
sleep 15

if sudo docker ps | grep -q tandd-postgres; then
    echo "✅ PostgreSQL database is running"
else
    echo "❌ PostgreSQL failed to start"
    exit 1
fi

if sudo docker ps | grep -q tandd-app; then
    echo "✅ Application is running"
else
    echo "❌ Application failed to start"
    exit 1
fi

if sudo docker ps | grep -q tandd-backup; then
    echo "✅ Backup service is running"
else
    echo "⚠️  Backup service not running (non-critical)"
fi

SERVER_IP=$(hostname -I | awk '{print $1}')

echo "---------------------------------------------"
echo "🎉 Deployment Completed Successfully!"
echo "---------------------------------------------"
echo ""
echo "📊 SERVICES RUNNING:"
echo "  • PostgreSQL Database (with automatic backups)"
echo "  • T&D Data Server Application"
echo "  • Daily Backup Service (7-day retention)"
echo ""
echo "🌐 ACCESS THE APPLICATION:"
echo "  HTTP:  http://$SERVER_IP/"
echo "  HTTPS: https://$SERVER_IP/ (self-signed certificate)"
echo ""
echo "ℹ️  HTTPS uses auto-generated self-signed certificate."
echo "   Browsers will show a warning - this is normal."
echo "   Click 'Advanced' → 'Proceed' to access."
echo ""
echo "🔐 TO USE PROPER SSL CERTIFICATE FROM IT:"
echo "   1. Place IT's certificates in /opt/amt-tandd/ssl-certs/"
echo "      - cert.pem (certificate file)"
echo "      - key.pem (private key file)"
echo "   2. Restart: cd /opt/amt-tandd && sudo docker compose restart app"
echo ""
echo "💾 DATABASE BACKUPS:"
echo "   Location: /opt/amt-tandd/tandd-data/backups/"
echo "   Schedule: Daily at midnight"
echo "   Retention: 7 days"
echo ""
echo "📝 CREDENTIALS SAVED IN:"
echo "   /opt/amt-tandd/.env"
echo "   ⚠️  Keep this file secure!"
echo "---------------------------------------------"

if curl -s http://localhost/ > /dev/null; then
    echo "✅ Web application is responding and ready to use!"
else
    echo "⚠️  Application started but not responding yet. Wait 30 seconds and try again."
fi

### -------------------------------
### 10. SSL CERTIFICATE HANDLING
### -------------------------------

echo ""
echo "---------------------------------------------"
echo "� SSL CERTIFICATE HANDLING"
echo "---------------------------------------------"

if [ "$SSL_RESTORED" = true ]; then
    echo "♻️  Restoring previously installed SSL certificate..."
    cp $SSL_BACKUP_DIR/cert.pem /opt/amt-tandd/ssl-certs/cert.pem
    cp $SSL_BACKUP_DIR/key.pem /opt/amt-tandd/ssl-certs/key.pem
    [ -f $SSL_BACKUP_DIR/server.key ] && cp $SSL_BACKUP_DIR/server.key /opt/amt-tandd/ssl-certs/server.key
    [ -f $SSL_BACKUP_DIR/server.csr ] && cp $SSL_BACKUP_DIR/server.csr /opt/amt-tandd/ssl-certs/server.csr
    echo "✅ SSL certificate restored successfully!"

    # Restart app to pick up restored certificate
    echo "🔄 Restarting app to apply restored certificate..."
    cd /opt/amt-tandd
    sudo docker compose restart app
    sleep 5
    echo "✅ App restarted with original SSL certificate"

    # Clean up temp backup
    rm -rf $SSL_BACKUP_DIR
    echo "✅ Temporary backup cleaned up"
else
    echo "📋 GENERATING CERTIFICATE SIGNING REQUEST (CSR)"
    echo ""
    echo "Generating CSR file for IT department..."

    # Determine Common Name (CN) for certificate
    if [ -z "$SSL_HOSTNAME" ]; then
        CERT_CN=$(hostname -f 2>/dev/null || hostname -I | awk '{print $1}')
        echo "  Auto-detected server identifier: $CERT_CN"
    else
        CERT_CN="$SSL_HOSTNAME"
        echo "  Using custom hostname: $CERT_CN"
    fi

    # Generate CSR and private key for IT
    openssl req -new -newkey rsa:2048 -nodes \
        -keyout /opt/amt-tandd/ssl-certs/server.key \
        -out /opt/amt-tandd/ssl-certs/server.csr \
        -subj "/C=${SSL_COUNTRY}/ST=${SSL_STATE}/L=${SSL_CITY}/O=${SSL_ORGANIZATION}/CN=${CERT_CN}" \
        2>/dev/null

    echo "✅ CSR generated successfully!"
    echo ""
    echo "📧 SEND THIS FILE TO YOUR IT DEPARTMENT:"
    echo "   File: /opt/amt-tandd/ssl-certs/server.csr"
    echo ""
    echo "📄 CSR CONTENT:"
    echo "---------------------------------------------"
    cat /opt/amt-tandd/ssl-certs/server.csr
    echo "---------------------------------------------"
    echo ""
    echo "🔧 AFTER RECEIVING CERTIFICATE FROM IT:"
    echo "   1. Save as: /opt/amt-tandd/ssl-certs/cert.pem"
    echo "   2. Run: sudo cp /opt/amt-tandd/ssl-certs/server.key /opt/amt-tandd/ssl-certs/key.pem"
    echo "   3. Run: cd /opt/amt-tandd && sudo docker compose restart app"
    echo ""
fi

echo "---------------------------------------------"
echo ""
echo "📚 For more information, visit the documentation."
echo "🆘 For support, contact ADANWARE."
echo ""
