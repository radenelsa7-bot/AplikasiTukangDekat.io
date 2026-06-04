# N8n Integration Documentation

**Date:** 4 Juni 2026  
**Project:** TukangDekat  
**Module:** Notification System via n8n  
**Status:** Implementation Guide

---

## 📋 Overview

N8n integration menyediakan notification system yang robust untuk TukangDekat. Sistem ini mengirim notifikasi WhatsApp, Email, dan SMS ke customer dan provider berdasarkan event lifecycle order dan payment.

### Supported Events

1. **order_created** - Order baru dibuat oleh customer
2. **order_accepted** - Provider menerima order
3. **order_rejected** - Provider menolak order
4. **work_started** - Provider memulai pekerjaan
5. **order_completed** - Provider menyelesaikan pekerjaan
6. **payment_dp_paid** - DP payment sudah dibayar
7. **payment_final_paid** - Final payment sudah dibayar
8. **payment_failed** - Payment gagal/timeout
9. **payout_completed** - Payout ke provider completed

### Supported Channels

- **WA** - WhatsApp via Fonnte/Wablas
- **EMAIL** - Email via Laravel Mail
- **SMS** - SMS via Twilio/lainnya

---

## 🔧 Setup & Configuration

### 1. Environment Variables

Tambahkan ke `.env`:

```bash
# N8N Configuration
N8N_URL=http://localhost:5678
N8N_WEBHOOK_URL=http://n8n:5678/webhook/tukangdekat-notification
N8N_WEBHOOK_SECRET=your-secret-key
N8N_WEBHOOK_KEY=your-webhook-key

# N8N Workflows
N8N_WORKFLOW_ORDER_CREATED_WA=workflow_order_created_wa
N8N_WORKFLOW_ORDER_ACCEPTED_WA=workflow_order_accepted_wa
N8N_WORKFLOW_ORDER_REJECTED_WA=workflow_order_rejected_wa
N8N_WORKFLOW_DP_PAID_WA=workflow_dp_paid_wa
N8N_WORKFLOW_ORDER_COMPLETED_WA=workflow_order_completed_wa
N8N_WORKFLOW_FINAL_PAID_WA=workflow_final_paid_wa
N8N_WORKFLOW_PAYMENT_FAILED_WA=workflow_payment_failed_wa
N8N_WORKFLOW_PAYOUT_COMPLETED_WA=workflow_payout_completed_wa

# WhatsApp Provider
N8N_WA_PROVIDER=fonnte
N8N_WA_API_KEY=your-wa-api-key

# Email
N8N_EMAIL_FROM=noreply@tukangdekat.id
```

### 2. Docker Setup

N8n sudah terconfigurasi di `docker-compose.yml`:

```yaml
n8n:
  image: n8nio/n8n:latest
  container_name: tukangdekat-n8n
  ports:
    - "5678:5678"
  environment:
    - N8N_BASIC_AUTH_ACTIVE=true
    - N8N_BASIC_AUTH_USER=admin
    - N8N_BASIC_AUTH_PASSWORD=changeme
    - WEBHOOK_URL=http://localhost:5678
  volumes:
    - n8n_data:/home/node/.n8n
  networks:
    - tukangdekat
```

**Start n8n:**
```bash
docker-compose up n8n
# Akses di http://localhost:5678
# Login dengan: admin / changeme
```

### 3. API Endpoints

#### Health Check
```http
GET /api/integrations/health
```

Response:
```json
{
  "status": "healthy",
  "timestamp": "2026-06-04T12:00:00Z",
  "service": "n8n-integration"
}
```

#### Dispatch Event (Protected)
```http
POST /api/integrations/n8n/events
Authorization: Bearer {token}
Content-Type: application/json

{
  "event_name": "order_created",
  "data": {
    "order_id": 1,
    "customer_id": 1,
    "provider_id": 2,
    "estimated_price": 100000
  },
  "channel": "WA"
}
```

Response:
```json
{
  "message": "Event dispatched successfully",
  "event_id": "evt_abc123",
  "status": "sent"
}
```

#### Get Notification Logs (Protected)
```http
GET /api/integrations/notifications/logs?event_name=order_created&channel=WA&status=SENT
Authorization: Bearer {token}
```

