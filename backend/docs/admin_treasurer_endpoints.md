# Admin & Treasurer API Endpoints

## 1. Admin: Verifikasi Provider

### Endpoint
- `POST /api/admin/providers/{providerId}/verify`
- `PATCH /api/admin/providers/{providerId}/verification`

### Middleware
- `auth:sanctum`
- `EnsureRole:ADMIN`

### Request Body
- `is_verified` (boolean, required)

### Example Request
```json
{
  "is_verified": true
}
```

### Response
```json
{
  "success": true,
  "message": "verification updated",
  "data": {
    "provider": {
      "id": 1,
      "user_id": 5,
      "business_name": "Provider Example",
      "area": "Jakarta",
      "is_verified": true
    }
  }
}
```

### Notes
- Endpoint `POST /api/admin/providers/{providerId}/verify` adalah alias yang memanggil metode yang sama dengan `PATCH /api/admin/providers/{providerId}/verification`.
- Properti `is_verified` menentukan apakah provider berhasil diverifikasi.

---

## 2. Treasurer: Laporan Pembayaran

### Endpoint
- `GET /api/treasurer/payments/report`
- `GET /api/treasurer/transactions`

### Middleware
- `auth:sanctum`
- `EnsureRole:TREASURER`

### Query Parameters
- `start_date` (YYYY-MM-DD, optional)
- `end_date` (YYYY-MM-DD, optional)
- `status` (optional, one of `UNPAID,PENDING,PAID,FAILED,EXPIRED`)
- `payment_type` (optional, one of `DP,FINAL`)
- `order_id` (optional, integer)
- `provider_id` (optional, integer)
- `per_page` (optional, integer, 1..100)
- `export` (optional, `csv`, `xls`, atau `excel`)

### Example Request
`GET /api/treasurer/payments/report?status=PAID&payment_type=FINAL&per_page=50`

### Response Structure
```json
{
  "success": true,
  "message": "ok",
  "data": {
    "payments": [
      {
        "id": 123,
        "order_id": 456,
        "payment_type": "FINAL",
        "status": "PAID",
        "amount": 150000,
        "platform_fee": 15000,
        "provider_payout": 135000,
        "refund_amount": null,
        "refund_status": null,
        "payment_reference": "INV-20260615-0001",
        "created_at": "2026-06-15T10:00:00.000000Z",
        "updated_at": "2026-06-15T10:00:00.000000Z"
      }
    ],
    "summary": {
      "total_payments": 10,
      "total_amount": 1000000,
      "total_paid_amount": 750000,
      "total_platform_fee": 75000,
      "total_provider_payout": 675000,
      "total_refund_amount": 0
    },
    "breakdown": {
      "by_status": [
        { "status": "PAID", "total": 5, "amount": 500000 }
      ],
      "by_type": [
        { "payment_type": "DP", "total": 3, "amount": 150000 }
      ]
    },
    "meta": {
      "current_page": 1,
      "last_page": 1,
      "per_page": 20,
      "total": 10
    },
    "filters": {
      "start_date": null,
      "end_date": null,
      "status": "PAID",
      "payment_type": "FINAL",
      "order_id": null,
      "provider_id": null
    }
  }
}
```

### Export
- `GET /api/treasurer/payments/report?export=csv`
- `GET /api/treasurer/payments/report?export=xls`
- `GET /api/treasurer/transactions?export=csv`

### Notes
- Export CSV/XLS mengabaikan paginasi dan mengekspor semua hasil yang cocok filter.
- `payments/report` dan `transactions` adalah alias yang sama, sehingga board dapat menggunakan salah satu.
