# AMT Monitoring System

# IT Prerequisites & System Requirements

This document describes the infrastructure, network, and system requirements required before deploying the AMT Monitoring System.

---

# 1. Server / VM Preparation

Prepare a Linux server or virtual machine with the specifications based on the expected number of sensors.

## Recommended Server Specifications

| Sensors        | Recommended RAM | Recommended Disk |
| -------------- | --------------- | ---------------- |
| 1 – 100        | 4 GB            | 50 GB SSD        |
| 100 – 500      | 8 GB            | 100 GB SSD       |
| 500 – 1,000    | 16 GB           | 200 GB SSD       |
| 1,000 – 5,000  | 32 GB           | 500 GB SSD       |
| 5,000 – 10,000 | 64 GB           | 1 TB SSD         |

---

## Notes

* SSD storage is strongly recommended.
* Linux Ubuntu Server is recommended.
* Docker must be installed and verified.
* OpenSSH access must be enabled.
* Root or sudo privileges are required for Docker operations.

---

## Docker Requirements

| Component | Minimum Version | Recommended Version |
| --------- | --------------- | ------------------- |
| Docker    | 20.10+          | 24.0+               |

---

# 2. Database Size Estimation

## Assumptions

* Average row size ≈ 170 bytes per reading
* Polling interval = every 5 minutes

| Sensors | Polling Interval | Readings/Day | Daily Growth | Yearly Growth |
| ------- | ---------------- | ------------ | ------------ | ------------- |
| 100     | 5 minutes        | 28,800       | ~5 MB        | ~1.8 GB       |
| 500     | 5 minutes        | 144,000      | ~24 MB       | ~8.5 GB       |
| 1,000   | 5 minutes        | 288,000      | ~48 MB       | ~17 GB        |
| 5,000   | 5 minutes        | 1,440,000    | ~240 MB      | ~85 GB        |
| 10,000  | 5 minutes        | 2,880,000    | ~480 MB      | ~170 GB       |

---

# 3. SMTP Service Account Requirements

A dedicated email account is required for the application to send:

* System notifications
* Alert notifications
* Monitoring alerts

The following information must be provided:

* SMTP Server IP or Hostname
* SMTP Port Number

If secure SMTP is used (SSL/TLS), the following must also be provided:

* Email account / service account username
* Password / credentials
* SSL/TLS port number

---

# 4. SNTP / NTP Requirements

A valid SNTP/NTP server hostname or IP address must be provided.

Time synchronization is mandatory for accurate monitoring and logging.

---

# 5. Reserved IP Addresses

Reserved IP addresses are required for:

* Application Server / VM
* T&D Base Station(s)

---

# 6. Firewall & Network Requirements

## 6.1 Base Station Communication

T&D Base Stations must be allowed to send reading data to the application server using HTTP.

### Source

* T&D Base Station(s)

### Destination

* Application Server

### Protocol

* HTTP

### Note

Only temperature and monitoring readings are transmitted. No sensitive data is exchanged.

---

## 6.2 Application Access

The application server must be accessible using:

* Hostname (if DNS resolvable)
  OR
* IP Address

Example:

```text
http://<vm_ip>
```

---

## HTTPS Note

The application is delivered with a self-signed certificate.

HTTPS access is supported, but the customer must replace the self-signed certificate with their own trusted SSL certificate if required.

---

# 6.3 Internet Access / Outbound Firewall Rules

The server requires outbound HTTPS access to trusted third-party providers for Docker image retrieval during:

Initial system installation
Future system updates

Note

Internet access or the required endpoint whitelisting is only needed for installation and update activities.

## Required Outbound Access

### Protocol
Note

Internet access or the required endpoint whitelisting is only needed for installation and update activities.
* HTTPS (TCP Port 443)

---

## Required Endpoints

| Endpoint             | Purpose                                                |
| -------------------- | ------------------------------------------------------ |
| ghcr.io              | GitHub Container Registry metadata and image retrieval |
| *.pkg.github.com     | GitHub Packages CDN for Docker image layers            |
| github.com           | GitHub authentication and token validation             |
| docker.io            | Docker Hub registry access                             |
| registry-1.docker.io | Docker image layer delivery                            |

---

## Why These Endpoints Are Required

* `github.com` is used for GitHub authentication and token validation.
* `ghcr.io` hosts container image metadata and registry services.
* `*.pkg.github.com` delivers Docker image layers and package content.
* `docker.io` and `registry-1.docker.io` are required to download PostgreSQL Docker images.

Blocking any of these endpoints may cause deployment or image pull failures.

---

## Security Note

* All endpoints belong to trusted third-party providers.
* All communication is outbound HTTPS traffic only.
* No inbound internet firewall changes are required.

---

# 7. Deployment Readiness Confirmation

After completing all preparation steps, the following information must be provided to proceed with deployment:

## Required Confirmation

1. Confirmation that the Linux server is ready
2. Confirmation that Docker is installed and operational
3. Confirmation that the server specifications match the sizing matrix
4. Confirmation that internet access or required endpoint whitelisting is completed

---

## Required Deployment Information

The following information must be shared with the deployment team:

1. Linux Server IP Address
2. Linux Server Username
3. Linux Server Password
4. SNTP/NTP Server IP or Hostname
5. SMTP Server IP/Hostname
6. SMTP Port Number
7. SMTP Service Account / Email Account
8. SMTP Credentials (if SSL/TLS is used)

---

# 8. Recommended Operating System

| Operating System | Recommendation |
| ---------------- | -------------- |
| Ubuntu Server    | Recommended    |

---

# 9. Additional Notes

* SSD storage is highly recommended for database performance.
* Stable internet connectivity is recommended during deployment.
* Docker services must remain enabled and running.
* The server must have sufficient free storage for future database growth.
