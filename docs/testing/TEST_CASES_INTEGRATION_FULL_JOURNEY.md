# Test Cases: Integration Testing – Full User Journey

**Version:** 1.0.0  
**Module:** Full Platform Integration  
**Related FR:** FR-01 hingga FR-26 (All)  
**Test Date:** Juni 2026  
**Tester:** Fatin Asyifa  
**Status:** Ready for Execution  
**Type:** E2E Integration Tests  

---

## 📋 Overview

Dokumen ini berisi test cases untuk integration testing yang menguji keseluruhan user journey dari berbagai perspektif:

**Test Scenarios:**
1. **Customer Journey:** Register → Browse → Order → Pay → Review
2. **Provider Journey:** Register → Verify → Receive Orders → Accept → Complete → Earn
3. **Admin Journey:** Dashboard → Verify Providers → Manage Platform → Reports
4. **Multi-User Interaction:** Customer A orders, Provider B accepts, handles payment
5. **Error Scenarios:** Network issues, payment failures, order cancellations

---

## Test Environment Setup

### System Requirements
- Backend: Laravel 11 running on http://127.0.0.1:8000
- Frontend: Flutter web on http://localhost:8888 (or chrome dev server)
- Database: MySQL with fresh seeded data
- Payment Gateway: Midtrans Sandbox
- Notification Service: n8n or mock
- Email Service: MailHog on localhost:1025
- Browser: Chrome with DevTools open

### Fresh Test Data
```bash
cd backend
php artisan migrate:fresh --seed --database=testing
php artisan tinker
# Seed test data
```

### Test User Accounts

**Customers:**
| Email | Password | Name | Balance |
|-------|----------|------|---------|
| fajar@example.com | password123 | Fajar | Rp 0 (new customer) |
| nabila@example.com | password123 | Nabila | Rp 0 (new customer) |
| siti@example.com | password123 | Siti | Rp 0 (new customer) |

**Providers:**
| Email | Password | Name | Service | Status |
|-------|----------|------|---------|--------|
| andi.listrik@example.com | password123 | Andi | Listrik | Verified |
| budi.plumbing@example.com | password123 | Budi | Plumbing | Verified |
| citra.ac@example.com | password123 | Citra | AC Service | Verified |

**Admin:**
| Email | Password | Name |
|-------|----------|------|
| admin@example.com | admin123 | Admin |

---

## Integration Test Suite 1: Complete Customer Journey

### IT-CUSTOMER-001: Full Customer Lifecycle
**Priority:** CRITICAL  
**Duration:** ~30 minutes  
**Objective:** Test complete customer experience from signup to review

**Prerequisites:**
- Fresh browser session
- Backend running
- Empty customer account

**Execution Steps:**

#### Phase 1: Registration & Setup (5 minutes)
```
1.1 Navigate to http://localhost:8888/register
1.2 Fill registration form:
    - Name: Fajar Test
    - Email: fajar.test@example.com
    - Password: Test@123456
    - Phone: 08123456789
1.3 Click Register button
    ✓ Account created
    ✓ Redirected to verify email
    ✓ Email received in MailHog
1.4 Click verification link in email
    ✓ Email verified
    ✓ Redirected to login
1.5 Login with new credentials
    ✓ Successfully logged in
    ✓ Redirected to Home page
```

**Verification Checklist:**
- [ ] User created in database
- [ ] Email verified status = true
- [ ] JWT token received
- [ ] Token stored in secure storage
- [ ] Can access protected endpoints

---

#### Phase 2: Browse & Explore Services (5 minutes)
```
2.1 Navigate to Home page
    ✓ Service list visible
    ✓ Minimal 3 services shown
2.2 View service details
    - Click "Teknisi Listrik"
    ✓ Service detail page loads
    ✓ Shows: name, description, price, rating, provider info
2.3 Test filters
    - Click "Filter"
    - Select "Electrical" category
    ✓ Only Electrical services shown
2.4 Test search
    - Search: "Listrik"
    ✓ Search results show matching services
2.5 View provider profile
    - Click provider avatar
    ✓ Provider profile page loads
    ✓ Shows: ratings, completed orders, reviews
```

