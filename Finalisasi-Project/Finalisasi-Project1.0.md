## FASE 2: Peningkatan Fitur Profil Akun

**Konteks Masalah:** Halaman profil akun saat ini terlalu kosong untuk semua *role*[cite: 4]. Perlu ditambahkan informasi dan fitur pengelolaan profil[cite: 4].
**Instruksi untuk Copilot:**

**Langkah Backend (Laravel):**
1. Buat *migration* untuk menambahkan kolom `profile_photo_path`, `full_name`, dan `phone_number` pada tabel `users` (jika belum ada).
2. Buat *endpoint* POST `/api/profile/update` dengan dukungan tipe `multipart/form-data` untuk unggah gambar.
3. Gunakan *facade* `Storage` Laravel untuk menyimpan foto ke direktori `public/profiles`.
4. Buat logika untuk menghapus foto lama dari *storage* saat *user* mengunggah foto baru atau menghapus foto.

**Langkah Frontend (Flutter):**
1. Perbarui layar Profil Akun untuk menampilkan `CircleAvatar` (foto profil), `Text` (Nama), dan `Text` (No HP)[cite: 4].
2. Buat form/dialog untuk proses Edit Profil (Nama, Nomor Telepon, Foto)[cite: 4].
3. Gunakan `ImagePicker` package untuk memilih gambar dari galeri/kamera[cite: 4].
4. Gunakan `Dio` dengan `FormData` untuk mengirim gambar beserta nama dan nomor telepon ke *backend*.

---

## FASE 3: Integrasi Fitur Baru (AI Chatbot Gemini)

**Konteks Masalah:** Penambahan asisten AI untuk *Customer Service* yang berfungsi membantu user ketika mendapati kendala di platform TukangDekat[cite: 1].
**Instruksi untuk Copilot:**

**Langkah Backend:**
1. Buat `ChatbotController` dengan *method* `sendMessage` yang dilindungi *middleware* Sanctum[cite: 1].
2. Gunakan `Http::withHeaders()` untuk menembak endpoint Gemini API Google.
3. Berikan *System Prompt*: "Kamu adalah asisten Customer Service berpengalaman untuk platform TukangDekat, aplikasi pemesanan jasa lokal di Kecamatan Bojongloa Kaler. Bantu user dengan ramah jika menemui kendala transaksi."[cite: 1]
4. Ambil data pesanan terakhir milik *user* yang sedang *login* dari database, dan sisipkan statusnya ke dalam *prompt* sebelum dikirim ke Gemini agar AI memahami konteks kendala user[cite: 1, 2].

**Langkah Frontend:**
1. Buat layar `ChatbotScreen` menggunakan `ListView` untuk merender gelembung *chat*.
2. Buat fungsi untuk mengirim pesan dari `TextField` ke `/api/chatbot/send` menggunakan *token* Sanctum[cite: 1, 2].
3. Tangani indikator *loading* saat menunggu respons API.

---

## FASE 4: Halaman Utama Awal (Landing / Welcome Screen)

**Konteks Fitur:** Membuat halaman pengantar (*Landing Screen*) yang pertama kali muncul saat aplikasi dibuka. Tujuannya agar pengguna tidak langsung dihadapkan pada tombol login, melainkan mendapatkan penjelasan singkat mengenai proyek aplikasi "TukangDekat" terlebih dahulu[cite: 1].
**Instruksi untuk Copilot (Flutter):**

1. Buat sebuah widget baru bernama `LandingScreen` (StatelessWidget) sebagai rute utama (`/`) saat aplikasi pertama kali dijalankan.
2. Desain tampilan halaman ini secara elegan dan bersih dengan komponen berikut:
   - **Bagian Atas/Tengah:** Logo aplikasi atau ilustrasi menarik, diikuti dengan Judul Besar: "TukangDekat".
   - **Bagian Deskripsi:** Tambahkan teks penjelasan proyek, contoh: *"Platform Pemesanan Jasa Lokal Terpercaya untuk Warga Kecamatan Bojongloa Kaler. Hubungkan kebutuhan perbaikan rumah Anda dengan teknisi listrik, plumbing, AC, dan bangunan terbaik di sekitar Anda secara transparan."*[cite: 1]
   - **Bagian Bawah:** Sediakan tombol utama yang menarik (misal: "Mulai Sekarang" atau "Masuk ke Aplikasi").
3. Berikan logika navigasi: Ketika tombol tersebut ditekan, arahkan pengguna ke halaman `LoginScreen` menggunakan `Navigator.pushReplacement` agar pengguna tidak bisa kembali ke halaman landing ini menggunakan tombol *back* perangkat.