# Test Cases: Payment Flow & Webhook

**Version:** 1.0.0  
**Module:** Payment Management  
**Related FR:** FR-16, FR-17, FR-18, FR-19  
**Test Date:** Juni 2026  
**Tester:** Fatin Asyifa  
**Status:** Ready for Execution  
**Priority:** CRITICAL (Payment is core functionality)

---

## 📋 Overview

Dokumen ini berisi test cases untuk testing payment flow end-to-end, termasuk:
- QRIS generation
- Payment verification
- Webhook handling
- Signature verification
- Payout processing
- Payment history

**Payment Flow:**
```
Order ACCEPTED → Generate QRIS (DP) → Payment Processing 
  → Webhook Callback → Verify Signature 
  → Update Payment Status → Process Payout to Provider
```

**Test Scope:**
- Generate QRIS Payment (FR-16)
- Payment Verification via Webhook (FR-17)
- Payout to Provider (FR-18)
- Payment History (FR-19)

---

## Test Environment Setup

### Prerequisites
- Backend running with Midtrans credentials configured
- Midtrans Sandbox account active
- Test merchant account setup
- Webhook URL configured: http://127.0.0.1:8000/api/v1/webhooks/midtrans
- Test orders in ACCEPTED status
- Database backup available

### Midtrans Sandbox Credentials
```
Server Key: {{SERVER_KEY}}
Client Key: {{CLIENT_KEY}}
Merchant ID: {{MERCHANT_ID}}
```

### Test Accounts
```
Customer: fajar@example.com / password123
Provider: andi.listrik@example.com / password123
Test Order: ORD-20260610-001 (Status: ACCEPTED, Amount: 150,000)
```

---

## Test Case Suite 1: QRIS Payment Generation

### TC-PAYMENT-001: Generate QRIS for Order DP (Postman)
**Priority:** CRITICAL  
**Type:** Positive Test  
**FR:** FR-16  
**Test Method:** Postman

**Precondition:**
- Order status = ACCEPTED (ORD-20260610-001)
- Customer has valid token
- Midtrans configured

**Test Steps:**
```
Endpoint: POST /api/v1/payments/generate-qris
Method: POST
Headers:
  Authorization: Bearer {customer_token}
  Content-Type: application/json

Body:
{
  "order_id": "ORD-20260610-001",
  "payment_type": "deposit",
  "amount": 75000
}
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Response:
  ```json
  {
    "message": "QRIS generated successfully",
    "data": {
      "transaction_id": "TRX-20260610-001",
      "order_id": "ORD-20260610-001",
      "qris_url": "https://api.sandbox.midtrans.com/qr/qr...",
      "qr_code": "base64_image_data",
      "amount": 75000,
      "expiry_time": 900,  // seconds
      "status": "pending",
      "created_at": "2026-06-10T10:00:00Z"
    }
  }
  ```
- ✅ QR code image returned (base64)
- ✅ Transaction entry created in database
- ✅ Status = pending
- ✅ Expiry time set (15 minutes)

**Manual Verification:**
1. Check database:
   ```sql
   SELECT * FROM payment_transactions WHERE transaction_id = 'TRX-20260610-001';
   ```
2. Verify qr_code stored
3. Verify status = 'pending'

---

### TC-PAYMENT-002: Generate QRIS - Duplicate Request (Idempotency)
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-16

**Precondition:**
- Already generated QRIS for order

**Test Steps:**
```
Endpoint: POST /api/v1/payments/generate-qris
Body: (same as TC-PAYMENT-001)
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Returns same QRIS (idempotent)
- ✅ No duplicate transaction created
- ✅ Response includes cached_from: existing_transaction_id

---

### TC-PAYMENT-003: Generate QRIS - Invalid Amount
**Priority:** HIGH  
**Type:** Negative Test  
**FR:** FR-16

**Test Steps:**
```
Body:
{
  "order_id": "ORD-20260610-001",
  "payment_type": "deposit",
  "amount": -50000  // Negative
}
```

**Expected Results:**
- ✅ Status Code: 422
- ✅ Error: "Amount must be greater than 0"

---

### TC-PAYMENT-004: Generate QRIS - Order Not Found
**Priority:** HIGH  
**Type:** Negative Test  
**FR:** FR-16

**Test Steps:**
```
Body:
{
  "order_id": "ORD-NOTEXIST-999",
  "payment_type": "deposit",
  "amount": 75000
}
```

**Expected Results:**
- ✅ Status Code: 404
- ✅ Message: "Order not found"

---

