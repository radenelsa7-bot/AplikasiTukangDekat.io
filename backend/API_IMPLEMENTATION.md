# API Backend - TukangDekat
## Pengaturan & Menjalankan

### Prasyarat
- PHP 8.1+
- MySQL 8.0+
- Composer
- Laravel 11

### Instalasi & Pengaturan
```bash
# 1. Instal dependensi
composer install

# 2. Konfigurasi .env
cp .env.example .env
# Perbarui variabel DB_*:
# DB_DATABASE=db_tukangdekat
# DB_USERNAME=root
# DB_PASSWORD=

# 3. Buat kunci aplikasi
php artisan key:generate

# 4. Jalankan migrasi & seeding
php artisan migrate:fresh --seed

# 5. Mulai server
php artisan serve --host=0.0.0.0 --port=8000
```

## Endpoint API

### 1. Autentikasi (Publik)
```
POST   /api/auth/register     - Daftarkan pengguna baru (CUSTOMER/PROVIDER)
POST   /api/auth/login        - Login & dapatkan token
POST   /api/auth/logout       - Logout (memerlukan token)
```

### 2. Katalog (Publik)
```
GET    /api/catalog/categories                    - Dapatkan semua kategori
GET    /api/catalog/categories/{categoryId}/providers  - Dapatkan penyedia berdasarkan kategori
GET    /api/catalog/providers/{providerId}       - Dapatkan detail penyedia
GET    /api/catalog/providers/search?q=...       - Cari penyedia
```

### 3. Pesanan (Dilindungi - auth:sanctum)
```
POST   /api/orders                      - Buat pesanan (CUSTOMER saja)
GET    /api/orders/my-orders            - Dapatkan pesanan saya
GET    /api/orders/{orderId}            - Dapatkan detail pesanan
POST   /api/orders/{orderId}/respond    - Penyedia terima/tolak pesanan
POST   /api/orders/{orderId}/start-work - Penyedia mulai bekerja
POST   /api/orders/{orderId}/complete   - Penyedia selesaikan pesanan
```

### 4. Pembayaran (Dilindungi)
```
GET    /api/payments/order/{orderId}         - Dapatkan pembayaran untuk pesanan
GET    /api/payments/{paymentId}             - Dapatkan status pembayaran
POST   /api/payments/{paymentId}/generate-qris  - Buat QRIS
POST   /api/webhooks/payment                 - Callback gateway pembayaran (webhook)
```

### 5. Ulasan (Dilindungi)
```
POST   /api/reviews/order/{orderId}      - Buat ulasan (CUSTOMER saja)
GET    /api/reviews/provider/{providerId} - Dapatkan ulasan penyedia
GET    /api/reviews/order/{orderId}       - Dapatkan ulasan pesanan
```

## Contoh Permintaan

### Daftar
```bash
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Fajar",
    "email": "fajar@mail.com",
    "phone": "08xxxx",
    "password": "secret123",
    "role": "CUSTOMER"
  }'
```

### Login
```bash
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "fajar@mail.com",
    "password": "secret123"
  }'
```

### Buat Pesanan (dengan token)
```bash
curl -X POST http://localhost:8000/api/orders \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer TOKEN_HERE" \
  -d '{
    "provider_id": 1,
    "category_id": 1,
    "schedule_at": "2026-05-15 14:00:00",
    "address": "Jl. Raya No. 123",
    "notes": "Ada kerusakan di saklar",
    "estimated_price": 300000
  }'
```

## Akun Pengujian

**Pelanggan:**
- Email: fajar@example.com
- Password: password123

**Penyedia:**
- Email: andi.listrik@example.com (Listrik)
- Email: budi.plumbing@example.com (Plumbing)
- Email: citra.ac@example.com (AC)
- Password: password123 (semua)

## Skema Basis Data

### Tabel yang Dibuat
- users
- provider_profiles
- service_categories
- provider_services
- orders
- order_attachments
- payments
- reviews
- notification_logs

## Arsitektur

- **Controller**: Menangani permintaan HTTP & validasi
- **Models**: Entitas basis data dengan hubungan
- **Routes**: Endpoint API RESTful
- **Middleware**: Autentikasi (Sanctum)

## Fitur Utama yang Diimplementasikan

✅ Pendaftaran Pengguna & Login (token Sanctum)
✅ Kontrol akses berbasis peran (CUSTOMER, PROVIDER, ADMIN, TREASURER)
✅ Katalog Layanan & Pencarian
✅ Siklus Hidup Pesanan (CREATED → ACCEPTED → IN_PROGRESS → COMPLETED → CLOSED)
✅ Manajemen Pembayaran (DP 50% + penyelesaian akhir)
✅ Sistem Ulasan & Rating
✅ Pencatatan Notifikasi
✅ Penanganan kesalahan & validasi

## Langkah Berikutnya

1. Implementasikan panel Manajemen Penyedia (admin)
2. Integrasikan gateway pembayaran (Midtrans/Xendit)
3. Atur alur kerja n8n untuk notifikasi
4. Tambahkan unggah file untuk lampiran pesanan
5. Implementasikan dasbor pelaporan Bendahara
6. Tambahkan riwayat pesanan & filter
7. Atur docker compose untuk penerapan
