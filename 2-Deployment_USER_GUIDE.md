# AMT T&D Deployment Guide

Before starting, check the [IT prerequisites](./1-IT_Prerequisites.md). Both methods need a Linux server with Docker, Docker Compose, SSH access, and sudo privileges. Online installation needs internet access and a GitHub token from ADANWARE. Offline installation needs Python 3; the server does not need internet access.

## Option A — Online Installation (`v1.23.2-lic-3`)

### 1. Connect to the server

```bash
ssh username@SERVER_IP
```

### 2. Download and run the installer

```bash
curl -fsSL https://raw.githubusercontent.com/Dev-Adanware/tandd-installer-script/main/tandd-installer.sh -o tandd-installer.sh
sudo bash tandd-installer.sh
```

Enter your NTP server and the GitHub token provided by ADANWARE when prompted.

### 3. Open the application

Open this address in a browser:

```text
http://SERVER_IP/
```

## Option B — Offline Installation (`v1.23.2-lic-3`)

Ask ADANWARE for the corrected package and its matching checksum. After you receive both files, use these commands.

Package name:

```text
amt-tandd-offline-licensing-v1.23.2-lic-3.tar.gz
```

### 1. Transfer the files

From your computer, in the folder containing the package and checksum, run:

```bash
scp amt-tandd-offline-licensing-v1.23.2-lic-3.tar.gz \
  amt-tandd-offline-licensing-v1.23.2-lic-3.tar.gz.sha256 \
  username@SERVER_IP:~/
```

### 2. Connect to the server and verify the checksum

```bash
ssh username@SERVER_IP
cd ~
sha256sum -c amt-tandd-offline-licensing-v1.23.2-lic-3.tar.gz.sha256
```

Continue only if the checksum result is `OK`.

### 3. Extract the package

```bash
mkdir -p ~/amt-tandd-install
tar -xzf amt-tandd-offline-licensing-v1.23.2-lic-3.tar.gz \
  -C ~/amt-tandd-install
cd ~/amt-tandd-install/amt-tandd-offline-licensing-v1.23.2-lic-3
```

### 4. Install and open the application

```bash
sudo ./install.sh
```

When installation finishes, open this address in a browser:

```text
http://SERVER_IP/
```

## License Activation — Both Methods

1. Copy the Installation ID shown in the application.
2. Send it to ADANWARE and request a license file.
3. Upload the license file you receive.

A **Trial** license expires on its stated date. A **Perpetual** license does not expire.

## Login and Configuration

Sign in with the administrator details provided for your installation. Change the default password after your first login.

Follow the [System and Base Station Configuration Guide](./3-SETUP_AND_CONFIGURATION.md).
