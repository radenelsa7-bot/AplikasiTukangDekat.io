PS C:\UAS\PM_UAS_rekayasa_Sistem_Informasi\mobile> flutter run
Launching lib\main.dart on M2003J15SC in debug mode...
lib/features/home/order_detail_page.dart:1930:23: Error: The argument type 'Uint8List?' can't be assigned to the parameter type 'Uint8List'.
 - 'Uint8List' is from 'dart:typed_data'.
                      paymentProofBytes,
                      ^
Target kernel_snapshot_program failed: Exception


FAILURE: Build failed with an exception.

* What went wrong:
Execution failed for task ':app:compileFlutterBuildDebug'.
> Process 'command 'C:\Users\Hype\flutter\bin\flutter.bat'' finished with non-zero exit value 1

* Try:
> Run with --stacktrace option to get the stack trace.
> Run with --info or --debug option to get more log output.
> Run with --scan to get full insights.
> Get more help at https://help.gradle.org.

BUILD FAILED in 24s
Running Gradle task 'assembleDebug'...                             25.1s
Error: Gradle task assembleDebug failed with exit code 1# Laporan Hasil Testing

## Informasi eksekusi

| Item | Nilai |
| --- | --- |
| Tanggal | 15 Juli 2026 |
| Branch | `testing-final-qa-2026-07-15` |
| Lingkungan | Workspace lokal Windows / PowerShell |
| Kesimpulan | **Belum layak rilis** |

## Ringkasan hasil

| ID | Area | Cara uji | Hasil | Status |
| --- | --- | --- | --- | --- |
| AT-01 | Analisis Flutter | `flutter analyze` | Proses tidak selesai dan tidak menghasilkan output; proses Dart dihentikan setelah macet. | TERBLOKIR |
| AT-02 | Test Flutter | `flutter test` | Proses tidak selesai dan tidak menghasilkan output; proses Dart dihentikan setelah macet. | TERBLOKIR |
| AT-03 | Test Laravel | `php artisan test` | **77 lulus, 5 skipped, 2 risky; 280 assertions; 7,24 detik.** | LULUS |
| AT-04 | E2E treasurer export | `npm test` | Percobaan pertama: Playwright gagal spawn worker (`EPERM`). Percobaan dengan izin proses lokal berjalan tetapi melewati batas waktu 30 detik. | GAGAL |
| MT-01 | Landing & login mobile | Perangkat Android fisik (`a4f890430503`) | Landing page tampil dan tombol **Mulai Sekarang** membuka formulir login. APK debug baru berhasil dibangun dan dipasang dengan `API_BASE_URL=http://192.168.1.7:8000`; server backend belum dijalankan pada alamat tersebut. | SEBAGIAN / TERBLOKIR |
| MT-02 | Katalog & dashboard admin | Perangkat Android fisik + API | Belum dapat dibuka karena login membutuhkan koneksi API; sesi pelanggan/admin belum tersedia. | TERBLOKIR |
| IT-01 | Alur pesanan & pembayaran | API + aplikasi + gateway sandbox | Belum dijalankan; memerlukan database test dan kredensial gateway sandbox. | BELUM DIUJI |
| ST-01 | Otorisasi role | Feature test + API | Tidak dapat dinilai: feature test berhenti pada koneksi database. | TERBLOKIR |

## Temuan utama

### FIX-01 — Error `No Material widget found` pada halaman Pesanan

- **Status:** Diperbaiki, menunggu retest perangkat.
- **Gejala:** Setelah pelanggan membuat pesanan dan daftar pesanan dimuat ulang, layar menampilkan error merah `No Material widget found` dari `_InkResponseStateWidget`.
- **Akar masalah:** Tombol filter `Semua` pada header `MyOrdersPage` memakai `InkWell` tanpa leluhur `Material`.
- **Perbaikan:** Tambahkan `Material(color: Colors.transparent)` yang membungkus `InkWell` pada `mobile/lib/features/home/my_orders_page.dart`.
- **Verifikasi build:** APK debug baru berhasil dibangun (120,004,110 byte) dan dipasang ke perangkat Android pada 15 Juli 2026.
- **Retest yang diperlukan:** Buat pesanan sebagai pelanggan, buka tab Pesanan, lalu ketuk filter `Semua`; halaman harus tampil normal dan bottom sheet filter harus terbuka.

