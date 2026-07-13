# 🔧 SOLUSI LOGIN MOBILE - Firewall & Network Fix
**Date:** 2026-07-13 | **Status:** Root Cause Identified ✅

---

## 🚨 ROOT CAUSE IDENTIFIED

**Problem:** Device timeout meski backend running → **WINDOWS FIREWALL BLOCKING PORT 8000**

**Error Pattern:**
```
[Login] Connection failed to: http://192.168.18.106:8000
[Login] Error: The request connection took longer than 0:01:00.000000 and it was aborted
```

**Why:**
- Backend listening di 0.0.0.0:8000 ✅
- PC accessible dari device via WiFi ✅
- **TAPI** Windows Firewall NOT allowing incoming connection on port 8000 ❌

---

## ✅ SOLUSI FIREWALL (Choose One)

### **Option 1: Add Firewall Rule (RECOMMENDED - Permanent)**

**Jalankan PowerShell sebagai ADMINISTRATOR:**

```powershell
# Run as Administrator
netsh advfirewall firewall add rule name="Laravel Port 8000" dir=in action=allow protocol=tcp localport=8000 profile=private
```

**Verify rule created:**
```powershell
netsh advfirewall firewall show rule name="Laravel Port 8000" verbose
```

---

### **Option 2: Disable Firewall Temporarily (FOR TESTING ONLY)**

**Run as Administrator:**
```powershell
# Disable for testing
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled $false

# Re-enable later
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled $true
```

⚠️ **NOT recommended for production** - less secure

---

### **Option 3: Windows Defender Firewall GUI (Manual)**

1. Press `Win + R` → `wf.msc` → Enter
2. Click "New Rule" → "Port"
3. Select "TCP" → Specific Local Port: `8000`
4. Action: "Allow"
5. Apply to: Check all (Domain, Private, Public)
6. Name: "Laravel Port 8000"
7. Finish

---

## 🔧 CONFIGURATION CHANGES MADE

### 1. **Dio Timeout** ✅ DONE
```dart
// mobile/lib/core/http/dio_provider.dart
connectTimeout: const Duration(seconds: 60),  // was 30s
receiveTimeout: const Duration(seconds: 60),
sendTimeout: const Duration(seconds: 60),
```

### 2. **Network Permissions** ✅ DONE
```xml
<!-- mobile/android/app/src/main/AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
```

### 3. **Backend Binding** ✅ DONE
```bash
# backend now listening on 0.0.0.0:8000 (all interfaces)
php artisan serve --host=0.0.0.0 --port=8000
```

### 4. **API URL Config** 
Two options in `mobile/.env`:
```bash
# Option A: IP Address (if firewall enabled for port)
API_BASE_URL=http://192.168.18.106:8000

# Option B: Hostname (DNS-based, more reliable)
API_BASE_URL=http://LAPTOP-1OCT1GD0:8000
```

---

## 🚀 DEPLOYMENT STEPS

### **Step 1: Fix Firewall (REQUIRED)**
```powershell
# Run as Administrator
netsh advfirewall firewall add rule name="Laravel Port 8000" dir=in action=allow protocol=tcp localport=8000 profile=private
```

### **Step 2: Verify Backend Running**
```bash
cd backend
php artisan serve --host=0.0.0.0 --port=8000
# Output: Server running on [http://0.0.0.0:8000]
```

### **Step 3: Test Backend Accessibility**
```bash
# From PC
curl -I http://192.168.18.106:8000/api/health
# Should return: HTTP/1.1 200 OK

# Or from device terminal
nslookup LAPTOP-1OCT1GD0    # Should resolve
ping LAPTOP-1OCT1GD0        # Should respond
```

### **Step 4: Clean & Rebuild Mobile App**
```bash
cd mobile
flutter clean
flutter pub get
flutter run    # Will use .env with proper URL
```

### **Step 5: Test Login on Device**
- Open app on device
- Enter email/password
- Should now connect and either succeed/fail with proper error, not timeout

---

## 🔍 TROUBLESHOOTING

### ❌ Still timing out after firewall fix?

**Check:**
1. Firewall rule created correctly
   ```powershell
   netsh advfirewall firewall show rule name="Laravel Port 8000"
   ```

2. Backend still running on 0.0.0.0
   ```bash
   netstat -ano | findstr 8000
   ```

3. Device on same network
   - Check PC WiFi: Settings → Network & Internet → WiFi → Properties
   - Check Device WiFi: Same SSID and Gateway (192.168.18.1)

4. Try hostname instead of IP
   - Update `.env` to: `API_BASE_URL=http://LAPTOP-1OCT1GD0:8000`
   - Rebuild app with `flutter clean && flutter pub get && flutter run`

### ❌ "Connection refused" after firewall fix?

- Backend crashed or not running
- Check terminal: `php artisan serve --host=0.0.0.0 --port=8000`
- Check logs: `backend/storage/logs/laravel.log`

### ❌ "Invalid credentials" (Good Sign! ✅)

- Firewall is working!
- Just invalid email/password
- Check database has users: `php artisan tinker` → `App\Models\User::all()`

---

## 📊 Validation Checklist

- [ ] Windows Firewall rule added for port 8000
- [ ] Backend running: `php artisan serve --host=0.0.0.0 --port=8000`
- [ ] PC & Device on same WiFi network
- [ ] Mobile app rebuilt with `flutter clean`
- [ ] Timeout duration increased to 60s in Dio config
- [ ] Network permissions added to AndroidManifest
- [ ] Test login on device

---

## 📝 Files Modified

| File | Change |
|------|--------|
| `mobile/lib/core/http/dio_provider.dart` | Timeout: 30s → 60s |
| `mobile/android/app/src/main/AndroidManifest.xml` | Added network permissions |
| `mobile/.env` | API_BASE_URL = `http://192.168.18.106:8000` |
| Backend CLI | Started with `--host=0.0.0.0 --port=8000` |

---

## 🎯 Next Action

**YOU MUST:**
1. Run this command **as Administrator** in PowerShell:
```powershell
netsh advfirewall firewall add rule name="Laravel Port 8000" dir=in action=allow protocol=tcp localport=8000 profile=private
```

2. Then rebuild and test mobile app:
```bash
cd mobile
flutter clean && flutter pub get && flutter run
```

3. Try login on device - should work now!

---

**Status:** 🟡 Pending Firewall Configuration  
**Updated:** 2026-07-13 12:35 UTC