**Database Checks:**
- [ ] All services visible to unauthenticated API calls
- [ ] Search index working
- [ ] Filters returning correct results

---

#### Phase 3: Create Order (5 minutes)
```
3.1 Navigate to Service Detail (Teknisi Listrik)
3.2 Click "Pesan Sekarang" (Book Now)
    ✓ Order form displayed
3.3 Fill order details:
    - Date: 2026-06-20
    - Time: 14:00
    - Location: Jl. Test 123, Jakarta
    - Notes: Pasang saklar baru
3.4 Submit order
    ✓ Order created successfully
    ✓ Order ID: ORD-XXXXXX
    ✓ Status: CREATED
    ✓ Redirected to order detail
3.5 Verify order in "My Orders" tab
    ✓ Order visible
    ✓ Status: CREATED
    ✓ Can see provider assigned
```

**API Verification:**
```
GET /api/v1/orders?role=customer
- Status: 200
- Data contains created order
- Status = CREATED
```

**Notification Checks:**
- [ ] Provider received email notification
- [ ] Email contains order details and link to accept

---

#### Phase 4: Provider Accepts & Payment Flow (8 minutes)
```
4.1 [NEW TAB/SESSION] Login as Provider (andi.listrik@example.com)
    ✓ Login successful
    ✓ Dashboard shows incoming order
4.2 View incoming order
    - Click order
    ✓ Order detail shows
    ✓ Customer location, notes visible
4.3 Accept order
    - Click "Terima Pesanan"
    ✓ Order status changed to ACCEPTED
    ✓ Payment flow triggered
4.4 [BACK TO CUSTOMER] Refresh page
    ✓ Order status updated to ACCEPTED
    ✓ Provider info now visible
    ✓ "Lakukan Pembayaran" button appears
4.5 Navigate to payment page
    - Click payment button
    ✓ QRIS generated
    ✓ QR code displayed
    ✓ Amount: 75,000 (50% deposit)
4.6 Simulate payment
    - Click "Buka Payment Gateway"
    - Select amount: 75,000
    - Confirm payment
    ✓ Payment submitted
4.7 Wait for webhook notification
    - Backend receives webhook from Midtrans
    ✓ Payment verified
    ✓ Status updated to PAID
4.8 Refresh page
    ✓ Payment status: PAID
    ✓ "Mulai Pekerjaan" button visible to provider
```

**Database Verification:**
```sql
SELECT * FROM orders WHERE id = 'ORD-XXXXX';
-- status = ACCEPTED

SELECT * FROM payment_transactions 
WHERE order_id = 'ORD-XXXXX';
-- status = paid
```

---

#### Phase 5: Work Execution (5 minutes)
```
5.1 [PROVIDER SESSION] Click "Mulai Pekerjaan"
    ✓ Work started
    ✓ Status: IN_PROGRESS
    ✓ Timer started
5.2 [CUSTOMER SESSION] Refresh
    ✓ Status: IN_PROGRESS
    ✓ Real-time status updated
5.3 [PROVIDER] Complete work
    - Click "Selesaikan Pekerjaan"
    - Add notes: "Saklar sudah dipasang"
    - Optional: Upload photos
    - Submit
    ✓ Status: COMPLETED
    ✓ Final payment triggered
5.4 [PROVIDER] Request final payment
    - Final payment QRIS: 75,000 remaining
    ✓ QR code displayed
5.5 [CUSTOMER] Receive notification
    ✓ Work completed notification
    ✓ Can see completion notes/photos
5.6 [CUSTOMER] Review page appears
    - Before confirming, can review work
    - Rating: 5 stars
    - Review: "Kerja bagus dan cepat"
    - Submit review
    ✓ Review saved
5.7 [CUSTOMER] Confirm completion
    - Click "Konfirmasi Selesai"
    - Final payment ready to process
    ✓ Status: CLOSED
```

**Final State:**
- Order: CLOSED
- All payments: PAID
- Review: SUBMITTED
- Payout: PENDING (scheduled for next day)

---

