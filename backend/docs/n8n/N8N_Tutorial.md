# N8N Tutorial - Setup WhatsApp & Gmail Notifications

Tutorial lengkap step-by-step untuk mengatur n8n guna mengirim notifikasi WhatsApp dan Email untuk TukangDekat.

---

## Daftar Isi

1. [Prerequisites](#prerequisites)
2. [Setup WhatsApp Notifications (Wablas)](#setup-whatsapp-notifications-wablas)
3. [Setup Email Notifications (Gmail)](#setup-email-notifications-gmail)
4. [Import Workflows ke n8n](#import-workflows-ke-n8n)
5. [Testing](#testing)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Sistem Requirements
- Docker & Docker Compose sudah running
- n8n container aktif: `tukangdekat_n8n` (port 5678)
- PostgreSQL/MySQL database running
- Backend Laravel sudah siap dan berjalan

### Accounts yang Dibutuhkan
1. **Wablas Account** (untuk WhatsApp)
   - Daftar di https://wablas.com
   - Dapatkan API Key
   
2. **Gmail Account** (untuk Email)
   - Akun Gmail aktif atau Google Workspace
   - 2FA (Two-Factor Authentication) enabled untuk keamanan

### Verifikasi Status n8n

```bash
# Cek n8n container running
docker ps | grep n8n

# Output example:
# abc123def456  docker.n8n.io/n8nio/n8n  "npm run start"  5 minutes ago  Up 5 minutes  0.0.0.0:5678->5678/tcp  tukangdekat_n8n
```

Jika tidak running, jalankan:
```bash
docker-compose up -d n8n
```

Buka browser: `http://localhost:5678` - seharusnya muncul n8n dashboard

---

## Setup WhatsApp Notifications (Wablas)

### Step 1: Daftar dan Dapatkan Wablas API Key

**1.1 Kunjungi Wablas**
- Buka https://wablas.com
- Klik "Get Started" atau "Sign Up"

**1.2 Isi Form Registrasi**
- Email: Gunakan email kantor/bisnis
- Password: Buat password kuat (min 8 karakter, mix uppercase/lowercase/number)
- Company Name: "TukangDekat"
- Klik "Register"

**1.3 Verifikasi Email**
- Cek email inbox (bisa masuk spam folder)
- Klik link verifikasi dari Wablas
- Email terverifikasi ✓

**1.4 Login ke Dashboard Wablas**
- URL: https://wablas.com/dashboard
- Email + Password

**1.5 Setup WhatsApp Channel**
- Di sidebar kiri, cari menu "Integration" atau "Channel"
- Klik "Add Channel" → pilih "WhatsApp"
- Scan QR code dengan WhatsApp pribadi Anda (akan jadi admin channel)
- Tunggu approval (biasanya instant)
- Channel status berubah menjadi "Connected" ✓

**1.6 Generate API Key**
- Buka menu "Settings" → "API Keys"
- Klik "Generate New Key"
- Nama: `TukangDekat-n8n`
- Copy API Key (panjang string: `wbl_xxx...`)
- Simpan di tempat aman (jangan share!)

> **Contoh API Key:** `wbl_20e8a2e2f4c5b3a1d9e8f7c6b5a4d3e2`

---

### Step 2: Setup Wablas Credential di n8n

**2.1 Buka n8n Dashboard**
- URL: http://localhost:5678
- Login (jika belum, setup admin akun pertama kali)

**2.2 Akses Credentials Menu**
- Klik icon profile (atas kanan) → "Credentials"
- Atau buka menu utama → "Credentials"

**2.3 Create New Credential**
- Klik "+ New" atau "Create Credential"
- Search: "HTTP Request"
- Pilih "HTTP Request"

**2.4 Isi Credential Detail**
- **Name:** `WablasAPI`
- **Authentication:** Pilih "Generic Credential Type"
- **Headers:**
  - Klik "Add Header"
  - Key: `Authorization`
  - Value: `Bearer wbl_20e8a2e2f4c5b3a1d9e8f7c6b5a4d3e2` (ganti dengan API key Anda)
  - Klik "+" untuk tambah header baru
  - Key: `Content-Type`
  - Value: `application/json`

**2.5 Test Connection** (Optional)
- Klik "Test" button
- Jika hijau ✓ = Sukses
- Jika merah ✗ = Ada masalah (cek kembali API key)

**2.6 Save Credential**
- Klik "Save"

---

### Step 3: Import WhatsApp Workflow ke n8n

**3.1 Siapkan File Workflow**
- File: `backend/docs/n8n/unified_notification_workflow.json`
- Pastikan file exist

**3.2 Buka n8n Editor**
- Klik menu utama (kiri atas) → "Editor" atau Home
- Lihat tombol "Import" atau "+ Create New"

**3.3 Import Workflow**
- Klik "+ Create Workflow" → "Import from file"
- Atau klik menu "..." → "Import"
- Pilih file `unified_notification_workflow.json`
- Klik "Open" atau "Import"

**3.4 Verify Workflow Structure**
- Workflow akan load dengan beberapa nodes:
  1. **Webhook n8n-events** (trigger)
  2. **Validate event_name** (filter)
  3. **Route by event_name** (switch/branch)
  4. **Build WA messages** nodes (6 functions)
  5. **Send WA message** (HTTP request ke Wablas)

**3.5 Update Send WA Message Node**
- Double-click node "Send WA message"
- Di panel kanan, update:
  - **URL:** `https://api.wablas.com/send-message`
  - **Method:** POST
  - **Authentication:** Pilih "Wablas HTTP Request" (credential yang baru dibuat)
  - **Body:**
    ```json
    {
      "phone": "={{$json[\"phone\"]}}",
      "message": "={{$json[\"message\"]}}"
    }
    ```
- Klik "Save" (ctrl+s)

**3.6 Test Workflow**
- Klik "Execute Workflow" (tombol play ▶)
- Input test data:
  ```json
  {
    "event_name": "order_created",
    "payload": {
      "order_code": "ORD-20260607-0001",
      "customer_name": "Budi",
      "customer_phone": "628123456789",
      "provider_name": "Tukang A",
      "provider_phone": "628987654321",
      "estimated_price": 500000,
      "dp_amount": 250000
    }
  }
  ```
- Lihat apakah ada error atau success

**3.7 Activate Workflow**
- Klik toggle "Active" (hijau = aktif)
- Workflow sekarang siap menerima webhook

---

## Setup Email Notifications (Gmail)

### Step 1: Siapkan Gmail Account

**1.1 Pilih Mana Gmail Biasa atau Google Workspace**

**Option A: Gmail Biasa (Personal)**
- Akun: user@gmail.com
- Perlu enable "Less secure app access"

**Option B: Google Workspace (Business)**
- Akun: noreply@tukangdekat.com
- Lebih aman dan rekomended

Lanjut dengan salah satu:

---

### Step 2A: Setup Gmail Biasa dengan App Password

**2A.1 Enable 2-Step Verification**
- Buka https://myaccount.google.com
- Menu kiri: "Security"
- Cari "2-Step Verification"
- Klik "Get Started"
- Ikuti proses verifikasi dengan HP

**2A.2 Generate App Password**
- Di halaman Security, cari "App passwords" (muncul setelah 2FA aktif)
- Klik "App passwords"
- Select App: "Mail"
- Select Device: "Windows/Mac/Linux" 
- Klik "Generate"
- Copy password yang muncul (16 karakter)
- **Simpan password ini!**

> **Contoh:** `abcd efgh ijkl mnop` (16 chars)

**2A.3 Note untuk Step 3**
- Email: `your-email@gmail.com`
- Password: `abcd efgh ijkl mnop` (app password)

---

### Step 2B: Setup Google Workspace (Recommended)

**2B.1 Buat Service Account (jika belum ada)**
- Buka https://console.cloud.google.com
- Project: `tukangdekat` (buat baru jika belum)
- Menu: "APIs & Services" → "Credentials"
- Create Credential → "Service Account"
- Name: `n8n-mailer`
- Email: `n8n-mailer@tukangdekat.iam.gserviceaccount.com`
- Grant roles: "Editor" (untuk simplicity) atau "Editor" + "Service Account User"

**2B.2 Generate JSON Key**
- Di halaman Service Account, tab "Keys"
- "Add Key" → "Create new key" → "JSON"
- Download file JSON
- **Simpan file ini di aman!**

**2B.3 Enable Gmail API**
- Di APIs & Services: "Library"
- Search "Gmail API"
- Klik "Enable"

**2B.4 Setup Domain-Wide Delegation (Optional)**
- Di Service Account, tab "Details"
- Cari "Domain-wide delegation"
- Klik "Enable"

---

### Step 3: Setup Email Credential di n8n

**3.1 Buka n8n Credentials**
- n8n Dashboard → icon profile → "Credentials"

**3.2 Create Gmail Credential**

**Jika Gmail Biasa:**
- Klik "+ New Credential"
- Type: "Gmail"
- Authentications: "Authorize to access Gmail"
- Email: Masukkan email Anda
- Klik "Authenticate with Gmail"
- Browser akan membuka Google Login
- Klik "Allow" untuk permission
- Klik "Save"

**Jika Google Workspace dengan Service Account:**
- Klik "+ New Credential"
- Type: "Gmail"
- Email: `noreply@tukangdekat.com` (akun yang akan send email)
- Klik "Connect to account"
- Upload JSON key dari Step 2B.2
- Klik "Save"

---

### Step 4: Import Email Workflow ke n8n

**4.1 Import File**
- Menu: "Import from file"
- Pilih `backend/docs/n8n/unified_notification_workflow_email.json`
- Klik "Import"

**4.2 Verify Email Workflow**
- Nodes:
  1. Webhook n8n-events
  2. Validate event_name
  3. Route by event_name
  4. Build email nodes (6 functions)
  5. Send Email (Gmail node)

**4.3 Update Send Email Node**
- Double-click node "Send Email"
- **From Email:** `noreply@tukangdekat.com`
- **Gmail Account:** Pilih credential yang baru dibuat
- **Subject:** `={{$json["subject"]}}`
- **HTML:** `={{$json["html"]}}`
- Klik "Save"

**4.4 Test Email Workflow**
- Klik "Execute Workflow"
- Input test data (sama seperti WhatsApp)
- Tunggu 5-10 detik
- Cek email inbox Anda
- Email test seharusnya tiba

**4.5 Activate Workflow**
- Klik toggle "Active" untuk mengaktifkan

---

## Import Workflows ke n8n

### Quick Recap: Dua Workflow Utama

| Workflow | File | Channel | Recipients |
|----------|------|---------|-----------|
| WhatsApp | `unified_notification_workflow.json` | WhatsApp via Wablas | Customer + Provider |
| Email | `unified_notification_workflow_email.json` | Email via Gmail | Customer + Provider |

### Best Practice

1. **Import WhatsApp dulu** (simpler setup)
2. **Test WhatsApp** dengan real phone number
3. **Import Email** (lebih complex)
4. **Test Email** dengan real email address
5. **Activate keduanya** setelah test berhasil

---

## Testing

### Test 1: Manual Webhook Trigger via curl

**Test WhatsApp Event:**
```bash
curl -X POST http://localhost:5678/webhook/n8n-events \
  -H "Content-Type: application/json" \
  -d '{
    "event_name": "order_created",
    "channel": "WA",
    "payload": {
      "order_id": 1,
      "order_code": "ORD-TEST-001",
      "customer_name": "Budi Santoso",
      "customer_phone": "628123456789",
      "customer_email": "budi@example.com",
      "provider_name": "Tukang Bangunan Pro",
      "provider_phone": "628987654321",
      "provider_email": "tukang@example.com",
      "estimated_price": 500000,
      "dp_amount": 250000,
      "status": "CREATED"
    }
  }'
```

**Expected Response:**
```json
{
  "message": "event_dispatched",
  "data": { ... }
}
```

**Test Email Event:**
```bash
curl -X POST http://localhost:5678/webhook/n8n-events \
  -H "Content-Type: application/json" \
  -d '{
    "event_name": "order_accepted",
    "channel": "EMAIL",
    "payload": {
      "order_code": "ORD-TEST-001",
      "customer_name": "Budi Santoso",
      "customer_email": "budi@example.com",
      "provider_name": "Tukang Bangunan Pro",
      "provider_email": "tukang@example.com",
      "status": "ACCEPTED"
    }
  }'
```

### Test 2: Check WhatsApp Message

**Setelah trigger WhatsApp:**
1. Cek WhatsApp pribadi Anda
2. Seharusnya ada pesan dari Business Account (channel Wablas Anda)
3. Pesan format: "Halo [nama], pesanan *[kode]* ..."

**Jika tidak ada:**
- Cek Wablas dashboard → "Message History"
- Lihat apakah ada error/failed status
- Buka n8n workflow → "Execution History"
- Lihat error log

### Test 3: Check Email

**Setelah trigger Email:**
1. Cek inbox email yang dikonfigurasi
2. Subject: "Pesanan ORD-TEST-001 - TukangDekat"
3. Body: HTML dengan detail order

**Jika tidak ada:**
- Cek folder Spam/Junk
- Di n8n: lihat execution history untuk error
- Di Gmail: check "Security settings" untuk app access

### Test 4: Full Order Flow

**Scenario: Create order → check notif WA + Email**

```bash
# 1. Create order via backend
curl -X POST http://localhost:3000/api/orders \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{
    "provider_id": 2,
    "category_id": 1,
    "schedule_at": "2026-06-10 10:00:00",
    "address": "Jl. Sudirman No. 123",
    "notes": "Perlu bangunan tempat tinggal",
    "estimated_price": 500000
  }'

# Response: order dibuat dengan order_code, id, dll

# 2. n8n otomatis trigger (subscribe ke webhook)
# 3. Customer + Provider dapat notif WA
# 4. Customer + Provider dapat email

# 5. Verify di WhatsApp & Email inbox
```

---

## Troubleshooting

### Issue 1: WhatsApp Message Tidak Terkirim

**Gejala:**
- Workflow execute berhasil tapi no WA message
- n8n execution history tidak error

**Solusi:**

1. **Cek Wablas Dashboard**
   - Buka https://wablas.com/dashboard
   - Menu "Message History"
   - Lihat status message: "Pending" / "Delivered" / "Failed"
   - Klik message untuk lihat detail error

2. **Cek Phone Number Format**
   - Format harus: `62` + nomor (tanpa 0)
   - ✓ Benar: `628123456789`
   - ✗ Salah: `08123456789`, `+628123456789`
   - Edit di n8n function node: "Build WA messages"
   - Ubah parsing phone number

3. **Cek API Key**
   - Pastikan API key di n8n credential masih valid
   - Jika sudah lama, generate key baru di Wablas
   - Update credential di n8n

4. **Cek Rate Limit**
   - Wablas mungkin rate limit requests
   - Cek dalam plan Wablas (free/paid)
   - Jika terbatas, upgrade plan

### Issue 2: Email Tidak Terkirim

**Gejala:**
- Workflow execute sukses, tapi email tidak tiba
- Tidak masuk inbox dan spam folder

**Solusi:**

1. **Cek Gmail Credential**
   - Login https://myaccount.google.com
   - Verify 2FA aktif
   - Verify app password sudah generate (jika Gmail biasa)
   - Verify Service Account authenticated (jika Workspace)

2. **Cek Email Address di Payload**
   - Pastikan email valid format
   - ✓ Benar: `budi@example.com`
   - ✗ Salah: `budi@example`, `budi.example.com`

3. **Cek Gmail API Limit**
   - Gmail memiliki rate limit
   - Default: 1000 email/hari untuk production
   - Upgrade ke paid quota jika perlu

4. **Enable "Less Secure Apps"** (jika Gmail biasa)
   - Buka https://myaccount.google.com/lesssecureapps
   - Turn ON "Allow less secure apps"

5. **Check n8n Send Email Node Config**
   - Verify "From Email" adalah email terverifikasi
   - Verify Gmail credential pilih yang benar
   - Test connection di n8n

### Issue 3: n8n Webhook URL Tidak Ditemukan

**Gejala:**
- curl test response 404 Not Found

**Solusi:**

1. **Verify n8n Running**
   ```bash
   docker ps | grep n8n
   curl http://localhost:5678 # Should return 200
   ```

2. **Verify Workflow Active**
   - Di n8n, workflow harus toggle "Active" ON
   - Di n8n, lihat webhook path di trigger node
   - Default path: `/webhook/n8n-events`

3. **Check Docker Network**
   - Pastikan container bisa berkomunikasi
   ```bash
   docker exec laravel_api curl http://tukangdekat_n8n:5678/webhook/n8n-events
   ```
   - Seharusnya response (meski error di body, tapi bukan timeout)

### Issue 4: n8n Container Crash

**Gejala:**
- `docker ps` tidak menunjukkan n8n
- `docker logs tukangdekat_n8n` ada error

**Solusi:**

```bash
# Stop container
docker-compose down n8n

# Remove container & volume (reset)
docker-compose down -v n8n

# Start kembali
docker-compose up -d n8n

# Check logs
docker logs tukangdekat_n8n -f
```

---

## Useful Commands

### n8n Related

```bash
# View n8n logs
docker logs tukangdekat_n8n -f

# Restart n8n
docker-compose restart n8n

# SSH into n8n container
docker exec -it tukangdekat_n8n sh

# Check n8n process
curl http://localhost:5678/api/health
```

### Testing

```bash
# Test webhook
curl -X POST http://localhost:5678/webhook/n8n-events \
  -H "Content-Type: application/json" \
  -d '{"event_name":"order_created","payload":{...}}'

# Test dari backend container
docker exec laravel_api curl http://tukangdekat_n8n:5678/api/health
```

### Database

```bash
# View notification logs (dari MySQL/PostgreSQL)
docker exec -it laravel_db mysql -u root -p db_tukangdekat
SELECT * FROM notification_logs ORDER BY created_at DESC LIMIT 10;
```

---

## FAQ

### Q: Berapa lama notif WhatsApp terkirim?
**A:** Biasanya instant (< 1 detik). Jika delay, cek rate limit Wablas atau koneksi internet.

### Q: Bisa kirim notif ke banyak nomor sekali?
**A:** Tidak di workflow ini. Tiap event kirim ke customer + provider (max 2). Untuk bulk, perlu setup loop di n8n.

### Q: Berapa biaya Wablas?
**A:** Free tier ada 100 message/hari. Paid mulai dari IDR 50K/bulan untuk lebih banyak.

### Q: Apakah perlu setup ulang setelah restart Docker?
**A:** Tidak. Credential dan workflow tersimpan di n8n database (n8n_data volume).

### Q: Bisa customize template message?
**A:** Ya, edit di n8n function node "Build WA messages" / "Build email". Update text/HTML di dalam function code.

### Q: Gimana jika email masuk spam?
**A:** 
1. Tambah SPF record di DNS domain
2. Tambah DKIM signature
3. Gunakan custom domain untuk email (jangan dari @gmail.com)
4. Di Gmail function node, update "From Name" lebih descriptive

### Q: Bisa test email tanpa n8n production?
**A:** Ya, buka n8n UI → "Execute" button di workflow untuk manual test.

---

## Next Steps

1. ✅ Setup Wablas account + API key
2. ✅ Import WhatsApp workflow
3. ✅ Test WhatsApp messaging
4. ✅ Setup Gmail credential
5. ✅ Import Email workflow
6. ✅ Test Email messaging
7. ✅ Activate both workflows
8. ✅ Monitor notification logs di database
9. ✅ Handle failure cases (store retry logic)
10. ✅ Document custom message templates

---

## Support & References

- **Wablas Docs:** https://wablas.com/documentation
- **Gmail API:** https://developers.google.com/gmail/api
- **n8n Docs:** https://docs.n8n.io
- **n8n Workflows:** https://n8n.io/workflows
- **GitHub Issues:** https://github.com/radenelsa7-bot/PM_UAS_rekayasa_Sistem_Informasi/issues

---

**Last Updated:** 2026-06-07  
**Version:** 1.0  
**Author:** TukangDekat Dev Team
