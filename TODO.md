# TODO - Finalisasi & Hardening AP (feature/backend-api-hardening)

## Checklist (prioritas)

### 1) Webhook security & idempotency + transaksi
- [x] Update `PaymentGatewayService@verifyWebhook()` menjadi fail-closed (webhook_secret kosong => reject) untuk driver non-midtrans.
- [ ] Tambah idempotency guard untuk webhook replay (prefer simpan last_external_transaction_id/processed markers di `payments`).
- [ ] Bungkus logic multi-write di `PaymentController@webhookPaymentCallback` dengan `DB::transaction()` dan hanya apply settlement/close order saat transisi status relevan (non-PAID -> PAID).


### 2) State transition guards & transaksi di Order flow
- [ ] Tambah guard status pada `OrderController@respondToOrder/startWork/completeOrder` (mis. respon hanya sekali, startWork hanya dari ACCEPTED, completeOrder hanya dari IN_PROGRESS).
- [ ] Bungkus multi-write di `createOrder`, `respondToOrder` (refund updates), dan `completeOrder` dengan `DB::transaction()`.
- [ ] Hardening perhitungan final amount di `completeOrder` (hindari null dereference).

### 3) Rate limiting & abuse protection
- [ ] Tambah throttle konsisten ke endpoint yang rawan abuse (generateQRIS, createReview, getPaymentStatus bila perlu).
- [ ] Verifikasi konfigurasi throttle agar tidak mengganggu gateway webhook.

### 4) Export safety (Treasurer)
- [ ] Hardening export csv/xls: batasi jumlah baris atau implement chunked/stream export untuk menghindari memory blow.
- [ ] Pastikan sanitasi XML untuk XLS tetap konsisten.

### 5) Testing & verification
- [ ] Tambah/extend tests untuk webhook invalid signature + replay idempotency.
- [ ] Jalankan `php artisan test` dan perbaiki yang gagal.

