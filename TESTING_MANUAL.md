# 🧪 Panduan Pengujian Manual - Aplikasi Seluler TukangDekat

**Status:** ✅ Aplikasi dikompilasi dengan sukses dan berjalan di Chrome
**Backend:** http://127.0.0.1:8000 (berjalan)
**Frontend:** Aplikasi web Chrome (berjalan)

---

## Daftar Periksa Pengaturan

Sebelum memulai pengujian, verifikasi:

- [x] Backend berjalan di http://127.0.0.1:8000
- [x] Aplikasi Flutter berjalan di Chrome
- [x] Chrome DevTools terbuka (F12)
- [x] Akun pengujian diseed di database

---

## Skenario Pengujian

### Skenario 1: Luncurkan Aplikasi & Layar Splash

**Langkah:**
1. Buka Chrome (seharusnya sudah terbuka dari `flutter run -d chrome`)
2. Cari layar muat aplikasi

**Hasil yang Diharapkan:**
- [ ] SplashPage muncul (menampilkan "CircularProgressIndicator")
- [ ] Setelah 2-3 detik, dialihkan ke LoginPage (tidak ada token tersimpan)
- [ ] URL: http://localhost:xxxxx (server dev Chrome)

**Jika Ada Masalah:**
- Periksa konsol browser (F12 → tab Console)
- Cari "CORS errors" atau "connection refused"
- Verifikasi backend berjalan: http://127.0.0.1:8000

---

### Skenario 2: Tampilan Halaman Login

**Hasil yang Diharapkan:**
- [ ] Judul "TukangDekat" terlihat
- [ ] Subtitle "Layanan Teknisi Terpercaya" terlihat
- [ ] Kolom email dengan ikon email
- [ ] Kolom password dengan ikon kunci
- [ ] Tombol "Masuk"
- [ ] Tautan "Belum punya akun? Daftar" di bagian bawah

**Data Pengujian Diisi Sebelumnya:**
- Email: `customer@test.com`
- Password: `password123`

---

### Skenario 3: Login Berhasil

**Langkah:**
1. Kolom email harus menampilkan: `customer@test.com`
2. Kolom password harus menampilkan: `password123`
3. Klik tombol "Masuk"

**Hasil yang Diharapkan:**
- [ ] Tombol menampilkan spinner loading saat autentikasi
- [ ] Tab Network menampilkan: POST /api/auth/login → 200 OK
- [ ] Respons berisi: token + data pengguna (id, name, email, role)
- [ ] Setelah sukses, navigasi ke HomePage
- [ ] Token disimpan di secure storage (tidak terlihat tapi terjadi)

**Pemeriksaan Permintaan Jaringan (DevTools):**
1. Buka DevTools (F12)
2. Buka tab Network
3. Filter dengan: "auth"
4. Anda seharusnya melihat:
   ```
   POST /api/auth/login
   Status: 200
   Response: {
     "message": "ok",
     "token": "xxx...",
     "user": {
       "id": 1,
       "name": "Fajar",
       "email": "customer@test.com",
       "role": "CUSTOMER"
     }
   }
   ```

---

### Skenario 4: Tampilan Halaman Beranda

**Setelah login berhasil, seharusnya melihat:**

**Tab 1: Beranda (Katalog)**
- [ ] Bilah pencarian: "Cari teknisi atau layanan" dengan ikon pencarian
- [ ] Bagian "Kategori Layanan"
- [ ] 5 kartu kategori (Listrik, Plumbing, AC, Bangunan Ringan, Elektronik)
- [ ] Daftar kategori dapat digulir secara horizontal

**Tab 2: Pesanan (Pesanan Saya)**
- [ ] Status kosong dengan pesan "Belum ada order"

**Tab 3: Akun (Akun)**
- [ ] Judul "Profil Akun"
- [ ] Kartu yang menampilkan: Email, Role, ID

**AppBar:**
- [ ] Judul: "TukangDekat"
- [ ] 3 tab terlihat di bagian bawah
- [ ] Tombol logout (ikon) di kanan atas