### FIX-02 — Filter pesanan kosong tidak menyediakan jalan kembali

- **Status:** Diperbaiki, menunggu retest perangkat.
- **Gejala:** Memilih filter yang tidak memiliki data membuat halaman hanya menampilkan pesan kosong; pengguna tidak dapat mengganti atau menghapus filter dari halaman tersebut.
- **Akar masalah:** Filter membandingkan satu status secara persis, sedangkan status order aktif tidak memiliki nilai `PENDING`. Selain itu, empty state tidak menyediakan aksi filter.
- **Perbaikan:** Tambahkan filter gabungan **Belum selesai** untuk `CREATED`, `ACCEPTED`, `IN_PROGRESS`, dan `COMPLETED`; perjelas label status; tambahkan tombol **Ubah Filter** dan **Tampilkan Semua Pesanan** pada empty state.
- **Verifikasi build:** APK debug baru berhasil dibangun (190,805,616 byte) dan dipasang ke perangkat Android pada 15 Juli 2026.
- **Retest yang diperlukan:** Pilih **Belum selesai**, **Menunggu konfirmasi**, dan status lain. Jika tidak ada data, gunakan **Tampilkan Semua Pesanan** atau **Ubah Filter**; pengguna harus selalu dapat kembali ke daftar lengkap.

### FIX-03 — Bottom sheet filter mengalami overflow pada layar kecil

- **Status:** Diperbaiki pada kode, menunggu build dan retest perangkat.
- **Gejala:** Membuka filter pesanan pada perangkat tertentu menampilkan `Bottom overflowed` karena daftar opsi lebih tinggi daripada batas default bottom sheet.
- **Perbaikan:** Bottom sheet filter diubah menjadi `DraggableScrollableSheet` dengan `ListView`, batas tinggi 35–90% layar, dan `isScrollControlled: true`. Opsi akan dapat digulir pada layar kecil serta tetap proporsional pada layar besar.
- **Catatan responsif:** Aplikasi sudah menggunakan `ScreenUtilInit` secara global; perbaikan ini memastikan konten vertikal yang dinamis juga dapat scroll, bukan hanya diskalakan.
- **Retest yang diperlukan:** Buka filter dalam orientasi portrait dan landscape. Geser daftar opsi sampai bawah; tidak boleh ada garis/indikator overflow dan setiap opsi harus tetap dapat dipilih.

### FIX-04 — Konfirmasi pembayaran DP gagal dan belum memiliki bukti pembayaran

- **Status:** Diperbaiki pada backend dan mobile, menunggu build/retest perangkat.
- **Perbaikan backend:** Endpoint konfirmasi kini memverifikasi akses pemilik order, mewajibkan file gambar bukti pembayaran (JPG, JPEG, PNG, atau WebP; maksimal 5 MB), dan menyimpan path serta waktu unggah pada payment.
- **Perbaikan mobile:** Dialog QRIS menyediakan pemilih screenshot dari galeri, preview bukti, dan memblokir tombol **Sudah Dibayar** hingga bukti dipilih. Bukti dikirim sebagai multipart ke endpoint konfirmasi.
- **Verifikasi otomatis:** `php artisan test tests/Feature/PaymentStepFlowTest.php` lulus — 1 test, 19 assertions.
- **Retest yang diperlukan:** Bayar DP, pilih screenshot bukti dari galeri, tekan **Sudah Dibayar**, dan pastikan notifikasi sukses muncul. Coba tanpa gambar; aplikasi harus meminta bukti, bukan mengirim konfirmasi.

### RES-01 — Konfigurasi database testing backend telah diperbaiki

- **Status:** Selesai
- **Perbaikan:** `.env.testing` dan `phpunit.xml` memakai SQLite in-memory. Migrasi enum MySQL diberi guard driver agar tidak dijalankan pada SQLite. `ProviderCoverageFactory` ditambahkan untuk test alur pembayaran.
- **Bukti:** `php artisan test` selesai dengan 77 test lulus, 5 skipped, dan 2 risky (280 assertions).

