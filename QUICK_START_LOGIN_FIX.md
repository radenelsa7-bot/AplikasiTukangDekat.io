# Quick Start - Login & Register Fix

## ⚡ Langkah Cepat untuk Menjalankan Aplikasi

### 1. Pastikan Docker Running
```bash
# Di terminal/PowerShell (sebagai Administrator jika perlu)
cd "c:/REKAYASA SI UAS/PM_UAS_rekayasa_Sistem_Informasi"

# Jalankan semua service
docker-compose up -d

# Verifikasi semua container berjalan
docker ps
```

**Expected output:**
```
NAMES             STATUS
laravel_app       Up 2 minutes
laravel_db        Up 2 minutes  
tukangdekat_n8n   Up 2 minutes
```

---

### 2. Test Backend API (Optional)
```bash
# Test login
curl -X POST http://localhost:8000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"password"}'

# Test register (dengan password yang memenuhi requirement)
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name":"User Baru",
    "email":"user@example.com",
    "phone":"08123456789",
    "password":"Password123!",
    "password_confirmation":"Password123!",
    "role":"CUSTOMER"
  }'
```

---

### 3. Jalankan Mobile/Web (Flutter)
```bash
# Terminal baru - cd ke folder mobile
cd mobile

# Get dependencies
flutter pub get

# Run di browser (Chrome)
flutter run -d chrome

# Atau run di Android Emulator
flutter run  # (auto-detect emulator)
```

---

### 4. Test di Aplikasi

#### Register User Baru
1. Klik tombol "Daftar" atau "Register"
2. Isi form:
   - **Nama:** [Nama Anda]
   - **Email:** [email@example.com]
   - **No. Telepon:** [08xxxxx]
   - **Password:** [Password123!] ← PENTING: Harus ada uppercase + angka
   - **Role:** Pilih "CUSTOMER" atau "PROVIDER"
3. Klik "Daftar"
4. Seharusnya muncul pesan sukses & di-redirect ke login

#### Login
1. Masukkan email & password
2. Klik "Masuk"
3. Seharusnya login berhasil dan masuk ke home screen

---

## 🔧 Jika Masih Error

### Error: "Network Error" / "Server Error"

**Solusi 1: Restart Docker**
```bash
cd "c:/REKAYASA SI UAS/PM_UAS_rekayasa_Sistem_Informasi"
docker-compose down
docker-compose up -d
```

**Solusi 2: Check API Base URL**
- File: `mobile/lib/config/api_config.dart`
- Pastikan API_BASE_URL = `http://127.0.0.1:8000`

**Solusi 3: Check Network Tab**
- Buka DevTools (F12 jika di Chrome)
- Pergi ke Network tab
- Coba login/register
- Lihat error response di Network tab
- Screenshot & bagikan error message

**Solusi 4: View Docker Logs**
```bash
# Lihat log backend
docker logs laravel_app

# Lihat log database
docker logs laravel_db

# Follow log real-time
docker logs -f laravel_app
```

---

## 📋 Password Requirements

Harus memenuhi SEMUA kriteria:
- ✅ Minimal 8 karakter
- ✅ 1 huruf besar (A-Z)
- ✅ 1 angka (0-9)  
- ✅ 1 karakter spesial (!@#$%^&*)

**Valid examples:**
- `Password123!`
- `Test@1234`
- `MyApp#999`
- `Admin@2024`

**Invalid examples:**
- `password` ❌ (no uppercase, no number, no special)
- `password123` ❌ (no uppercase, no special)
- `PASSWORD123!` ❌ (no lowercase - ini optional sih tapi recommended)

---

## 📱 Test Credentials

Sudah ada test user:
```
Email: admin@example.com
Password: password
```

Atau buat user baru dengan register endpoint.

---

## ✅ Checklist untuk Debugging

- [ ] Docker containers semua UP (docker ps)
- [ ] Backend accessible (http://localhost:8000)
- [ ] Database migrations sudah di-run (artisan migrate:status)
- [ ] Flutter dependencies installed (flutter pub get)
- [ ] API base URL correct (http://127.0.0.1:8000)
- [ ] Password memenuhi requirements
- [ ] Email belum pernah digunakan di database (untuk register)

---

## 📞 Bantuan

Jika masih error:
1. Buka file `LOGIN_REGISTER_FIX_GUIDE.md` untuk info lengkap
2. Lihat Docker logs: `docker logs laravel_app`
3. Check Network tab di DevTools
4. Share error message + screenshots untuk bantuan lebih lanjut

---

**Status:** ✅ Semua service sudah fixed & running  
**Terakhir Update:** 2026-06-20
