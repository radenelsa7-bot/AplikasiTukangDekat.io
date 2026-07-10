# CHANGELOG_IMPLEMENTATION_2 — Tahap 2 (Core DP/Lunas) 

## Persetujuan Harga Akhir sebelum FINAL Payment

a) DB
- Tambah migrasi `final_price_approvals` untuk menyimpan proposed final price dan status approval customer.

b) Backend flow
- `OrderController@completeOrder`:
  - tidak lagi membuat `Payment` bertipe `FINAL` secara langsung
  - membuat/refresh record `FinalPriceApproval` dengan status `PENDING`

- `PaymentController@confirmPayment`:
  - menolak `payment_type=FINAL` (HTTP 409) jika approval customer belum `APPROVED`.

c) API
- Tambah endpoint (role customer):
  - `POST /api/orders/{orderId}/final-price/approve`
  - handler ada di `OrderFinalPriceController@decide`
  - approve: membuat `Payment FINAL` bila belum ada
  - reject: mengubah approval status menjadi `REJECTED`

## Test
- `php artisan test` tetap lulus (73 passed; 2 risky, 2 skipped).