#### Phase 6: Verification & History (2 minutes)
```
6.1 [CUSTOMER] View in order history
    ✓ Order shows in completed
    ✓ Can see invoice
    ✓ Can download receipt
6.2 [PROVIDER] View in earnings
    ✓ Completed order shows
    ✓ Earnings calculated: 75,000 - 7,500 fee = 67,500
    ✓ Payout scheduled
6.3 [ADMIN] View in dashboard
    - Login as admin@example.com
    ✓ Order visible in platform stats
    ✓ Payment tracked
    ✓ Provider payout tracked
```

---

### IT-CUSTOMER-002: Multiple Orders & Provider Rotation
**Priority:** HIGH  
**Duration:** ~45 minutes  
**Objective:** Test multiple orders, different providers

**Scenario:**
1. Customer A creates 3 different orders
2. Provider B accepts order 1
3. Provider C accepts order 2
4. Provider B completes order 1
5. Verify customer only sees own orders

**Expected Results:**
- [ ] All orders visible in customer's list
- [ ] Each assigned to correct provider
- [ ] Data isolation maintained
- [ ] Payments tracked separately

---

## Integration Test Suite 2: Complete Provider Journey

### IT-PROVIDER-001: Full Provider Lifecycle
**Priority:** CRITICAL  
**Duration:** ~25 minutes  
**Objective:** Test provider experience from registration to payout

**Execution Steps:**

#### Phase 1: Provider Registration & Verification (7 minutes)
```
1.1 Register new provider account
    - Email: provider.test@example.com
    - Password: Test@123456
    - Name: Provider Test
    - Service: Teknisi Listrik
    - Years of experience: 5
    - Phone: 08123456789
    ✓ Account created
    ✓ Status: PENDING_VERIFICATION
1.2 Submit verification documents
    - ID card upload
    - Service certificate
    - Bank account details
    ✓ Documents submitted
1.3 [ADMIN] Review provider application
    - Login as admin
    - View pending providers
    - Review documents
    - Approve provider
    ✓ Provider status: VERIFIED
1.4 [PROVIDER] Receive approval notification
    ✓ Email received
    ✓ Dashboard updated: Status = VERIFIED
```

---

#### Phase 2: Provider Dashboard & Settings (5 minutes)
```
2.1 View provider dashboard
    ✓ Shows: stats, pending orders, earnings
2.2 Update availability status
    - Toggle: Available/Unavailable
    ✓ Status updated
    ✓ Available providers show in search
2.3 Configure service details
    - Update price
    - Update description
    - Set service hours
    ✓ Changes saved
2.4 View performance metrics
    ✓ Total completed orders: 0
    ✓ Rating: N/A
    ✓ Response time: -
```

---

#### Phase 3: Receive & Accept Orders (5 minutes)
```
3.1 Dashboard shows incoming order
    - From customer: Fajar
    - Service: Teknisi Listrik
    - Date/Time: 2026-06-20, 14:00
    ✓ Order details visible
3.2 Review customer's request
    - Location
    - Notes
    - Photos (if any)
3.3 Accept order
    ✓ Status: ACCEPTED
    ✓ Customer notified
3.4 View accepted order
    ✓ Shows customer contact info
    ✓ Can call/message customer (if implemented)
```

---

#### Phase 4: Complete Order & Earn (6 minutes)
```
4.1 When scheduled time arrives
    - Navigate to order
    - Click "Mulai Pekerjaan"
    ✓ In progress
4.2 Complete work
    - Add notes
    - Upload completion photos
    - Click "Selesaikan"
    ✓ Work marked complete
    ✓ Final payment pending
4.3 Customer reviews work
    ✓ Provider sees review
    ✓ Rating: 5 stars
4.4 Payment processed
    ✓ Platform fee deducted
    ✓ Net earning: 67,500
4.5 View in earnings
    ✓ Completed order shows
    ✓ Amount credited
    ✓ Payout status: PENDING
```

---

#### Phase 5: Payout & Financial History (2 minutes)
```
5.1 View payout history
    ✓ Shows completed orders
    ✓ Shows pending payouts
    ✓ Shows completed payouts
5.2 Request manual payout (if available)
    ✓ Button available if balance > threshold
5.3 View financial dashboard
    ✓ Total earnings: 67,500
    ✓ Platform fee: 7,500
    ✓ Net earning: 67,500
    ✓ Pending payout: 67,500
```