---

### Skenario 5: Jelajahi Kategori

**Langkah:**
1. Di tab Beranda
2. Gulir horizontal melalui kartu kategori
3. Klik pada kategori "Listrik" (kartu pertama)

**Hasil yang Diharapkan:**
- [ ] Kartu kategori disorot (warna/latar belakang berbeda)
- [ ] Bagian "Teknisi Tersedia" muncul di bawah
- [ ] Menampilkan 3 penyedia untuk kategori Listrik
- [ ] Setiap kartu penyedia menampilkan:
   - Nama (contoh: "Andi Elektrik")
   - Deskripsi/area
   - Rating (★ 4.5 atau serupa)
   - Ikon panah (→)

**Network Check:**
- DevTools Network tab should show:
  ```
  GET /api/catalog/categories/{id}/providers
  Status: 200
  Response: {
    "data": [
      {
        "id": 1,
        "businessName": "Andi Elektrik",
        "avgRating": 4.5,
        ...
      },
      ...
    ]
  }
  ```

---

### Skenario 6: Halaman Detail Penyedia

**Langkah:**
1. Klik pada salah satu kartu penyedia (contoh: "Andi Elektrik")

**Hasil yang Diharapkan:**
- [ ] Navigasi ke ProviderDetailPage
- [ ] AppBar menampilkan judul "Detail Teknisi"
- [ ] Tombol kembali (←) muncul di sebelah kiri
- [ ] Menampilkan informasi penyedia:
  - Foto profil (avatar lingkaran dengan ikon)
  - Nama bisnis (besar)
  - Rating dengan bintang (★ 4.5)
  - Badge "Terverifikasi" (jika terverifikasi)
  - Teks deskripsi
  - Area/Alamat

**Bagian Layanan Tersedia (Layanan):**
- [ ] Judul "Layanan Tersedia"
- [ ] Daftar layanan dengan:
  - Nama layanan
  - Format harga: "Rp50000 / jam" (atau per pekerjaan)

**Tombol CTA:**
- [ ] Tombol "Pesan Sekarang" di bagian bawah (lebar penuh)

**Pemeriksaan Jaringan:**
```
GET /api/catalog/providers/{id}
Status: 200
Response mencakup: array layanan
```

---

### Skenario 7: Buat Order

**Langkah:**
1. Di ProviderDetailPage
2. Klik tombol "Pesan Sekarang"

**Hasil yang Diharapkan:**
- [ ] Navigasi ke CreateOrderPage
- [ ] AppBar menampilkan judul "Buat Order"
- [ ] Bagian "Detail Order" terlihat

**Kolom Formulir:**
- [ ] Kolom teks "Alamat Lokasi" (3 baris, ikon lokasi)
- [ ] Kolom "Catatan Tambahan" (3 baris, ikon catatan)
- [ ] Tombol "Tanggal Pekerjaan" (ikon kalender)
- [ ] Tombol "Jam Pekerjaan" (ikon jam)
- [ ] Kotak informasi pembayaran menjelaskan pembagian 50-50
- [ ] Tombol "Buat Order"

**Langkah Mengisi Formulir:**
1. Ketik alamat: "Jl. Contoh No 123, Bandung"
2. Ketik catatan: "Ada masalah dengan instalasi"
3. Klik "Tanggal Pekerjaan" → Pilih tanggal besok
4. Klik "Jam Pekerjaan" → Pilih waktu (contoh: 14:00)
5. Klik "Buat Order"

**Hasil yang Diharapkan:**
- [ ] Tombol menampilkan spinner loading
- [ ] Tab Network menampilkan: POST /api/orders → 201 Created
- [ ] Pesan sukses muncul: "Order berhasil dibuat!"
- [ ] Navigasi kembali ke CatalogPage

**Permintaan Jaringan:**
```
POST /api/orders
Payload: {
  "provider_id": 1,
  "address": "...",
  "schedule_at": "2026-05-15T14:00:00.000Z",
  ...
}
Status: 201
Response: OrderData yang dibuat
```

