<!-- markdownlint-disable -->

# Software Requirements Specification
for
**TukangDekat – Platform Pemesanan Jasa Lokal Kecamatan Bojongloa Kaler Berbasis Mobile & API**
Version 1.0 approved (UTS)
Prepared by **Nabila, Aldo, Tetep, Nabil, Fatin, Fazna, Elsa, Fajar**
Universitas Kebangsaan Republik Indonesia
2026-03-23

## Table of Contents
Revision History  
1. Introduction  
1.1 Purpose  
1.2 Document Conventions  
1.3 Intended Audience and Reading Suggestions  
1.4 Product Scope  
1.5 References  
2. Overall Description  
2.1 Product Perspective  
2.2 Product Functions  
2.3 User Classes and Characteristics  
2.4 Operating Environment  
2.5 Design and Implementation Constraints  
2.6 User Documentation  
2.7 Assumptions and Dependencies  
3. External Interface Requirements  
3.1 User Interfaces  
3.2 Hardware Interfaces  
3.3 Software Interfaces  
3.4 Communications Interfaces  
4. System Features  
5. Other Nonfunctional Requirements  
6. Other Requirements  
Appendix A: Glossary  
Appendix B: Analysis Models  
Appendix C: To Be Determined List  

---

## Revision History
| Name | Date | Reason For Changes | Version |
|---|---:|---|---:|
| Kelompok A1 | 2026-03-23 | Initial SRS for TukangDekat | 1.0 |

---

# 1. Introduction

## 1.1 Purpose
Dokumen ini menetapkan kebutuhan perangkat lunak untuk **TukangDekat**, sebuah sistem informasi yang menghubungkan warga/pelanggan dengan penyedia jasa lokal (tukang/teknisi) di **Kecamatan Bojongloa Kaler**. Sistem terdiri dari aplikasi mobile (Flutter) dan backend REST API (Laravel), dengan integrasi pembayaran QRIS untuk mekanisme DP dan pelunasan, serta notifikasi otomatis menggunakan n8n melalui WhatsApp dan email.

## 1.2 Document Conventions
- Kebutuhan fungsional diberi kode `FR-xx`.
- Kebutuhan nonfungsional diberi kode `NFR-xx`.
- Aturan bisnis diberi kode `BR-xx`.
- Prioritas: High, Medium, Low.
- Format tanggal: YYYY-MM-DD.

## 1.3 Intended Audience and Reading Suggestions
Dokumen ini ditujukan untuk:
- Dosen/penguji sebagai acuan evaluasi analisis dan desain.
- Tim pengembang sebagai acuan implementasi backend dan mobile.
- Tim pengujian sebagai acuan skenario uji.
Urutan baca disarankan: Bagian 1–2 (overview), Bagian 4 (fitur), Bagian 3 (interface), Bagian 5 (nonfungsional), lampiran (model).

## 1.4 Product Scope
TukangDekat bertujuan:
- mempermudah warga memperoleh jasa lokal yang relevan,
- meningkatkan kesempatan kerja dan pendapatan penyedia jasa lokal,
- menyediakan alur pemesanan dan pembayaran yang transparan,
- menyediakan riwayat transaksi dan status order secara real-time.

Kategori jasa yang difokuskan:
1) Listrik, 2) Plumbing, 3) AC, 4) Bangunan Ringan, 5) Servis Elektronik Rumah.

## 1.5 References
- Panduan Tugas Besar Rekayasa Sistem Informasi Kelas A1.
- Dokumentasi Laravel.
- Dokumentasi Flutter.
- Dokumentasi Docker dan Docker Compose.
- Dokumentasi n8n.
- Dokumentasi payment gateway pendukung QRIS (misal Midtrans/Xendit) dan webhook.

---

# 2. Overall Description

## 2.1 Product Perspective
Sistem ini menggantikan proses pemesanan jasa yang umumnya dilakukan manual (rekomendasi tetangga/WhatsApp) menjadi sistem terintegrasi yang mendukung pencarian penyedia jasa, pemesanan, pembayaran, notifikasi, dan pelaporan ringkas.

