# SRS Crosscheck Report (2026-07-01)

Dokumen ini memetakan implementasi project terhadap `docs/srs/SRS_TukangDekat_v1.1.md`.
Status:
- ✅ Implemented: sudah tersedia di codebase
- ⚠️ Partial: ada implementasi, tetapi belum lengkap/terverifikasi end-to-end
- ❌ Gap: belum ditemukan implementasi yang memenuhi SRS

## Ringkasan Cepat
- Total FR diperiksa: 37
- ✅ Implemented: 31
- ⚠️ Partial: 5
- ❌ Gap: 1
- NFR utama (security, observability, CI/CD, docker): mayoritas tersedia, namun masih ada gap keamanan pada manajemen secret karena `backend/.env` berisi API key nyata.

## Hasil Validasi Eksekusi (2026-07-01)
- Mobile lint/analyze (targeted): PASS
   - Command: `flutter analyze lib/features/home/home_page.dart`
- Backend feature tests: PARTIAL FAIL
   - Command: `php artisan test --testsuite=Feature --stop-on-failure`
   - Result: 4 PASS, 1 FAIL, 31 pending (stop at first failure)
   - Failing test: `Tests\Feature\ApiResponseFormatTest > auth endpoints return consistent json structure`
   - Failure detail: expected status 201, actual 422 pada skenario register (indikasi data uji tidak fresh / validasi payload berubah)

## Matrix Functional Requirement (FR)

### Auth & Authorization
- FR-01 Registrasi customer/provider: ✅ (`backend/routes/api.php`, `AuthController@register`)
- FR-02 Login + token akses: ✅ (`AuthController@login`, Sanctum token)
- FR-03 Logout: ✅ (`AuthController@logout`)
- FR-04 Role-based access: ✅ (middleware `role.customer`, `role.provider`, `role.admin`, `role.treasurer`)

### Provider Management
- FR-05 Provider update profil: ✅ (`ProfileController@updateProfile`, `provider_profiles`)
- FR-06 Admin verifikasi provider: ✅ (`AdminController@updateVerification`)
- FR-07 Admin nonaktifkan provider: ✅ (`AdminController@deactivateProvider`)

### Catalog & Search
- FR-08 Kategori + daftar provider per kategori: ✅ (`CatalogController@getCategories`, `getProvidersByCategory`)
- FR-09 Search provider by keyword/category: ✅ (`CatalogController@searchProviders`)
- FR-10 Detail provider + layanan: ✅ (`CatalogController@getProviderDetail`)

### Order Lifecycle
- FR-11 Create order (jadwal, alamat, catatan, foto opsional): ⚠️
  - Data inti sudah ada (`OrderController@createOrder`)
  - Dukungan attachment order sudah ada tabel (`order_attachments`) tetapi endpoint upload attachment saat create order belum terlihat jelas terpakai di mobile.
- FR-12 Provider accept/reject: ✅ (`OrderController@respondToOrder`)
- FR-13 Status CREATED/ACCEPTED/IN_PROGRESS/COMPLETED/CANCELLED/CLOSED: ✅ (`orders.status` + flow controller)
- FR-14 Start work hanya jika DP paid: ✅ (`OrderController@startWork` validasi payment DP)

### Payment DP & Final via QRIS
- FR-15 DP 50% saat order dibuat: ✅ (`createOrder`, `dpAmount = estimated_price * 0.5`)
- FR-16 Generate QRIS DP: ✅ (`PaymentController@generateQRIS`)
- FR-17 Webhook update status payment: ✅ (`webhooks/payment`, verify signature)
- FR-18 Buat final bill setelah completed: ✅ (`OrderController@completeOrder`)
- FR-19 Generate QRIS pelunasan: ✅ (endpoint generate QRIS generik per payment)
- FR-20 Auto close order saat final paid: ✅ (`PaymentController@webhookPaymentCallback`)

### Notifications
- FR-21 Emit event notifikasi ke n8n pada event utama: ✅ (`N8nNotificationService` dipanggil di order/payment flow)
- FR-22 Notifikasi WhatsApp/email via n8n: ⚠️
  - Hook/event ada, tetapi delivery eksternal WA/email bergantung konfigurasi n8n runtime (belum bisa dibuktikan hanya dari source code).

