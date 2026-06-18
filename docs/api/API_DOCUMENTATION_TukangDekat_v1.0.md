# API Documentation – TukangDekat (REST API)
Version 1.0  
Date: 2026-03-30

Dokumen ini mendefinisikan kontrak REST API untuk sistem TukangDekat (Backend Laravel, API-only).

## 1) Base URL
- Production (TBD): `https://api.example.com`
- Development (local): `http://localhost:8000`

## 2) Format Umum
- Request/response: JSON
- Auth: Bearer Token (JWT/Personal Access Token – implementasi dapat disesuaikan)
- Header yang digunakan:
  - `Content-Type: application/json`
  - `Authorization: Bearer <token>` (untuk endpoint yang butuh login)

## 3) Status Code Konvensi
- `200 OK` sukses
- `201 Created` data berhasil dibuat
- `400 Bad Request` request tidak valid
- `401 Unauthorized` token tidak ada/invalid
- `403 Forbidden` role tidak sesuai
- `404 Not Found` resource tidak ditemukan
- `422 Unprocessable Entity` validasi gagal
- `500 Internal Server Error` error server

## 4) Data Model Ringkas (Referensi)
- User: role = CUSTOMER | PROVIDER | ADMIN | TREASURER
- Order.status = CREATED | ACCEPTED | IN_PROGRESS | COMPLETED | CANCELLED | CLOSED
- Payment.payment_type = DP | FINAL
- Payment.status = UNPAID | PENDING | PAID | FAILED | EXPIRED

---

# 5) Endpoints

## 5.1 Authentication

### POST /api/auth/register
Registrasi user baru (customer atau provider).

**Request**
```json
{
  "name": "Fajar",
  "email": "fajar@mail.com",
  "phone": "08xxxx",
  "password": "secret123",
  "role": "CUSTOMER"
}
```

**Response 201**
```json
{
  "message": "registered",
  "data": {
    "user_id": 1,
    "role": "CUSTOMER"
  }
}
```

### POST /api/auth/login
Login dan mendapatkan token.

**Request**
```json
{
  "email": "fajar@mail.com",
  "password": "secret123"
}
```

**Response 200**
```json
{
  "message": "ok",
  "token": "BearerTokenHere",
  "user": {
    "id": 1,
    "name": "Fajar",
    "role": "CUSTOMER"
  }
}
```

### POST /api/auth/logout
Butuh token. Mengakhiri sesi (opsional, tergantung implementasi token).

**Response 200**
```json
{ "message": "logged_out" }
```

---

## 5.2 Service Catalog & Provider

### GET /api/categories
List kategori jasa.

**Response 200**
```json
{
  "data": [
    { "id": 1, "name": "Listrik", "is_active": true },
    { "id": 2, "name": "Plumbing", "is_active": true }
  ]
}
```

### GET /api/providers
Cari provider (filter opsional).

**Query Params (opsional)**
- `category_id`
- `q` (keyword nama/deskripsi)
- `is_verified=true|false`

**Response 200**
```json
{
  "data": [
    {
      "user_id": 10,
      "name": "Tukang A",
      "provider_profile": {
        "business_name": "Tukang A Service",
        "area": "Bojongloa Kaler",
        "is_verified": true,
        "avg_rating": 4.7
      }
    }
  ]
}
```

### GET /api/providers/{provider_user_id}
Detail provider.

**Response 200**
```json
{
  "data": {
    "user_id": 10,
    "name": "Tukang A",
    "provider_profile": {
      "business_name": "Tukang A Service",
      "description": "Spesialis listrik rumah",
      "address": "Bojongloa Kaler",
      "is_verified": true
    },
    "services": [
      {
        "id": 100,
        "category_id": 1,
        "name": "Perbaikan instalasi",
        "base_price": 150000,
        "price_unit": "per kunjungan",
        "is_active": true
      }
    ]
  }
}
```

### POST /api/provider/profile
**Role: PROVIDER**  
Buat/update profil provider.

**Request**
```json
{
  "business_name": "Tukang A Service",
  "description": "Spesialis listrik",
  "area": "Bojongloa Kaler",
  "address": "Jl. Contoh No. 1"
}
```

**Response 200**
```json
{ "message": "updated" }
```

### POST /api/provider/services
**Role: PROVIDER**  
Tambah layanan provider.

**Request**
```json
{
  "category_id": 1,
  "name": "Service listrik",
  "base_price": 150000,
  "price_unit": "per kunjungan"
}
```

**Response 201**
```json
{
  "message": "created",
  "data": { "service_id": 100 }
}
```

### PATCH /api/provider/services/{id}
**Role: PROVIDER**  
Update layanan provider.

---

