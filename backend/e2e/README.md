<!-- markdownlint-disable -->

E2E Playwright untuk fitur ekspor bendahara (treasurer)

Persiapan:

1. Instal Node.js (>=16) dan npm.
2. Dari folder `backend/e2e` jalankan:

```bash
npm install
```

3. Konfigurasi environment (opsional):
   - `PLAYWRIGHT_BASE_URL` (default: http://localhost)
   - `TEST_TOKEN` - Bearer token untuk pengguna `TREASURER` (dibutuhkan untuk test CSV)

Menjalankan test:

```bash
npm test
```

Catatan:
- Test `treasurer-export.spec.js` memanggil endpoint `/api/treasurer/payments/report?export=csv` dan memerlukan token autentikasi.
- Anda bisa membuat pengguna treasurer test dan menghasilkan token melalui Laravel Sanctum atau endpoint token aplikasi, lalu atur `TEST_TOKEN` sebelum menjalankan test.

Pembantu token cepat:

Dari folder `backend` jalankan perintah Artisan untuk membuat/mencari pengguna `TREASURER` dan mencetak token:

```bash
php artisan test:make-token --save
```

Perintah ini akan membuat pengguna `test.treasurer@example.com` (jika belum ada), mencetak `TEST_TOKEN`, dan menyimpannya ke `backend/e2e/.env` jika opsi `--save` digunakan.