### TC-PAYMENT-005: Generate QRIS - Order Not Accepted
**Priority:** HIGH  
**Type:** Negative Test  
**FR:** FR-16

**Precondition:**
- Order status = CREATED (not ACCEPTED)

**Test Steps:**
```
Body:
{
  "order_id": "ORD-20260610-002",  // Status: CREATED
  "payment_type": "deposit",
  "amount": 75000
}
```

**Expected Results:**
- ✅ Status Code: 403 Forbidden
- ✅ Message: "Order must be accepted before payment"

---

## Test Case Suite 2: Payment Webhook Handling

### TC-PAYMENT-006: Webhook - Successful Payment (PAID)
**Priority:** CRITICAL  
**Type:** Positive Test  
**FR:** FR-17  
**Test Method:** Manual + cURL

**Precondition:**
- QRIS generated (TRX-20260610-001)
- Customer paid via mobile banking or simulator
- Midtrans sends webhook notification

**Test Steps (Simulated):**
```bash
curl -X POST http://127.0.0.1:8000/api/v1/webhooks/midtrans \
  -H "Content-Type: application/json" \
  -d '{
    "transaction_id": "TRX-20260610-001",
    "order_id": "ORD-20260610-001",
    "payment_type": "qris",
    "gross_amount": 75000,
    "transaction_status": "settlement",
    "transaction_time": "2026-06-10 10:30:00",
    "signature_key": "{{SIGNATURE_KEY}}"
  }'
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Response:
  ```json
  {
    "message": "Payment processed successfully"
  }
  ```
- ✅ Payment status updated to PAID in database
- ✅ Order status progression allowed (can start work now)
- ✅ Customer receives email receipt
- ✅ Provider receives notification about payment

**Database Verification:**
```sql
SELECT * FROM payment_transactions WHERE transaction_id = 'TRX-20260610-001';
-- Should show: status = 'paid', verified_at = current_timestamp
```

---

### TC-PAYMENT-007: Webhook - Payment Failed (DENIED)
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-17

**Webhook Payload:**
```json
{
  "transaction_id": "TRX-20260610-002",
  "order_id": "ORD-20260610-001",
  "transaction_status": "deny",
  "gross_amount": 75000,
  "signature_key": "{{SIGNATURE_KEY}}"
}
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Payment status updated to FAILED
- ✅ Customer notified to retry payment
- ✅ Order remains in ACCEPTED state (not progressed)
- ✅ Customer can generate new QRIS

---

### TC-PAYMENT-008: Webhook - Payment Expired
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-17

**Webhook Payload:**
```json
{
  "transaction_id": "TRX-20260610-003",
  "transaction_status": "expire",
  "signature_key": "{{SIGNATURE_KEY}}"
}
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Payment status updated to EXPIRED
- ✅ Customer can generate new QRIS
- ✅ Old QRIS becomes invalid

---

### TC-PAYMENT-009: Webhook - Duplicate Notification (Idempotency)
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-17

**Scenario:**
- Same webhook notification received twice (network retry)

**Steps:**
1. Send webhook for TRX-20260610-001 with status=settlement
2. Process successfully
3. Send same webhook again

**Expected Results:**
- ✅ First call: Status 200, payment processed
- ✅ Second call: Status 200, idempotent
- ✅ No duplicate entries in database
- ✅ Payment not processed twice
- ✅ Uses transaction_id for idempotency check

---

## Test Case Suite 3: Webhook Signature Verification

### TC-PAYMENT-010: Webhook - Valid Signature
**Priority:** CRITICAL  
**Type:** Positive Test  
**FR:** FR-17

**Description:**
Verify webhook with correct Midtrans signature

**Test Steps:**
```
1. Get webhook payload from Midtrans
2. Signature generation:
   - Sort keys alphabetically
   - Concatenate: transaction_id + status + gross_amount + ServerKey
   - Generate SHA512 hash
   - Compare with signature_key in payload

Payload:
{
  "transaction_id": "TRX-20260610-001",
  "order_id": "ORD-20260610-001",
  "gross_amount": 75000,
  "transaction_status": "settlement",
  "signature_key": "b3d9d2a2f1c9e8a7..."  // Valid signature
}
```

**Expected Results:**
- ✅ Signature verification passes
- ✅ Payment processed normally
- ✅ Status 200 OK

**Verification Code:**
```php
$serverKey = env('MIDTRANS_SERVER_KEY');
$transaction_id = 'TRX-20260610-001';
$order_id = 'ORD-20260610-001';
$gross_amount = 75000;
$status = 'settlement';

$signatureKey = hash('sha512', 
  $transaction_id . $status . $gross_amount . $serverKey
);