## 5.3 Orders

### POST /api/orders
**Role: CUSTOMER**  
Buat order baru.

**Request**
```json
{
  "provider_user_id": 10,
  "category_id": 1,
  "provider_service_id": 100,
  "schedule_at": "2026-04-02T10:00:00+07:00",
  "address": "Jl. Pelanggan No. 2",
  "notes": "Lampu sering mati",
  "estimated_price": 300000
}
```

**Response 201**
```json
{
  "message": "created",
  "data": {
    "order": {
      "id": 501,
      "order_code": "ORD-20260330-0001",
      "status": "CREATED",
      "estimated_price": 300000
    },
    "dp_payment": {
      "id": 9001,
      "payment_type": "DP",
      "amount": 150000,
      "status": "UNPAID"
    }
  }
}
```

### GET /api/orders
List order milik user (customer/provider/admin). Filter opsional.

**Query Params (opsional)**
- `status`
- `date_from`, `date_to`

### GET /api/orders/{id}
Detail order.

### POST /api/orders/{id}/attachments
Upload bukti foto (opsional).
- multipart form-data (implementasi bisa disesuaikan)

### POST /api/orders/{id}/accept
**Role: PROVIDER**  
Menerima order.

**Response 200**
```json
{ "message": "accepted", "order_status": "ACCEPTED" }
```

### POST /api/orders/{id}/reject
**Role: PROVIDER**  
Menolak order.

**Response 200**
```json
{ "message": "rejected", "order_status": "CANCELLED" }
```

### POST /api/orders/{id}/start
**Role: PROVIDER**  
Mulai pengerjaan.
**Rule:** DP harus `PAID`.

**Response 200**
```json
{ "message": "started", "order_status": "IN_PROGRESS" }
```

### POST /api/orders/{id}/complete
**Role: PROVIDER**  
Selesaikan order + set final_price.

**Request**
```json
{ "final_price": 350000 }
```

**Response 200**
```json
{
  "message": "completed",
  "data": {
    "order_status": "COMPLETED",
    "final_payment": {
      "id": 9002,
      "payment_type": "FINAL",
      "amount": 200000,
      "status": "UNPAID"
    }
  }
}
```

### POST /api/orders/{id}/cancel
**Role: CUSTOMER (dan/atau ADMIN)**  
Batalkan order (aturan refund DP: TBD).

---

## 5.4 Payments (QRIS)

### POST /api/payments/{payment_id}/qris
Generate QRIS untuk DP atau FINAL.

**Response 200**
```json
{
  "message": "qris_created",
  "data": {
    "payment_id": 9001,
    "status": "PENDING",
    "qris": {
      "qr_url": "https://gateway.example/qris/...",
      "expiry_at": "2026-03-30T14:00:00+07:00"
    }
  }
}
```

### GET /api/payments/{payment_id}
Cek status pembayaran.

**Response 200**
```json
{
  "data": {
    "id": 9001,
    "payment_type": "DP",
    "amount": 150000,
    "status": "PAID",
    "paid_at": "2026-03-30T13:10:00+07:00"
  }
}
```

### POST /api/webhooks/payments
Webhook callback dari payment gateway.  
**No Auth Bearer**, tapi wajib verifikasi signature/secret.

**Contoh Payload (disederhanakan)**
```json
{
  "external_payment_id": "pg_123",
  "status": "PAID",
  "amount": 150000,
  "signature": "abc..."
}
```

**Response 200**
```json
{ "message": "ok" }
```

---

## 5.5 Notifications (via n8n)

### POST /api/integrations/n8n/events
Endpoint internal (opsional) untuk mengirim event ke n8n (atau backend langsung call webhook n8n).
Event yang direkomendasikan:
- `order_created`
- `order_accepted`
- `order_rejected`
- `dp_paid`
- `order_completed`
- `final_paid`

**Request**
```json
{
  "event_name": "dp_paid",
  "channel": "WA",
  "payload": {
    "order_id": 123,
    "payment_id": 456,
    "amount": 75000
  }
}
```

**Response 200**
```json
{
  "message": "event_dispatched",
  "data": {
    "event_name": "dp_paid",
    "channel": "WA",
    "status": "SENT",
    "id": 1
  }
}
```

---

## 5.6 Reviews

### POST /api/orders/{id}/review
**Role: CUSTOMER**  
Review setelah order `CLOSED`.

**Request**
```json
{
  "rating": 5,
  "comment": "Cepat dan rapih"
}
```

**Response 201**
```json
{ "message": "review_created" }
```

### GET /api/providers/{provider_user_id}/reviews
List review provider.

---

## 5.7 Admin & Treasurer

