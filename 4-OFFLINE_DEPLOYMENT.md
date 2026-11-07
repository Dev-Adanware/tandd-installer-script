# AMT T&D v1.23.2 Offline Installation and Upgrade

This guide covers a new offline installation and the validated upgrade from **v1.23.1 to v1.23.2**. Use the [online deployment guide](./2-Deployment_USER_GUIDE.md) only for the existing GitHub-based installation path.

## Obtain the package

ADANWARE provides a password-protected [download link](https://cloud.dadi411-family.eu/s/YC8EFNkHxsQ8jFo). Obtain the password directly from ADANWARE. Download both files to a machine that can access the link:

- `amt-tandd-offline-licensing-v1.23.2.tar.gz`
- `amt-tandd-offline-licensing-v1.23.2.tar.gz.sha256`

The published archive SHA-256 is `65017442ba21fe2316e17fdac86cc436f03091b9ec294b08f5d82ab0f12be450`. Stop and contact ADANWARE if either checksum verification below fails.

## Server requirements

- x86-64/amd64 Linux server with Docker Engine and the Docker Compose plugin installed and functional.
- Administrator or sudo access, plus sufficient storage for the included application images, PostgreSQL data, and backups.
- Local network connectivity to monitoring devices and application users.
- Correct system time and a reliable NTP source; license validation depends on time.
- Python 3 on the target server for the package installer.

The target server needs no internet access when these prerequisites and the complete package are available. It does not need a GitHub token or GitHub Container Registry access. See [IT prerequisites](./1-IT_Prerequisites.md) for server sizing and network requirements.

## Install a new server

Run steps 1 and 2 on the download machine. Replace `username` and `SERVER_IP` with your server details.

### 1. Verify the downloaded archive

From the directory containing both downloaded files:

```bash
sha256sum -c amt-tandd-offline-licensing-v1.23.2.tar.gz.sha256
```

Confirm that the result is `OK` and that the archive digest matches the published SHA-256 above. Do not extract an archive that fails verification.

### 2. Transfer the archive

```bash
scp amt-tandd-offline-licensing-v1.23.2.tar.gz \
  username@SERVER_IP:~/
```

Alternatively, transfer the verified archive using approved removable media.

### 3. Extract it on the Linux server

```bash
mkdir -p ~/amt-tandd-install

tar -xzf ~/amt-tandd-offline-licensing-v1.23.2.tar.gz \
  -C ~/amt-tandd-install

cd ~/amt-tandd-install/amt-tandd-offline-licensing-v1.23.2
```

### 4. Verify the files inside the package

```bash
sha256sum -c SHA256SUMS
```

Every listed file must report `OK`. Stop and contact ADANWARE if any check fails.

### 5. Install

```bash
sudo ./install.sh
```

The installer verifies the package, loads the included Docker images locally, and starts the deployment with `--pull never`. Follow any installer prompts. Keep the archive and checksum file for your records.

## First activation

1. Open `http://SERVER_IP/` in a browser that can reach the server.
2. The **Activation Required** page displays the Installation ID. Copy it and provide it to ADANWARE.
3. ADANWARE issues a customer-specific signed `license.json` for the supported license type.
4. Upload `license.json` through the activation page, then continue to login after successful activation.

No trial is granted automatically. The browser and target server do not need internet access for activation; the license file is issued through your agreed process with ADANWARE.

## Upgrade an existing customer installation

The validated legacy upgrade path is **v1.23.1 → v1.23.2**. Versions older than v1.23.1 require an ADANWARE compatibility assessment. Do not use the online installer for this offline upgrade.

Before starting:

1. Confirm the installed application version, image, Compose project, PostgreSQL volume, and deployment layout. Stop and contact ADANWARE if the layout differs from the validated installation.
2. Schedule a maintenance window and pause ingestion as required for a consistent backup.
3. Create and verify a PostgreSQL backup. Preserve the application data, licensing state, environment credentials, SSL certificates, public keys, Compose files, and backup helper. Protect the backup and confirm the recovery procedure before proceeding.
4. Verify the package as described above. Keep the previous package and images available for an approved recovery procedure.

From the extracted v1.23.2 package directory, run:

```bash
sudo ./install.sh /opt/amt-tandd
```

The installer checks the existing deployment and contains a guarded, one-time legacy Installation ID migration. **Do not bypass it.** If a preflight check fails, stop and contact ADANWARE. Do not alter identity files, credentials, or the PostgreSQL volume to force the upgrade. The installer preserves the existing data and starts the local images with `--pull never`.

Afterward, compare application data and license state with the pre-upgrade record, then verify login, monitoring, reports, device ingestion, and backups.

## License management

Signed trial licenses have an expiration date. A valid supported license and its Installation ID are stored with persistent application data and are preserved by supported upgrades and container recreation while the signing key remains trusted. Administrators can view the Installation ID and manage supported license actions under **Settings → About**; the activation page displays the Installation ID when activation is required.

The approved v1.23.2 upgrade guide does **not** establish perpetual-license semantics or trial-to-perpetual conversion for this release. Ask ADANWARE to confirm availability and the supported procedure before relying on either. The browser-based **Offline Software Update** section is currently disabled; use the approved offline installer for updates.

## Verify the deployment

Run these commands on the server. The Compose commands use the standard `/opt/amt-tandd` deployment path:

```bash
sudo systemctl status docker
sudo docker compose --project-name amt-tandd \
  --file /opt/amt-tandd/docker-compose.offline.yml ps
sudo docker compose --project-name amt-tandd \
  --file /opt/amt-tandd/docker-compose.offline.yml logs --tail=100 app postgres backup
curl -i http://localhost/api/license/status
```

Review the `postgres` service status and logs for database health. The HTTP command checks the license-status endpoint; its unauthenticated response may be limited or require authentication and must not be used to infer that an Installation ID is missing. Open `http://SERVER_IP/` to check activation or login, and use **Settings → About** after administrator login. If the installation is still waiting for activation, copy the ID from the activation page. To recheck package integrity from the extracted package directory, run `sha256sum -c SHA256SUMS`; on the download machine, rerun the archive `.sha256` check above.

## Troubleshooting and recovery

- **Checksum failure:** Stop. Obtain fresh package files from ADANWARE and verify them before retrying.
- **Docker or PostgreSQL unhealthy:** Save the Compose status and logs. Confirm Docker is running and the server has adequate storage. Contact ADANWARE if service health does not recover.
- **Activation or license problem:** Check system time and NTP, preserve the displayed Installation ID and error details, and contact ADANWARE for license or identity recovery.
- **Upgrade preflight or post-upgrade failure:** Stop further changes. Retain logs, the prior images, the verified backup, and the current data. Follow the approved recovery procedure with ADANWARE, using matching PostgreSQL and application-data backups when a restore is necessary.

Never delete Docker volumes or manually replace identity files to troubleshoot. The offline deployment does not require a GitHub token.
