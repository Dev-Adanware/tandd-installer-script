# AMT Monitoring System

## Quick Installation Guide

This guide explains how to install and open the AMT Monitoring System.

---

# Before You Start this session

Please make sure you have:

    A PC or laptop
    Linux Server IP Address
    Linux Server Username
    Linux Server Password
    SNTP/NTP Server IP
    GitHub Token provided by ADANWARE
    Confirmation from the IT team that:
        The Linux server is ready
        Docker is installed and running
        Internet access or required endpoint whitelisting is completed

---

# Step 1 — Connect to the Linux Server

Open CMD or Terminal and type:

```bash
ssh username@SERVER_IP
```

Example:

```bash
ssh admin@192.168.0.50
```

You will see:

```text
admin@192.168.0.50's password:
```

Type the Linux server password and press ENTER.

---

# Step 2 — Download the Installer

Copy and paste the following command:

```bash
curl -fsSL https://raw.githubusercontent.com/Dev-Adanware/tandd-installer-script/main/tandd-installer.sh -o tandd-installer.sh
```

Press ENTER.

---

# Step 3 — Run the Installer

Copy and paste:

```bash
sudo bash tandd-installer.sh
```

Press ENTER.

If asked for password, enter the Linux server password.

---

# Step 4 — Enter the Required Information

When you see:

```text
🌐 Enter your NTP server IP or hostname
```

Type the SNTP/NTP IP provided by the IT team.

---

When you see:

```text
GitHub Username [Dev-Adanware]:
```

Just press ENTER.

Do NOT change anything.

---

When you see:

```text
GitHub Token:
```

Paste the GitHub Token provided by ADANWARE.

Press ENTER.

---

# Step 5 — Wait for Installation to Finish

Please wait until the installation is completed.

This may take several minutes.

---

# Step 6 — Open the AMT Monitoring System

After installation is completed:

1. Open a web browser
2. Type:

```text
http://SERVER_IP
```

Example:

```text
http://192.168.0.50
```

---

# Step 7 — Login

Use the following login information:

```text
Username: admin
Password: admin123
```

You can now access the dashboard.
