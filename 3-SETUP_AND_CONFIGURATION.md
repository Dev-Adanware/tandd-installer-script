# System & TandD Base Station Setup Guide

> **Prerequisite:**  
> This session can be started **only after** you complete the deployment session successfully.  
> Do not proceed unless deployment is fully verified.

---

## Overview

This guide covers the setup and configuration of two main components:

1. **TandD Base Station** – Hardware setup and network configuration  
2. **System Dashboard** – Application configuration and device integration

---

## 1. TandD Base Station Setup

### 1.1. Physical Connection
- [ ] Connect the Base Station to a power source using the supplied adapter.
- [ ] Connect the Base Station to your local network via Ethernet cable (or prepare Wi-Fi settings if supported).
- [ ] Verify LED indicators: Power and Network/Activity lights should be stable or blinking normally.

### 1.2. Network Configuration
- [ ] Obtain the Base Station IP address from your router's DHCP client list or use the TandD Device Finder utility.
- [ ] (Optional) Assign a static IP to the Base Station for consistent access.
- [ ] Ensure the Base Station can reach the internet if cloud sync is required.

### 1.3. Pairing TandD Data Loggers / Sensors
- [ ] Put sensors in registration mode (refer to sensor manual).
- [ ] On Base Station interface: go to **Device Management** → **Register New Device**.
- [ ] Wait for confirmation that each device is successfully paired.
- [ ] Label each sensor with its assigned channel/ID.

---

## 2. Configure T&D Base Station for AMT-T&D Software

After deploying the AMT-T&D software, you need to configure the Base Station to send readings to the server.

### 2.1. Open RTR500WB Settings Utility
- [ ] Install/Open the **RTR500WB Settings Utility** on any Windows computer connected to the same network as the Base Station.

### 2.2. Connect to Base Station
- [ ] Click on the **Operation** tab → **Search Network**.
- [ ] You should see your Base Station listed. **Double-click** on it.
- [ ] Enter the Base Station password when prompted and click **OK**.

### 2.3. Configure Server Settings
- [ ] In the settings window, go to **HTTP(s) Settings**.
- [ ] **Connection Destination:** Choose `Custom`.
- [ ] **HTTP(s) Server:** Enter the IP address or hostname where the AMT-T&D software is deployed (e.g., `192.168.1.xxx`).
- [ ] **HTTP(s) Port Number:** `80`
- [ ] **Destination Path:** `/api/rtr500/device/`
- [ ] **Secure Connection:** `OFF` (Turn ON only if you have configured HTTPS/SSL).
- [ ] **Connection Interval:** `5 minutes` (or your preferred interval).
- [ ] Click **Apply** to save the configuration.

### 2.4. Test Connection
- [ ] Click on the **Transmission Test** tab (or button).
- [ ] Click **"Test transmission of the current readings"**.
- [ ] You should see a success message, indicating the connection between the Base Station and the AMT-T&D software is working.

### 2.5. Repeat for Multiple Base Stations
- [ ] If you have more than one Base Station, repeat steps **2.1 through 2.4** for each unit.

---

## 3. System Dashboard Configuration

### 3.1. Access the Dashboard
- [ ] Ensure the System Dashboard application is running (post-deployment).
- [ ] Open the Dashboard URL in a browser.
- [ ] Log in with your administrator credentials.

### 3.2. Add TandD Base Station as a Data Source
- [ ] Navigate to **Settings** → **Data Sources** → **Add New**.
- [ ] Select `TandD Base Station` from the device type list.
- [ ] Enter Base Station IP address and API port (default: `80` or custom).
- [ ] Provide API key or credentials if authentication is required.
- [ ] Test connection – should show `Success`.

### 3.3. Map Sensor Channels
- [ ] Go to **Device Manager** → **TandD Devices**.
- [ ] Import paired sensors from the Base Station (or add manually by channel ID).
- [ ] Assign each sensor to a readable name/location (e.g., "Cold Room A - Temp Sensor").
- [ ] Set unit preferences (°C/°F, humidity %, etc.).

### 3.4. Configure Data Visualization
- [ ] Create dashboards/widgets for real-time sensor values.
- [ ] Set up charts for historical trending (temperature, humidity, etc.).
- [ ] Add threshold alerts (e.g., notify if temperature exceeds 8°C).

### 3.5. Alert & Notification Rules
- [ ] Define alert conditions per sensor.
- [ ] Configure notification channels: Email, SMS, Webhook, or Dashboard popup.
- [ ] Test alert by temporarily triggering a threshold event.

### 3.6. System Dashboard Final Checks
- [ ] Verify that incoming data from Base Station updates correctly.
- [ ] Check data logs for completeness (no missing intervals).
- [ ] Confirm that alert rules are active and working.

---

## 4. Integration Validation

- [ ] **Data flow test:** Change temperature on a sensor → see real-time update in Dashboard (< 5 min interval + processing time).
- [ ] **Alert test:** Force threshold breach → receive notification.
- [ ] **Restart test:** Reboot Base Station and Dashboard → automatic reconnection.
- [ ] **Log retention:** Verify historical data is stored and retrievable.

---

## 5. Troubleshooting Quick Reference

| Issue | Possible Fix |
|--------|----------------|
| Cannot find Base Station in RTR500WB Settings Utility | Ensure Windows PC is on same network; check firewall settings; restart utility |
| Connection test fails | Verify AMT-T&D software is running; check IP address, port 80, and destination path |
| "Secure Connection" errors | Set to OFF unless HTTPS is fully configured on server |
| Dashboard not receiving data | Verify API endpoint URL and credentials; check Base Station transmission logs |
| Alerts not firing | Check threshold values and notification channel configuration |

---

## 6. Post-Setup Checklist

- [ ] Base Station physically connected and powered on.
- [ ] All sensors paired with Base Station.
- [ ] RTR500WB Settings Utility configured with correct HTTP(s) settings.
- [ ] Connection test successful for each Base Station.
- [ ] System Dashboard showing live sensor data.
- [ ] Alerts configured and tested.
- [ ] Backup configuration exported (both Base Station and Dashboard).
- [ ] Setup documentation saved in repo.

> **Next steps after setup:**  
> Proceed to user acceptance testing or monitoring phase.

---

*For TandD-specific details, refer to the official RTR500WB Base Station manual. For Dashboard API details, see `/docs/api/tandd-integration.md` (if available).*