### BLK-01 — Flutter CLI tidak menyelesaikan analisis maupun test

- **Severity:** Blocker untuk verifikasi mobile otomatis
- **Bukti:** `flutter analyze` dan `flutter test` tidak menghasilkan output dan tidak selesai; proses Dart berjalan terus lalu dihentikan agar tidak mengunci sesi pengujian.
- **Dampak:** Tidak ada bukti lulus/gagal untuk kode Flutter. Test yang tersedia saat ini hanya `mobile/test/widget_test.dart` dengan skenario build aplikasi.
- **Tindak lanjut:** Jalankan ulang satu per satu dari terminal lokal/IDE, pastikan `flutter doctor` sehat dan dependency/cache tersedia. Setelah CLI normal, tambahkan test untuk login, katalog, form pesanan, dan navigasi dashboard admin.

### BLK-02 — E2E laporan treasurer belum dapat dieksekusi hingga selesai

- **Severity:** High
- **Bukti:** Playwright mula-mula gagal `spawn EPERM`; setelah diberi izin proses lokal, skenario berjalan tetapi melewati batas waktu 30 detik. Dokumentasi E2E mensyaratkan API aktif dan `TEST_TOKEN` pengguna `TREASURER`.
- **Tindak lanjut:** Jalankan backend test server, buat token dengan `php artisan test:make-token --save`, pastikan `PLAYWRIGHT_BASE_URL` dan `TEST_TOKEN` benar, lalu jalankan `npm test` dari `backend/e2e`.

### BLK-03 — Server API development belum berjalan untuk uji perangkat

- **Severity:** High
- **Bukti:** Perangkat fisik `a4f890430503` terdeteksi dan aplikasi `com.example.mobile` dapat dibuka. Landing page serta formulir login tampil. Wi-Fi tersambung ke jaringan `192.168.1.0/24` dengan IP perangkat `192.168.1.17`. Konfigurasi mobile diperbarui ke `API_BASE_URL=http://192.168.1.7:8000`, APK debug baru (190,806,247 byte) berhasil dibangun dan dipasang, tetapi server backend belum berjalan pada host tersebut.
- **Dampak:** Login, katalog, pesanan, dashboard admin, dan seluruh skenario yang membutuhkan API belum dapat divalidasi pada perangkat.
- **Tindak lanjut:** Jalankan `php artisan serve --host=0.0.0.0 --port=8000` dari folder `backend`, pastikan firewall mengizinkan port 8000, lalu login dengan akun test dan lanjutkan skenario katalog/admin/pesanan.

## Rencana uji manual setelah blocker ditutup

1. Jalankan `flutter analyze`, `flutter test`, dan `php artisan test`; simpan output hasilnya.
2. Dengan akun pelanggan, buat pesanan dan pastikan pesanan langsung muncul tanpa refresh manual.
3. Dengan akun provider, terima pesanan, pastikan mulai kerja ditolak sebelum DP `PAID`, lalu selesaikan pekerjaan setelah pembayaran test.
4. Dengan akun admin, buka dashboard, cek statistik, setiap menu (Provider, Kategori, Pengguna, Pesanan, Transaksi, Laporan), dan logout.
5. Dengan akun pelanggan berbeda, verifikasi katalog/pesanan tidak menampilkan data milik pengguna lain.
6. Uji kondisi error: internet mati, API mengembalikan error, input invalid, izin lokasi ditolak, dan upload gambar invalid.
7. Uji webhook pembayaran pada sandbox: signature valid mengubah status; signature invalid ditolak.

## Kriteria kelulusan sebelum rilis

- Seluruh automated test lulus atau setiap pengecualian memiliki persetujuan tertulis.
- Tidak ada bug blocker/critical terbuka pada autentikasi, otorisasi, pesanan, atau pembayaran.
- Semua skenario manual prioritas tinggi berstatus lulus dan memiliki bukti screenshot/log.
- E2E ekspor treasurer dan smoke test staging lulus.