---

### Skenario 8: Lihat Pesanan Saya

**Langkah:**
1. Setelah order dibuat, klik tab "Pesanan"

**Hasil yang Diharapkan:**
- [ ] Order muncul di daftar dengan:
  - Tata letak kartu pesanan
  - Badge status (dikodekan dengan warna, contoh: biru untuk "CREATED")
  - Kode order (ORD-20260514-XXXX)
  - Alamat
  - Tanggal/waktu jadwal
  - Harga perkiraan (Rp...)

**Klik pada Order:**
1. Klik kartu order

**Hasil yang Diharapkan - Detail Order:**
- [ ] Navigasi ke OrderDetailPage
- [ ] Menampilkan bagian:
  - Kartu status (dengan warna)
  - Kode order
  - Alamat
  - Jadwal
  - Informasi harga
  - Rincian pembayaran (DP + Final)

**Pemeriksaan Jaringan:**
```
GET /api/orders
Status: 200
Response: daftar pesanan

GET /api/orders/{id}
Status: 200
Response: detail pesanan lengkap
```

---

### Skenario 9: Cari Penyedia

**Langkah:**
1. Kembali ke tab Beranda
2. Klik bilah pencarian di atas
3. Ketik nama penyedia: "Andi"

**Hasil yang Diharapkan:**
- [ ] Input pencarian fokus
- [ ] Saat mengetik, hasil diperbarui secara real-time
- [ ] Menampilkan penyedia yang cocok
- [ ] Dapat diklik untuk melihat detail penyedia

**Pemeriksaan Jaringan:**
```
GET /api/catalog/providers/search?q=andi
Status: 200
Response: penyedia yang disaring
```

---

### Skenario 10: Keluar (Logout)

**Langkah:**
1. Di halaman mana pun dengan AppBar
2. Klik tombol logout (ikon) di kanan atas

**Hasil yang Diharapkan:**
- [ ] Tombol menampilkan spinner loading
- [ ] Tab Network menampilkan: POST /api/auth/logout → 200
- [ ] Navigasi kembali ke LoginPage
- [ ] Token dihapus dari penyimpanan
- [ ] Tautan "Belum punya akun? Daftar" terlihat
- [ ] Dapat login lagi dengan sesi baru

---

## Skenario Error yang Akan Diuji

### E1: Kredensial Salah
**Langkah:**
1. Di LoginPage
2. Ubah email menjadi: invalid@test.com
3. Pertahankan password: password123
4. Klik Masuk

**Hasil yang Diharapkan:**
- [ ] Pesan kesalahan muncul
- [ ] Network menampilkan: POST /api/auth/login → 422 (validation error)
- [ ] Tetap di LoginPage (tidak ada navigasi)

### E2: Formulir Kosong
**Langkah:**
1. Di LoginPage
2. Hapus kedua kolom
3. Klik Masuk

**Hasil yang Diharapkan:**
- [ ] Kesalahan validasi formulir muncul
- [ ] Pesan "Email wajib diisi"
- [ ] Pesan "Password wajib diisi"
- [ ] Tidak ada panggilan API yang dibuat (validasi di sisi klien)

### E3: Backend Offline
**Langkah:**
1. Hentikan server backend (di terminal tempat `php artisan serve` berjalan)
2. Coba login

**Hasil yang Diharapkan:**
- [ ] Spinner loading ditampilkan
- [ ] Setelah timeout (~5-10 detik), pesan kesalahan muncul
- [ ] Tab Network menampilkan: Failed (Connection error)
- [ ] Pesan kesalahan: "Connection error" atau serupa

---

## Daftar Periksa Browser DevTools

### Tab Konsol (F12 → Console)
- [ ] Tidak ada pesan kesalahan merah
- [ ] Tidak ada kesalahan "CORS"
- [ ] Tidak ada kesalahan "undefined"
- [ ] Periksa peringatan (teks kuning) - biasanya baik-baik saja

