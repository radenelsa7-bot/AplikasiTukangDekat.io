# HELP_RUN_PROJECT.md — Tata Cara Aman Menjalankan Proyek dengan Docker (Tim/Reviewer)

Dokumen ini dibuat agar **siapa pun** (anggota tim/dosen/reviewer) bisa menjalankan repository ini secara instan tanpa salah langkah, tanpa perlu menginstal PHP, Composer, atau MySQL secara manual di laptop mereka.

Sistem ini memanfaatkan **Docker** untuk mengisolasi backend dan database, serta **Flutter** lokal untuk aplikasi mobile.

---

## 0) Checklist Sebelum Mulai

1. Pastikan **Docker Desktop** sudah terinstal di laptop Anda dan posisinya sedang aktif/running.
2. Pastikan port `8000` (untuk API Laravel) dan port `3306` (untuk MySQL lokal) sedang tidak dipakai oleh aplikasi lain di laptop Anda (matikan Laragon/XAMPP lokal jika sedang aktif).
3. Jangan pernah melakukan commit atau push pada file rahasia lokal (`.env`).

---

## 1) Menjalankan Backend & Database via Docker

Dengan Docker, Anda tidak perlu melakukan `cp .env.example .env` atau mengedit konfigurasi database manual, karena seluruh environment development sudah diintegrasikan secara aman di dalam file `docker-compose.yml` pada root project.

### Langkah-Langkah:

1. Buka terminal Anda (VS Code Terminal / Git Bash) tepat di **root folder project** `PM_UAS_REKAYASA_SISTEM_INFORMASI` (folder paling luar tempat file `docker-compose.yml` berada).
2. Jalankan perintah sakti untuk melakukan build dan menyalakan kontainer di background:
   ```bash
   docker compose up -d --build