### POST /api/admin/providers/{provider_user_id}/verify
**Role: ADMIN**  
Verifikasi provider.

**Response 200**
```json
{ "message": "verified" }
```

### GET /api/treasurer/transactions
**Role: TREASURER**  
Lihat transaksi DP dan FINAL.

**Query Params (opsional)**
- `date_from`, `date_to`
- `payment_type=DP|FINAL`
- `status`

**Response 200**
```json
{
  "data": [
    {
      "payment_id": 9001,
      "order_id": 501,
      "payment_type": "DP",
      "amount": 150000,
      "status": "PAID",
      "paid_at": "2026-03-30T13:10:00+07:00"
    }
  ]
}
```

---

## 5.8 Chatbot (AI Customer Service)

### POST /api/chatbot/send
**Role: AUTHENTICATED (Customer/Provider/Admin)**  
Kirim pesan ke AI chatbot untuk mendapatkan bantuan customer service. Chatbot akan memberikan respons berdasarkan konteks pesanan terakhir user.

**Request**
```json
{
  "message": "Bagaimana cara membayar pesanan saya?"
}
```

**Request Headers**
```
Authorization: Bearer <token>
Content-Type: application/json
```

**Response 200 (Success)**
```json
{
  "success": true,
  "message": "Chatbot response received",
  "data": {
    "user_message": "Bagaimana cara membayar pesanan saya?",
    "assistant_message": "Untuk membayar pesanan Anda, ikuti langkah berikut: 1) Buka detail pesanan. 2) Klik tombol 'Bayar Sekarang'. 3) Pilih metode pembayaran QRIS. 4) Scan QR code dengan aplikasi banking Anda.",
    "order_context": "Pesanan terakhir Anda: kode ORD-20260618-0001, status ACCEPTED, alamat Jl. Contoh No. 5, harga estimasi Rp 300.000.",
    "raw_response": {
      "model": "gemini-1.0",
      "choices": [
        {
          "message": {
            "content": "Untuk membayar pesanan Anda, ikuti langkah berikut..."
          }
        }
      ]
    }
  }
}
```

**Response 400 (Validation Error)**
```json
{
  "success": false,
  "message": "Validation failed",
  "error_code": "VALIDATION_ERROR",
  "status_code": 422,
  "errors": {
    "message": [
      "Message is required."
    ]
  }
}
```

**Response 401 (Unauthorized)**
```json
{
  "success": false,
  "message": "Unauthorized",
  "error_code": "UNAUTHORIZED",
  "status_code": 401
}
```

**Response 500 (Gemini API Error)**
```json
{
  "success": false,
  "message": "Failed to contact Gemini API",
  "error_code": "GEMINI_API_ERROR",
  "status_code": 502,
  "details": {
    "status": 401,
    "response": {
      "error": "Invalid API key"
    }
  }
}
```

**Validasi Input**
- `message`: required, string, max 1000 karakter
- Throttle limit: 10 requests per 1 menit (rate limit)

**Fitur Chatbot**
- Sistem prompt: "Kamu adalah asisten Customer Service berpengalaman untuk platform TukangDekat, aplikasi pemesanan jasa lokal di Kecamatan Bojongloa Kaler. Bantu user dengan ramah jika menemui kendala transaksi."
- Context insertion: Data pesanan terakhir user (order_code, status, address, estimated_price) otomatis disertakan dalam request ke Gemini API.
- Fallback context: Jika user belum memiliki riwayat pesanan, sistem akan mengirim pesan default: "Tidak ada riwayat pesanan terakhir untuk pengguna ini."
- Max response tokens: 512

**Error Handling**
| Error Code | Status | Deskripsi |
|------------|--------|-----------|
| `VALIDATION_ERROR` | 422 | Input message tidak valid |
| `UNAUTHORIZED` | 401 | Token tidak ada atau invalid |
| `GEMINI_NOT_CONFIGURED` | 500 | Konfigurasi Gemini API belum diatur |
| `GEMINI_API_ERROR` | 502 | Gemini API request gagal |
| `GEMINI_RESPONSE_INVALID` | 502 | Respons Gemini dalam format tidak terduga |

---

# 6) Aturan Bisnis Penting (Enforced Rules)
1) Provider tidak boleh `start` order jika DP belum `PAID`.
2) Pelunasan hanya dibuat setelah order `COMPLETED` dan `final_price` diinput provider.
3) Order menjadi `CLOSED` hanya jika payment FINAL `PAID`.
4) Webhook payment harus diverifikasi signature/secret.

# 7) To Be Determined (TBD)
- Payment gateway final (Midtrans/Xendit)
- Format signature verification detail (mengikuti gateway pilihan)
- Refund policy DP
- SLA respon provider