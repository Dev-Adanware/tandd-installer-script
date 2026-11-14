# AMT T&D Offline Upgrade

For a new offline installation, package requests, checksum verification, and installation steps, use the [Deployment Guide](./2-Deployment_USER_GUIDE.md).

## Supported upgrade

The validated offline upgrade is from **v1.23.1 to v1.23.2-lic-3**. Contact ADANWARE before upgrading from another version. Do not use the online installer for this offline upgrade.

Before the maintenance window:

1. Confirm the existing installation uses the supported version and standard `/opt/amt-tandd` location.
2. Create and verify a PostgreSQL backup.
3. Keep the existing data, license, configuration, SSL files, and backup safe.
4. Obtain the upgrade package and checksum from ADANWARE, then follow the verification steps in the [Deployment Guide](./2-Deployment_USER_GUIDE.md).

From the extracted package directory, run:

```bash
sudo ./install.sh /opt/amt-tandd
```

If an upgrade check fails, stop and contact ADANWARE. Do not delete Docker volumes or replace Installation ID files to force the upgrade.

## After the upgrade

Open the application and check activation, login, device readings, reports, and backups. If a service does not start, save the installer output and contact ADANWARE. Keep the verified backup and do not make further changes until you receive help.
