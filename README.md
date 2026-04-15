# AMT T&D Automated Installer

Automated deployment script for the **AMT T&D Data Server** by [ADANWARE](https://adanware.com).

---

## Requirements

Before running the installer, ensure the target server has:

- **OS**: Linux (Ubuntu 20.04+ recommended)
- **RAM**: Minimum 2 GB
- **Disk**: Minimum 5 GB free space
- **Docker**: Version 20.10 or higher
- **Internet access**: To reach `ghcr.io` (GitHub Container Registry)
- **GitHub Token**: A personal access token with `read:packages` permission (provided by ADANWARE)

---

## Installation

### Step 1 — Download the installer

```bash
curl -fsSL https://raw.githubusercontent.com/Dev-Adanware/tandd-installer-script/main/tandd-installer.sh -o tandd-installer.sh
```

### Step 2 — Run the installer

```bash
sudo bash tandd-installer.sh
```

### Step 3 — Follow the prompts

The installer will ask for:

```
📋 SETUP CONFIGURATION
---------------------------------------------
🌐 Enter your NTP server IP or hostname [192.168.0.1]: <your NTP server>
🔐 GitHub credentials required to download the application:
   GitHub Username [Dev-Adanware]: 
   GitHub Token (input hidden): <token provided by ADANWARE>
```

---

## What the Installer Does

1. ✅ Verifies system prerequisites (OS, RAM, disk, Docker)
2. ✅ Creates working directory at `/opt/amt-tandd/`
3. ✅ Backs up existing SSL certificates (on re-deployment)
4. ✅ Authenticates with GitHub Container Registry
5. ✅ Generates a secure PostgreSQL password (first-time only)
6. ✅ Creates Docker Compose configuration
7. ✅ Pulls and starts all services (App + Database + Backup)
8. ✅ Restores SSL certificates (on re-deployment)
9. ✅ Generates a CSR for IT department to sign (first-time only)

---

## After Installation

Access the application at:

| Protocol | URL |
|----------|-----|
| HTTP | `http://<server-ip>/` |
| HTTPS | `https://<server-ip>/` |

**Default credentials:**
- Username: `admin`
- Password: `admin123`

> ⚠️ Change the default password immediately after first login.

---

## SSL Certificate Setup

On **first-time deployment**, the installer generates a Certificate Signing Request (CSR):

1. Send `/opt/amt-tandd/ssl-certs/server.csr` to your IT department
2. Receive the signed certificate (`cert.pem`) from IT
3. Place the files on the server:
   ```bash
   sudo cp cert.pem /opt/amt-tandd/ssl-certs/cert.pem
   sudo cp /opt/amt-tandd/ssl-certs/server.key /opt/amt-tandd/ssl-certs/key.pem
   ```
4. Restart the app:
   ```bash
   cd /opt/amt-tandd && sudo docker compose restart app
   ```

On **re-deployment**, existing SSL certificates are automatically backed up and restored — no manual steps needed.

---

## Re-deployment / Update

To update the application to the latest version, simply re-run the installer:

```bash
sudo bash tandd-installer.sh
```

The installer will:
- ✅ Preserve the existing database and credentials
- ✅ Preserve the existing SSL certificates
- ✅ Pull and deploy the latest application version

---

## Data & Backups

| Item | Location |
|------|----------|
| Application data | `/opt/amt-tandd/tandd-data/` |
| Database backups | `/opt/amt-tandd/tandd-data/backups/` |
| SSL certificates | `/opt/amt-tandd/ssl-certs/` |
| Environment / credentials | `/opt/amt-tandd/.env` |

> ⚠️ Keep `/opt/amt-tandd/.env` secure — it contains the database password.

---

## Support

For support, contact **ADANWARE**.