### Tab Jaringan (F12 → Network)
- [ ] Semua permintaan API menampilkan "200 OK" atau "201 Created"
- [ ] Tidak ada kesalahan "404 Not Found"
- [ ] Tidak ada "500 Internal Server Error"
- [ ] Waktu respons < 1 detik (biasanya 100-300ms)

### Tab Penyimpanan (F12 → Application/Storage)
- [ ] Setelah login, periksa "Local Storage" atau "Secure Storage"
- [ ] Token harus disimpan (mungkin terenkripsi)
- [ ] Setelah logout, token harus dihapus

---

## Daftar Periksa Pengujian Cepat

Cetak ini dan centang saat Anda melanjutkan:

```
LANDING:
- [ ] Aplikasi dimuat tanpa kesalahan
- [ ] SplashPage muncul
- [ ] Pengalihan ke LoginPage

LOGIN:
- [ ] Kolom email diisi sebelumnya dengan customer@test.com
- [ ] Kolom password diisi sebelumnya dengan password123
- [ ] Klik Masuk berfungsi
- [ ] Navigasi ke HomePage

HOMEPAGE:
- [ ] 3 tab terlihat (Beranda, Pesanan, Akun)
- [ ] Tab 1 menampilkan kategori
- [ ] Tab 2 menampilkan "Belum ada order"
- [ ] Tab 3 menampilkan informasi profil

CATALOG:
- [ ] Klik kategori menyaring penyedia
- [ ] Klik penyedia menampilkan detail
- [ ] Klik "Pesan Sekarang" membuka formulir

BUAT ORDER:
- [ ] Isi kolom formulir
- [ ] Pilih tanggal dan waktu
- [ ] Submit membuat order
- [ ] Pesan sukses muncul

LIHAT PESANAN:
- [ ] Klik tab Pesanan menampilkan order
- [ ] Klik order menampilkan detail
- [ ] Lihat rincian pembayaran

PENCARIAN:
- [ ] Ketik di bilah pencarian
- [ ] Hasil muncul secara real-time
- [ ] Dapat diklik hasil

LOGOUT:
- [ ] Klik tombol logout
- [ ] Kembali ke LoginPage
- [ ] Dapat login lagi

KESALAHAN:
- [ ] Kredensial salah menampilkan kesalahan
- [ ] Formulir kosong melakukan validasi
- [ ] Tidak ada kesalahan konsol
```

---

## Kriteria Kesuksesan

✅ **APLIKASI BERFUNGSI JIKA:**
1. Kompilasi berhasil (tidak ada kesalahan merah)
2. Aplikasi terbuka di Chrome tanpa mogok
3. Dapat login dengan akun pengujian
4. Dapat menjelajahi kategori dan penyedia
5. Dapat membuat order
6. Dapat melihat detail order
7. Tidak ada kesalahan konsol
8. Permintaan jaringan selesai dengan sukses

---

## Masalah Umum & Solusi

| Masalah | Solusi |
|---------|--------|
| "Tidak dapat terhubung ke backend" | Mulai backend: `php artisan serve` |
| Kesalahan "CORS" di konsol | Tambahkan header CORS ke Laravel (biasanya sudah dikonfigurasi) |
| Tombol tidak merespons | Periksa apakah spinner loading ditampilkan - tunggu respons |
| Halaman kosong setelah login | Periksa konsol browser untuk kesalahan |
| Tidak dapat membuat order | Isi semua kolom yang diperlukan (alamat, tanggal, waktu) |
| Order tidak muncul | Tunggu 2 detik dan segarkan tab Pesanan |

---

## Selanjutnya: Jika Semua Pengujian Lulus ✅

Lanjutkan ke Fase 3:
1. Integrasi gateway pembayaran (Midtrans/Xendit)
2. Alur penerimaan order penyedia
3. Notifikasi real-time

---

**Pengujian Dimulai:** 14 Mei 2026
**Status:** Siap untuk pengujian manual

Semoga beruntung! 🎉
