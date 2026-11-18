# AMT T&D User Guide

## Install or update

Follow the [Deployment Guide](./2-Deployment_USER_GUIDE.md) for current online and offline installation instructions. Do not use older installation or update commands.

## Use the application

1. Open the application address provided by your administrator.
2. Sign in with your account.
3. View current and historical readings on the dashboard and reports pages.

To connect T&D base stations or configure the application, follow the [System and Base Station Configuration Guide](./3-SETUP_AND_CONFIGURATION.md).

## Backup & Restore

Open **Settings** → **Backup/Restore** and select **Backup/Restore Station**. Backups are created manually when you select a scope and choose **Download Backup**; the application does not create scheduled backups. You can download a full database backup, a Settings & Configuration backup, or a Sensor Data backup. Store downloaded `.amtbackup` files outside the application server.

To restore, choose a backup file, review the displayed scope, and choose **Start Restore** once. The application validates the file before changing application data and shows progress automatically. A full restore replaces the included database data with the selected snapshot. A Sensor Data restore merges readings and historical warnings while preserving settings and device configuration. See the [System and Base Station Configuration Guide](./3-SETUP_AND_CONFIGURATION.md) for the setup screen.

For help, contact ADANWARE or your system administrator.
