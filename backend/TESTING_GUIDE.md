# Panduan Testing Review Rating API

Dokumen ini menjelaskan cara menjalankan dan melakukan testing untuk API Review Rating pada proyek PM UAS Rekayasa Sistem Informasi.

## Prasyarat

Pastikan Anda telah:
1. Menginstal Docker dan Docker Compose
2. Memiliki file `.env` yang dikonfigurasi dengan benar
3. Menjalankan semua service melalui Docker Compose (`docker compose up -d`)

## Struktur Testing

Testing dilakukan menggunakan PHP Unit dan Laravel Testing Framework. File test terletak di:
```
tests/Feature/ReviewRatingApiTest.php
```

## Menjalankan Test

### 1. Menjalankan Semua Test Review Rating

Jalankan perintah berikut dari direktori backend:

```bash
cd backend
docker compose exec pm_uas_app php artisan test --filter=ReviewRatingApiTest
```

Atau dari root project:

```bash
docker compose -f backend/docker-compose.yml exec pm_uas_app php artisan test --filter=ReviewRatingApiTest
```

### 2. Menjalankan Test Tertentu

Untuk menjalankan test khusus `customer_can_create_review_for_completed_order_and_provider_avg_rating_updates`:

```bash
docker exec pm_uas_app php artisan test --filter=customer_can_create_review_for_completed_order_and_provider_avg_rating_updates
```

Untuk menjalankan test `get_provider_review_summary_returns_correct_rating_distribution`:

```bash
docker exec pm_uas_app php artisan test --filter=get_provider_review_summary_returns_correct_rating_distribution
```

### 3. Menjalankan Semua Test dengan Verbose Output

Untuk melihat output yang lebih detail:

```bash
docker exec pm_uas_app php artisan test tests/Feature/ReviewRatingApiTest.php --verbose
```

### 4. Menjalankan Test dengan Coverage Report

Untuk melihat code coverage:

```bash
docker exec pm_uas_app php artisan test tests/Feature/ReviewRatingApiTest.php --coverage
```

## Deskripsi Test Cases

### Test 1: Customer Dapat Membuat Review untuk Order yang Selesai

**File:** `tests/Feature/ReviewRatingApiTest.php::test_customer_can_create_review_for_completed_order_and_provider_avg_rating_updates`

**Deskripsi:**
Test ini memverifikasi bahwa customer dapat membuat review untuk order yang telah selesai, dan rating rata-rata provider akan diupdate secara otomatis.

**Endpoint yang Diuji:**
```
POST /api/orders/{orderId}/review
```

**Data yang Dikirim:**
```json
{
  "rating": 5,
  "comment": "Great work"
}
```

**Validasi:**
- Response status: 201 (Created)
- Rating yang disimpan: 5
- Komentar yang disimpan: "Great work"
- Rating rata-rata provider diupdate menjadi 5.0

**Kriteria Berhasil:**
✓ Review berhasil dibuat
✓ Rating tersimpan di database
✓ Provider profile diupdate dengan rating rata-rata

---

### Test 2: Dapatkan Ringkasan Review Provider dengan Distribusi Rating Benar

**File:** `tests/Feature/ReviewRatingApiTest.php::test_get_provider_review_summary_returns_correct_rating_distribution`

**Deskripsi:**
Test ini memverifikasi bahwa API dapat mengembalikan ringkasan rating provider dengan distribusi rating yang benar.

**Endpoint yang Diuji:**
```
GET /api/reviews/provider/{providerId}/summary
```

**Data Setup Test:**
- Membuat 3 order yang selesai untuk 1 provider
- Rating yang diberikan: 5, 4, dan 3

**Response yang Diharapkan:**
```json
{
  "data": {
    "provider_id": 4,
    "average_rating": 4.0,
    "total_reviews": 3,
    "distribution": {
      "5": 1,
      "4": 1,
      "3": 1,
      "2": 0,
      "1": 0
    }
  }
}
```

**Validasi:**
- Response status: 200 (OK)
- Provider ID: integer (type strict)
- Average rating: 4.0 (float dengan decimal)
- Total reviews: 3
- Distribusi rating correct untuk setiap level

**Kriteria Berhasil:**
✓ Menampilkan provider_id sebagai integer
✓ Menampilkan average_rating sebagai float (4.0, bukan 4)
✓ Menampilkan total_reviews dengan benar
✓ Menampilkan distribusi rating untuk setiap level (1-5)

## Endpoint API yang Diuji

