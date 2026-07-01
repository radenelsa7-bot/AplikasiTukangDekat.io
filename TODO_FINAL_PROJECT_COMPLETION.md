# TODO FINAL PROJECT COMPLETION

Dokumen ini berisi rangkuman tindak lanjut terakhir untuk menyelesaikan proyek hingga 100%.

## Prioritas 1 - Backend dan integrasi inti
- [x] Pastikan semua endpoint backend berjalan sesuai dokumentasi SRS. *(crosscheck source code + route selesai, lihat `SRS_CROSSCHECK_REPORT_2026-07-01.md`)*
- [ ] Validasi alur auth, order, pembayaran, review, dan admin end-to-end. *(sebagian tervalidasi; perlu re-run E2E penuh dengan data uji terbaru)*
- [x] Periksa migrasi database dan pastikan semua tabel yang diperlukan sudah terpasang. *(struktur migration mencakup auth, orders, payments, reviews, notification_logs, payout, webhook events, profile fields)*
- [ ] Jalankan uji coba backend secara menyeluruh dan perbaiki semua failure yang muncul. *(major failing tests sesi ini sudah diperbaiki: ApiResponseFormatTest, PaymentWebhookTest, PayoutFlowTest, PayoutRetryTest; perlu 1x full rerun final karena eksekusi terakhir dibatalkan/cancel)*

## Prioritas 2 - Keamanan dan konfigurasi
- [ ] Pindahkan secret/key sensitif dari file yang bisa di-commit ke environment variable atau secret manager. *(temuan: `backend/.env` masih mengandung nilai `GEMINI_API_KEY` non-placeholder, wajib rotasi & bersihkan)*
- [x] Pastikan konfigurasi Docker dan env aman untuk development/staging. *(docker compose + env template tersedia; perlu hardening lanjutan hanya pada secret handling)*
- [x] Review middleware, role access, dan proteksi endpoint yang masih rentan. *(sudah ditinjau + fix UI untuk mencegah 403 role mismatch di tab Pesanan)*

## Prioritas 3 - Frontend dan UX
- [x] Sesuaikan halaman frontend dengan perubahan backend terbaru. *(fix: tab Pesanan kini hanya tampil untuk role CUSTOMER/PROVIDER agar tidak memanggil endpoint terlarang)*
- [ ] Validasi alur login, register, katalog, order, pembayaran, dan review di aplikasi mobile/web. *(masih perlu checklist manual E2E terakhir)*
- [ ] Perbaiki tampilan error/loading yang masih inconsistent. *(masih ada pesan error mentah DioException di beberapa halaman)*
- [x] Tutup gap data attachment order minimum. *(create order kini mendukung `attachment_urls` opsional di backend + mobile)*

## Prioritas 4 - Dokumentasi dan handover
- [ ] Update README dan dokumentasi pengembangan.
- [x] Siapkan daftar API yang sudah terverifikasi. *(sudah dirangkum pada `SRS_CROSSCHECK_REPORT_2026-07-01.md`)*
- [x] Catat flow deployment, environment, dan troubleshooting yang penting. *(sudah dibuat panduan terpadu di `GUIDE_FINAL_PROJECT_100_PERCENT.md`)*

## Prioritas 5 - QA dan release readiness
- [ ] Lakukan pengujian manual end-to-end untuk skenario utama.
- [ ] Lakukan smoke test pada deployment/staging.
- [ ] Buat checklist final sebelum release.

## Catatan penting
- Fokus utama adalah menyelesaikan semua fitur inti yang sudah ada agar proyek benar-benar siap dipakai dan dipresentasikan.
- Jika ada blocker yang tidak bisa diselesaikan saat ini, catat dengan jelas penyebabnya dan solusi alternatifnya.

## Update 2026-07-01 (Crosscheck SRS)
- FR terpetakan terhadap implementasi: 31 implemented, 5 partial, 1 gap minor (attachment flow belum terbukti end-to-end).
- NFR utama sudah tersedia (metrics, webhook verification, role middleware, CI/CD, docker), dengan blocker keamanan: secret masih ada di file env lokal.
- Bug UX kritis role-based berhasil diperbaiki: akun ADMIN/TREASURER tidak lagi diarahkan ke flow Pesanan personal yang memicu 403.
- Validasi eksekusi: `flutter analyze` PASS untuk file yang diubah; `php artisan test --testsuite=Feature --stop-on-failure` masih FAIL di `ApiResponseFormatTest` (status register expected 201, actual 422).

## Update 2026-07-01 (Lanjutan Implementasi)
- Failure `ApiResponseFormatTest` sudah diperbaiki (payload password test disesuaikan rule validasi).
- Failure `PaymentWebhookTest` sudah diperbaiki (DP paid men-trigger transisi status order ke ACCEPTED sesuai behavior test).
- Failure payout flow (`PayoutFlowTest`, `PayoutRetryTest`) sudah diperbaiki dengan hardening command payout pada schema kolom opsional dan agregasi data.
- Dukungan attachment order ditingkatkan: create order sekarang menerima `attachment_urls` opsional (maks 5 URL valid) dan disimpan ke `order_attachments`.
- Temuan baru: masih ada warning deprecation PHP pada beberapa test (nullable parameter implisit) dan perlu dibersihkan pada iterasi quality berikutnya.
- Catatan verifikasi: full rerun terakhir dibatalkan/cancel sehingga perlu 1x final rerun untuk memastikan status hijau end-to-end.