---

### IT-PROVIDER-002: Provider Rejection & Cancellation
**Priority:** MEDIUM  
**Objective:** Test provider rejection workflow

**Scenario:**
1. Provider receives order
2. Provider rejects order
3. Order becomes available to other providers
4. Another provider accepts

**Expected:**
- [ ] Rejection reason stored
- [ ] Automatic assignment to next available provider
- [ ] Original customer notified

---

## Integration Test Suite 3: Multi-User Interaction

### IT-INTERACTION-001: Concurrent Orders & Communication
**Priority:** HIGH  
**Duration:** ~30 minutes  
**Objective:** Test platform with multiple simultaneous users

**Setup:**
- 3 customer browser tabs
- 3 provider browser tabs  
- Admin tab

**Scenario:**

```
T+0:00  Customer A creates order #1 (Listrik)
        ✓ Provider A receives notification
        
T+0:05  Customer B creates order #2 (Plumbing)
        ✓ Provider B receives notification
        
T+0:10  Customer C creates order #3 (AC Service)
        ✓ Provider C receives notification
        
T+0:15  Provider A accepts order #1
        ✓ Customer A sees status change
        
T+0:20  Provider B rejects order #2
        ✓ Customer B notified
        ✓ Order reassigned to Provider C (auto/manual)
        
T+0:25  Customer A initiates payment
        ✓ Payment gateway open
        
T+0:30  Provider C accepts order #3
        ✓ Customer C notified
        
T+0:35  Payment #1 webhook received
        ✓ Payment verified
        ✓ Provider A can start work
        
T+0:40  Provider A starts work (order #1)
        ✓ Customer A sees IN_PROGRESS
        ✓ Timer started
        
T+0:45  Provider C receives payment notification (order #3)
        ✓ Ready to start when paid
        
T+1:00  Provider A completes work (order #1)
        ✓ Customer A receives notification
        ✓ Can provide review
        
T+1:05  Customer A leaves review (5 stars)
        ✓ Provider A's rating updated
        ✓ Review visible on profile
```

**Verification:**
- [ ] All real-time updates working
- [ ] No data mixing between users
- [ ] Notifications delivered correctly
- [ ] Concurrent operations handled

---

## Integration Test Suite 4: Error Scenarios

### IT-ERROR-001: Network Disconnection During Payment
**Priority:** HIGH  
**Objective:** Test resilience to network issues

**Scenario:**
```
1. Customer initiates QRIS payment
2. Browser closes/network disconnects at step 2
3. Payment webhook still received from Midtrans
4. Status updated correctly
5. Customer can check status later
```

**Expected:**
- [ ] Payment eventually marked as PAID
- [ ] UI updates when customer returns
- [ ] No duplicate charges

---

### IT-ERROR-002: Order Cancellation During Payment
**Priority:** MEDIUM  
**Objective:** Test edge case handling

**Scenario:**
```
1. Order accepted by provider
2. Customer initiates payment
3. Customer cancels order while payment pending
4. Payment webhook arrives 5 seconds later
```

**Expected:**
- [ ] Payment processed but refunded
- [ ] Order status = CANCELLED
- [ ] Funds returned to customer
- [ ] Provider notified of cancellation

---

### IT-ERROR-003: Provider Cancellation After Work Started
**Priority:** MEDIUM  
**Objective:** Test provider cancellation rules

**Scenario:**
```
1. Provider accepts order
2. Payment verified
3. Provider starts work
4. Provider clicks cancel
```

**Expected:**
- [ ] Cancel button disabled (after started)
- [ ] OR requires admin approval
- [ ] Penalty applied if applicable

---

### IT-ERROR-004: Duplicate Webhook Notification
**Priority:** HIGH  
**Objective:** Test idempotency

**Scenario:**
```
1. Payment webhook received
2. Same webhook received again (network retry)
```

**Expected:**
- [ ] First: Processed normally
- [ ] Second: Recognized as duplicate, not reprocessed
- [ ] No double-charging

---

## Integration Test Suite 5: Data Integrity & Security

### IT-SECURITY-001: Data Isolation - Customer Perspectives
**Priority:** CRITICAL  
**Objective:** Verify customer cannot see other customer's data

