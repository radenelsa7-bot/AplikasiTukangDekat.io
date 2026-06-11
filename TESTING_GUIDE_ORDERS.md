<!-- markdownlint-disable -->

# Panduan Pengujian: Fitur Pesanan (Diperbaiki)

## Status
✅ **DIPERBAIKI**: Masalah tampilan UI pesanan diselesaikan
✅ **Backend**: Semua 27 endpoint API terverifikasi berfungsi
✅ **Frontend**: Logika refresh Riverpod diimplementasikan
✅ **Kompilasi**: Tidak ada kesalahan, peringatan ditekan
✅ **Pembayaran**: Alur QRIS siap gateway dengan verifikasi tanda tangan webhook dan fallback simulasi

## Yang Diperbaiki

### Masalah
Pesanan berhasil dibuat di backend tetapi tidak muncul di tab "Pesanan" UI Flutter.

### Penyebab Akar
`CreateOrderController` dan `OrderActionController` tidak menyegarkan `myOrdersProvider` setelah API berhasil, menyebabkan UI menampilkan data stale.

### Solusi
Menambahkan `_ref.refresh(myOrdersProvider)` ke 4 metode kritis:
1. `createOrder()` - Setelah pesanan dibuat
2. `respondToOrder()` - Setelah penyedia merespons pesanan
3. `startWork()` - Setelah pekerjaan dimulai
4. `completeOrder()` - Setelah pekerjaan selesai

**File Dimodifikasi**: [lib/features/home/order_providers.dart](lib/features/home/order_providers.dart)

## Langkah-langkah Pengujian

### Pengujian 1: Buat Pesanan sebagai Pelanggan (Fajar)
1. **Login**: fajar@example.com / password123
2. **Jelajahi**: Pergi ke Beranda → Pilih Tukang Listrik Andi
3. **Buat Pesanan**: Isi formulir:
   - Layanan: Tukang Listrik
   - Tanggal: 2026-05-20
   - Jam: 14:00
   - Alamat: Test alamat Fajar
   - Catatan: Test order
4. **Verifikasi**: 
   - ✅ Pesan sukses menampilkan "Order berhasil dibuat!"
   - ✅ Beralih ke tab Pesanan
   - ✅ **PESANAN BARU MUNCUL LANGSUNG** (tidak perlu refresh manual)

### Pengujian 2: Buat Pesanan sebagai Pelanggan (Nabila)
1. **Logout**: Akun Fajar
2. **Login**: nabila@example.com / password123
3. **Jelajahi**: Beranda → Pilih penyedia apa pun
4. **Buat Pesanan**: Formulir serupa
5. **Verifikasi**:
   - ✅ Pesanan muncul di tab Pesanan segera
   - ✅ Hanya menampilkan pesanan Nabila (bukan Fajar)

### Pengujian 3: Tindakan Penyedia (Andi - Penyedia)
1. **Login**: andi.listrik@example.com / password123
2. **Periksa Tab Pesanan**: Seharusnya melihat pesanan dari pelanggan
3. **Terima Pesanan**: Ketuk pesanan → Tombol Terima
4. **Verifikasi**:
   - ✅ Status pesanan berubah menjadi ACCEPTED
   - ✅ UI menyegarkan segera
5. **Mulai Pekerjaan**: Setelah diterima, ketuk → Mulai Pekerjaan
6. **Verifikasi**:
   - ✅ Pembayaran DP harus sudah PAID
   - ✅ Status berubah menjadi IN_PROGRESS hanya setelah pembayaran dikonfirmasi
   - ✅ UI menyegarkan segera
7. **Selesaikan Pekerjaan**: Setelah dimulai, ketuk → Selesaikan Pekerjaan
8. **Verifikasi**:
   - ✅ Status berubah menjadi COMPLETED
   - ✅ Tab Pesanan diperbarui segera

### Pengujian 4: Isolasi Multi-Pengguna
1. **Login sebagai Fajar**: Verifikasi hanya 2 pesanan Fajar yang terlihat
2. **Logout**
3. **Login sebagai Nabila**: Verifikasi hanya 1 pesanan Nabila yang terlihat
4. **Logout**
5. **Login sebagai Andi**: Verifikasi pesanan masuk dari pelanggan terlihat
6. **Diharapkan**:
   - ✅ Tidak ada kebocoran data lintas pengguna
   - ✅ Setiap pengguna hanya melihat pesanan yang relevan

