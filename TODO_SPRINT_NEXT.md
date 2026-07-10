# TODO_SPRINT_NEXT — Konsolidasi Tahap 2 (DB Schema + Core Flow)

## Target
- Tambah/rapikan tabel untuk Coverage Area, Kategori Kerusakan, Status Pembayaran, dan log harga akhir.
- Sesuaikan core order/payment flow agar mendukung: DP → Kerjakan → Selesai → Pelunasan → Rating, plus persetujuan harga akhir oleh customer sebelum pelunasan.

## Step by step
1. [ ] Audit migrasi/tabel yang sudah ada: `orders`, `payments`, `provider_profiles`, `service_categories`, `provider_services`.
2. [ ] Rancang skema baru untuk:
   - wilayah: kota/kecamatan/kode_pos
   - kategori kerusakan: berat/sedang/ringan
   - status pembayaran: DP/lunas (atau status berjenjang)
   - log harga akhir: menyimpan perubahan harga akhir oleh provider + approval customer
3. [ ] Buat migrasi baru (atau migrasi penyesuaian) dan update seeders/test fixtures bila perlu.
4. [ ] Update model relasi + enum/status constants (order/payment).
5. [ ] Update controller/service untuk flow DP & Lunas.
6. [ ] Tambah test feature untuk persetujuan harga akhir dan status pembayaran.
7. [ ] Jalankan `php artisan test`.

## Exit Criteria
- Test suite tetap lulus.
- Endpoint order/payment bekerja sesuai flow pada SRS.

