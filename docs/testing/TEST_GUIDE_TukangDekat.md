# Panduan Testing – TukangDekat

**Versi:** 1.0  
**Terakhir Diperbarui:** Juni 2026  
**Penulis:** Tim QA  

---

## Daftar Isi

1. [Ringkasan](#ringkasan)
2. [Strategi Testing](#strategi-testing)
3. [Testing Backend](#testing-backend)
4. [Testing Frontend/Mobile](#testing-frontendmobile)
5. [Testing E2E](#testing-e2e)
6. [Testing Performa](#testing-performa)
7. [Testing Keamanan](#testing-keamanan)
8. [Eksekusi Test](#eksekusi-test)
9. [Integrasi CI/CD](#integrasi-cicd)
10. [Pelaporan Bug](#pelaporan-bug)

---

## Ringkasan

TukangDekat adalah platform marketplace jasa dengan komponen utama:

- **Backend:** REST API Laravel 11
- **Mobile:** Flutter (Android & iOS)
- **Pembayaran:** Integrasi QRIS Midtrans
- **Otomasi:** n8n untuk notifikasi
- **Database:** MySQL

**Cakupan Testing:**
- Unit Tests (Logika Bisnis)
- Integration Tests (API, Database, Layanan Eksternal)
- Feature Tests (Validasi Endpoint)
- E2E Tests (User Journey Lengkap)
- Performance Tests (Beban, Response Time)
- Security Tests (Autentikasi, Otorisasi, Validasi Input)

---

## Strategi Testing

### Pyramid Testing

```
        △
       ╱ ╲
      ╱ E2E╲
     ╱──────╲
    ╱Integration╲
   ╱──────────────╲
  ╱  Unit Tests    ╲
 ╱────────────────────╲
```

- **Unit Tests:** 50% (Fungsi individual, services)
- **Integration Tests:** 30% (Database, API eksternal)
- **E2E Tests:** 20% (User journey lengkap)

### Target Coverage

| Komponen | Target Coverage | Status |
|----------|-----------------|--------|
| Backend Services | 80% | TBD |
| Controllers | 70% | TBD |
| Models | 85% | TBD |
| Mobile UI | 60% | TBD |

---

## Testing Backend

### Setup

```bash
cd backend

# Install dependencies
composer install

# Buat database test
cp .env.example .env.testing
php artisan migrate --database=testing --seed

# Jalankan tests
php artisan test
```

### Struktur Test

```
backend/tests/
├── Unit/
│   ├── XenditPayoutGatewayTest.php      # Logika gateway pembayaran
│   ├── PayoutMonitoringTest.php         # Monitoring & alert
│   └── ExampleTest.php
├── Feature/
│   ├── PaymentWebhookTest.php           # Pemrosesan webhook
│   ├── PayoutFlowTest.php               # Flow Order → Payout
│   ├── TreasurerExportTest.php          # Laporan treasurer
│   └── AuthTest.php
└── Integration/
    └── NetworkBackoffTest.php           # Logika retry & backoff
```

### Unit Tests

**Tujuan:** Testing logika bisnis terisolasi tanpa dependensi eksternal.

#### Contoh: Test Payout Gateway

```php
// backend/tests/Unit/XenditPayoutGatewayTest.php
public function test_send_success_returns_transaction_reference()
{
    Http::fake([
        '*' => Http::response(['id' => 'tx-1'], 200)
    ]);

    $gateway = new XenditPayoutGateway('test_key', 'https://api.test');
    $res = $gateway->send([
        'amount' => 10000,
        'bank_code' => 'MANDIRI',
        'account_number' => '000111222333'
    ]);

    $this->assertTrue($res['success']);
    $this->assertSame('tx-1', $res['transaction_reference']);
}
```

**Jalankan Unit Tests:**

```bash
php artisan test --filter=XenditPayoutGatewayTest
```

### Feature Tests

**Tujuan:** Testing API endpoints dengan interaksi database.

#### Contoh: Test Payment Webhook

```php
// backend/tests/Feature/PaymentWebhookTest.php
public function test_midtrans_webhook_marks_payment_paid_and_closes_final_order()
{
    config([
        'services.payments.driver' => 'midtrans',
        'services.payments.midtrans_server_key' => 'midtrans-secret-key',
    ]);

    $customer = User::factory()->create(['role' => 'CUSTOMER']);
    $provider = User::factory()->create(['role' => 'PROVIDER']);

    $order = Order::create([
        'order_code' => 'ORD-' . now()->format('Ymd') . '-0001',
        'customer_id' => $customer->id,
        'provider_id' => $provider->id,
        'status' => 'CREATED',
    ]);

    $payment = Payment::create([
        'order_id' => $order->id,
        'payment_type' => 'FINAL',
        'amount' => 150000,
        'status' => 'PENDING',
    ]);

    $payload = [
        'order_id' => $payment->external_payment_id,
        'status_code' => '200',
        'transaction_status' => 'settlement',
        'signature_key' => hash('sha512', /* ... */),
    ];

    $response = $this->postJson('/api/webhooks/payment', $payload);

    $response->assertStatus(200);
    $this->assertSame('PAID', $payment->fresh()->status);
    $this->assertSame('CLOSED', $order->fresh()->status);
}
```

**Jalankan Feature Tests:**

```bash
php artisan test --filter=PaymentWebhookTest
```

### Integration Tests

**Tujuan:** Testing logika retry, backoff, dan kegagalan network.

#### Contoh: Test Network Backoff

```php
// backend/tests/Integration/NetworkBackoffTest.php
public function test_retries_on_5xx_then_succeeds()
{
    Http::fakeSequence()
        ->push(['message' => 'server error'], 500)
        ->push(['id' => 'tx_123'], 200);

    $gateway = new XenditPayoutGateway('test_key', 'https://api.xendit.test');
    $res = $gateway->send(['amount' => 10000]);

    $this->assertTrue($res['success']);
    Http::assertSentCount(2);  // Verifikasi retry terjadi
}
```

**Jalankan Integration Tests:**

```bash
php artisan test tests/Integration/
```

### Skenario Test Kunci

#### 1. Autentikasi & Otorisasi

- [ ] Register sebagai CUSTOMER → dapatkan token
- [ ] Register sebagai PROVIDER → dapatkan token
- [ ] Login dengan credential invalid → 401
- [ ] Akses endpoint protected tanpa token → 401
- [ ] CUSTOMER akses endpoint PROVIDER → 403
- [ ] Token expiry & refresh

#### 2. Order Lifecycle

- [ ] Buat order → AUTO-CREATE pembayaran DP 50%
- [ ] Terima order di dashboard provider
- [ ] Provider ACCEPT order
- [ ] Mulai order ketika DP PAID (bukan sebelumnya)
- [ ] Complete order → AUTO-CREATE pembayaran FINAL
- [ ] Tidak bisa CLOSE order sampai FINAL PAID
- [ ] Cancel order (validasi status transitions)

#### 3. Payment Flow

- [ ] Generate QRIS → dapatkan QR code
- [ ] Webhook: PAID → update status Payment + Order
- [ ] Webhook: Signature invalid → 401
- [ ] Webhook: Duplikat event → idempotent
- [ ] Webhook: QR EXPIRED → tracking tanggal expiry

#### 4. Treasurer Reports

- [ ] Treasurer GET /api/treasurer/payments/report
- [ ] Export CSV dengan headers yang benar
- [ ] Export XLS dengan data
- [ ] Non-treasurer access → 403
- [ ] Filter berdasarkan rentang tanggal

#### 5. Fungsi Admin

- [ ] ADMIN verifikasi provider
- [ ] Provider menjadi terverifikasi + searchable
- [ ] Visibilitas profil provider

### Jalankan Semua Backend Tests

```bash
# Jalankan semua tests
php artisan test

# Jalankan dengan coverage report
php artisan test --coverage

# Jalankan test file tertentu
php artisan test tests/Feature/PaymentWebhookTest.php

# Jalankan dengan output detail
php artisan test --verbose

# Stop pada failure pertama
php artisan test --stop-on-failure
```

---

## Testing Frontend/Mobile

### Setup

```bash
cd mobile

# Install dependencies
flutter pub get

# Jalankan tests
flutter test
```

### Widget Tests

**Lokasi:** `mobile/test/widget_test.dart`

**Tujuan:** Testing komponen UI individual secara terisolasi.

```dart
void main() {
  testWidgets('Login screen validates email', (WidgetTester tester) async {
    await tester.pumpWidget(MyApp());

    // Cari widgets
    expect(find.byType(EmailField), findsOneWidget);
    expect(find.byType(PasswordField), findsOneWidget);

    // Masukkan email invalid
    await tester.enterText(find.byType(EmailField), 'invalid');
    await tester.tap(find.byType(LoginButton));
    await tester.pump();

    // Verifikasi pesan error
    expect(find.text('Invalid email'), findsOneWidget);
  });
}
```

### Integration Tests (Flutter)

**Lokasi:** `mobile/integration_test/`

**Tujuan:** Testing app flows di device/emulator sebenarnya.

```dart
// mobile/integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete order flow', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Login
    await tester.enterText(find.byType(TextField).first, 'user@test.com');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Cari provider
    await tester.tap(find.byIcon(Icons.search));
    await tester.enterText(find.byType(SearchField), 'AC Repair');
    await tester.pumpAndSettle();

    // Buat order
    await tester.tap(find.text('Order Now'));
    await tester.pumpAndSettle();

    expect(find.text('Order Created'), findsOneWidget);
  });
}
```

**Jalankan Mobile Tests:**

```bash
# Widget tests
flutter test

# Integration tests di Android
flutter drive --target=integration_test/app_test.dart

# Integration tests di emulator
flutter test integration_test/
```

### Skenario Mobile Test Kunci

- [ ] Flow register & login
- [ ] Cari provider berdasarkan kategori
- [ ] Filter providers (rating, jarak, harga)
- [ ] Buat order dengan date picker
- [ ] Upload foto attachment
- [ ] Lihat QR code QRIS
- [ ] Polling status pembayaran
- [ ] Submit review & rating
- [ ] Provider-side: accept/reject order
- [ ] Provider-side: input final price & complete
- [ ] Navigasi antar screens
- [ ] Token refresh pada 401
- [ ] Handling network error
- [ ] Offline mode (jika ada)

---

## Testing E2E

### Setup

```bash
cd backend/e2e

# Install Playwright
npm install @playwright/test

# Buat .env
cp .env.example .env
# Set: TEST_TOKEN, API_BASE_URL
```

### Struktur Test

```
backend/e2e/
├── tests/
│   ├── treasurer-export.spec.js
│   ├── payment-flow.spec.js
│   ├── order-lifecycle.spec.js
│   └── auth-flow.spec.js
├── playwright.config.js
└── README.md
```

### Contoh: Test Treasurer Export

```javascript
// backend/e2e/tests/treasurer-export.spec.js
const { test, expect } = require('@playwright/test');

test.describe('Endpoint export treasurer', () => {
  test('CSV export mengembalikan CSV ketika TEST_TOKEN disediakan', async ({ request }) => {
    const token = process.env.TEST_TOKEN;
    test.skip(!token, 'TEST_TOKEN tidak diatur');

    const res = await request.get('/api/treasurer/payments/report?export=csv', {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Accept': 'text/csv'
      }
    });

    expect(res.status()).toBe(200);
    expect(res.headers()['content-type']).toContain('text/csv');
    
    const body = await res.text();
    expect(body).toContain('payment_id');
    expect(body.length).toBeGreaterThan(10);
  });

  test('XLS export dengan data', async ({ request }) => {
    const token = process.env.TEST_TOKEN;
    
    const res = await request.get('/api/treasurer/payments/report?export=xls', {
      headers: { 'Authorization': `Bearer ${token}` }
    });

    expect(res.status()).toBe(200);
    expect(res.headers()['content-disposition']).toContain('treasurer_payments_');
  });
});
```

### Jalankan E2E Tests

```bash
cd backend/e2e

# Jalankan semua tests
npx playwright test

# Jalankan test file tertentu
npx playwright test tests/treasurer-export.spec.js

# Jalankan dengan UI mode
npx playwright test --ui

# Jalankan dengan debugging
npx playwright test --debug

# Generate HTML report
npx playwright show-report
```

### Cakupan E2E Test

- [ ] **Auth Flow**
  - Register CUSTOMER & PROVIDER
  - Login dengan credential valid/invalid
  - Persistensi token

- [ ] **Order Lifecycle**
  - Customer membuat order
  - Provider menerima order
  - Accept/reject order
  - Mulai kerja (ketika DP dibayar)
  - Complete kerja & input final price
  - Order status CLOSED

- [ ] **Payment Flow**
  - Generate QRIS
  - Simulasi webhook payment
  - Order status transitions
  - Final payment & order closure

- [ ] **Treasurer Reports**
  - Export CSV
  - Export XLS
  - Filter berdasarkan tanggal
  - Pengecekan otorisasi

---

## Testing Performa

### Load Testing (Apache JMeter)

**File:** `docs/testing/jmeter-tukangdekat.jmx`

#### Skenario: 100 concurrent users, durasi 5 menit

```
Thread Group:
  - Number of Threads: 100
  - Ramp-up Time: 60 sec
  - Loop Count: 10

HTTP Requests:
  - GET /api/categories
  - POST /api/auth/login
  - GET /api/providers
  - POST /api/orders
```

**Jalankan Load Test:**

```bash
jmeter -n -t docs/testing/jmeter-tukangdekat.jmx -l results.jtl -j jmeter.log
```

### Target Performa (NFR-01)

| Endpoint | Target Response Time | Status |
|----------|----------------------|--------|
| GET /api/categories | < 500ms | TBD |
| GET /api/providers | < 1000ms | TBD |
| POST /api/orders | < 1500ms | TBD |
| POST /api/webhooks/payment | < 500ms | TBD |
| GET /api/treasurer/payments/report | < 2000ms | TBD |

### Profiling

```bash
# Backend profiling
php artisan tinker

# Gunakan Laravel Debugbar
composer require barryvdh/laravel-debugbar --dev

# Slow query log
php artisan db:monitor

# Cek N+1 queries
composer require barryvdh/laravel-query-detector --dev
```

---

## Testing Keamanan

### Checklist OWASP Top 10

- [ ] **A01: Broken Access Control**
  - CUSTOMER tidak dapat akses endpoint PROVIDER
  - PROVIDER tidak dapat akses endpoint ADMIN
  - Token expiry diterapkan

- [ ] **A02: Cryptographic Failures**
  - Password di-hash dengan bcrypt (10+ rounds)
  - HTTPS diaktifkan
  - Data sensitif tidak di-log

- [ ] **A03: Injection**
  - SQL injection: gunakan parameterized queries (Eloquent)
  - XSS: output encoding di Flutter
  - Command injection: hindari shell_exec

- [ ] **A04: Insecure Design**
  - Business rules diterapkan (misalnya, start order hanya jika DP PAID)
  - Rate limiting di endpoint sensitif

- [ ] **A05: Security Misconfiguration**
  - Hapus debug mode di production
  - Disable directory listing
  - Set secure headers

- [ ] **A06: Vulnerable Components**
  - Perbarui Laravel, packages secara berkala
  - Gunakan `composer audit`
  - Scan dengan `npm audit` (Node packages)

- [ ] **A07: Authentication Failures**
  - 2FA opsional (enhancement di masa depan)
  - Login attempt throttling
  - Session timeout

- [ ] **A08: Software & Data Integrity Failures**
  - Webhook signature verification wajib
  - Code review sebelum deploy
  - Dependency pinning

- [ ] **A09: Logging & Monitoring Failures**
  - Log failed payment attempts
  - Log unauthorized access
  - Alert pada repeated failures

- [ ] **A10: SSRF**
  - Validasi payment gateway URLs
  - Whitelist external services

### Security Test Commands

```bash
# Cek dependencies untuk vulnerabilities
composer audit
npm audit (jika menggunakan Node packages)

# Jalankan security linter
php artisan tinker
# Cek hardcoded secrets

# Test webhook signature validation
php tests/Feature/PaymentWebhookTest.php --filter=rejects_invalid_signature

# Test rate limiting
ab -n 100 -c 10 http://localhost:8000/api/auth/login

# Test CORS headers
curl -H "Origin: https://evil.com" http://localhost:8000/api/orders

# Test authentication
curl -H "Authorization: Bearer invalid_token" http://localhost:8000/api/orders
```

---

## Eksekusi Test

### Sebelum Setiap Sprint

```bash
# 1. Update test data
php artisan migrate:fresh --seed

# 2. Jalankan semua tests
php artisan test --coverage

# 3. Lihat coverage report
open storage/coverage/index.html

# 4. Jalankan security audit
composer audit

# 5. Jalankan mobile tests
cd mobile && flutter test

# 6. Update test documentation
# Update docs/testing/ jika diperlukan
```

### Daily Sanity Check

```bash
# Quick smoke test
php artisan test tests/Feature/AuthTest.php
php artisan test tests/Feature/PaymentWebhookTest.php

# Cek bug baru
gh issue list --repo radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi \
  --state open --label "bug" --limit 10
```

### Sebelum Release

```bash
# 1. Full test suite
php artisan test --coverage --stop-on-failure

# 2. E2E tests
npx playwright test --project=chromium

# 3. Load test (30 sec, 50 users)
jmeter -n -t docs/testing/jmeter-tukangdekat-quick.jmx

# 4. Security scan
composer audit
npm audit (jika ada)

# 5. Mobile build & test
flutter build apk --release
flutter test integration_test/

# 6. Smoke test di staging
bash backend/deploy/smoke-test.sh
```

---

## Integrasi CI/CD

### GitHub Actions Workflow

**File:** `.github/workflows/test.yml`

```yaml
name: Test Suite

on: [push, pull_request]

jobs:
  backend:
    runs-on: ubuntu-latest
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: tukangdekat_test

    steps:
      - uses: actions/checkout@v3
      - uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          extensions: mysql, curl

      - name: Install dependencies
        run: |
          cd backend
          composer install --no-progress

      - name: Jalankan tests
        run: |
          cd backend
          php artisan test --coverage

      - name: Upload coverage
        uses: codecov/codecov-action@v3

  mobile:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.10.0'

      - name: Jalankan tests
        run: |
          cd mobile
          flutter test

  e2e:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install Playwright
        run: npx playwright install

      - name: Jalankan E2E tests
        run: |
          cd backend/e2e
          npm install
          npx playwright test
        env:
          TEST_TOKEN: ${{ secrets.TEST_TOKEN }}
          API_BASE_URL: http://localhost:8000
```

---

## Pelaporan Bug

### Template Bug Report

**Judul:** `[KOMPONEN] Deskripsi singkat`

**Contoh:** `[Payment] Webhook gagal dengan 500 saat signature invalid`

**Deskripsi:**

```
## Langkah Reproduksi

1. Generate QRIS payment
2. Kirim webhook dengan signature invalid
3. Amati response

## Expected Behavior

Mengembalikan 401 Unauthorized dengan pesan error yang jelas

## Actual Behavior

Mengembalikan 500 Internal Server Error

## Environment

- Backend: Laravel 11 (commit abc1234)
- Database: MySQL 8.0
- OS: Ubuntu 22.04

## Logs

```
[2026-06-10 10:30:45] production.ERROR: Call to undefined method... in PaymentWebhookController.php:45
```

## Attachments

- Screenshot error
- curl command untuk reproduksi
```

### Buat Bug Issue

```bash
gh issue create \
  --title "[Payment] Webhook gagal dengan 500 saat signature invalid" \
  --body "$(cat bug-report.md)" \
  --label "bug,priority: high,module: payment"
```

---

## Test Maintenance

### Monthly Tasks

- [ ] Review & update test data (seeders)
- [ ] Hapus test files yang sudah tidak berguna
- [ ] Update dokumentasi test
- [ ] Archive test results lama
- [ ] Analisis coverage gaps
- [ ] Update performance baselines

### Quarterly Tasks

- [ ] Review & upgrade testing frameworks
- [ ] Evaluasi tools testing baru
- [ ] Audit security testing
- [ ] Benchmarking performance testing
- [ ] Training tim tentang test patterns baru

---

## Resources

### Dokumentasi

- [Laravel Testing Docs](https://laravel.com/docs/11.x/testing)
- [Flutter Testing Guide](https://flutter.dev/docs/testing)
- [Playwright Docs](https://playwright.dev)
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/)

### Tools

- **Backend:** PHPUnit, Artisan
- **Mobile:** Flutter Test, Integration Testing
- **E2E:** Playwright, Postman
- **Load:** Apache JMeter
- **Security:** OWASP ZAP, Composer Audit

### CI/CD

- GitHub Actions (free untuk repo public)
- Codecov (coverage tracking)

---

## Kontak & Support

**QA Lead:** aldyrmdny-lab  
**Pertanyaan?** Komentar di GitHub Issues atau DM di Slack.

---

**Terakhir Diperbarui:** Juni 2026  
**Review Berikutnya:** Juli 2026