### Pengujian 5: Persistansi Jangka Panjang
1. **Buat Pesanan**: Sebagai Fajar
2. **Tutup Aplikasi**: Restart lengkap
3. **Buka Kembali**: Aplikasi harus dimuat
4. **Verifikasi**:
   - ✅ Tab Pesanan menampilkan pesanan yang dibuat
   - ✅ Token disimpan di FlutterSecureStorage
   - ✅ Data pesanan disimpan di backend

## Verifikasi Backend (Pengujian Curl)

### Pengujian Pesanan Pelanggan (Fajar)
```bash
# Login
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"fajar@example.com","password":"password123"}'

# Respons: token="15|AcSbpUzECvIbsKUeYGQEaZotbNb7sELyYA9jrRSAbc0fd674"

# Dapatkan pesanan
curl -X GET http://localhost:8000/api/orders/my-orders \
  -H "Authorization: Bearer 15|AcSbpUzECvIbsKUeYGQEaZotbNb7sELyYA9jrRSAbc0fd674"

# Diharapkan: Array dengan 2 pesanan (id: 1, 2)
```

### Pengujian Pesanan Penyedia (Andi)
```bash
# Login
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"andi.listrik@example.com","password":"password123"}'

# Dapatkan pesanan masuk
curl -X GET http://localhost:8000/api/orders/my-orders \
  -H "Authorization: Bearer <ANDI_TOKEN>"

# Diharapkan: Array dengan 3 pesanan (id: 1, 2, 3)
```

## Kait Notifikasi n8n

Jika `N8N_WEBHOOK_URL` dikonfigurasi di `backend/.env`, backend juga akan mengirim muatan acara ke n8n dan menyimpan baris log di `notification_logs`.

### Acara yang Dikirim
- `order_created`
- `order_accepted`
- `order_rejected`
- `work_started`
- `order_completed`
- `dp_paid`
- `final_paid`

### Env yang Diperlukan
```bash
N8N_WEBHOOK_URL=https://your-n8n-domain/webhook/...
N8N_WEBHOOK_SECRET=optional-shared-secret
N8N_EVENT_SECRET=optional-event-secret
```

### Bentuk Muatan
Setiap permintaan mencakup:
- `event_name`
- `channel`
- `payload`
- `sent_at`

Penanganan webhook juga mencatat hasil notifikasi sebagai `SENT`, `FAILED`, atau `SKIPPED`.

## Alur Pembayaran

### Perilaku Saat Ini
- `POST /api/payments/{paymentId}/generate-qris` sekarang mendukung mode `simulation` dan `midtrans`.
- Jika `PAYMENT_GATEWAY_DRIVER=midtrans`, backend akan mengirim transaksi Snap Midtrans dengan pembayaran `qris`.
- Jika kredensial belum ada, endpoint tetap fallback ke muatan simulasi agar pengujian lokal tidak terhenti.
- `POST /api/webhooks/payment` memverifikasi tanda tangan Midtrans dengan rumus `sha512(order_id + status_code + gross_amount + server_key)`.
- Penyedia tidak bisa mulai kerja sebelum DP benar-benar berstatus `PAID`.

### Env yang Diperlukan
```bash
PAYMENT_GATEWAY_DRIVER=midtrans
MIDTRANS_SERVER_KEY=YOUR_SERVER_KEY
MIDTRANS_CLIENT_KEY=YOUR_CLIENT_KEY
MIDTRANS_IS_PRODUCTION=false
```

### Catatan
- Untuk pengujian lokal, boleh tetap pakai `PAYMENT_GATEWAY_DRIVER=simulation`.
- Saat pindah ke Midtrans asli, isi `MIDTRANS_SERVER_KEY`, `MIDTRANS_CLIENT_KEY`, lalu set `MIDTRANS_IS_PRODUCTION` sesuai environment.
- Pada mobile, `checkout_url` dari respons bisa langsung dibuka untuk pembayaran QRIS Midtrans.

## Kebijakan Keuangan

### Komisi & Penyelesaian
- `PLATFORM_COMMISSION_PERCENT` menentukan potongan platform dari setiap pembayaran yang berhasil dibayar.
- Backend menyimpan `commission_percent`, `platform_fee`, `provider_payout`, dan `settlement_status` di tabel `payments`.
- Saat pembayaran berstatus `PAID`, backend secara otomatis menghitung payout penyedia dan menandai penyelesaian sebagai `READY`.

### Kebijakan Pengembalian Dana
- `DP_REFUND_PERCENT` menentukan berapa persen DP yang dikembalikan saat pesanan dibatalkan sebelum pengerjaan.
- Jika pesanan berstatus `CANCELLED` dan DP sudah dibayar, backend menandai pengembalian dana sebagai `REQUESTED`.
- Data pengembalian dana disimpan di field `refund_amount`, `refund_status`, `refund_reason`, dan `refund_requested_at`.