### 1. Create Review
- **Method:** POST
 - **Endpoint:** `/api/orders/{orderId}/review`
- **Autentikasi:** Sanctum (Customer)
- **Request Body:**
  ```json
  {
    "rating": 1-5,
    "comment": "string|nullable"
  }
  ```
- **Response:** 
  - Status: 201
  - Data: Review yang dibuat

### 2. Get Provider Review Summary
- **Method:** GET
- **Endpoint:** `/api/reviews/provider/{providerId}/summary`
- **Autentikasi:** Sanctum (Customer)
- **Response:**
  - Status: 200
  - Data: Ringkasan rating dan distribusi

## Debugging Test

### Jika Test Gagal

1. **Cek Log Container:**
   ```bash
   docker compose logs pm_uas_app
   ```

2. **Cek Database:**
   ```bash
   docker compose exec pm_uas_db mysql -ularavel -psecret laravel -e "SELECT * FROM reviews;"
   ```

3. **Jalankan Migrasi Ulang:**
   ```bash
   docker exec pm_uas_app php artisan migrate:refresh
   ```

4. **Cek Response yang Dikembalikan:**
   Tambahkan `dd($response->json())` di test untuk melihat response lengkap

### Kasus Umum dan Solusi

**Kasus:** Test gagal dengan pesan "service not running"
**Solusi:** 
```bash
cd backend
docker compose up -d
```

**Kasus:** Database error saat running test
**Solusi:**
```bash
docker exec pm_uas_app php artisan migrate:refresh --seed
```

**Kasus:** Review sudah ada untuk order tertentu
**Solusi:** Test menggunakan database transaction, jadi setiap test dimulai dari state bersih. Jika masalah persisten, jalankan:
```bash
docker compose down -v
docker compose up -d
```

## Controller yang Diuji

File: `app/Http/Controllers/Api/ReviewController.php`

**Method yang Diuji:**
1. `createReview($request, $orderId)` - Membuat review baru
2. `getProviderReviewSummary($providerId)` - Mendapatkan ringkasan rating provider

**Fitur Utama:**
- Validasi customer hanya bisa membuat review
- Validasi order harus selesai (status COMPLETED atau CLOSED)
- Prevent duplicate review untuk satu order
- Auto-update rating rata-rata provider
- Hitung distribusi rating per level (1-5)
- Return tipe data yang strict (integer dan float)

## Format JSON Response

### Create Review Response
```json
{
  "message": "review created",
  "data": {
    "order_id": 1,
    "customer_id": 1,
    "provider_id": 2,
    "rating": 5,
    "comment": "Great work",
    "created_at": "2026-06-07T19:41:23.000000Z",
    "updated_at": "2026-06-07T19:41:23.000000Z"
  }
}
```

### Get Provider Summary Response
```json
{
  "data": {
    "provider_id": 2,
    "average_rating": 4.0,
    "total_reviews": 3,
    "distribution": {
      "5": 1,
      "4": 1,
      "3": 1,
      "2": 0,
      "1": 0
    }
  }
}
```

## Best Practices Testing

1. **Selalu Gunakan RefreshDatabase Trait**
   - Setiap test berjalan dengan database state bersih
   - Tidak ada data sisa dari test sebelumnya

2. **Gunakan Factory untuk Data Setup**
   - Membuat user, order, dan data lain dengan factory
   - Lebih maintainable dan readable

3. **Validasi Seluruh Aspek**
   - Response status
   - Response body
   - Database state
   - Side effects (misalnya update provider rating)

4. **Gunakan Descriptive Test Names**
   - Test name harus menjelaskan apa yang diuji
   - Gunakan format: `test_<action>_<condition>_<expected_result>`

## Troubleshooting Common Issues

| Masalah | Penyebab | Solusi |
|---------|---------|--------|
| Type error pada integer/float | JSON encoder tidak preserve .0 | Gunakan `JSON_PRESERVE_ZERO_FRACTION` flag |
| Review duplicate | Validation tidak berjalan | Cek middleware dan validation di controller |
| Provider rating tidak update | Query aggregation error | Verify aggregate query di database |
| Test timeout | Database query lambat | Tambah index atau optimize query |

## Referensi

- Laravel Testing Documentation: https://laravel.com/docs/11.x/testing
- Laravel HTTP Tests: https://laravel.com/docs/11.x/http-tests
- PHP Unit Documentation: https://phpunit.de/

---

**Last Updated:** 2026-06-07  
**Status:** ✓ All Tests Passing
