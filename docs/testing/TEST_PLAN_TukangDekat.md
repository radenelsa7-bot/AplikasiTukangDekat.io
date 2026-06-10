# Test Plan - Aplikasi TukangDekat

**Versi:** 1.0.0  
**Status:** Active  
**Tanggal Dibuat:** Juni 2026  
**Terakhir Diperbarui:** Juni 2026  
**Penulis:** Tim QA - Fatin Asyifa  
**Project:** PM_UAS_rekayasa_Sistem_Informasi  

---

## 📋 Daftar Isi

1. [Executive Summary](#executive-summary)
2. [Scope Testing](#scope-testing)
3. [Functional Requirements Coverage](#functional-requirements-coverage)
4. [Testing Strategy](#testing-strategy)
5. [Test Environment Setup](#test-environment-setup)
6. [Test Cases Framework](#test-cases-framework)
7. [Tools & Resources](#tools--resources)
8. [Schedule & Deliverables](#schedule--deliverables)
9. [Exit Criteria](#exit-criteria)
10. [Risk & Mitigation](#risk--mitigation)
11. [Bug Report Template](#bug-report-template)

---

## Executive Summary

Dokumen ini mendefinisikan rencana pengujian komprehensif untuk aplikasi **TukangDekat** - sebuah platform marketplace untuk jasa layanan teknisi.

**Aplikasi mencakup:**
- Backend REST API (Laravel 11)
- Mobile/Web Frontend (Flutter)
- Payment Gateway Integration (Midtrans QRIS)
- Notification System (n8n)
- Database (MySQL)

**Objektif Testing:**
- Memastikan semua functional requirements (FR-01 hingga FR-26) berfungsi dengan benar
- Menvalidasi integrasi antara frontend, backend, dan third-party services
- Mengidentifikasi dan mendokumentasikan bugs sebelum production
- Memastikan aplikasi memenuhi standar kualitas dan keamanan

**Target Coverage:** 85%+ dari functional requirements

---

## Scope Testing

### ✅ In Scope

| Area | Komponen | Status |
|------|----------|--------|
| **Authentication** | Login, Register, Password Reset, Token Management | akan diuji |
| **User Management** | Profile, Role Management, Verification | akan diuji |
| **Service Catalog** | List Services, Filter, Search, Details | akan diuji |
| **Order Management** | Create, Accept, Start, Complete, Cancel Orders | akan diuji |
| **Payment** | QRIS Payment, Webhook Verification, Payout | akan diuji |
| **Notification** | Email, SMS, In-App Notifications | akan diuji |
| **Provider Features** | Dashboard, Order History, Rating | akan diuji |
| **Customer Features** | Search, Booking, Review, Rating | akan diuji |
| **Admin Features** | Dashboard, User Management, Reports | akan diuji |

### ❌ Out of Scope

- Performance testing di production environment
- Load testing untuk >10,000 concurrent users
- Security penetration testing
- Infrastructure/DevOps testing
- Third-party API changes (Midtrans, n8n)

---

## Functional Requirements Coverage

### Authentication Module (FR-01 s/d FR-05)

| FR ID | Requirement | Description | Priority | Status |
|-------|-------------|-------------|----------|--------|
| FR-01 | User Registration | Pengguna dapat mendaftar dengan email/password | High | akan diuji |
| FR-02 | User Login | Pengguna dapat login dengan credentials | High | akan diuji |
| FR-03 | Password Reset | Pengguna dapat reset password via email | Medium | akan diuji |
| FR-04 | Token Management | Sistem mengelola JWT token dengan benar | High | akan diuji |
| FR-05 | Role-Based Access | User memiliki role terpisah (Customer/Provider/Admin) | High | akan diuji |

### Service Catalog Module (FR-06 s/d FR-08)

| FR ID | Requirement | Description | Priority | Status |
|-------|-------------|-------------|----------|--------|
| FR-06 | List Services | Customer dapat melihat list services yang tersedia | High | akan diuji |
| FR-07 | Filter Services | Dapat filter services berdasarkan kategori/harga/rating | High | akan diuji |
| FR-08 | Service Details | Customer dapat melihat detail lengkap service | High | akan diuji |

### Order Management Module (FR-09 s/d FR-15)

| FR ID | Requirement | Description | Priority | Status |
|-------|-------------|-------------|----------|--------|
| FR-09 | Create Order | Customer dapat membuat order baru | High | akan diuji |
| FR-10 | Order Status Transition | Order bisa transition: CREATED → ACCEPTED → IN_PROGRESS → COMPLETED | High | akan diuji |
| FR-11 | Accept Order | Provider dapat accept order dari customer | High | akan diuji |
| FR-12 | Start Work | Provider dapat mulai pekerjaan (setelah pembayaran DP) | High | akan diuji |
| FR-13 | Complete Work | Provider dapat mark pekerjaan selesai | High | akan diuji |
| FR-14 | Cancel Order | Customer/Provider dapat cancel order sesuai rules | Medium | akan diuji |
| FR-15 | Order History | Pengguna dapat melihat order history lengkap | Medium | akan diuji |

### Payment Module (FR-16 s/d FR-19)

| FR ID | Requirement | Description | Priority | Status |
|-------|-------------|-------------|----------|--------|
| FR-16 | Generate QRIS | Sistem dapat generate QRIS untuk pembayaran | High | akan diuji |
| FR-17 | Payment Verification | Webhook dari Midtrans memverifikasi pembayaran | High | akan diuji |
| FR-18 | Payout to Provider | Sistem dapat process payout ke rekening provider | High | akan diuji |
| FR-19 | Payment History | Pengguna dapat melihat payment history | Medium | akan diuji |

### Notification Module (FR-20 s/d FR-22)

| FR ID | Requirement | Description | Priority | Status |
|-------|-------------|-------------|----------|--------|
| FR-20 | Email Notification | Sistem mengirim email notifications sesuai events | High | akan diuji |
| FR-21 | In-App Notification | Sistem mengirim in-app notifications real-time | Medium | akan diuji |
| FR-22 | Notification Preferences | Pengguna dapat mengatur preferensi notifikasi | Low | akan diuji |

### Review & Rating Module (FR-23 s/d FR-26)

| FR ID | Requirement | Description | Priority | Status |
|-------|-------------|-------------|----------|--------|
| FR-23 | Submit Review | Customer dapat submit review setelah order selesai | Medium | akan diuji |
| FR-24 | Submit Rating | Customer dapat rate provider 1-5 stars | Medium | akan diuji |
| FR-25 | View Ratings | Ratings ditampilkan di profile provider | Medium | akan diuji |
| FR-26 | Rating Calculation | Sistem kalkulasi average rating provider | Medium | akan diuji |

---

## Testing Strategy

### Testing Levels

```
┌─────────────────────────────────────────┐
│          E2E Testing (20%)               │
│  Full user journey: Register → Order    │
│         → Payment → Complete            │
└─────────────────────────────────────────┘
         ↑
┌─────────────────────────────────────────┐
│    Integration Testing (30%)             │
│  API ↔ Database, API ↔ External Service  │
│  Payment Gateway, Notification Service   │
└─────────────────────────────────────────┘
         ↑
┌─────────────────────────────────────────┐
│       Unit Testing (50%)                 │
│  Individual functions, service logic     │
│  Business rule validation                │
└─────────────────────────────────────────┘
```

### Test Types

| Type | Scope | Tools | Priority |
|------|-------|-------|----------|
| **Unit Tests** | API business logic, validation | PHPUnit | High |
| **API Integration** | REST endpoints, database operations | Postman, REST Client | High |
| **Feature Tests** | Complete feature workflows | Feature Tests (Laravel) | High |
| **E2E Tests** | User journey end-to-end | Flutter Driver, Manual | Medium |
| **Manual Testing** | UI/UX, edge cases, user experience | Manual with Checklist | Medium |
| **Security Tests** | Authentication, Authorization, Input Validation | Manual + OWASP | Medium |
| **Performance** | Response time, pagination, caching | Browser DevTools | Low |
| **Regression** | Previous fixes verification | Test Suite | High |

### Test Case Structure

Setiap test case mengikuti struktur:

```yaml
ID: TC-XXX-YYY
Module: [Module Name]
FR: [Related FR ID]
Title: [Clear test case title]
Priority: [High/Medium/Low]
Preconditions:
  - Kondisi awal yang diperlukan
Steps:
  1. Step pertama
  2. Step kedua
Expected Result:
  - Hasil yang diharapkan 1
  - Hasil yang diharapkan 2
Edge Cases:
  - Edge case 1
  - Edge case 2
Notes:
  - Catatan tambahan
```

---

## Test Environment Setup

### Backend Setup

```bash
cd backend

# Buat environment file
cp .env.example .env.testing

# Install dependencies
composer install

# Generate key
php artisan key:generate

# Create database
mysql -u root -p -e "CREATE DATABASE tukangdekat_test;"

# Run migrations
php artisan migrate --database=testing

# Seed test data
php artisan db:seed --database=testing --seeder=TestDataSeeder

# Run tests
php artisan test
```

### Frontend Setup

```bash
cd mobile

# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Run widget tests
flutter test

# Run integration tests
flutter drive --target=test_driver/app.dart
```

### Test Credentials

**Customer Accounts:**
| Email | Password | Name |
|-------|----------|------|
| fajar@example.com | password123 | Fajar (Customer) |
| nabila@example.com | password123 | Nabila (Customer) |
| siti@example.com | password123 | Siti (Customer) |

**Provider Accounts:**
| Email | Password | Name | Service |
|-------|----------|------|---------|
| andi.listrik@example.com | password123 | Andi | Teknisi Listrik |
| budi.plumbing@example.com | password123 | Budi | Tukang Pipa |
| citra.ac@example.com | password123 | Citra | AC Service |

**Admin Accounts:**
| Email | Password | Name |
|-------|----------|------|
| admin@example.com | admin123 | Admin |

### External Services Setup

**Midtrans Sandbox:**
- Server Key: [dari .env.testing]
- Client Key: [dari .env.testing]
- Payment Gateway: https://app.sandbox.midtrans.com

**n8n (Notifications):**
- URL: http://localhost:5678
- Webhook: http://localhost:5678/webhook/...

**Email Testing:**
- Tool: MailHog (http://localhost:1025)
- SMTP: localhost:1025

---

## Test Cases Framework

### Category 1: Authentication (FR-01 hingga FR-05)

**TC-AUTH-001: Successful User Registration**
- Precondition: User belum terdaftar
- Steps:
  1. Navigate ke registration page
  2. Input email: `test.user@example.com`
  3. Input password: `Test@1234`
  4. Input confirm password: `Test@1234`
  5. Click register button
- Expected:
  - ✅ User berhasil terdaftar
  - ✅ Redirect ke login page
  - ✅ Email verification dikirim

**TC-AUTH-002: Login with Valid Credentials**
- Precondition: User sudah terdaftar (fajar@example.com)
- Steps:
  1. Input email: `fajar@example.com`
  2. Input password: `password123`
  3. Click login
- Expected:
  - ✅ Login berhasil
  - ✅ JWT token tersimpan
  - ✅ Redirect ke dashboard

**TC-AUTH-003: Login with Invalid Password**
- Steps:
  1. Input email: `fajar@example.com`
  2. Input password: `wrongpassword`
  3. Click login
- Expected:
  - ❌ Login gagal
  - ✅ Error message: "Email atau password salah"
  - ✅ Stay di login page

### Category 2: Service Catalog (FR-06 hingga FR-08)

**TC-CATALOG-001: List All Services**
- Precondition: User sudah login sebagai customer
- Steps:
  1. Navigate ke home/catalog page
  2. Observe list of services
- Expected:
  - ✅ Minimal 3 services ditampilkan
  - ✅ Setiap service menampilkan: name, rating, price, provider
  - ✅ Pagination berfungsi jika >10 services

**TC-CATALOG-002: Filter Services by Category**
- Steps:
  1. Click filter button
  2. Select category: "Listrik"
  3. Apply filter
- Expected:
  - ✅ Hanya services kategori Listrik ditampilkan
  - ✅ Clear filter button tersedia

### Category 3: Order Management (FR-09 hingga FR-15)

**TC-ORDER-001: Create New Order**
- Precondition: Customer login (fajar@example.com), ada provider tersedia
- Steps:
  1. Navigate ke service catalog
  2. Select service "Teknisi Listrik"
  3. Input order details:
     - Date: 2026-06-15
     - Time: 14:00
     - Address: Jl. Test 123
     - Notes: Pasang saklar
  4. Submit order
- Expected:
  - ✅ Order berhasil dibuat
  - ✅ Order mendapat ID unik
  - ✅ Status: CREATED
  - ✅ Redirect ke order detail page
  - ✅ Notifikasi dikirim ke provider

**TC-ORDER-002: Order Status Transition (CREATED → ACCEPTED)**
- Precondition: Order sudah created, provider login
- Steps:
  1. Provider melihat incoming order
  2. Click "Terima Pesanan" button
  3. Confirm acceptance
- Expected:
  - ✅ Status berubah menjadi ACCEPTED
  - ✅ Customer menerima notifikasi
  - ✅ Deposit (DP) payment di-trigger

### Category 4: Payment (FR-16 hingga FR-19)

**TC-PAYMENT-001: Generate and Pay QRIS**
- Precondition: Order accepted, ready for DP payment
- Steps:
  1. Navigate ke payment page
  2. Click "Generate QRIS"
  3. Open payment gateway (simulated)
  4. Complete payment
- Expected:
  - ✅ QRIS berhasil di-generate
  - ✅ QR code ditampilkan
  - ✅ Payment status pending
  - ✅ Webhook dari Midtrans received
  - ✅ Payment status updated ke PAID

**TC-PAYMENT-002: Webhook Signature Verification**
- Precondition: Payment callback dari Midtrans
- Steps:
  1. Midtrans mengirim webhook dengan signature
  2. Backend memverifikasi signature
- Expected:
  - ✅ Signature valid
  - ✅ Payment status di-update di database
  - ✅ Order status bisa progress ke IN_PROGRESS

### Category 5: Notifications (FR-20 hingga FR-22)

**TC-NOTIF-001: Email Notification on Order Created**
- Steps:
  1. Customer membuat order baru
  2. Check email inbox (MailHog)
- Expected:
  - ✅ Email dikirim ke provider
  - ✅ Email berisi order details
  - ✅ Link untuk accept order

**TC-NOTIF-002: In-App Notification Real-Time**
- Precondition: Provider app terbuka di tab lain
- Steps:
  1. Customer membuat order
  2. Observer provider app
- Expected:
  - ✅ Notifikasi muncul real-time
  - ✅ Toast/badge indicator

### Category 6: Review & Rating (FR-23 hingga FR-26)

**TC-RATING-001: Submit Review After Completion**
- Precondition: Order selesai (COMPLETED), customer login
- Steps:
  1. Navigate ke completed order
  2. Click "Beri Review"
  3. Input rating: 5 stars
  4. Input review: "Kerja bagus dan cepat"
  5. Submit
- Expected:
  - ✅ Review berhasil disimpan
  - ✅ Rating terupdate di provider profile
  - ✅ Average rating kalkulasi ulang

---

## Tools & Resources

### API Testing Tools

1. **Postman**
   - Collection: `docs/postman/TukangDekat_API.postman_collection.json`
   - Environment: `docs/postman/TukangDekat.postman_environment.json`
   - Usage: Import dan jalankan all requests

2. **cURL / REST Client**
   - Alternative untuk quick testing
   - Command examples di `docs/api/CURL_EXAMPLES.md`

### UI/Automation Testing

1. **Flutter Driver**
   - Location: `mobile/test_driver/app.dart`
   - Run: `flutter drive --target=test_driver/app.dart`

2. **Manual Testing Checklist**
   - Document: `docs/testing/MANUAL_CHECKLIST.md`

### Monitoring Tools

1. **Browser DevTools**
   - Network: Monitor API calls
   - Console: Check errors
   - Storage: Verify token/cache

2. **MailHog** (Email Testing)
   - URL: http://localhost:1025
   - Verify email notifications

3. **n8n Dashboard**
   - Monitor workflow execution
   - Check notification logs

### Version Control

- Branch naming: `testing/test-{category}`
- Commit format: `test: add test cases for {feature}`
- PR template: `.github/pull_request_template.md`

---

## Schedule & Deliverables

### Timeline

| Week | Phase | Duration | Deliverables |
|------|-------|----------|--------------|
| Week 1 (11-17 Mei) | Test Planning & Setup | 5 days | ✅ Test Plan (this doc), Test Data Seeder, Postman Collection |
| Week 2 (18-24 Mei) | Auth & API Testing | 5 days | ✅ Test Cases Auth, API Test Results, Bug Reports |
| Week 3 (25-31 Mei) | Order Management Testing | 5 days | ✅ Test Cases Order, E2E Scenarios, Test Results |
| Week 4 (1-7 Jun) | Payment & Notification | 5 days | ✅ Payment Flow Test, Webhook Verification, Bug Reports |
| Week 5 (8-14 Jun) | Integration Testing | 5 days | ✅ Full User Journey Tests, Regression Test, Integration Report |
| Week 6 (15-18 Jun) | Final QA & Regression | 3 days | ✅ Final Test Report, Bug Fix Verification, Sign-off |

### Deliverable Documents

| Document | Location | Owner | Status |
|----------|----------|-------|--------|
| Test Plan | docs/testing/TEST_PLAN_TukangDekat.md | QA | ✅ Active |
| Test Cases | docs/testing/TEST_CASES_*.md | QA | akan dibuat |
| Postman Collection | docs/postman/TukangDekat_API.postman_collection.json | QA | akan dibuat |
| Test Execution Report | docs/testing/TEST_EXECUTION_REPORT.md | QA | akan dibuat |
| Bug Report | docs/testing/BUG_REPORTS.md | QA | akan dibuat |
| Final QA Report | docs/testing/FINAL_QA_REPORT.md | QA | akan dibuat |

---

## Exit Criteria

Testing akan dianggap **selesai** ketika:

### Functional Criteria
- ✅ 100% functional requirements (FR-01 hingga FR-26) sudah diuji
- ✅ Minimal 85% test cases berhasil (PASSED)
- ✅ Semua HIGH priority bugs sudah di-fix dan verified
- ✅ Minimal 50% MEDIUM priority bugs sudah di-fix

### Quality Criteria
- ✅ Zero critical bugs
- ✅ API response time < 200ms (95th percentile)
- ✅ Zero data corruption issues
- ✅ Zero security vulnerabilities (OWASP TOP 10)

### Documentation Criteria
- ✅ Semua test cases terdokumentasi
- ✅ Semua bugs terdokumentasi dengan clear reproduction steps
- ✅ Final QA report approved oleh PM

### Sign-off
- ✅ QA Lead: Approved
- ✅ Dev Lead: Approved
- ✅ Project Manager: Approved

---

## Risk & Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| **Third-party API delay** (Midtrans, n8n) | High | High | Setup sandbox, mock responses, fallback scenarios |
| **Data loss in testing** | Medium | High | Regular DB backup, separate test database |
| **Flaky tests** | Medium | Medium | Use proper wait strategies, log all failures |
| **Scope creep** | High | Medium | Strict change management, document additions separately |
| **Resource constraints** | Low | Medium | Cross-training, documentation focus |
| **Environment issues** | Medium | Medium | IaC (Dockerfile), environment checklist |

---

## Bug Report Template

Setiap bug harus dilaporkan menggunakan format ini:

```markdown
## Bug Report: [Judul Bug]

### Basic Information
- **Bug ID:** BUG-XXX-YYY
- **Date:** YYYY-MM-DD
- **Reported By:** [Nama Tester]
- **Module:** [Module Name]
- **Priority:** [Critical/High/Medium/Low]
- **Status:** New/In Progress/Fixed/Verified/Closed

### Environment
- **Backend:** Version X.X.X, Environment: [Dev/Staging]
- **Frontend:** Version X.X.X, Platform: [Web/Mobile/iOS/Android]
- **Database:** MySQL X.X
- **Browser:** [Chrome/Firefox/Safari] Version X.X

### Steps to Reproduce
1. Step 1
2. Step 2
3. Step 3

### Expected Result
- Apa yang seharusnya terjadi

### Actual Result
- Apa yang terjadi sebenarnya

### Screenshots/Logs
- [Attach screenshot atau log file]

### Related Test Case
- TC-XXX-YYY

### Related Functional Requirement
- FR-XX

### Affected Users
- [Describe who is affected]

### Workaround (if available)
- [If user can work around, describe it]

### Additional Notes
- [Any additional context]
```

---

## Approval & Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| QA Lead | Fatin Asyifa | - | Pending |
| Development Lead | - | - | Pending |
| Project Manager | - | - | Pending |
| Client | - | - | Pending |

---

**Document Version History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | Juni 2026 | Fatin Asyifa | Initial version |

---

*Dokumen ini adalah template komprehensif untuk test planning aplikasi TukangDekat. Setiap section dapat di-customize sesuai kebutuhan project.*