## 2.2 Product Functions
Fungsi utama sistem:
- registrasi dan login pengguna berbasis role,
- pengelolaan profil penyedia jasa dan verifikasi,
- pencarian dan pemilihan jasa,
- pembuatan order dan perubahan status,
- pembayaran DP 50% dan pelunasan 50% melalui QRIS,
- penerimaan notifikasi status pembayaran dari payment gateway,
- notifikasi otomatis WhatsApp/email via n8n,
- rating dan ulasan,
- monitoring transaksi oleh pengurus dan bendahara.

## 2.3 User Classes and Characteristics
- Customer (warga/pelanggan): memesan jasa, melakukan pembayaran, memberi rating.
- Provider (tukang/teknisi): menerima order, mengerjakan, memperbarui status order.
- Admin (pengurus): mengelola kategori, memverifikasi provider, memonitor aktivitas.
- Treasurer (bendahara): memonitor transaksi pembayaran, rekap pembayaran.

## 2.4 Operating Environment
- Mobile: Android (minimal versi 8+).
- Backend: server Linux/VPS.
- Database: MySQL atau PostgreSQL.
- Deployment backend menggunakan Docker dan Docker Compose.
- Komunikasi menggunakan HTTPS.

## 2.5 Design and Implementation Constraints
- Backend bersifat API-only.
- Backend (Laravel, web server, database) harus terisolasi dengan Docker.
- Mobile mengonsumsi API backend.
- Backend harus dapat dihosting (hosting backend saja).
- Sistem wajib terintegrasi dengan pembayaran QRIS serta notifikasi via n8n.

## 2.6 User Documentation
- Panduan penggunaan customer.
- Panduan penggunaan provider.
- Panduan admin dan bendahara.
- Dokumentasi API.

## 2.7 Assumptions and Dependencies
- Payment gateway menyediakan sandbox dan webhook callback.
- Pengiriman WhatsApp/email bergantung pada konfigurasi provider pada n8n.
- Kebijakan komisi platform dan refund akan ditentukan pada fase implementasi (TBD).

---

# 3. External Interface Requirements

## 3.1 User Interfaces
Minimal layar aplikasi:
- login/register,
- home + kategori,
- daftar provider + detail,
- form buat order (jadwal, alamat, catatan),
- detail order + status,
- halaman pembayaran (DP dan pelunasan),
- riwayat order,
- rating & ulasan,
- dashboard admin/bendahara (role-based).

## 3.2 Hardware Interfaces
Kamera perangkat dapat digunakan untuk unggah foto kerusakan (opsional).

## 3.3 Software Interfaces
- Mobile ↔ Backend REST API (JSON).
- Backend ↔ Database.
- Backend ↔ Payment gateway (QRIS + webhook callback).
- Backend ↔ n8n (webhook untuk trigger notifikasi).

## 3.4 Communications Interfaces
- HTTP/HTTPS dengan JSON payload.
- Mekanisme autentikasi token untuk mengakses API.
- Webhook endpoint untuk notifikasi pembayaran.

---

# 4. System Features

## 4.1 Authentication & Authorization
**Priority:** High  
- FR-01 Sistem menyediakan registrasi pengguna (customer/provider).  
- FR-02 Sistem menyediakan login dan token akses.  
- FR-03 Sistem menyediakan logout.  
- FR-04 Sistem menerapkan pembatasan akses berdasarkan role.

## 4.2 Provider Management
**Priority:** High  
- FR-05 Provider dapat membuat dan memperbarui profil.  
- FR-06 Admin dapat memverifikasi provider.  
- FR-07 Admin dapat menonaktifkan provider bila melanggar kebijakan.

## 4.3 Service Catalog & Search
**Priority:** High  
- FR-08 Sistem menyediakan kategori jasa dan daftar provider per kategori.  
- FR-09 Customer dapat mencari provider berdasarkan kategori dan kata kunci.  
- FR-10 Sistem menampilkan detail provider dan layanan yang tersedia.

