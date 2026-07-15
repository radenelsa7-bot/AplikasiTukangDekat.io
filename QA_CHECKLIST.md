# QA Checklist — Final Release

**Test run:** 15 Juli 2026
**Branch:** `testing-final-qa-2026-07-15`
**Status rilis:** **BELUM LAYAK RILIS** — suite backend belum mendapat koneksi database testing; pengujian Flutter, E2E, manual, dan payment sandbox belum selesai.

Status: `[x]` lulus/terverifikasi, `[!]` gagal atau terblokir, `[ ]` belum diuji.

## 1. Automated checks

- [!] `flutter analyze` — proses tidak selesai dan tidak menghasilkan output di environment pengujian.
- [!] `flutter test` — proses tidak selesai dan tidak menghasilkan output di environment pengujian.
- [x] `php artisan test` — **77 passed, 5 skipped, 2 risky** (280 assertions). SQLite in-memory dipakai secara terisolasi untuk testing.
- [!] Playwright E2E `npm test` — percobaan awal gagal spawn worker (`EPERM`); setelah izin proses lokal, skenario melewati batas waktu 30 detik.

## 2. Environment & secrets

- [ ] `APP_ENV` benar untuk staging.
- [ ] Database khusus testing tersedia dan kredensialnya diisi pada `backend/.env.testing`.
- [ ] `XENDIT_API_KEY` dan `MIDTRANS_SERVER_KEY` menggunakan kredensial sandbox saat testing payment.
- [ ] `PAYOUT_ALERT_WEBHOOK` dan `PAYOUT_ALERT_EMAIL` diatur bila alerting diuji.

## 3. Database, queue, dan scheduler

- [x] Migrasi/suite database testing berjalan pada SQLite in-memory.
- [ ] Seeder akun dan data uji dijalankan pada database testing saja.
- [ ] Worker queue berjalan dan job payout/alert berhasil diproses.
- [ ] Scheduler (`php artisan schedule:list` dan job terjadwal) diverifikasi.

## 4. API, otorisasi, dan keamanan

- [x] Register, login, logout, dan token autentikasi diuji oleh suite backend. Refresh session masih memiliki skenario skipped pada test harness.
- [x] Non-admin ditolak dari endpoint admin; non-treasurer ditolak dari laporan treasurer.
- [x] Validasi input profil/unggahan foto diuji oleh suite backend.
- [ ] Data pesanan tidak bocor antarpengguna.

## 5. Alur bisnis dan pembayaran

- [ ] Katalog: daftar, pencarian, kategori, kota/kecamatan, detail provider, kondisi loading/error/kosong.
- [x] Pesanan: buat → respons provider → DP `PAID` → mulai kerja → selesai → pelunasan diuji oleh `PaymentStepFlowTest`.
- [ ] Provider tidak dapat memulai pekerjaan sebelum DP berstatus `PAID`.
- [x] Midtrans webhook: signature benar diterima; signature salah ditolak.
- [ ] Xendit sandbox payout dan pencatatan `payout_provider_responses` diverifikasi.
- [ ] Notifikasi n8n dan realtime notification log diverifikasi jika diaktifkan.

## 6. Mobile manual test

- [!] Landing page dan navigasi ke formulir login diuji pada perangkat Android fisik. APK debug terbaru sudah dipasang dengan endpoint host `192.168.1.7:8000`; login/logout menunggu server backend development dijalankan pada alamat tersebut.
- [ ] `CatalogPage`: pencarian/filter lokasi, detail provider, loading/error/empty state (menunggu koneksi API dan sesi pelanggan).
- [ ] `AdminDashboardPage`: statistik, navigasi tujuh menu, logout, dan akses khusus admin (menunggu koneksi API dan akun admin).
- [ ] Uji perangkat/emulator target, perubahan orientasi, jaringan mati, izin lokasi ditolak, dan unggah gambar gagal.

## 7. E2E, release, dan pascarilis

- [ ] E2E ekspor CSV laporan treasurer lulus dengan `TEST_TOKEN` valid.
- [ ] Smoke test API health check setelah deploy staging.
- [ ] Tag rilis dan release notes dibuat setelah semua blocker ditutup.
- [ ] Log dan alert dimonitor minimal 30 menit setelah rilis.
- [ ] Alur payout dikonfirmasi pada 1–3 data sampel sandbox/staging.

Lihat [laporan hasil testing](TESTING_REPORT_2026-07-15.md) untuk bukti, blocker, dan langkah tindak lanjut.
