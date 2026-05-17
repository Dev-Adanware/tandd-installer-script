# T&D Data Server - Simple Installation Guide

This guide will help you install the T&D Data Server application even if you don't have technical experience. Follow these steps carefully.

## What is the T&D Data Server?

The T&D Data Server is a simple application that collects temperature and humidity data from T&D wireless data loggers and shows it in an easy-to-read dashboard.

## Before You Begin

You will need:
1. A computer (Windows, Mac, or Linux) that will run 24/7 to collect data
2. An internet connection
3. About 20 minutes of time
4. Your T&D base station already set up and working

## Step-by-Step Installation

### Step 1: Install Docker on Your Computer

**Windows:**
1. Visit the official Docker Desktop download page: https://www.docker.com/products/docker-desktop
2. Click **Download for Windows** and run the installer.
3. Follow the installation wizard (default options are fine).
4. After installation, Docker Desktop will start automatically; you may need to log out and back in.

**macOS:**
1. Go to the official Docker Desktop download page: https://www.docker.com/products/docker-desktop
2. Choose the appropriate download for your Mac (Apple silicon or Intel) and run the installer.
3. Drag the Docker icon to the **Applications** folder.
4. Open Docker from Applications; it may ask for your password to finish setup.

**Linux (Ubuntu/Debian):**
Follow Docker’s official installation guide:
```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
```
If you are using a different Linux distribution, see Docker’s platform‑specific instructions at https://docs.docker.com/engine/install/.

### Step 2: Download the Installation Script

1. Open a terminal/command prompt:
   - Windows: Press Windows+R, type `cmd`, press Enter
   - Mac: Open Applications > Utilities > Terminal
   - Linux: Press Ctrl+Alt+T

2. Copy and paste this command, then press Enter:
   ```
   curl -fsSL https://raw.githubusercontent.com/Dev-Adanware/tandd-installer-script/main/tandd-installer.sh -o tandd-installer.sh
   ```

3. Run the installer with:
   ```
   sudo bash tandd-installer.sh
   ```
   The installer will then ask you for some configuration values:

   ```
   📋 SETUP CONFIGURATION
   ---------------------------------------------
   🌐 Enter your NTP server IP or hostname [192.168.0.1]: <your NTP server>
   🔐 GitHub credentials required to download the application:
      GitHub Username [Dev-Adanware]: 
      GitHub Token (input hidden): <token provided by ADANWARE>
   ```



### Step 4: Access Your New System

When the installation finishes, you'll see a message like:
```
🎉 Installation Complete!
```

The script will show you:
- Web address to access your system (usually something like: http://your-computer-name.local)
- Login username: admin
- Login password: admin123

### Step 5: First Login

1. Open a web browser (Chrome, Firefox, Safari, or Edge)
2. In the address bar at the top, type the web address shown at the end of the installation
3. Press Enter
4. You should see a login page
5. Enter:
   - Username: admin
   - Password: admin123
6. Click the "Login" button

### Step 6: Change Your Password (Important!)

For security, please change your password after first login:
1. Click on your username in the top-right corner
2. Select "Profile" or "Account Settings"
3. Look for "Change Password"
4. Enter your current password (admin123)
5. Enter a new password you'll remember
6. Confirm the new password
7. Save your changes

## Connecting Your T&D Devices

Once logged in, you need to tell your T&D base station where to send data:

1. In the T&D Data Server, look for "Settings" or "Device Configuration"
2. Find the section for "API Endpoint" or "Data Receiver URL"
3. It should show something like: `http://your-server-address/api/rtr500/device/`
4. Give this entire URL to whoever set up your T&D base station, or enter it yourself in the base station's configuration

## What Happens Next?

- The application will automatically start collecting data from your T&D loggers
- You can view temperature and humidity readings on the dashboard
- The system will send email alerts if temperatures go outside normal ranges
- Daily backups of your data are created automatically
- The application will restart automatically if your computer restarts

## Need Help?

If you encounter problems:
1. Make sure Docker is running (look for the Docker icon in your system tray/menu bar)
2. Try restarting your computer and running the installation script again
3. Contact the person who provided you with the T&D equipment for further assistance

## Keeping Your System Updated

To update to newer versions in the future:
1. Open a terminal/command prompt
2. Navigate to the installation folder (usually `/opt/amt-tandd` on Linux/Mac, or where you ran the script on Windows)
3. Run:
   ```
   sudo ./deploy_amt_tandd.sh
   ```
   The script will check for updates and apply them automatically.

---

**Remember:** This computer needs to stay powered on and connected to the internet to collect data from your T&D devices. If you turn off the computer, data collection will stop until you turn it back on.