## Laporan Pembayaran Bendahara

### Endpoint
```bash
GET /api/treasurer/payments/report
```

### Akses
- Hanya pengguna dengan role `TREASURER` yang bisa mengakses endpoint ini.

### Parameter Kueri
- `start_date` — filter dari tanggal `YYYY-MM-DD`
- `end_date` — filter sampai tanggal `YYYY-MM-DD`
- `status` — `UNPAID`, `PENDING`, `PAID`, `FAILED`, `EXPIRED`
- `payment_type` — `DP` atau `FINAL`
- `order_id` — filter transaksi per pesanan
- `provider_id` — filter transaksi per penyedia
- `per_page` — jumlah data per halaman, default 20

### Respons Ringkas
- `summary.total_payments`
- `summary.total_amount`
- `summary.total_paid_amount`
- `summary.total_platform_fee`
- `summary.total_provider_payout`
- `summary.total_refund_amount`
- `breakdown.by_status`
- `breakdown.by_type`
- `data` berisi daftar detail pembayaran yang sudah di-paginate

### Contoh Curl
```bash
curl -X GET "http://localhost:8000/api/treasurer/payments/report?start_date=2026-05-01&end_date=2026-05-31&status=PAID&per_page=10" \
   -H "Authorization: Bearer YOUR_TREASURER_TOKEN"
```

## Alur Ulasan

### Pengujian Ulasan sebagai Pelanggan
1. Login sebagai pelanggan.
2. Buka pesanan dengan status `COMPLETED` atau `CLOSED`.
3. Ketuk **Tulis Ulasan**.
4. Pilih rating dan tambahkan komentar opsional.
5. Verifikasi:
   - ✅ Ulasan disimpan melalui `POST /api/reviews/order/{orderId}`
   - ✅ Halaman detail pesanan sekarang menampilkan ulasan yang dikirim
   - ✅ Halaman detail penyedia menampilkan rating rata-rata yang diperbarui dan daftar ulasan

### Endpoint API Ulasan
- `POST /api/reviews/order/{orderId}`
- `GET /api/reviews/order/{orderId}`
- `GET /api/reviews/provider/{providerId}`

## Alur Verifikasi Admin

### Pengaturan
Gunakan akun dengan `role = ADMIN`. Jika tidak ada pengguna admin, buat satu dengan tinker atau data seed.

### Pengujian UI Admin
1. Login sebagai admin.
2. Buka tab **Admin** baru di layar beranda.
3. Verifikasi daftar hanya menampilkan penyedia dengan `is_verified = false`.
4. Ketuk **Verifikasi** pada satu penyedia.
5. Verifikasi:
   - ✅ Status penyedia berubah menjadi terverifikasi di backend
   - ✅ Penyedia dihapus dari daftar yang tertunda
   - ✅ Acara `provider_verified` dikirim ke `n8n` jika dikonfigurasi

### Endpoint API Admin
- `GET /api/admin/providers/pending`
- `PATCH /api/admin/providers/{providerId}/verification`

## Hasil yang Diharapkan

| Pengujian | Sebelum Perbaikan | Setelah Perbaikan |
|------|-----------|-----------|
| Buat pesanan | ❌ Tidak terlihat di UI | ✅ Terlihat langsung |
| Respons pesanan | ❌ Status tidak diperbarui di UI | ✅ Diperbarui langsung |
| Ganti akun | ❌ Kebocoran lintas pengguna mungkin | ✅ Terisolasi dengan benar |
| Logout/Login | ❌ Pembersihan token diperlukan | ✅ Berfungsi dengan benar |
| Refresh manual | ⚠️ Diperlukan solusi workaround | ❌ Tidak diperlukan lagi |

## Keterbatasan yang Diketahui (Jika Ada)
- Integrasi gateway asli sudah siap untuk Midtrans, tapi kredensial produksi belum diisi di repo.

## Instruksi Rollback
Jika masalah terjadi, kembalikan [lib/features/home/order_providers.dart](lib/features/home/order_providers.dart) untuk menghapus panggilan `_ref.refresh(myOrdersProvider)` dari semua 4 metode.

## Catatan Tambahan
- Semua 27 endpoint API backend terverifikasi berfungsi
- Timeout Dio diatur ke 30 detik (koneksi + terima)
- Autentikasi token dengan Sanctum berfungsi dengan benar
- Kueri basis data filtering berdasarkan peran dan ID pengguna berfungsi dengan benar