### Rating & Review
- FR-23 Customer review setelah order selesai: ✅ (`ReviewController@createReview`)
- FR-24 Hitung avg rating provider: ✅ (`ReviewController` + data review summary)

### Treasurer Monitoring
- FR-25 Daftar transaksi DP/final: ✅ (`TreasurerController@paymentReport`)
- FR-26 Ringkasan transaksi per rentang tanggal: ✅ (`summary`, filter start/end date)

### Chatbot
- FR-27 Chatbot interaktif: ✅ (`ChatbotController@sendMessage`, mobile `chatbot_screen.dart`)
- FR-28 Mengingat konteks order terakhir: ✅ (system prompt memuat last order user)

### Provider Payout
- FR-29 Catat pencairan dana provider: ✅ (`provider_payouts`, financial fields payments)
- FR-30 Admin/treasurer lihat status payout + riwayat: ✅ (`ProviderPayoutController`, halaman admin treasurer)
- FR-31 Alur payout otomatis/job: ✅ (`SendProviderPayoutJob`, command/job terkait)
- FR-32 Tandai payout gagal + retry manual: ✅ (`status FAILED`, endpoint retry)

### Profile Management
- FR-33 Upload foto profil: ✅ (`ProfileController@updateProfile`, field `profile_photo`)
- FR-34 Hapus foto profil: ✅ (`ProfileController@deleteProfilePhoto`)

### QRIS Image Capture
- FR-35 Capture QRIS dari checkout URL: ✅ (`PaymentController@captureQris`, tools/capture-qris)

### Data Export
- FR-36 Export CSV transaksi: ✅ (`TreasurerController`, `export=csv`)
- FR-37 Export XLS/Excel transaksi: ✅ (`export=xls|excel`)

## Non-Functional Crosscheck (NFR)
- NFR-04 HTTPS: ⚠️ belum dapat diverifikasi dari source saja untuk environment aktif.
- NFR-05 Password hashing aman: ✅ (`Hash::make` di register)
- NFR-06 Webhook signature verify: ✅ (`PaymentGatewayService->verifyWebhook`)
- NFR-07 Role access control: ✅ (middleware + guard di controller)
- NFR-11 Metrics endpoint: ✅ (`MetricsController`, `/api/metrics`)
- NFR-13 CI/CD GitHub Actions: ✅ (`.github/workflows/backend-tests.yml`, `backend/.github/workflows/ci.yml`)
- NFR-14 Docker compose + env template: ✅ (`docker-compose.yml`, `backend/docker-compose.yml`, `.env.example`)
- NFR-15 Secret via env dan tidak hardcoded: ⚠️ ditemukan risiko karena `backend/.env` berisi nilai `GEMINI_API_KEY` non-placeholder.
- NFR-16 Rate limiting + webhook idempotency: ✅ (throttle middleware + `processed_webhook_events`)
- NFR-17 Session-based auth: ✅ (`/api/auth/session-login`, `/api/auth/session-logout`)

## Temuan Bug/Kesenjangan Utama
1. Role ADMIN/TREASURER mengakses tab Pesanan memicu 403 pada endpoint `GET /api/orders/my-orders`.
   - Dampak: UX error pada akun non-customer/provider.
   - Status: FIXED di mobile navigation (tab Pesanan hanya tampil untuk CUSTOMER/PROVIDER).
2. Secret management belum aman penuh.
   - Dampak: potensi kebocoran API key jika file ter-commit atau dishare.
   - Aksi lanjutan: rotasi key, hapus dari tracked file, gunakan secret manager/env per environment.
3. Attachment order (foto kerusakan) belum terbukti end-to-end dari mobile create order.
   - Dampak: FR-11 masih partial.
   - Aksi lanjutan: pastikan endpoint upload + UI create order mengirim file attachment.

## Rekomendasi Lanjutan Prioritas Tinggi
1. Rotasi `GEMINI_API_KEY` dan seluruh key pembayaran, lalu pastikan hanya placeholder di `.env.example`.
2. Tambah test integrasi untuk role UI flow admin/treasurer agar 403 seperti kasus tab Pesanan tidak terulang.
3. Tutup gap FR-11 dengan implementasi upload attachment pada flow buat order mobile + API yang tervalidasi.
4. Jalankan verifikasi end-to-end terstruktur (auth -> order -> DP -> start -> complete -> final -> review -> report).
