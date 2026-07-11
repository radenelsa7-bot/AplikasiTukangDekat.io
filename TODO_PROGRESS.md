# TODO_PROGRESS

Status eksekusi konsolidasi:

- [x] Sprint Auth/Session: TODO_SESSION_FIX (log ter-logout otomatis saat refresh) sudah dikerjakan di tahap konfigurasi CORS + sanitization
- [x] Sprint Tests: `php artisan test` sudah dijalankan dan mayoritas test lulus (warnings/deprecations & 2 warning/skip terkait enforcement).

Berikutnya yang dikerjakan (berdasarkan prioritas sistem):

- [ ] Konsolidasi DB schema migrasi untuk Coverage Area, Kategori Kerusakan, Status Pembayaran, log Harga Akhir
- [ ] Penyesuaian core order/payment flow: DP/Lunas + persetujuan harga akhir
- [ ] RBAC cleanup & restrukturisasi direktori (jika masih ada ketidaksesuaian)
- [ ] UI: Landing page, responsivitas, pemisahan provider/customer
- [ ] Core features: notifikasi real-time, coverage area enforcement, pencarian vendor, bidding queue
- [ ] Form: maps, upload foto bertahap, perbaikan upload file (bukan URL)
- [ ] Chatbot upgrade

