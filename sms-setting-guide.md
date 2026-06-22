# SMS Settings Configuration Guide

## Overview

The T&D Sensor Dashboard supports SMS notifications to alert responsible personnel when sensor events occur (threshold breaches, device errors, battery low, etc.). SMS notifications work alongside email notifications and can be configured through the web UI or directly via REST API.

---

## 1. Supported SMS Providers

The system supports four provider types:

| Provider | Required Credentials | Notes |
|----------|---------------------|-------|
| **Twilio** | Account SID, Auth Token, Sender Phone Number | Most widely used |
| **Vonage (Nexmo)** | API Key, API Secret, Sender Phone Number | Formerly Nexmo |
| **Plivo** | Auth ID, Auth Token, Sender Phone Number | Cost-effective alternative |
| **Custom HTTP API** | Custom endpoint URL, headers, body template | For any SMS gateway |

---

## 2. Configuring SMS Settings (Admin Only)

### 2.1 Via Web UI

1. Navigate to **Settings** > **SMS** tab in the dashboard
2. Select your **Provider** from the dropdown
3. Enter the provider credentials:
   - **API Key** — Account SID (Twilio), API Key (Vonage), or Auth ID (Plivo)
   - **API Secret** — Auth Token (Twilio/Plivo) or API Secret (Vonage)
   - **Sender Number** — Your outbound phone number in E.164 format (e.g. `+1234567890`)
4. For **Custom** provider, also configure:
   - **URL** — The SMS gateway endpoint (e.g. `https://api.example.com/send`)
   - **Method** — HTTP method: `POST` or `GET`
   - **Headers** — JSON string of HTTP headers (e.g. `{"Authorization": "Bearer token", "Content-Type": "application/json"}`)
   - **Body Template** — JSON template with placeholders:
     - `{{to}}` — recipient phone number
     - `{{message}}` — SMS text content
     - `{{from}}` — sender phone number

     Example:
     ```json
     {
       "to": "{{to}}",
       "msg": "{{message}}",
       "sender": "{{from}}"
     }
     ```
5. Click **Save SMS Settings**
6. Click **Send Test SMS** (enter a phone number) to verify the configuration

### 2.2 Via API

All SMS setting operations require **admin authentication**.

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/settings/sms` | Get current SMS settings |
| `POST` | `/settings/sms` | Create or update SMS settings |
| `PATCH` | `/settings/sms/toggle` | Enable or disable SMS notifications |
| `POST` | `/settings/sms/test` | Send a test SMS to verify settings |

**Save SMS Settings**
```
POST /settings/sms
Content-Type: application/json

{
  "provider": "twilio",
  "api_key": "ACxxxxxxxxxxxxxxxx",
  "api_secret": "your_auth_token",
  "sender_number": "+1234567890"
}
```

**Custom Provider Example**
```
POST /settings/sms
Content-Type: application/json

{
  "provider": "custom",
  "api_key": "",
  "api_secret": "",
  "sender_number": "+1234567890",
  "custom_url": "https://api.smsprovider.com/v1/send",
  "custom_method": "POST",
  "custom_headers": "{\"Authorization\": \"Bearer your_token\"}",
  "custom_body_template": "{\"to\": \"{{to}}\", \"message\": \"{{message}}\", \"from\": \"{{from}}\"}"
}
```

**Test SMS**
```
POST /settings/sms/test
Content-Type: application/json

{
  "phone_number": "+1234567890"
}
```

**Toggle SMS On/Off**
```
PATCH /settings/sms/toggle
```
Returns: `{ "is_active": true }` or `{ "is_active": false }`

---

## 3. Managing SMS Recipients

Recipients are the phone numbers that will receive SMS alerts. Each recipient can be configured to receive specific alert types and can be scoped to specific devices or departments.

### 3.1 Via Web UI

1. In the **SMS** settings tab, scroll to the **Recipients** section
2. Click **Add Recipient** and fill in:
   - **Phone Number** — in E.164 format (e.g. `+1234567890`)
   - **Name** — optional label for the contact
   - **Alert Types** — select which alerts to receive, or "all"
   - **Receive All Alerts** — toggle on to receive alerts for ALL devices, or leave off to receive only alerts for assigned devices
   - **Departments / Devices** — optionally assign specific departments or devices
3. Use the **Edit** or **Delete** buttons on each recipient row to manage

### 3.2 Via API

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/settings/sms/recipients` | List all SMS recipients |
| `POST` | `/settings/sms/recipients` | Add a new recipient |
| `PUT` | `/settings/sms/recipients/{id}` | Update a recipient |
| `DELETE` | `/settings/sms/recipients/{id}` | Remove a recipient |

