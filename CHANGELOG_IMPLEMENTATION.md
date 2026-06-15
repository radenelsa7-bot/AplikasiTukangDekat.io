# CHANGELOG IMPLEMENTATION

## 1. Ringkasan Perubahan
- Dibuat file dokumentasi baru: `CHANGELOG_IMPLEMENTATION.md`.
- Arsitektur otorisasi disentralisasi dengan menggunakan middleware baru: `backend/app/Http/Middleware/CheckRole.php`.
- Konfigurasi middleware alias ditambahkan di `backend/bootstrap/app.php`.
- Routing API diperbarui di `backend/routes/api.php` agar menggunakan middleware `role:*` secara konsisten.
- Duplikasi route yang tidak relevan di `backend/routes/web.php` dihapus untuk mencegah bypass autentikasi/otorisasi.

## 2. Kondisi Sebelum Perubahan (Before)
Sebelumnya, pengecekan peran sering dilakukan secara inline di dalam implementasi route atau controller, misalnya dengan logika `if ($user->role !== 'ADMIN') { return response()->json(['message' => 'forbidden'], 403); }`.
Kelemahan pendekatan ini:
- Logika otorisasi tersebar di banyak tempat, membuat pemeliharaan dan review menjadi lebih sulit.
- Risiko inkonsistensi tinggi; endpoint yang seharusnya terlindungi bisa saja luput dari pemeriksaan.
- Sulit membackup aturan akses terpusat ke dalam satu pola yang mudah dibaca oleh tim.
- Kode menjadi lebih panjang dan kurang terstruktur, terutama untuk pembatasan hak akses mutasi data.

## 3. Kondisi Setelah Perubahan (After)
Sekarang sistem otorisasi menggunakan middleware `CheckRole` terpusat.
Middleware ini diberi alias `role` di `backend/bootstrap/app.php`, sehingga route dapat menuliskan aturan dengan parameter:
- `role:admin`
- `role:readonly`
- `role:write`

Implementasi ini memaksa semua permintaan API yang memerlukan hak akses memanggil middleware yang konsisten daripada melakukan pengecekan manual.
Contoh penggunaan saat ini di `backend/routes/api.php`:
- Endpoint admin hanya bisa diakses dengan `middleware('role:admin')`.
- Endpoint treasurer/report menggunakan `middleware('role:readonly')`.
- Endpoint pembuatan dan update order menggunakan `middleware('role:write')`.

## 4. Ekspektasi Sistem (What Should Be There)
Agar tidak terjadi kebocoran hak akses, endpoint harus mematuhi aturan berikut:
- `role:admin`: hanya untuk akun dengan `role === 'ADMIN'`.
- `role:readonly`: hanya untuk akun `TREASURER` atau `ADMIN`.
- `role:write`: untuk akun yang boleh melakukan mutasi kecuali `TREASURER`; secara implisit menerima `CUSTOMER`, `PROVIDER`, dan `ADMIN`, tetapi menolak akses mutasi dari `TREASURER`.

Aturan bisnis utama setelah perubahan:
- Semua akses mutasi data API harus melalui route yang jelas dan menggunakan `role:write`, bukan inline manual.
- Semua akses laporan / pembacaan data yang bersifat pelaporan atau monitoring harus menggunakan `role:readonly`.
- `TREASURER` tidak boleh melakukan operasi mutasi di endpoint API inti yang mengubah data transaksi atau onboarding provider.
- `ADMIN` tetap memiliki hak penuh untuk pengelolaan dan mutasi data.
- Setiap endpoint yang pernah memakai inline role check sebelumnya harus direview dan, bila belum, dipindahkan ke `CheckRole`.

> Catatan: untuk menjaga konsistensi, catat setiap endpoint baru yang memerlukan otorisasi dengan parameter `role:*` dan jangan gunakan lagi `if ($user->role ...)` langsung di controller kecuali untuk kasus web UI khusus yang benar-benar tidak bisa dipindahkan.