Response:
```json
{
  "data": [
    {
      "id": 1,
      "event_name": "order_created",
      "channel": "WA",
      "payload_json": "{...}",
      "status": "SENT",
      "sent_at": "2026-06-04T12:00:00Z",
      "created_at": "2026-06-04T12:00:00Z"
    }
  ],
  "pagination": {
    "total": 100,
    "per_page": 50,
    "current_page": 1,
    "last_page": 2
  }
}
```

#### Get Notification Log Detail (Protected)
```http
GET /api/integrations/notifications/logs/{id}
Authorization: Bearer {token}
```

#### N8n Webhook Callback
```http
POST /api/integrations/n8n/webhook
X-N8N-Signature: {signature}
Content-Type: application/json

{
  "message_id": "MSG123",
  "status": "delivered",
  "phone": "628123456789"
}
```

---

## 🔄 Event Flow

### Order Created Flow

```
Customer creates Order
    ↓
Order::create()
    ↓
N8nNotificationService::dispatch('order_created', {...})
    ↓
NotificationLog::create() [status: SENT/FAILED]
    ↓
HTTP POST to N8N_WEBHOOK_URL
    ↓
N8n Workflow executes (order_created_WA)
    ↓
Send WhatsApp to Customer + Provider
    ↓
N8n Webhook Callback (optional)
```

### Payment DP Paid Flow

```
Payment Gateway Webhook (Xendit/Midtrans)
    ↓
PaymentController::webhookPaymentCallback()
    ↓
Payment::update(['status' => 'PAID'])
    ↓
N8nNotificationService::dispatch('payment_dp_paid', {...})
    ↓
NotificationLog::create()
    ↓
HTTP POST to N8N_WEBHOOK_URL
    ↓
N8n Workflow executes (payment_dp_paid_WA)
    ↓
Send WhatsApp: "Payment received for order {order_code}"
```

---

## 📊 N8n Workflow Examples

### Workflow 1: Order Created - Send WA to Customer & Provider

**Trigger:** HTTP Webhook  
**Incoming Data:**
```json
{
  "event_name": "order_created",
  "channel": "WA",
  "data": {
    "order_id": 1,
    "order_code": "ORD-001-ABC",
    "customer_id": 1,
    "provider_id": 2,
    "estimated_price": 100000,
    "dp_amount": 50000
  }
}
```

**Workflow Steps:**

1. **HTTP Webhook** - Listen for POST from Laravel backend
2. **Extract Data** - Parse incoming JSON payload
3. **Parallel Send** - Simultaneously send WA messages:
   - **Branch A:** Send to Customer
     - Template: "Hi {customer_name}, order #{order_code} dari {provider_name} sudah dibuat. DP: Rp{dp_amount}. Silakan lakukan pembayaran."
   - **Branch B:** Send to Provider
     - Template: "Hi {provider_name}, ada order baru dari {customer_name}. Rp{estimated_price}. Silakan accept/reject order."
4. **Log Result** - POST back to `/api/integrations/n8n/webhook` with status
5. **Error Handling** - Retry on failure dengan exponential backoff

**Configuration:**
```
Trigger: Webhook (HTTP POST)
Channel: Fonnte WhatsApp Gateway
Headers:
  Authorization: Bearer {WA_API_KEY}
  Content-Type: application/json

Fonnte API Endpoint: https://api.fonnte.com/send
```

### Workflow 2: Payment DP Paid - Notify Both Parties

**Trigger:** HTTP Webhook  
**Incoming Data:**
```json
{
  "event_name": "payment_dp_paid",
  "channel": "WA",
  "data": {
    "order_id": 1,
    "payment_id": 5,
    "payment_type": "DP",
    "amount": 50000,
    "order_status": "ACCEPTED"
  }
}
```

**Workflow Steps:**

1. **HTTP Webhook** - Receive payment confirmation
2. **Query Order Data** - REST call ke `/api/orders/{order_id}`
3. **Parallel Notifications:**
   - **To Customer:** "DP untuk order #{order_code} sudah terkonfirmasi. Rp{amount}. Provider akan segera memulai pekerjaan."
   - **To Provider:** "DP dari {customer_name} sudah diterima. Rp{amount}. Silakan mulai pekerjaan."
4. **Send Email Confirmation** - Optional email receipt
5. **Log Status** - Callback to `/api/integrations/n8n/webhook`

### Workflow 3: Order Completed - Request Final Payment

