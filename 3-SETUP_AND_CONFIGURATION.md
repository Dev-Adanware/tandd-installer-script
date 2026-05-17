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

### 1.3. Accessing the Base Station Interface
- [ ] Open a web browser and navigate to `http://<Base-Station-IP>`.
- [ ] Log in using default credentials (refer to TandD documentation, typically `admin` / `password`).
- [ ] Change default password immediately for security.

### 1.4. Pairing TandD Data Loggers / Sensors
- [ ] Put sensors in registration mode (refer to sensor manual).
- [ ] On Base Station interface: go to **Device Management** → **Register New Device**.
- [ ] Wait for confirmation that each device is successfully paired.
- [ ] Label each sensor with its assigned channel/ID.

### 1.5. Data Transmission Settings
- [ ] Configure logging interval (e.g., every 5 minutes).
- [ ] Set up data destination:
    - Local storage (on Base Station)
    - Cloud service (if used)
    - Forwarding to System Dashboard API (custom endpoint)
- [ ] Save and apply settings.

### 1.6. Verify Base Station Operation
- [ ] Check that live data appears for each paired sensor.
- [ ] Force a manual data transmission test.
- [ ] Confirm data is being sent to the expected destination.

---

## 2. System Dashboard Configuration

### 2.1. Access the Dashboard
- [ ] Ensure the System Dashboard application is running (post-deployment).
- [ ] Open the Dashboard URL in a browser.
- [ ] Log in with your administrator credentials.

### 2.2. Add TandD Base Station as a Data Source
- [ ] Navigate to **Settings** → **Data Sources** → **Add New**.
- [ ] Select `TandD Base Station` from the device type list.
- [ ] Enter Base Station IP address and API port (default: `80` or custom).
- [ ] Provide API key or credentials if authentication is required.
- [ ] Test connection – should show `Success`.

### 2.3. Map Sensor Channels
- [ ] Go to **Device Manager** → **TandD Devices**.
- [ ] Import paired sensors from the Base Station (or add manually by channel ID).
- [ ] Assign each sensor to a readable name/location (e.g., "Cold Room A - Temp Sensor").
- [ ] Set unit preferences (°C/°F, humidity %, etc.).

### 2.4. Configure Data Visualization
- [ ] Create dashboards/widgets for real-time sensor values.
- [ ] Set up charts for historical trending (temperature, humidity, etc.).
- [ ] Add threshold alerts (e.g., notify if temperature exceeds 8°C).

### 2.5. Alert & Notification Rules
- [ ] Define alert conditions per sensor.
- [ ] Configure notification channels: Email, SMS, Webhook, or Dashboard popup.
- [ ] Test alert by temporarily triggering a threshold event.

### 2.6. System Dashboard Final Checks
- [ ] Verify that incoming data from Base Station updates correctly.
- [ ] Check data logs for completeness (no missing intervals).
- [ ] Confirm that alert rules are active and working.

---

## 3. Integration Validation

- [ ] **Data flow test:** Change temperature on a sensor → see real-time update in Dashboard (< 1 min delay).
- [ ] **Alert test:** Force threshold breach → receive notification.
- [ ] **Restart test:** Reboot Base Station and Dashboard → automatic reconnection.
- [ ] **Log retention:** Verify historical data is stored and retrievable.

---

## 4. Troubleshooting Quick Reference

| Issue | Possible Fix |
|--------|----------------|
| Cannot access Base Station web interface | Check network connection, ping IP, restart Base Station |
| Sensors not pairing | Ensure sensors are in registration mode and within range |
| Dashboard not receiving data | Verify API endpoint URL and credentials in Data Source settings |
| Alerts not firing | Check threshold values and notification channel configuration |

---

## 5. Post-Setup Checklist

- [ ] Base Station operational with all sensors paired.
- [ ] System Dashboard showing live sensor data.
- [ ] Alerts configured and tested.
- [ ] Backup configuration exported (both Base Station and Dashboard).
- [ ] Setup documentation saved in repo.

> **Next steps after setup:**  
> Proceed to user acceptance testing or monitoring phase.

---

*For TandD-specific details, refer to the official Base Station manual. For Dashboard API details, see `/docs/api/tandd-integration.md` (if available).*