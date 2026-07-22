# TukangDekat — Aplikasi Pemesanan Jasa Lokal

Status: Siap Untuk Uji Coba End-to-End dan Deployment
(https://github.com/radenelsa7-bot/AplikasiTukangDekat.io)

---

## 📋 Table of Contents

- [Profil & Pengenalan Aplikasi](#-profil--pengenalan-aplikasi)
- [Tim Developer](#-tim-developer)
- [Status Proyek](#-status-proyek)
- [Fitur & Fungsi](#-fitur--fungsi)
- [Tampilan Antarmuka](#-tampilan-antarmuka)
- [Infrastruktur & Arsitektur](#-infrastruktur--arsitektur)
- [Teknis Instalasi](#-teknis-instalasi)
- [Cara Penggunaan](#-cara-penggunaan)
- [Akun Demo](#-akun-demo)
- [API Documentation](#-api-documentation)
- [Troubleshooting](#-troubleshooting)
- [Roadmap Pengembangan](#-roadmap-pengembangan)

---

## 🎯 Profil & Pengenalan Aplikasi

**TukangDekat** adalah platform digital yang menghubungkan warga atau pelanggan dengan penyedia jasa lokal (tukang atau teknisi). Aplikasi ini dirancang untuk memudahkan proses pemesanan dan pembayaran jasa secara online dengan fitur-fitur modern.

### Latar Belakang

Sistem ini menggantikan proses pemesanan jasa yang umumnya dilakukan secara manual (melalui rekomendasi tetangga atau WhatsApp) menjadi sistem terintegrasi yang mendukung:

- Pencarian penyedia jasa terdekat
- Pemesanan layanan secara digital
- Pembayaran digital dengan QRIS
- Manajemen order secara real-time
- Rating dan ulasan layanan

### Kategori Jasa yang Tersedia

| No | Kategori |
|----|----------|
| 1 | Listrik |
| 2 | Plumbing |
| 3 | AC |
| 4 | Bangunan Ringan |
| 5 | Servis Elektronik Rumah |

### Target Pengguna

| Role | Deskripsi |
|------|-----------|
| **Customer** (warga/pelanggan) | Memesan jasa, melakukan pembayaran, memberi rating |
| **Provider** (tukang/teknisi) | Menerima order, mengerjakan, memperbarui status order |
| **Admin + Treasurer** (pengurus + bendahara) | Mengelola kategori, memverifikasi provider, memonitor aktivitas, Memonitor transaksi pembayaran, rekap pembayaran|

---

## 👥 Tim Developer

| Peran | Nama | NIM |
|-------|------|-----|
| **Project Manager** | R. Elsa Balqis Khoerunnisa S | 20241320062 |
| **Backend Developer** | Muhammad Fajar Nurjaman | 20241320059 |
| **Backend Developer** | Fatin Asyifa Nurrizky JenPutri | 20241320073 |
| **Backend Developer** | Nabilah Asana Alecia | 20241320076 |
| **Frontend Developer** | Tetep Safarudin | 20241320065 |
| **Frontend Developer** | Fazna Laisal Ramadhan | 20241320081 |
| **Frontend Developer** | Nabil Ramadhan | 20241320068 |
| **QA Testing** | Aldy Ramadany | 20241320050 |

---

## 📊 Status Proyek

**Status:** 🚀 Siap untuk Uji Coba End-to-End & Deployment

### Milestone Terbaru yang Tercapai

- ✅ **Sinkronisasi Backend-Frontend**: Alur pembuatan pesanan di mobile kini sinkron dengan backend, termasuk pengiriman data wilayah (`kota_id`, `kecamatan_id`) dan upload foto kerusakan via file
- ✅ **Alur Pembayaran Lengkap**: Sistem pembayaran bertahap (DP & Lunas) dengan persetujuan harga akhir oleh pelanggan telah diimplementasikan dan divalidasi end-to-end
- ✅ **Validasi Backend Solid**: Seluruh test suite backend (14 tes) berhasil dijalankan
- ✅ **Perbaikan UI Kritis**: Tombol persetujuan harga akhir muncul dengan benar, dan masalah akses role-based pada tab pesanan telah diperbaiki

---

## 💡 Fitur & Fungsi

### 4.1 Authentication & Authorization
- Registrasi pengguna dengan role-based (Customer, Provider, Admin, Treasurer)
- Login menggunakan email dan password
- Session-based authentication dengan Laravel Sanctum
- Role-based access control (RBAC)

### 4.2 Provider Management
- Registrasi penyedia jasa dengan verifikasi admin
- Profil provider dengan business name dan coverage area
- Pengelolaan layanan oleh provider sendiri
- Status verifikasi provider (pending, approved, rejected)
- **Mailtrap Notification**: Notifikasi email otomatis saat akun provider diverifikasi admin

### 4.3 Service Catalog & Search
- Daftar kategori layanan
- Pencarian provider berdasarkan kategori
- Filter berdasarkan lokasi (kota/kecamatan)
- Detail provider dengan layanan dan harga

### 4.4 Order Lifecycle
- Pembuatan order dengan upload foto kerusakan
- Status order: PENDING → ACCEPTED → IN_PROGRESS → COMPLETED → CLOSED
- Respon order oleh provider
- Mulai dan selesaikan pekerjaan oleh provider
- Update harga final oleh provider sebelum pelunasan

### 4.5 Payment (DP & Final) via QRIS - Midtrans
- Pembayaran DP 50% menggunakan QRIS
- Pembayaran pelunasan 50% setelah persetujuan harga final
- **Integrasi Midtrans** sebagai Payment Gateway utama
- Webhook untuk notifikasi pembayaran otomatis
- Validasi tanda tangan webhook untuk keamanan

### 4.6 Notifications
- **Mailtrap** untuk notifikasi pemberitahuan akun yang sudah diverifikasi
- Notifikasi pada setiap perubahan status order
- Notifikasi pembayaran kepada customer dan provider

### 4.7 Rating & Review
- Customer dapat memberikan rating dan ulasan kepada provider
- Review terkait layanan yang diberikan

### 4.8 Treasurer Monitoring
- Dashboard monitoring transaksi pembayaran
- Laporan pembayaran harian/bulanan
- Rekapitulasi fee platform dan payout provider

### 4.9 Chatbot - Gemini AI
- **Chatbot integrasi Gemini API** untuk bantuan pengguna
- Komunikasi natural language processing
- Support bahasa Indonesia

---

## 🖼️ Tampilan Antarmuka

### Mobile App (Flutter)

Berikut adalah beberapa layar utama yang tersedia di aplikasi mobile:

| Layar | File | Deskripsi |
|-------|------|-----------|
| Landing Page | `mobile/lib/landing/landing_screen.dart` | Halaman pembuka aplikasi |
| Login | `mobile/lib/features/auth/login_page.dart` | Autentikasi pengguna |
| Register | `mobile/lib/features/auth/register_page.dart` | Registrasi akun baru |
| Catalog/Home | `mobile/lib/features/home/catalog_page.dart` | Daftar layanan/provider |
| Create Order | `mobile/lib/features/home/create_order_page.dart` | Form pemesanan layanan |
| My Orders | `mobile/lib/features/home/my_orders_page.dart` | Daftar pesanan pengguna |
| Order Detail | `mobile/lib/features/home/order_detail_page.dart` | Detail dan tracking order |
| Provider Dashboard | `mobile/lib/features/home/provider_dashboard_page.dart` | Dashboard untuk provider |
| Provider Services | `mobile/lib/features/home/provider_services_page.dart` | Kelola layanan provider |
| Admin Dashboard | `mobile/lib/features/admin/admin_dashboard_page.dart` | Dashboard admin |
| Admin Categories | `mobile/lib/features/admin/admin_categories_page.dart` | Kelola kategori |
| Admin Transactions | `mobile/lib/features/admin/admin_transactions_page.dart` | Kelola transaksi |
| Admin Reports | `mobile/lib/features/admin/admin_reports_page.dart` | Laporan keuangan |
| Chatbot | `mobile/lib/features/chat/chatbot_screen.dart` | Asisten virtual berbasis Gemini AI |
| Location Picker | `mobile/lib/features/maps/osm_location_picker_screen.dart` | Pemilihan lokasi di peta menggunakan OpenStreetMap |

### Komponen UI Utama

- **Bottom Navigation**: Navigasi utama untuk Customer & Provider
- **Gradient App Bar**: Desain modern dengan efek gradient
- **Live Tracking Map**: Widget peta untuk tracking lokasi (Menggunakan **Flutter Map + OpenStreetMap**)
- **Order Status Timeline**: Visualisasi status order secara real-time

---

## ⚙️ Infrastruktur & Arsitektur

### Arsitektur Sistem

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Mobile App    │────▶│   Backend API   │────▶│    Database     │
│   (Flutter)     │     │    (Laravel)    │     │    (MySQL)      │
└─────────────────┘     └─────────────────┘     └─────────────────┘
        │                        │                        │
        │                        ▼                        │
        │               ┌─────────────────┐               │
        │               │  Mailtrap SMTP  │               │
        │               │  (Email Service)│               │
        │               └─────────────────┘               │
        │                        │                        │
        └────────────────────────┼────────────────────────┘
                                 │
                                 ▼
                    ┌─────────────────────────┐
                    │   Payment Gateway         │
                    │   (Midtrans QRIS)         │
                    └─────────────────────────┘
```

### Teknologi yang Digunakan

#### Backend
| Teknologi | Versi | Keterangan |
|-----------|-------|------------|
| PHP | ^8.2 | Runtime environment |
| Laravel | ^12.0 | Framework utama |
| Laravel Sanctum | ^4.0 | Authentication SPA |
| MySQL | 8.0 | Database |
| Docker | latest | Containerization |
| Mailtrap | - | Email testing service |

#### Mobile
| Teknologi | Versi | Keterangan |
|-----------|-------|------------|
| Flutter | ^3.11 | Framework mobile |
| Dart | SDK | Bahasa pemrograman |
| Riverpod | ^2.6.1 | State management |
| Dio | ^5.8.0 | HTTP client |
| Flutter Map | ^8.3.1 | Map widget untuk OpenStreetMap |
| Latlong2 | ^0.10.1 | Geospatial coordinates |

#### Services Eksternal
| Service | Keterangan |
|---------|------------|
| Midtrans | Payment gateway untuk QRIS |
| Mailtrap | Email notification service |
| Gemini API | Chatbot AI service |

### Struktur Folder

```
PM_UAS_rekayasa_Sistem_Informasi/
├── backend/                      # Laravel API
│   ├── app/
│   │   ├── Http/Controllers/Api/ # API Controllers
│   │   ├── Models/               # Eloquent Models
│   │   ├── Services/             # Business logic services
│   │   ├── Mail/                 # Email templates
│   │   └── ...
│   ├── database/
│   │   ├── migrations/         # Database migrations
│   │   ├── seeders/            # Database seeders
│   │   └── ...
│   ├── routes/
│   │   └── api.php             # API routes
│   ├── tests/
│   │   └── Feature/            # Feature tests
│   ├── Dockerfile
│   └── composer.json
├── mobile/                       # Flutter application
│   ├── lib/
│   │   ├── features/           # Feature modules
│   │   │   ├── maps/           # Map features (OpenStreetMap)
│   │   │   ├── chat/           # Chatbot features
│   │   │   └── ...
│   │   ├── core/               # Shared components
│   │   ├── app/                # App configuration
│   │   └── main.dart
│   ├── pubspec.yaml
│   └── analysis_options.yaml
├── docs/                         # Dokumentasi
│   ├── srs/                      # Software Requirements Specification
│   ├── api/                        # API documentation
│   ├── testing/                    # Test documentation
│   └── view-website/               # Website screenshots
├── website/                      # Landing page statis
├── scripts/                      # Utility scripts
├── postman/                      # Postman collections
├── docker-compose.yml
└── README.md
```

### Docker Infrastructure

```yaml
# docker-compose.yml Services
services:
  backend:      # Laravel API (port 8000)
    image: laravel-backend
    ports: ["8000:8000"]
    
  db:           # MySQL Database (port 3306)
    image: mysql:8.0
    ports: ["3306:3306"]
```

---

## 🔧 Teknis Instalasi

### Prasyarat Sistem

| Komponen | Versi Minimum |
|----------|---------------|
| Docker | 24.0+ |
| Docker Compose | 2.0+ |
| PHP | 8.2+ (untuk development non-docker) |
| Flutter SDK | 3.11+ |
| Android SDK / Xcode | Untuk mobile development |

### Metode 1: Instalasi dengan Docker (Direkomendasikan)

#### Langkah 1: Clone Repository
```bash
git clone https://github.com/radenelsa7-bot/AplikasiTukangDekat.io.git
cd AplikasiTukangDekat.io
```

#### Langkah 2: Jalankan Docker Compose
```bash
docker compose up -d --build
```

#### Langkah 3: Instalasi Dependencies & Migrasi Database
```bash
# Masuk ke container backend
docker compose exec backend composer install

# Generate application key
docker compose exec backend php artisan key:generate

# Jalankan migrasi dan seeder
docker compose exec backend php artisan migrate --seed
```

#### Langkah 4: Verifikasi Instalasi
```bash
# Cek health endpoint
curl http://localhost:8000/api/health

# Atau buka di browser
# http://localhost:8000/api/health
```

### Metode 2: Instalasi Manual (Development)

#### Backend (Laravel API)
```bash
# Masuk ke folder backend
cd backend

# Salin file environment
copy .env.example .env

# Install dependencies
composer install

# Generate application key
php artisan key:generate

# Edit .env sesuai konfigurasi database Anda
# DB_HOST=127.0.0.1
# DB_DATABASE=db_tukangdekat
# DB_USERNAME=root
# DB_PASSWORD=rahasia

# Jalankan migrasi
php artisan migrate --seed

# Jalankan server
php artisan serve
```

#### Mobile (Flutter)
```bash
# Masuk ke folder mobile
cd mobile

# Install dependencies
flutter pub get

# Analisis kode
flutter analyze

# Jalankan di device
flutter run -d <device>

# Build APK (Android)
flutter build apk --release

# Build iOS
flutter build ios --release
```

### Environment Variables

#### Backend (.env)

| Variable | Deskripsi | Contoh Nilai |
|----------|-----------|--------------|
| `APP_NAME` | Nama aplikasi | TukangDekat |
| `APP_ENV` | Environment | local/staging/production |
| `APP_KEY` | Encryption key | base64:xxx |
| `APP_DEBUG` | Debug mode | true/false |
| `APP_URL` | URL aplikasi | http://localhost |
| `DB_CONNECTION` | Database driver | mysql |
| `DB_HOST` | Database host | db (Docker) / 127.0.0.1 |
| `DB_PORT` | Database port | 3306 |
| `DB_DATABASE` | Database name | db_tukangdekat |
| `DB_USERNAME` | Database user | root |
| `DB_PASSWORD` | Database password | rahasia |
| `PAYMENT_GATEWAY_DRIVER` | Payment driver | midtrans |
| `MIDTRANS_SERVER_KEY` | Midtrans server key | Mid-server-xxx |
| `MIDTRANS_CLIENT_KEY` | Midtrans client key | Mid-client-xxx |
| `MIDTRANS_IS_PRODUCTION` | Production mode | false |
| `MAIL_MAILER` | Email driver | smtp |
| `MAIL_HOST` | Mailtrap host | sandbox.smtp.mailtrap.io |
| `MAIL_PORT` | Mailtrap port | 2525 |
| `MAIL_USERNAME` | Mailtrap username | xxx |
| `MAIL_PASSWORD` | Mailtrap password | xxx |
| `GEMINI_API_KEY` | Gemini API Key untuk chatbot | AIxxx |

#### Mobile (.env)

| Variable | Deskripsi | Contoh Nilai |
|----------|-----------|--------------|
| `API_BASE_URL` | URL backend API | http://192.168.1.18:8000 |
| `APP_ENV` | Environment | development |

---

## 📱 Cara Penggunaan

### Untuk Customer (Warga/Pelanggan)

1. **Registrasi Akun**
   - Buka aplikasi mobile
   - Pilih "Register"
   - Isi nama, email, password, dan nomor telepon
   - Pilih role sebagai "Customer"

2. **Login**
   - Masukkan email dan password yang telah didaftarkan
   - Sistem akan mengarahkan ke halaman utama

3. **Cari Layanan**
   - Pilih kategori layanan yang dibutuhkan
   - Lihat daftar provider yang tersedia
   - Filter berdasarkan lokasi dan harga

4. **Buat Pesanan**
   - Klik "Pesan Layanan" pada provider yang dipilih
   - Upload foto kerusakan (opsional)
   - Isi detail kebutuhan
   - Submit order

5. **Lakukan Pembayaran DP**
   - Tunggu provider menerima order
   - Klik "Bayar DP" pada order
   - Scan QRIS menggunakan aplikasi e-wallet
   - Upload bukti pembayaran

6. **Terima Layanan**
   - Provider akan memulai pekerjaan
   - Pantau status order secara real-time

7. **Pelunasan & Review**
   - Setelah pekerjaan selesai, terima pesanan
   - Provider mengajukan harga final (jika ada tambahan biaya)
   - Setujui harga final
   - Lakukan pembayaran pelunasan via QRIS (Midtrans)
   - Berikan rating dan ulasan

### Untuk Provider (Tukang/Teknisi)

1. **Registrasi Akun**
   - Buka aplikasi mobile
   - Pilih "Register" sebagai "Provider"
   - Isi nama, email, password, business name
   - Pilih kategori layanan dan wilayah kerja

2. **Verifikasi Akun**
   - Tunggu admin memverifikasi akun
   - **Cek email (Mailtrap)** untuk notifikasi verifikasi dari admin

3. **Kelola Layanan**
   - Tambah layanan yang disediakan
   - Atur harga dan deskripsi layanan

4. **Terima & Kerjakan Pesanan**
   - Lihat pesanan masuk di dashboard
   - Terima pesanan yang ingin dikerjakan
   - Klik "Mulai Pekerjaan" saat mulai mengerjakan
   - Upload foto selesai pekerjaan

5. **Pengelolaan Keuangan**
   - Lihat riwayat pembayaran
   - Pantau fee yang diterima

### Untuk Admin + Treasurer

1. **Login sebagai Admin**
   - Gunakan akun admin@example.com / password

2. **Verifikasi Provider**
   - Buka menu "Providers" → "Pending"
   - Review data provider
   - Approve atau Reject registrasi
   - Sistem akan mengirim notifikasi via **Mailtrap** ke provider yang diverifikasi

3. **Kelola Kategori**
   - Tambah/edit/hapus kategori layanan
   - Atur deskripsi dan ikon kategori

4. **Monitor Transaksi**
   - Lihat semua pesanan
   - Pantau status pembayaran
   - Generate laporan keuangan

5. **Monitor Pembayaran**
   - Lihat semua transaksi pembayaran
   - Generate laporan keuangan
   - Rekapitulasi fee platform

---

## 👤 Akun Demo

Setelah menjalankan seeder, berikut beberapa akun test yang tersedia:

| Role | Email | Password | Deskripsi |
|------|-------|----------|-----------|
| Admin | admin@example.com | password | Mengelola sistem |
| Customer | fajar@example.com | password123 | Pengguna layanan |
| Customer | nabila@example.com | password123 | Pengguna layanan |
| Customer | aldo@example.com | password123 | Pengguna layanan |
| Provider | andi.listrik@example.com | password123 | Teknisi Listrik |
| Provider | budi.plumbing@example.com | password123 | Teknisi Plumbing |
| Provider | citra.ac@example.com | password123 | Servis AC |

> **Catatan:** Akun provider awalnya memiliki status `pending` dan perlu diverifikasi oleh admin. Notifikasi verifikasi akan dikirim via Mailtrap.

---

## 📡 API Documentation

### Base URL
```
http://localhost:8000/api
```

### Public Endpoints

| Method | Endpoint | Deskripsi |
|--------|----------|-----------|
| POST | `/auth/register` | Registrasi pengguna |
| POST | `/auth/login` | Login pengguna |
| POST | `/auth/session-login` | Session login (SPA) |
| POST | `/auth/session-logout` | Session logout |
| GET | `/catalog/categories` | Daftar kategori |
| GET | `/catalog/wilayah/kota` | Daftar kota |
| GET | `/catalog/wilayah/kota/{id}/kecamatan` | Daftar kecamatan |
| GET | `/catalog/providers` | Daftar provider |
| GET | `/catalog/providers/{id}` | Detail provider |
| GET | `/catalog/providers/{id}/reviews` | Review provider |
| GET | `/cities` | Daftar kota (dropdown) |
| GET | `/districts` | Daftar kecamatan (dropdown) |

### Protected Endpoints (Requires Authentication)

#### Authentication
| Method | Endpoint | Role | Deskripsi |
|--------|----------|------|-----------|
| POST | `/auth/logout` | Semua | Logout |
| POST | `/profile/update` | Semua | Update profil |
| DELETE | `/profile/photo` | Semua | Hapus foto profil |

#### Orders
| Method | Endpoint | Role | Deskripsi |
|--------|----------|------|-----------|
| POST | `/orders/attachments` | Customer | Upload foto kerusakan |
| POST | `/orders` | Customer | Buat order baru |
| GET | `/orders/my-orders` | Customer | Daftar order saya |
| GET | `/orders/{id}` | Customer/Provider | Detail order |
| POST | `/orders/{id}/respond` | Provider | Terima/tolak order |
| POST | `/orders/{id}/start-work` | Provider | Mulai pekerjaan |
| POST | `/orders/{id}/complete` | Provider | Selesaikan pekerjaan |
| POST | `/orders/{id}/final-price/submit` | Provider | Ajukan harga final |
| POST | `/orders/{id}/final-price/approve` | Customer | Setujui harga final |
| POST | `/orders/{id}/cancel` | Customer | Batalkan order |
| POST | `/orders/{id}/review` | Customer | Berikan review |

#### Payments
| Method | Endpoint | Role | Deskripsi |
|--------|----------|------|-----------|
| GET | `/payments/order/{orderId}` | Customer/Provider | Daftar pembayaran |
| GET | `/payments/{id}` | Customer/Provider | Detail pembayaran |
| POST | `/payments/{id}/generate-qris` | Customer | Generate QRIS (Midtrans) |
| POST | `/payments/{id}/confirm` | Customer | Konfirmasi pembayaran |
| POST | `/payments/{id}/capture-qris` | Customer | Capture QRIS image |

#### Chatbot
| Method | Endpoint | Role | Deskripsi |
|--------|----------|------|-----------|
| POST | `/chatbot/send` | Semua | Kirim pesan ke chatbot (Gemini AI) |

#### Admin
| Method | Endpoint | Role | Deskripsi |
|--------|----------|------|-----------|
| GET | `/admin/dashboard` | Admin | Dashboard admin |
| GET | `/admin/providers` | Admin | Daftar provider |
| PATCH | `/admin/providers/{id}/verification` | Admin | Verifikasi provider |
| POST | `/admin/categories` | Admin | Tambah kategori |
| GET | `/admin/payments/report` | Admin/Treasurer | Laporan pembayaran |
| GET | `/admin/reports/summary` | Admin/Treasurer | Ringkasan laporan |

#### Provider
| Method | Endpoint | Role | Deskripsi |
|--------|----------|------|-----------|
| GET | `/provider/dashboard` | Provider | Dashboard provider |
| GET | `/provider/profile` | Provider | Profil provider |
| PUT | `/provider/profile` | Provider | Update profil |
| GET | `/provider/coverage` | Provider | Coverage area |
| POST | `/provider/services` | Provider | Tambah layanan |
| PATCH | `/provider/services/{id}` | Provider | Update layanan |

### Webhooks

| Endpoint | Deskripsi |
|----------|-----------|
| POST `/webhooks/payment` | Webhook untuk notifikasi pembayaran (Midtrans) |
| GET `/health` | Health check endpoint |
| GET `/metrics` | Metrics untuk monitoring |

---

## 🛠️ Troubleshooting

### Masalah Umum

#### 1. Error Koneksi Database
```bash
# Pastikan .env menggunakan host database yang benar untuk Docker
DB_HOST=db

# Cek log container
docker compose logs backend
docker compose logs db
```

#### 2. Masalah Login/CSRF/Sanctum
```bash
# Pastikan .env memiliki konfigurasi berikut:
SANCTUM_STATEFUL_DOMAINS=localhost,127.0.0.1
SESSION_DOMAIN=localhost
```

#### 3. Masalah Flutter Analyze
```bash
# Aktifkan Developer Mode pada Windows
# Windows Settings → Update & Security → For Developers → Enable Developer Mode
```

#### 4. Masalah Permission di Docker
```bash
# Jika ada error permission, jalankan:
docker compose exec backend chmod -R 775 storage bootstrap/cache
```

#### 5. Masalah Network pada Mobile
```bash
# Pastikan API_BASE_URL di mobile/.env sesuai IP server
# Untuk emulator Android, gunakan 10.0.2.2
# Untuk device fisik, gunakan IP komputer Anda
```

#### 6. Masalah Mailtrap Email
```bash
# Pastikan konfigurasi Mailtrap di .env benar:
MAIL_MAILER=smtp
MAIL_HOST=sandbox.smtp.mailtrap.io
MAIL_PORT=2525
MAIL_USERNAME=your_mailtrap_username
MAIL_PASSWORD=your_mailtrap_password
```

#### 7. Masalah Gemini API Chatbot
```bash
# Pastikan GEMINI_API_KEY sudah diset di .env
# API Key dapat didapatkan dari https://ai.google.dev/
GEMINI_API_KEY=your_gemini_api_key
```

### Perintah Bermanfaat

```bash
# Restart semua service
docker compose restart

# Hentikan semua service
docker compose down

# Hapus data database
docker compose down -v

# Lihat log real-time
docker compose logs -f backend

# Masuk ke container backend
docker compose exec backend sh

# Jalankan test backend
docker compose exec backend php artisan test

# Flush cache
docker compose exec backend php artisan cache:clear
docker compose exec backend php artisan config:clear
```

---

## 🚀 Roadmap Pengembangan

### Fase Saat Ini (v1.0)
- [x] Autentikasi role-based
- [x] Catalog layanan & pencarian provider
- [x] Order lifecycle lengkap
- [x] Pembayaran DP & pelunasan via QRIS (Midtrans)
- [x] Webhook payment gateway
- [x] Rating & review
- [x] Admin dashboard
- [x] Treasurer monitoring
- [x] Chatbot integrasi Gemini AI
- [x] Notifikasi email via Mailtrap
- [x] Maps dengan OpenStreetMap

### Fase Selanjutnya (v1.1+)
- [ ] Pengujian Manual E2E pada aplikasi mobile
- [ ] Hardening keamanan (secret management)
- [ ] Deployment ke staging dan produksi
- [ ] Implementasi push notification
- [ ] Fitur live chat real-time
- [ ] Multi-language support
- [ ] PWA support untuk web

---

## 📄 Lisensi

Proyek ini dikembangkan untuk keperluan akademik (Ujian Akhir Semester) Program Studi Sistem Informasi, Universitas Kebangsaan Republik Indonesia.

---

## 🤝 Kontribusi

Untuk berkontribusi pada proyek ini:

1. Fork repository
2. Buat feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit perubahan (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

---

**Versi dokumentasi:** 1.1.0