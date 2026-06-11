# Test Cases: Order Lifecycle (Postman + Manual)

**Version:** 1.0.0  
**Module:** Order Management  
**Related FR:** FR-09, FR-10, FR-11, FR-12, FR-13, FR-14, FR-15  
**Test Date:** Juni 2026  
**Tester:** Fatin Asyifa  
**Status:** Ready for Execution  

---

## 📋 Overview

Dokumen ini berisi test cases untuk testing Order Lifecycle dari status CREATED hingga CLOSED/COMPLETED.

**Test Scope:**
- Order Creation (FR-09)
- Order Status Transitions (FR-10)
- Provider Accept Order (FR-11)
- Start Work (FR-12)
- Complete Work (FR-13)
- Cancel Order (FR-14)
- Order History (FR-15)

**Order Status Flow:**
```
CREATED → ACCEPTED → IN_PROGRESS → COMPLETED → CLOSED
         ↓
       CANCELLED
```

---

## Test Environment Setup

### Prerequisites
- Backend running (http://127.0.0.1:8000)
- Test customers seeded (fajar@example.com, nabila@example.com, siti@example.com)
- Test providers seeded (andi.listrik@example.com, budi.plumbing@example.com)
- Payment gateway sandbox configured
- Database with fresh seed data

### Test Data
- Customer: fajar@example.com / password123
- Provider: andi.listrik@example.com / password123
- Service: Teknisi Listrik (ID: 1, Price: 150,000)

---

## Test Case Suite 1: Order Creation (CREATED Status)

### TC-ORDER-001: Create Order - Customer (Postman)
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-09  
**Test Method:** Postman

**Precondition:**
- Customer logged in and has valid token
- Service exists (ID: 1)

**Test Steps:**
```
Endpoint: POST /api/v1/orders
Method: POST
Headers:
  Authorization: Bearer {customer_token}
  Content-Type: application/json

Body:
{
  "service_id": 1,
  "scheduled_date": "2026-06-15",
  "scheduled_time": "14:00",
  "location": "Jl. Test No. 123, Jakarta",
  "notes": "Pasang saklar 3 fase",
  "payment_method": "QRIS",
  "urgency": "normal"
}
```

**Expected Results:**
- ✅ Status Code: 201 Created
- ✅ Response:
  ```json
  {
    "message": "Order created successfully",
    "data": {
      "id": "ORD-20260610-001",
      "customer_id": 2,
      "provider_id": 3,
      "service_id": 1,
      "status": "CREATED",
      "total_amount": 150000,
      "scheduled_date": "2026-06-15",
      "scheduled_time": "14:00",
      "location": "Jl. Test No. 123, Jakarta",
      "notes": "Pasang saklar 3 fase",
      "created_at": "2026-06-10T10:00:00Z",
      "updated_at": "2026-06-10T10:00:00Z"
    }
  }
  ```
- ✅ Order mendapat ID unik (ORD-20260610-001)
- ✅ Status = CREATED
- ✅ Order entry saved di database

**Manual Verification:**
1. Check database:
   ```sql
   SELECT * FROM orders WHERE id = 'ORD-20260610-001';
   ```
2. Verify status = 'CREATED'
3. Verify all fields saved correctly

**Additional Checks:**
- [ ] Email notifikasi dikirim ke provider
- [ ] Order muncul di customer's order list
- [ ] Order detail page accessible

---

### TC-ORDER-002: Create Order - Missing Required Fields
**Priority:** HIGH  
**Type:** Negative Test  
**FR:** FR-09

**Test Steps:**
```
Body (without location):
{
  "service_id": 1,
  "scheduled_date": "2026-06-15",
  "scheduled_time": "14:00",
  "notes": "Pasang saklar"
  // Missing: location
}
```

**Expected Results:**
- ✅ Status Code: 422 Unprocessable Entity
- ✅ Response:
  ```json
  {
    "message": "Validation failed",
    "errors": {
      "location": ["The location field is required"]
    }
  }
  ```

---

### TC-ORDER-003: Create Order - Invalid Service ID
**Priority:** MEDIUM  
**Type:** Negative Test  
**FR:** FR-09

**Test Steps:**
```
Body:
{
  "service_id": 9999,  // Non-existent
  "scheduled_date": "2026-06-15",
  "scheduled_time": "14:00",
  "location": "Jl. Test No. 123",
  "notes": "Test"
}
```

**Expected Results:**
- ✅ Status Code: 404 Not Found
- ✅ Message: "Service not found"

---

### TC-ORDER-004: Create Order - Past Date/Time
**Priority:** MEDIUM  
**Type:** Negative Test  
**FR:** FR-09

**Test Steps:**
```
Body:
{
  "service_id": 1,
  "scheduled_date": "2026-06-01",  // Past date
  "scheduled_time": "10:00",
  "location": "Jl. Test",
  "notes": "Test"
}
```

**Expected Results:**
- ✅ Status Code: 422
- ✅ Error: "Scheduled date must be in the future"

---

## Test Case Suite 2: Order Status Transition

### TC-ORDER-005: Provider Accept Order (CREATED → ACCEPTED)
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-10, FR-11  
**Test Method:** Postman + Manual

**Precondition:**
- Order in CREATED status (ORD-20260610-001)
- Provider logged in with valid token

**Test Steps:**
```
Endpoint: POST /api/v1/orders/{order_id}/accept
Method: POST
Headers:
  Authorization: Bearer {provider_token}
  Accept: application/json

Body: {}
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Response:
  ```json
  {
    "message": "Order accepted successfully",
    "data": {
      "id": "ORD-20260610-001",
      "status": "ACCEPTED",
      "accepted_at": "2026-06-10T10:30:00Z"
    }
  }
  ```
- ✅ Database order.status updated to ACCEPTED
- ✅ Timestamp accepted_at recorded
- ✅ Customer receives notification

**Manual Verification:**
1. Navigate to order detail page
2. Status changed from CREATED to ACCEPTED
3. Provider info now shows in order
4. "Start Work" button visible

---

### TC-ORDER-006: Provider Reject Order (CREATED → CANCELLED)
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-10, FR-14

**Test Steps:**
```
Endpoint: POST /api/v1/orders/{order_id}/reject
Body:
{
  "reason": "Lokasi terlalu jauh"
}
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Status changed to CANCELLED
- ✅ Reason stored in database
- ✅ Customer notified
- ✅ Order becomes available to other providers

---

### TC-ORDER-007: Provider Start Work (ACCEPTED → IN_PROGRESS)
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-10, FR-12

**Precondition:**
- Order status = ACCEPTED
- Deposit (DP) payment already paid
- Provider ready to start work

**Test Steps:**
```
Endpoint: POST /api/v1/orders/{order_id}/start
Method: POST
Headers:
  Authorization: Bearer {provider_token}
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Status changed to IN_PROGRESS
- ✅ Response includes:
  ```json
  {
    "status": "IN_PROGRESS",
    "started_at": "2026-06-15T14:00:00Z"
  }
  ```
- ✅ started_at timestamp recorded
- ✅ Customer receives notification
- ✅ Order timer/tracking started (if applicable)

**Manual Verification:**
1. Provider can see timer/work duration
2. Customer gets real-time updates
3. UI shows "In Progress" status

---

### TC-ORDER-008: Provider Start Work - No Payment
**Priority:** HIGH  
**Type:** Negative Test  
**FR:** FR-12

**Precondition:**
- Order status = ACCEPTED
- DP payment NOT paid

**Test Steps:**
```
Endpoint: POST /api/v1/orders/{order_id}/start
```

**Expected Results:**
- ✅ Status Code: 403 Forbidden
- ✅ Message: "Deposit payment must be completed before starting work"

---

### TC-ORDER-009: Provider Complete Work (IN_PROGRESS → COMPLETED)
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-10, FR-13

**Precondition:**
- Order status = IN_PROGRESS
- Work completed by provider

**Test Steps:**
```
Endpoint: POST /api/v1/orders/{order_id}/complete
Method: POST
Body:
{
  "completion_notes": "Saklar sudah dipasang dengan sempurna",
  "photos": [
    "base64_image_data"
  ]
}
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Status changed to COMPLETED
- ✅ Response:
  ```json
  {
    "status": "COMPLETED",
    "completed_at": "2026-06-15T14:45:00Z",
    "completion_notes": "Saklar sudah dipasang dengan sempurna"
  }
  ```
- ✅ Photos/evidence saved
- ✅ Completion timestamp recorded
- ✅ Customer notified and asked to confirm/review
- ✅ Final payment triggered

**Manual Verification:**
1. Customer sees order in COMPLETED state
2. Can view completion photos
3. Can submit review
4. Invoice generated

---

### TC-ORDER-010: Customer Confirm Order Completion
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-13

**Precondition:**
- Order status = COMPLETED
- Customer logged in

**Test Steps:**
```
Endpoint: POST /api/v1/orders/{order_id}/confirm
Method: POST
Body: {}
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Status changed to CLOSED
- ✅ Final payment processed
- ✅ Provider payout calculated and processed
- ✅ Order removed from active orders list

---

## Test Case Suite 3: Order Cancellation

### TC-ORDER-011: Customer Cancel Order (CREATED → CANCELLED)
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-14

**Precondition:**
- Order status = CREATED
- Customer logged in
- Within cancellation window (0-1 hour)

**Test Steps:**
```
Endpoint: POST /api/v1/orders/{order_id}/cancel
Method: POST
Headers:
  Authorization: Bearer {customer_token}
Body:
{
  "reason": "Berubah pikiran"
}
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Status changed to CANCELLED
- ✅ Refund processed if payment already done
- ✅ Provider notified
- ✅ Order removed from active orders

---

### TC-ORDER-012: Cancel Order - After Acceptance (Not Allowed)
**Priority:** MEDIUM  
**Type:** Negative Test  
**FR:** FR-14

**Precondition:**
- Order status = ACCEPTED
- Cancellation not allowed after acceptance

**Test Steps:**
```
Endpoint: POST /api/v1/orders/{order_id}/cancel
```

**Expected Results:**
- ✅ Status Code: 403 Forbidden
- ✅ Message: "Cannot cancel accepted orders"

---

### TC-ORDER-013: Provider Cancel Order (ACCEPTED → CANCELLED)
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-14

**Precondition:**
- Order status = ACCEPTED
- Provider needs to cancel
- Must provide valid reason

**Test Steps:**
```
Endpoint: POST /api/v1/orders/{order_id}/cancel-as-provider
Body:
{
  "reason": "Emergency muncul"
}
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Status changed to CANCELLED
- ✅ Penalty/reputation impact recorded (if applicable)
- ✅ Customer notified
- ✅ Order available to other providers

---

## Test Case Suite 4: Order History & List

### TC-ORDER-014: Get Customer's Order List
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-15

**Test Steps:**
```
Endpoint: GET /api/v1/orders?role=customer
Headers:
  Authorization: Bearer {customer_token}

Query Parameters:
  status: (optional) CREATED,ACCEPTED,IN_PROGRESS,COMPLETED,CLOSED
  page: 1
  per_page: 10
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Response contains:
  ```json
  {
    "message": "Orders retrieved",
    "data": [
      {
        "id": "ORD-20260610-001",
        "service": {...},
        "provider": {...},
        "status": "COMPLETED",
        "total_amount": 150000,
        "created_at": "2026-06-10T10:00:00Z"
      }
    ],
    "pagination": {
      "total": 5,
      "current_page": 1,
      "last_page": 1
    }
  }
  ```
- ✅ Only customer's own orders shown
- ✅ Pagination working correctly

---

### TC-ORDER-015: Get Provider's Order List
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-15

**Test Steps:**
```
Endpoint: GET /api/v1/orders?role=provider
Headers:
  Authorization: Bearer {provider_token}
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Shows all orders assigned/accepted by provider
- ✅ Can filter by status

---

### TC-ORDER-016: Get Order Detail
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-15

**Test Steps:**
```
Endpoint: GET /api/v1/orders/{order_id}
Headers:
  Authorization: Bearer {token}
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Response includes complete order information:
  - Order details
  - Customer info
  - Provider info
  - Service details
  - Payment history
  - Timeline/status history
- ✅ Only order owner or related parties can view
- ✅ Non-related user gets 403

---

### TC-ORDER-017: Order Status History Timeline
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-15

**Expected Result:**
- ✅ Order detail page shows timeline of all status changes
- ✅ Each status change shows timestamp
- ✅ Example:
  ```
  2026-06-10 10:00 - Order Created by Customer
  2026-06-10 10:05 - Order Accepted by Provider
  2026-06-15 14:00 - Work Started
  2026-06-15 14:45 - Work Completed
  2026-06-16 09:00 - Order Confirmed by Customer
  ```

---

## Manual Testing Scenarios

### Scenario 1: Complete Happy Path (Postman + Manual)

**Objective:** Test full order lifecycle from creation to completion

**Steps:**
1. **TC-ORDER-001:** Create order as customer
   - Save order ID: ORD-XXXX-XXX
   
2. **TC-ORDER-005:** Accept order as provider
   - Verify status changed
   
3. **Manual:** Navigate to payment page
   - Generate QRIS
   - Simulate payment
   - Verify deposit paid
   
4. **TC-ORDER-007:** Start work as provider
   - Status → IN_PROGRESS
   
5. **Manual:** Wait for work completion
   
6. **TC-ORDER-009:** Complete work as provider
   - Upload completion photos
   
7. **Manual:** Customer confirms completion
   - Leave review
   - Rate provider
   
8. **TC-ORDER-016:** Verify order in CLOSED status
   - Check invoice
   - Verify payment completed

---

### Scenario 2: Order Rejection

**Objective:** Test provider rejection workflow

**Steps:**
1. Create order
2. Provider rejects order
3. Verify customer notified
4. Verify order available to other providers
5. Another provider accepts

---

### Scenario 3: Multi-User Isolation

**Objective:** Verify data isolation between users

**Steps:**
1. Customer A creates order
2. Login as Customer B
   - ✅ Cannot see Customer A's order
3. Login as Provider A
   - ✅ Can only see accepted orders
   - ✅ Cannot see other provider's orders

---

## UI/Manual Testing Checklist

### Customer Perspective
- [ ] Can see "Create Order" button on service detail
- [ ] Order form has all required fields
- [ ] Can submit order successfully
- [ ] Order appears in "My Orders" list immediately
- [ ] Can see order status in real-time
- [ ] Can receive notifications on order status changes
- [ ] Can view provider info when accepted
- [ ] Can upload photos when completing (if applicable)
- [ ] Can leave review/rating after completion
- [ ] Can cancel order within cancellation window

### Provider Perspective
- [ ] Receives notification when new order created
- [ ] Can see incoming orders in dashboard
- [ ] Can accept/reject order
- [ ] After acceptance, can see "Start Work" button
- [ ] Can start work (after payment confirmed)
- [ ] Can upload completion photos
- [ ] Can add completion notes
- [ ] Receives payment confirmation

### Admin Perspective
- [ ] Can see all orders with filters
- [ ] Can view order details
- [ ] Can see payment status
- [ ] Can see provider payout status
- [ ] Can generate reports

---

## Bug Report Template

Use this format for any bugs found:

```
BUG-ORDER-XXX: [Title]
Priority: [Critical/High/Medium/Low]
Severity: [Critical/Major/Minor/Trivial]

Description:
[Describe what happened]

Steps to Reproduce:
1. [Step 1]
2. [Step 2]

Expected Result:
[What should happen]

Actual Result:
[What actually happened]

Environment:
- Backend: http://127.0.0.1:8000
- Browser: [Chrome/Firefox/Safari]
- Device: [Android/iOS/Web]

Attachment:
- [Screenshot]
- [Video]
- [Log file]

Related Test Case:
TC-ORDER-XXX

Status:
- [ ] New
- [ ] Confirmed
- [ ] Fixed
- [ ] Verified
```

---

## Postman Collection Integration

The order test cases are included in the main Postman collection:
- Location: `docs/postman/TukangDekat_API.postman_collection.json`
- Folder: "Orders"
- Include: All POST, GET, UPDATE requests

**How to run:**
1. Import collection in Postman
2. Set environment variables (base_url, token)
3. Run individual requests or full test suite
4. Review test results

---

## Execution Report

| Test Case | Status | Result | Notes | Date |
|-----------|--------|--------|-------|------|
| TC-ORDER-001 | PENDING | - | - | - |
| TC-ORDER-002 | PENDING | - | - | - |
| TC-ORDER-003 | PENDING | - | - | - |
| ... | ... | ... | ... | ... |

**Summary:**
- Total Test Cases: 17
- Passed: 0
- Failed: 0
- Blocked: 0
- Pending: 17

---

**Document Version History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | Juni 2026 | Fatin Asyifa | Initial version - Order lifecycle test cases |
