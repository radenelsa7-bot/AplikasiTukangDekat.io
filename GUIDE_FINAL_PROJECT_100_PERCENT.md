# GUIDE FINAL PROJECT 100 PERCENT - TUKANGDEKAT

Dokumen ini adalah panduan end-to-end untuk menyelesaikan proyek hingga siap presentasi dan release internal.

## 1. Tujuan Guide
- Menyatukan langkah teknis backend, mobile, QA, keamanan, dan dokumentasi.
- Menjadi acuan tunggal untuk status progres dan langkah final.
- Menutup gap antara implementasi dengan SRS v1.1.

## 2. Scope Fitur Inti yang Wajib Lulus
- Auth dan role access.
- Katalog provider dan pencarian.
- Order lifecycle lengkap.
- Pembayaran DP dan FINAL via QRIS + webhook.
- Review dan rating.
- Admin verification dan treasurer reporting/export.
- Chatbot, profile photo, payout flow, metrics.

## 3. Prasyarat Environment
- Backend Laravel dapat dijalankan (PHP + Composer + DB).
- Mobile Flutter SDK terpasang.
- Database dapat diakses.
- File env terkonfigurasi (tanpa hardcode secret nyata di file yang dibagikan).

## 4. Setup dan Menjalankan Project
### Backend
1. Masuk ke folder backend.
2. Install dependency Composer.
3. Siapkan env dari env example.
4. Generate app key.
5. Jalankan migration dan seeding bila diperlukan.
6. Jalankan server/backend container.

### Mobile
1. Masuk ke folder mobile.
2. Jalankan flutter pub get.
3. Pastikan API_BASE_URL mengarah ke backend aktif.
4. Jalankan aplikasi (web/android) untuk uji alur.

## 5. Alur Verifikasi End-to-End (Wajib)
1. Register customer dan provider.
2. Login customer, cari provider, buat order.
3. Generate QRIS DP, webhook DP sukses.
4. Provider terima order, mulai kerja, selesaikan order.
5. Generate QRIS FINAL, webhook FINAL sukses, order menjadi CLOSED.
6. Customer kirim review.
7. Admin verifikasi/nonaktifkan provider (uji role access).
8. Treasurer buka report dan uji export CSV/XLS.

## 6. Hasil Perbaikan Terbaru (Sesi Ini)
- Fix UI role-based tab Pesanan agar ADMIN/TREASURER tidak memicu 403.
- Fix test register response format (password test disesuaikan dengan rule validasi).
- Fix webhook behavior DP agar status order transisi ke ACCEPTED sesuai ekspektasi test.
- Tambahan dukungan attachment URLs di create order:
  - Backend menerima attachment_urls (maks 5 URL valid).
  - Backend menyimpan ke order_attachments.
  - Order detail/list ikut membawa relasi attachments.
  - Mobile create order mengirim attachment_urls opsional (satu URL per baris).
- Fix flow command payout agar kompatibel pada DB fresh/testing:
  - Penanganan kolom opsional pembayaran dibuat aman.
  - Query agregasi payout dibuat lebih stabil lintas database.

## 7. Status QA Otomatis
- Backend feature suite sempat gagal, lalu beberapa failure sudah diperbaiki.
- Status terakhir yang tervalidasi dalam sesi:
  - ApiResponseFormatTest: PASS
  - PaymentWebhookTest: PASS
  - PayoutFlowTest: PASS
  - PayoutRetryTest: PASS
- Ada 1 patch test security yang sudah diterapkan, tetapi full rerun terakhir dibatalkan/cancel, sehingga perlu 1 kali rerun final untuk konfirmasi hijau total.

## 8. Temuan Baru yang Harus Ditindak
1. Warning deprecation PHP pada beberapa test terkait parameter nullable implisit (bukan blocker fungsional, tapi perlu dibersihkan).
2. Secret management masih jadi perhatian utama:
   - Pastikan tidak ada API key nyata pada file env yang berisiko dibagikan.
   - Lakukan rotasi key bila pernah terekspos.
3. Attachment saat ini berbasis URL (sudah menutup gap data attachment), namun upload file langsung dari kamera/perangkat masih bisa ditingkatkan pada iterasi berikutnya.

## 9. Checklist Release Readiness
- [ ] Semua feature tests backend hijau dalam satu kali run final.
- [ ] Smoke test staging berjalan tanpa error kritis.
- [ ] Validasi manual E2E utama selesai (auth sampai review/report).
- [ ] Secret sudah disanitasi dan tervalidasi aman.
- [ ] README dan dokumen handover sudah sinkron dengan implementasi terbaru.
- [ ] Bukti uji (log/screenshot) terdokumentasi.

## 10. Rencana Eksekusi Praktis (Urutan Kerja)
1. Jalankan full test backend sekali lagi sampai hijau total.
2. Jalankan checklist E2E manual.
3. Final hardening secret dan env.
4. Finalisasi dokumentasi handover dan checklist release.
5. Freeze scope lalu persiapan presentasi/demo.
