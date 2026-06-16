# Master Prompt Copilot: TukangDekat Project (Laravel API & Flutter)

## Konteks Proyek (@workspace)
Kamu adalah Senior Full-stack Developer. Proyek ini bernama "TukangDekat", sebuah platform pemesanan jasa lokal.
- **Backend:** Laravel (API-only), autentikasi menggunakan Laravel Sanctum.
- **Frontend:** Flutter dengan state management dan package `dio` / `http` untuk *networking*.
- **Database:** MySQL/PostgreSQL.

Tugas di bawah ini dibagi menjadi 3 fase. **Kerjakan SATU per SATU sesuai urutan saat saya memintanya.**

---

## FASE 1: Bug Fixing (Prioritas Tinggi)

### 1.1 Fix Error 422 saat Registrasi
[cite_start]**Konteks Masalah:** Frontend Flutter mendapatkan respons `422 Unprocessable Content` saat *user* mencoba register sebagai teknisi/customer[cite: 11].
**Instruksi untuk Copilot:**
1. Buka `RegisterController` atau controller yang menangani `/api/auth/register` di Laravel.
2. Analisis aturan validasi (`$request->validate(...)`).
3. Buatkan skrip untuk mengembalikan JSON *error message* yang lebih detail agar kita tahu *field* mana yang gagal divalidasi.
4. Buka file UI Flutter untuk halaman Register, pastikan *payload* JSON yang dikirim via Dio/Http nama *key*-nya persis sama dengan yang diminta Laravel (misal: `password_confirmation`, `role`, dsb).

### 1.2 Fix Error 500 saat Buat Order
[cite_start]**Konteks Masalah:** Aplikasi Flutter mengalami `DioException [bad response]` dengan status 500 Internal Server Error saat menekan tombol "Buat Order".
**Instruksi untuk Copilot:**
1. Periksa `OrderController` pada *method* yang menangani pembuatan order.
2. Tambahkan blok `try-catch` dan gunakan `Log::error($e->getMessage())` untuk menangkap detail *error* ke dalam `storage/logs/laravel.log`.
3. Pastikan semua relasi database (seperti `user_id`, `provider_id`, `service_id`) tidak melanggar aturan *Foreign Key* atau bernilai *Null*.
4. Perbaiki *method* tersebut agar selalu mengembalikan respons JSON (contoh: `return response()->json(['error' => 'Pesan error'], 500);`) alih-alih melempar HTML *stack trace*.

### 1.3 Penyesuaian Admin Panel
[cite_start]**Konteks Masalah:** Tampilan dan hak akses Admin belum sesuai dengan SRS (Software Requirements Specification)[cite: 1, 2].
**Instruksi untuk Copilot:**
1. Cek *middleware* Sanctum di `routes/api.php`. Pastikan *endpoint* khusus admin dibungkus dengan pengecekan *role* (misal: `middleware('role:ADMIN')`).
2. Buatkan *layout* dasar di Flutter khusus untuk *role* Admin yang menyembunyikan menu "Buat Pesanan" dan memunculkan menu "Verifikasi Teknisi".

---

## FASE 2: Peningkatan Fitur Profil Akun

[cite_start]**Konteks Masalah:** Halaman profil akun terlalu kosong untuk semua *role*[cite: 4]. [cite_start]Perlu ditambahkan foto profil [cite: 5][cite_start], nama lengkap [cite: 6][cite_start], dan nomor telepon[cite: 7]. [cite_start]Selain itu, harus ada fitur untuk mengedit data tersebut [cite: 9] [cite_start]dan menghapus foto profil[cite: 10].
**Instruksi untuk Copilot:**

**Langkah Backend (Laravel):**
1. Buat *migration* untuk menambahkan kolom `profile_photo_path`, `full_name`, dan `phone_number` pada tabel `users` (jika belum ada).
2. Buat *endpoint* POST `/api/profile/update` dengan dukungan tipe `multipart/form-data` untuk unggah gambar.
3. Gunakan *facade* `Storage` Laravel untuk menyimpan foto ke direktori `public/profiles`.
4. [cite_start]Buat logika untuk menghapus foto lama dari *storage* saat *user* mengunggah foto baru [cite: 9] [cite_start]atau menghapus foto[cite: 10].

**Langkah Frontend (Flutter):**
1. Perbarui layar Profil Akun untuk menampilkan `CircleAvatar` (foto profil), `Text` (Nama), dan `Text` (No HP).
2. Buat form/dialog untuk proses Edit Profil.
3. Gunakan `ImagePicker` package untuk memilih gambar dari galeri/kamera.
4. Gunakan `Dio` dengan `FormData` untuk mengirim gambar beserta nama dan nomor telepon ke *backend*.

---

## FASE 3: Integrasi Fitur Baru (AI Chatbot Gemini)

**Konteks Masalah:** Penambahan asisten AI untuk *Customer Service* yang terintegrasi di dalam aplikasi.
**Instruksi untuk Copilot:**

**Langkah Backend:**
1. Buat `ChatbotController` dengan *method* `sendMessage` yang dilindungi *middleware* Sanctum.
2. Gunakan `Http::withHeaders()` untuk menembak endpoint Gemini API Google.
3. Berikan *System Prompt*: "Kamu adalah asisten Customer Service untuk platform TukangDekat."
4. Ambil data pesanan terakhir milik *user* yang sedang *login* dari database, dan sisipkan statusnya ke dalam *prompt* sebelum dikirim ke Gemini.

**Langkah Frontend:**
1. Buat layar `ChatbotScreen` menggunakan `ListView` untuk merender gelembung *chat*.
2. Buat fungsi untuk mengirim pesan dari `TextField` ke `/api/chatbot/send` menggunakan *token* Sanctum.
3. Tangani indikator *loading* saat menunggu respons API.