// Compare with received signature_key
if ($signatureKey === $receivedSignatureKey) {
  // Valid signature
}
```

---

### TC-PAYMENT-011: Webhook - Invalid Signature (Tampered)
**Priority:** CRITICAL  
**Type:** Negative Test  
**FR:** FR-17

**Scenario:**
- Webhook payload tampered/modified
- Signature doesn't match

**Test Steps:**
```
Payload:
{
  "transaction_id": "TRX-20260610-001",
  "gross_amount": 75000,
  "transaction_status": "settlement",
  "signature_key": "INVALID_SIGNATURE_HASH_..."  // Tampered
}
```

**Expected Results:**
- ✅ Status Code: 403 Forbidden atau 401 Unauthorized
- ✅ Response:
  ```json
  {
    "message": "Invalid webhook signature"
  }
  ```
- ✅ Payment NOT processed
- ✅ Request logged for security audit
- ✅ Alert sent to admin

**Security Verification:**
- [ ] Tampered payload rejected
- [ ] No payment update to database
- [ ] Security log entry created
- [ ] Admin alert triggered

---

### TC-PAYMENT-012: Webhook - Missing Signature
**Priority:** HIGH  
**Type:** Negative Test  
**FR:** FR-17

**Test Steps:**
```
Payload (without signature_key):
{
  "transaction_id": "TRX-20260610-001",
  "gross_amount": 75000,
  "transaction_status": "settlement"
  // Missing: signature_key
}
```

**Expected Results:**
- ✅ Status Code: 400 Bad Request
- ✅ Message: "Missing signature verification"

---

## Test Case Suite 4: Payout Processing

### TC-PAYMENT-013: Payout to Provider - Automatic
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-18

**Scenario:**
- Order completed
- Final payment verified and paid
- System triggers payout to provider

**Precondition:**
- Order status = COMPLETED
- Final payment received and verified
- Provider bank account configured

**Expected Results:**
- ✅ Payout created in payment_payouts table
- ✅ Status: PENDING
- ✅ Amount: Service price - Platform fee (10%)
- ✅ Scheduled for next business day
- ✅ Provider receives notification
- ✅ Provider can track payout status

**Database Check:**
```sql
SELECT * FROM payment_payouts 
WHERE order_id = 'ORD-20260610-001';
-- Status: PENDING, scheduled_at: tomorrow
```

---

### TC-PAYMENT-014: Payout Status - Processed
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-18

**Scenario:**
- Payout executed successfully
- Bank confirmed transfer

**Expected Results:**
- ✅ Payout status updated to PROCESSED
- ✅ processed_at timestamp recorded
- ✅ Reference number saved
- ✅ Provider receives email confirmation

---

### TC-PAYMENT-015: Payout - Failed Retry
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-18

**Scenario:**
- Initial payout failed (invalid bank account, etc.)
- System retries next day
- Eventually succeeds

**Expected Results:**
- ✅ First attempt: Status = FAILED
- ✅ failure_reason recorded
- ✅ Automatic retry scheduled
- ✅ Provider can manually request retry
- ✅ Eventually marks as PROCESSED

---

## Test Case Suite 5: Payment History

### TC-PAYMENT-016: Get Payment History - Customer
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-19

**Test Steps:**
```
Endpoint: GET /api/v1/payments/history?role=customer
Headers:
  Authorization: Bearer {customer_token}
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Response contains:
  ```json
  {
    "message": "Payment history retrieved",
    "data": [
      {
        "transaction_id": "TRX-20260610-001",
        "order_id": "ORD-20260610-001",
        "amount": 75000,
        "payment_type": "deposit",
        "status": "paid",
        "paid_at": "2026-06-10T10:30:00Z",
        "receipt_url": "https://..."
      }
    ],
    "pagination": {
      "total": 5,
      "per_page": 10
    }
  }
  ```
- ✅ Only customer's payments shown
- ✅ Can filter by status, date range

---

### TC-PAYMENT-017: Download Payment Receipt
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-19