## 4.4 Order Lifecycle
**Priority:** High  
- FR-11 Customer dapat membuat order (provider, jadwal, alamat, catatan, foto opsional).  
- FR-12 Provider dapat menerima atau menolak order.  
- FR-13 Sistem menyimpan status order: CREATED, ACCEPTED, IN_PROGRESS, COMPLETED, CANCELLED, CLOSED.  
- FR-14 Provider dapat memulai pengerjaan (IN_PROGRESS) hanya jika DP sudah dibayar.

## 4.5 Payment (DP & Final) via QRIS
**Priority:** High  
- FR-15 Sistem membuat tagihan DP sebesar 50% dari estimasi biaya saat order dibuat.  
- FR-16 Sistem menghasilkan QRIS untuk pembayaran DP.  
- FR-17 Sistem menerima webhook callback pembayaran dari payment gateway dan memperbarui status DP.  
- FR-18 Setelah order COMPLETED dan final_price ditetapkan, sistem membuat tagihan pelunasan sebesar (final_price - dp_amount).  
- FR-19 Sistem menghasilkan QRIS untuk pembayaran pelunasan.  
- FR-20 Sistem menutup order (CLOSED) ketika pelunasan berhasil dibayar.

## 4.6 Notifications
**Priority:** Medium  
- FR-21 Sistem mengirim event notifikasi ke n8n saat: order dibuat, order diterima/ditolak, DP paid, order completed, final paid.  
- FR-22 Sistem mengirim notifikasi ke customer/provider melalui WhatsApp dan email (melalui n8n).

## 4.7 Rating & Review
**Priority:** Medium  
- FR-23 Customer dapat memberi rating dan ulasan setelah order selesai.  
- FR-24 Sistem menghitung rating rata-rata provider.

## 4.8 Treasurer Monitoring
**Priority:** Medium  
- FR-25 Bendahara dapat melihat daftar transaksi DP dan pelunasan.  
- FR-26 Bendahara dapat melihat ringkasan transaksi berdasarkan rentang tanggal.

---

# 5. Other Nonfunctional Requirements

## 5.1 Performance Requirements
- NFR-01 Respons API endpoint umum < 1 detik pada kondisi normal.
- NFR-02 Sistem mendukung minimal 100 order/hari (skala tugas besar).

## 5.2 Safety Requirements
- NFR-03 Sistem menyimpan jejak perubahan status order dan event pembayaran untuk audit.

## 5.3 Security Requirements
- NFR-04 Semua komunikasi menggunakan HTTPS.
- NFR-05 Password disimpan dengan hashing yang aman.
- NFR-06 Webhook payment gateway diverifikasi menggunakan secret/signature.
- NFR-07 Pembatasan akses endpoint berdasarkan role.

## 5.4 Software Quality Attributes
- NFR-08 Maintainability: modul terpisah (auth, catalog, orders, payments, notifications).
- NFR-09 Reliability: transaksi pembayaran menggunakan database transaction.
- NFR-10 Usability: proses pemesanan dapat dilakukan dengan langkah yang sederhana.

## 5.5 Business Rules
- BR-01 DP sebesar 50% dari estimasi biaya.
- BR-02 Provider hanya dapat memulai pengerjaan setelah DP dibayar.
- BR-03 Pelunasan dilakukan setelah order selesai.
- BR-04 Komisi platform dan refund policy: TBD.

---

# 6. Other Requirements
- Export laporan transaksi (opsional).
- SLA respon provider (opsional/TBD).

---

## Appendix A: Glossary
- Customer: pelanggan
- Provider: penyedia jasa
- Order: pemesanan jasa
- DP: uang muka
- QRIS: QR pembayaran
- Webhook: endpoint callback pembayaran

## Appendix B: Analysis Models
- Class Diagram
- Sequence Diagram
- Component Diagram
- Deployment Diagram
- API Contract (lampiran)

## Appendix C: To Be Determined List
1. Payment gateway final yang digunakan (rencana: Midtrans sandbox).
2. Komisi platform dan settlement ke provider.
3. Refund policy DP bila pembatalan.