**Add Recipient**
```
POST /settings/sms/recipients
Content-Type: application/json

{
  "phone_number": "+1234567890",
  "name": "John Smith",
  "alert_types": "all",
  "receive_all": true,
  "department_ids": [1, 2],
  "device_ids": [5, 10]
}
```

**Alert Types** (use as comma-separated string, or `"all"`):
- `upper_limit` — Temperature/humidity exceeds upper threshold
- `lower_limit` — Temperature/humidity drops below lower threshold
- `battery_low` — Device battery ≤ 20%
- `sensor_error` — Sensor malfunction
- `communication_error` — Base station can't reach remote unit
- `device_unregistered` — Device disconnected

**Update Recipient** (all fields optional)
```
PUT /settings/sms/recipients/1
Content-Type: application/json

{
  "phone_number": "+0987654321",
  "name": "Jane Doe",
  "alert_types": "upper_limit,lower_limit",
  "receive_all": false,
  "department_ids": [3],
  "device_ids": []
}
```

---

## 4. Alert Types and Behavior

### Critical Alerts (Always Sent)

These alert types **cannot be filtered** by recipient settings and are always sent regardless of alert type selection:

- **Communication Error** — Base station cannot reach a remote unit
- **Sensor Error** — Sensor malfunction detected
- **Device Unregistered** — Device has disconnected

### Configurable Alerts

These respect each recipient's `alert_types` setting:

- **Upper Limit** — Temperature or humidity exceeds the upper threshold
- **Lower Limit** — Temperature or humidity drops below the lower threshold
- **Battery Low** — Device battery drops to 20% or below
- **Signal Loss** — Signal communication interrupted

### Recovery Messages

When an alert condition is resolved (values return to normal, device reconnects, etc.), a **recovery SMS** is automatically sent to the same recipients who received the original alert.

---

## 5. SMS Message Format

### Warning SMS
```
ALERT #42: UPPER LIMIT | Sensor: Lab Temp | Value: 35.2°C | Threshold: 30.0°C | Time: 2026-06-22 14:30
```

### Recovery SMS
```
RESOLVED #42: UPPER LIMIT | Sensor: Lab Temp | Condition returned to normal
```

---

## 6. Phone Number Format

All phone numbers must be in **E.164** international format:

| Correct | Incorrect |
|---------|-----------|
| `+1234567890` | `1234567890` |
| `+447700900123` | `07700900123` |
| `+61412345678` | `0412 345 678` |

Format: `+` followed by country code and subscriber number (no spaces, dashes, or parentheses).

---

## 7. Database Setup

If SMS functionality has not been initialized, run the database migration:

```bash
python backend/migrations/migrate_add_sms_tables.py
# Or with environment-based config:
python backend/migrations/migrate_add_sms_tables.py --use-env
```

This creates the following tables:
- `sms_settings` — Provider configuration
- `sms_recipients` — Recipient contact list
- `sms_recipient_department` — Recipient-to-department mapping
- `sms_recipient_device` — Recipient-to-device mapping

---

## 8. Error Handling & Troubleshooting

- SMS send failures are **logged but not fatal** — they don't block other system operations
- Network timeout is set to **15 seconds**
- Each failed SMS attempt logs a detailed error message for debugging
- Use the **Send Test SMS** button to verify your provider configuration before relying on alerts
- If SMS is not enabled (`is_active: false`), no SMS will be sent regardless of recipient configuration
- Verify phone numbers are in E.164 format — invalid numbers are the most common cause of delivery failures

---

## 9. Backup & Restore

SMS configuration and recipient data are included in the system's backup and restore operations. When you export a backup, the following tables are saved:
- `sms_settings`
- `sms_recipients`
- `sms_recipient_department`
- `sms_recipient_device`

Restoring a backup will reinstate all SMS settings and recipients as they were at the time of backup.