**Trigger:** HTTP Webhook  
**Incoming Data:**
```json
{
  "event_name": "order_completed",
  "channel": "WA",
  "data": {
    "order_id": 1,
    "order_code": "ORD-001-ABC",
    "customer_id": 1,
    "final_price": 100000
  }
}
```

**Workflow Steps:**

1. **HTTP Webhook** - Receive completion notification
2. **Calculate Final Amount** - final_price - dp_amount
3. **Send to Customer:**
   - "Pekerjaan order #{order_code} sudah selesai. Sisa pembayaran: Rp{final_amount}. Silakan lakukan pembayaran."
   - Include Payment Link / QRIS
4. **Notify Provider:**
   - "Pekerjaan sudah dikonfirmasi selesai. Menunggu pembayaran akhir dari customer."
5. **Log & Callback**

---

## 🧪 Testing

### Run Tests

```bash
cd backend

# Run all n8n integration tests
php artisan test tests/Feature/N8nIntegrationTest.php

# Run specific test
php artisan test tests/Feature/N8nIntegrationTest.php --filter test_order_created_event_dispatch

# With coverage
php artisan test tests/Feature/N8nIntegrationTest.php --coverage
```

### Manual Testing

**1. Test Health Check:**
```bash
curl http://localhost:8000/api/integrations/health
```

**2. Test Dispatch Event:**
```bash
curl -X POST http://localhost:8000/api/integrations/n8n/events \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "event_name": "order_created",
    "data": {"order_id": 1},
    "channel": "WA"
  }'
```

**3. Test Get Logs:**
```bash
curl http://localhost:8000/api/integrations/notifications/logs \
  -H "Authorization: Bearer {token}"
```

**4. Test N8n Webhook Callback:**
```bash
curl -X POST http://localhost:8000/api/integrations/n8n/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "message_id": "MSG123",
    "status": "delivered"
  }'
```

---

## 🚀 Deployment

### Production Setup

1. **Update `.env.production`:**
```bash
N8N_URL=https://n8n.tukangdekat.id
N8N_WEBHOOK_URL=https://api.tukangdekat.id/webhook/n8n-notification
N8N_WEBHOOK_SECRET=production-secret-key
N8N_WA_API_KEY=production-wa-api-key
```

2. **Setup N8n in Production:**
```bash
# Use RDS for database
# Use S3 for storage
# Enable SSL/TLS
# Configure firewall rules
# Setup monitoring & alerting
```

3. **Database Migration:**
```bash
php artisan migrate
```

4. **Queue Setup:**
Ensure notification dispatch jobs are queued:
```bash
php artisan queue:work --queue=notifications
```

5. **Monitoring:**
- Monitor `/api/integrations/health` every 5 minutes
- Setup alerts for failed notifications
- Track notification metrics in Sentry

---

## 📈 Monitoring & Debugging

### Check Notification Status

```bash
# Via Laravel Tinker
php artisan tinker

# Get all failed notifications
NotificationLog::where('status', 'FAILED')->paginate();

# Get notifications for specific event
NotificationLog::where('event_name', 'order_created')->latest()->get();

# Check error count per event
NotificationLog::where('status', 'FAILED')
  ->groupBy('event_name')
  ->selectRaw('event_name, count(*) as count')
  ->get();
```

### View N8n Logs

1. Access N8n UI: http://localhost:5678
2. Go to **Executions** tab
3. View workflow run history and logs
4. Check **Credentials** for API key validity

### Common Issues

| Issue | Solution |
|-------|----------|
| Webhook URL unreachable | Check firewall, DNS, N8n service running |
| Authentication failed | Verify N8N_WEBHOOK_SECRET in both backend and N8n |
| WA messages not sent | Check WA provider API key, rate limits, quota |
| Notification logs not created | Verify database connection, migrations ran |
| High latency | Enable caching, optimize queries, scale workers |

---

## 📝 Next Steps

1. ✅ Implement IntegrationController & N8nNotificationService
2. ✅ Create comprehensive tests
3. ✅ Setup routes & configuration
4. 🔄 Create N8n workflows in production
5. 🔄 Integration test dengan real WhatsApp provider
6. 🔄 Setup monitoring & alerting
7. 🔄 Performance optimization

---

## 📚 References

- [N8n Documentation](https://docs.n8n.io/)
- [Fonnte WhatsApp API](https://fonnte.com/docs)
- [Laravel Notifications](https://laravel.com/docs/11.x/notifications)
- [Queues & Jobs](https://laravel.com/docs/11.x/queues)
