<!-- markdownlint-disable -->

## Status Penerapan & Saat Ini

Ringkasan implementasi saat ini dan tindakan yang tersisa untuk fitur saluran pembayaran (cabang: feature/payout-prod).

Selesai
- Saluran pembayaran (layanan + pekerjaan antrian) diimplementasikan.
- Adaptor gateway: adaptor Xendit dan adaptor Mock tersedia.
- Perilaku coba ulang/backoff diimplementasikan pada `SendProviderPayoutJob`.
- Orkestrasi penyedia dan penanganan idempoten diimplementasikan.
- Endpoint ekspor bendahara (CSV / XLS) diimplementasikan di backend.
- Runbook, playbook penerapan, skrip pembantu, dan alur kerja CI ditambahkan.
- Tes e2e mock untuk alur pembayaran lolos secara lokal.

Tertunda (prioritas tinggi terlebih dahulu)
- Dapatkan Kunci API Sandbox Rahasia Xendit dengan izin pencairan dana.
- Jalankan tes end-to-end sandbox menggunakan kunci sandbox Xendit nyata.
- Tambahkan GitHub Secrets yang diperlukan untuk penerapan (`DEPLOY_HOST`, `DEPLOY_USER`, `DEPLOY_KEY`, `DEPLOY_PATH`, `XENDIT_API_KEY`, `MIDTRANS_*`).
- Gabungkan `feature/payout-prod` → `main` dan aktifkan alur kerja penerapan.
- Mulai pekerja antrian di staging (systemd / supervisor) dan verifikasi pemrosesan pekerjaan.

Tertunda (prioritas menengah/rendah)
- Verifikasi dan finalisasi penanganan verifikasi webhook Midtrans.
- UI Bendahara: verifikasi pengalaman pengguna ekspor/unduhan dan penanganan kasus tepi.
- Pemantauan dan pemberitahuan untuk pembayaran yang gagal dan metrik pengulangan.
- Pemeriksaan asap/kanari pasca-penerapan dan observabilitas (log/metrik).

Cara melanjutkan (direkomendasikan)
1. Berikan rahasia sandbox Xendit (atau aktifkan izin pencairan dana) dan jalankan:

   php artisan config:clear
   php artisan payouts:test-gateway --to=08123456789

2. Tambahkan GitHub Secrets (gunakan pembantu `deploy/set_github_secrets.sh` atau melalui pengaturan repositori).
3. Gabungkan PR dan aktifkan Actions; kemudian terapkan ke staging dan mulai pekerja antrian.

Catatan
- Hindari menulis rahasia penyedia ke env tingkat OS (Windows `setx`) — gunakan rahasia repositori untuk CI dan `.env` untuk dev lokal saja.
- Gateway Mock tersedia untuk memvalidasi saluran lengkap secara lokal sambil menunggu izin sandbox.

Kontak
- Jika Anda inginkan, saya bisa: menandai pengulas dan/atau melakukan penggabungan secara otomatis (memerlukan token GitHub dengan cakupan `repo`).
