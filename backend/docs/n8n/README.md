# n8n Notification Workflows - TukangDekat

Unified notification workflows untuk mengirim notifikasi ke customer dan provider via WhatsApp atau Email.

## File Workflows

### 1. `unified_notification_workflow.json` (WhatsApp)
- **Channel:** WhatsApp (via Wablas API)
- **Events:** order_created, order_accepted, order_rejected, dp_paid, order_completed, final_paid
- **Recipients:** Customer + Provider (sesuai event)

### 2. `unified_notification_workflow_email.json` (Email)
- **Channel:** Email (via Gmail SMTP)
- **Events:** order_created, order_accepted, order_rejected, dp_paid, order_completed, final_paid
- **Recipients:** Customer + Provider (sesuai event)

## Setup Instructions

### Prerequisites
- n8n instance berjalan (port 5678, sudah ada di docker-compose)
- Credential WA provider (Wablas/Fonnte) atau Gmail account untuk Email

### A. Setup WhatsApp Workflow

1. **Import workflow:**
   - Buka n8n UI → `http://localhost:5678`
   - Menu: Import → Upload `unified_notification_workflow.json`

2. **Setup Wablas Credential:**
   - Di n8n: Credentials → Create → HTTP Request
   - Name: `waApi`
   - Header:
     - Key: `apiKey`
     - Value: `<Wablas API Key>`
   - Test connection

3. **Update Function Nodes** (jika perlu custom phone format):
   - Edit node "Build WA messages (order_created)" dll
   - Adjust phone number format sesuai Wablas requirement

4. **Activate Workflow:**
   - Klik toggle "Active" untuk mengaktifkan
   - Test dengan endpoint: `POST /webhook/n8n-events`

### B. Setup Email Workflow

1. **Import workflow:**
   - Buka n8n UI → `http://localhost:5678`
   - Menu: Import → Upload `unified_notification_workflow_email.json`

2. **Setup Gmail Credential:**
   - Di n8n: Credentials → Create → Gmail
   - Authenticate dengan Gmail account (atau Google Workspace)
   - Grant permission untuk send email

3. **Update Send Email node:**
   - Edit node "Send Email"
   - Update `fromEmail` ke sender email Anda
   - Verify credential terpilih

4. **Activate Workflow:**
   - Klik toggle "Active"
   - Test dengan endpoint: `POST /webhook/n8n-events`

## Required Payload Format

Backend mengirim event ke n8n dengan format:

```json
{
  "event_name": "order_created|order_accepted|order_rejected|dp_paid|order_completed|final_paid",
  "channel": "WA|EMAIL",
  "payload": {
    "order_id": 123,
    "order_code": "ORD-20260607-0001",
    "customer_name": "Budi",
    "customer_email": "budi@example.com",
    "customer_phone": "628123456789",
    "provider_name": "Tukang Bangunan A",
    "provider_email": "provider@example.com",
    "provider_phone": "628987654321",
    "estimated_price": 500000,
    "dp_amount": 250000,
    "amount": 250000,
    "remaining_amount": 250000,
    "final_price": 500000,
    "status": "CREATED|ACCEPTED|CANCELLED|COMPLETED|CLOSED",
    "refund_count": 0,
    "reason": "Optional rejection reason"
  }
}
```

## Event Behavior

| Event | Recipients | Action |
|-------|-----------|--------|
| `order_created` | Customer + Provider | New order notification |
| `order_accepted` | Customer | Provider accepted order |
| `order_rejected` | Customer | Provider rejected with reason |
| `dp_paid` | Customer + Provider | DP payment received |
| `order_completed` | Customer | Work done, request final payment |
| `final_paid` | Customer + Provider | Final payment received, order closed |

## Testing

### Quick Test via cURL

```bash
# WhatsApp webhook (n8n:5678)
curl -X POST http://localhost:5678/webhook/n8n-events \
  -H "Content-Type: application/json" \
  -d '{
    "event_name": "order_created",
    "channel": "WA",
    "payload": {
      "order_id": 1,
      "order_code": "ORD-20260607-0001",
      "customer_name": "Budi",
      "customer_email": "budi@example.com",
      "customer_phone": "628123456789",
      "provider_name": "Tukang A",
      "provider_email": "tukang@example.com",
      "provider_phone": "628987654321",
      "estimated_price": 500000,
      "dp_amount": 250000
    }
  }'

# Email webhook
curl -X POST http://localhost:5678/webhook/n8n-events \
  -H "Content-Type: application/json" \
  -d '{
    "event_name": "order_accepted",
    "channel": "EMAIL",
    "payload": {
      "order_code": "ORD-20260607-0001",
      "customer_name": "Budi",
      "customer_email": "budi@example.com",
      "provider_name": "Tukang A"
    }
  }'
```

## Configuration in Backend

### .env Setup

```env
N8N_WEBHOOK_URL=http://localhost:5678/webhook/n8n-events
N8N_SECRET=optional-webhook-secret
N8N_EVENT_SECRET=optional-event-secret
```

### Routes

Backend mengirim ke n8n via `N8nNotificationService`:
- Route: `POST /api/integrations/n8n/events` (manual trigger)
- Auto-trigger dari: Order creation, Payment webhook, Order respond

## Troubleshooting

### Workflow tidak trigger
- Pastikan n8n container running: `docker logs tukangdekat_n8n`
- Cek webhook path di n8n vs backend config
- Verify network connectivity: `docker exec laravel_api curl http://tukangdekat_n8n:5678/webhook/n8n-events`

### Email tidak terkirim
- Verify Gmail credential authenticated
- Check Gmail security settings allow "Less secure app access" atau gunakan App Password
- Review n8n logs: `docker exec tukangdekat_n8n npm run start`

### WhatsApp tidak terkirim
- Verify Wablas API key valid
- Check phone number format (harus dengan country code 62 untuk Indonesia)
- Test Wablas API directly dengan curl

## Notes

- Workflow ini unified = satu workflow handle semua event
- Perubahan message template → edit function node di n8n
- Untuk multi-language support → tambah kondisi bahasa di function node
- Error handling: jika API gagal, log disimpan tapi tidak re-retry otomatis
