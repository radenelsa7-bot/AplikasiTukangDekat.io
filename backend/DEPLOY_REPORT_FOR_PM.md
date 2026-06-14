# Laporan Smoke Deploy (untuk PM)

Branch: feature/backend-123-deploy-smoke
Pull Request: https://github.com/radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi/pull/38
Tanggal: 6 Juni 2026

Ringkasan
- Tujuan: Menyelesaikan artefak smoke-test dan dokumentasi untuk memvalidasi kesiapan deployment.
- Status: Dokumentasi dan skrip smoke-test sudah disiapkan; eksekusi smoke test menunggu di staging.

Apa yang telah saya perbarui
- `backend/DEPLOY_STATUS.md`: memperbarui status, menambahkan instruksi smoke-test langkah demi langkah dan persyaratan lingkungan.
- `backend/.github/workflows/ci-staging.yml`: memperbaiki workflow CI staging agar dilewati jika secrets hilang dan memperbarui trigger untuk menyertakan `feature/backend-123-deploy-smoke`.
- Memastikan keberadaan:
  - `deploy/smoke-test.sh` (skrip untuk menjalankan smoke test)
  - `app/Console/Commands/DeploySmokeTest.php` (perintah artisan `deploy:smoke`)
  - Konfigurasi Supervisor: `deploy/supervisor.conf`

Cara verifikasi (Ops)
1. Pastikan server memiliki PHP (>=8.1), composer, database, dan redis yang dikonfigurasi.
2. Pastikan queue worker berjalan (systemd atau supervisor).
3. Dari direktori backend jalankan:

```bash
./deploy/smoke-test.sh
# atau
php artisan deploy:smoke --url="https://staging.example.com"
```

Hasil yang diharapkan: kode keluar 0 dan informasi mengenai health check serta perintah readiness artisan tercetak.

## Pembaruan Pekerjaan Saat Ini
- Branch backend saat ini: `feature/backend-120-reviews-rating-api`
- Menyelesaikan alur auto-create order DP dan beralih ke pekerjaan Reviews & Rating API.
- Menambahkan endpoint ringkasan review provider dan dukungan agregasi rating.
- Menambahkan feature test untuk pembuatan review dan ringkasan rating provider.
- Verifikasi lokal terblokir karena runtime PHP tidak tersedia di lingkungan editor ini.
- Langkah berikutnya yang direncanakan: jalankan test API Review baru dan validasi endpoint `/api/reviews/provider/{id}/summary` setelah runtime PHP tersedia.

Catatan
- Saya telah mendorong pembaruan dokumentasi ke branch `feature/backend-123-deploy-smoke` di remote.
- GitHub Actions sekarang dikonfigurasi untuk menjalankan workflow staging untuk branch ini saat secrets repository tersedia.
- Pull request #38 terbuka dan siap untuk ditinjau.
- Eksekusi smoke test menunggu akses lingkungan staging.

Penghalang
- Smoke test lokal via Docker tidak dapat dijalankan di lingkungan ini karena Docker tidak terpasang.
- Akses lingkungan staging diperlukan untuk menyelesaikan validasi smoke dan pengujian queue worker produksi.

Langkah berikutnya (untuk dilakukan di lingkungan staging)
- Jalankan smoke test dan catat hasilnya di file ini atau `backend/DEPLOY_STATUS.md`.
- Jika smoke test lulus, tandai `Full smoke test validation` dan `Production queue worker testing` sebagai selesai di `backend/DEPLOY_STATUS.md`.