**Test Steps:**
```
Endpoint: GET /api/v1/payments/{transaction_id}/receipt
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ PDF receipt returned
- ✅ Contains:
  - Transaction ID
  - Order details
  - Amount
  - Payment date
  - QR code
  - Provider info

---

### TC-PAYMENT-018: Payment History - Provider View
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-19

**Test Steps:**
```
Endpoint: GET /api/v1/payments/history?role=provider
```

**Expected Results:**
- ✅ Shows earnings/payments from completed orders
- ✅ Shows pending payouts
- ✅ Shows processed payouts
- ✅ Total earnings summary

---

## Integration Test: Full Payment Flow

### TC-PAYMENT-INT-001: Complete Payment Lifecycle
**Priority:** CRITICAL  
**Type:** Integration Test  
**Test Method:** Manual + Postman + Webhook Simulator

**Objective:**
Test complete payment flow from order acceptance to payout

**Steps:**

**Step 1: Order Accepted**
```
1. Customer creates order (ORD-20260610-001)
2. Provider accepts order
3. Order status: ACCEPTED
4. DP amount due: 50%
```

**Step 2: Generate QRIS (TC-PAYMENT-001)**
```
POST /api/v1/payments/generate-qris
Response: QRIS generated, transaction_id: TRX-20260610-001
```

**Step 3: Customer Pays via QRIS**
```
1. Customer opens QR code in mobile banking
2. Confirms payment 75,000
3. Payment submitted
```

**Step 4: Midtrans Webhook Notification (TC-PAYMENT-006)**
```
Midtrans sends webhook:
  POST /api/v1/webhooks/midtrans
  Payload: transaction_status = settlement
Expected: Payment marked as PAID
```

**Step 5: Provider Starts Work**
```
POST /api/v1/orders/ORD-20260610-001/start
Expected: Status 200 (allowed because payment is paid)
Order status: IN_PROGRESS
```

**Step 6: Provider Completes Work**
```
POST /api/v1/orders/ORD-20260610-001/complete
Expected: Final payment triggered
```

**Step 7: Final Payment**
```
POST /api/v1/payments/generate-qris
  amount: 75,000 (remaining 50%)
Midtrans webhook: settlement
Payment marked as PAID
Order status: COMPLETED
```

**Step 8: Customer Confirms**
```
POST /api/v1/orders/ORD-20260610-001/confirm
Expected: Order status CLOSED
```

**Step 9: Payout Processing (TC-PAYMENT-013)**
```
Check payment_payouts table:
- Status: PENDING
- Amount: 75,000 - 7,500 (10% fee) = 67,500
- Scheduled: Next business day
```

**Final Verification:**
- [ ] Order: CLOSED
- [ ] All payments: PAID
- [ ] Payout: PENDING
- [ ] Customer received receipts
- [ ] Provider received notifications
- [ ] Admin dashboard updated

---

## Security Testing

### TC-PAYMENT-SEC-001: SQL Injection in Webhook
**Priority:** CRITICAL  
**Type:** Security Test

**Test:**
```
Payload:
{
  "transaction_id": "'; DROP TABLE payment_transactions; --",
  "gross_amount": 75000
}
```

**Expected:**
- ✅ Payload sanitized
- ✅ No SQL injection possible
- ✅ Treated as regular string

---

### TC-PAYMENT-SEC-002: CSRF Protection
**Priority:** HIGH  
**Type:** Security Test

**Test:**
- Generate QRIS from different origin
- Expected: CORS/CSRF check fails

---

### TC-PAYMENT-SEC-003: Rate Limiting
**Priority:** MEDIUM  
**Type:** Security Test

**Test:**
- Send 100 webhook requests in 1 minute
- Expected: Rate limiting kicks in, returns 429

---

## Performance Testing

### TC-PAYMENT-PERF-001: QRIS Generation Response Time
**Priority:** MEDIUM  
**Target:** < 500ms

```
Test: Generate QRIS
Expected: Response in < 500ms
```

---

### TC-PAYMENT-PERF-002: Webhook Processing Response Time
**Priority:** HIGH  
**Target:** < 200ms

```
Test: Receive webhook, process, return
Expected: Complete in < 200ms
```

---

## Execution Report Template

| Test Case | Status | Result | Notes | Date |
|-----------|--------|--------|-------|------|
| TC-PAYMENT-001 | PENDING | - | - | - |
| TC-PAYMENT-002 | PENDING | - | - | - |
| ... | ... | ... | ... | ... |

**Summary:**
- Total: 21 test cases
- Passed: 0
- Failed: 0
- Blocked: 0

---

## Bug Reporting

Use standard bug template for any issues:

```
BUG-PAYMENT-XXX: [Title]
Severity: [Critical/High/Medium/Low]

Description: [Details]
Steps: [How to reproduce]
Expected: [What should happen]
Actual: [What happened]
Related TC: TC-PAYMENT-XXX
```

---

## Postman Collection

Payment test cases included in main collection:
- Location: `docs/postman/TukangDekat_API.postman_collection.json`
- Folder: "Payments"

---

**Document Version History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | Juni 2026 | Fatin Asyifa | Initial version - Payment & Webhook test cases |