**Steps:**
```
1. Customer A logs in
   - Can see own orders only
2. Switch to Customer B
   - Cannot see Customer A's orders
   - Cannot access Customer A's data via URL manipulation
3. Try direct API call as Customer A to access Customer B's order
   - API returns 403 Forbidden
```

**Verification:**
```
✓ No data leakage
✓ All data filtered by user_id
✓ Authorization checks in place
```

---

### IT-SECURITY-002: Provider Cannot Access Admin Functions
**Priority:** HIGH  
**Objective:** Verify role-based access control

**Steps:**
```
1. Login as Provider
2. Try to access /admin/dashboard
   - Redirected or 403 error
3. Try API call: GET /api/v1/admin/users
   - Returns 403 Forbidden
```

---

### IT-SECURITY-003: SQL Injection Prevention
**Priority:** CRITICAL  
**Objective:** Test input sanitization

**Steps:**
```
1. In order notes, enter: "; DROP TABLE orders; --"
2. Submit order
3. Check database
```

**Expected:**
- [ ] No SQL injection
- [ ] Treated as literal string
- [ ] Database intact

---

## Performance Integration Tests

### IT-PERF-001: Full Journey Response Times
**Priority:** MEDIUM  
**Target Times:**

| Action | Target | Acceptable |
|--------|--------|------------|
| Login | 200ms | <500ms |
| Browse Services | 300ms | <800ms |
| Create Order | 500ms | <1000ms |
| Accept Order | 400ms | <1000ms |
| Process Payment | 200ms | <500ms |
| Webhook Response | 100ms | <200ms |

**Test:**
1. Perform full customer journey
2. Measure each API call response time
3. Log any times exceeding acceptable threshold

---

### IT-PERF-002: Database Query Optimization
**Priority:** MEDIUM  
**Objective:** Ensure no N+1 queries

**Steps:**
1. Enable Laravel Query Debugbar
2. Navigate through app
3. Check query count
4. Verify no excessive queries

**Expected:**
- [ ] <20 queries per page load
- [ ] No N+1 problems
- [ ] Proper eager loading

---

## Execution Report

### Phase 1: Customer Journey
| Step | Test Case | Status | Duration | Notes |
|------|-----------|--------|----------|-------|
| Registration | IT-CUSTOMER-001 | - | - | - |
| Browse | IT-CUSTOMER-001 | - | - | - |
| Order | IT-CUSTOMER-001 | - | - | - |
| Payment | IT-CUSTOMER-001 | - | - | - |
| Review | IT-CUSTOMER-001 | - | - | - |

### Phase 2: Provider Journey
| Step | Test Case | Status | Duration | Notes |
|------|-----------|--------|----------|-------|
| Verify | IT-PROVIDER-001 | - | - | - |
| Accept | IT-PROVIDER-001 | - | - | - |
| Complete | IT-PROVIDER-001 | - | - | - |
| Earn | IT-PROVIDER-001 | - | - | - |

### Phase 3: Multi-User
| Test | Status | Issues | Notes |
|------|--------|--------|-------|
| IT-INTERACTION-001 | - | - | - |

### Phase 4: Errors
| Test | Status | Result | Notes |
|------|--------|--------|-------|
| IT-ERROR-001 | - | - | - |
| IT-ERROR-002 | - | - | - |
| IT-ERROR-003 | - | - | - |
| IT-ERROR-004 | - | - | - |

### Phase 5: Security
| Test | Status | Result | Notes |
|------|--------|--------|-------|
| IT-SECURITY-001 | - | - | - |
| IT-SECURITY-002 | - | - | - |
| IT-SECURITY-003 | - | - | - |

---

## Summary Report

**Total Integration Tests:** 15+  
**Total Manual Steps:** 200+  
**Estimated Duration:** 3-4 hours  

**Success Criteria:**
- [ ] All happy path scenarios pass
- [ ] All error scenarios handled gracefully
- [ ] No security vulnerabilities
- [ ] Response times acceptable
- [ ] All notifications working
- [ ] All data isolation verified

---

**Document Version History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | Juni 2026 | Fatin Asyifa | Initial version - Integration testing scenarios |
