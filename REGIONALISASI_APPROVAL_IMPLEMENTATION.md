# Implementasi Fitur Regionalisasi & Provider Registration Approval

**Status:** ✅ Complete Implementation  
**Last Updated:** 2026-07-15  
**Technology Stack:** Flutter + Laravel (Sanctum)

---

## 📋 Ringkasan Fitur

Implementasi lengkap untuk:
1. **Data Master Wilayah** - CRUD Cities & Districts (Admin)
2. **Cascading Dropdown** - Pemilihan lokasi berjenjang (Provider)
3. **Registration Approval Workflow** - Approval/Rejection oleh Admin
4. **Auth Guard Middleware** - Blocking screen untuk pending providers

---

## 🗄️ DATABASE SCHEMA

### Migration File
- **Location:** `backend/database/migrations/2026_07_15_000001_add_location_and_approval_to_users_table.php`

### Changes Made to `users` Table
```sql
ALTER TABLE users ADD COLUMN city_id BIGINT UNSIGNED NULLABLE FOREIGN KEY REFERENCES wilayah_kota(id);
ALTER TABLE users ADD COLUMN district_id BIGINT UNSIGNED NULLABLE FOREIGN KEY REFERENCES wilayah_kecamatan(id);
ALTER TABLE users ADD COLUMN provider_status ENUM('pending', 'approved', 'rejected') NULLABLE DEFAULT NULL;
```

### Existing Tables Used
- `wilayah_kota` (cities) - Already exists
- `wilayah_kecamatan` (districts) - Already exists

---

## 🔧 BACKEND IMPLEMENTATION

### 1. Updated Models

#### User Model (`backend/app/Models/User.php`)
```php
// Relationships
public function city(): BelongsTo
{
    return $this->belongsTo(WilayahKota::class, 'city_id');
}

public function district(): BelongsTo
{
    return $this->belongsTo(WilayahKecamatan::class, 'district_id');
}

// Mass assignable
protected $fillable = [
    // ... existing fields ...
    'city_id',
    'district_id',
    'provider_status',
];
```

### 2. New Controllers

#### CityController
**File:** `backend/app/Http/Controllers/Api/CityController.php`

**Endpoints:**
- `GET /api/cities` - List all cities (public, searchable)
- `GET /api/cities/{id}` - Get city detail
- `POST /api/admin/cities` - Create city (admin only)
- `PUT /api/admin/cities/{id}` - Update city (admin only)
- `DELETE /api/admin/cities/{id}` - Delete city (admin only)

**Response Format:**
```json
{
  "success": true,
  "message": "Cities retrieved successfully",
  "data": [
    {
      "id": 1,
      "name": "Jakarta",
      "created_at": "2026-07-15T10:00:00Z",
      "updated_at": "2026-07-15T10:00:00Z"
    }
  ]
}
```

#### DistrictController
**File:** `backend/app/Http/Controllers/Api/DistrictController.php`

**Endpoints:**
- `GET /api/districts?city_id={id}` - List districts by city (public)
- `GET /api/districts/{id}` - Get district detail
- `POST /api/admin/districts` - Create district (admin only)
- `PUT /api/admin/districts/{id}` - Update district (admin only)
- `DELETE /api/admin/districts/{id}` - Delete district (admin only)

**Response Format:**
```json
{
  "success": true,
  "message": "Districts retrieved successfully",
  "data": [
    {
      "id": 1,
      "kota_id": 1,
      "name": "Pusat",
      "created_at": "2026-07-15T10:00:00Z",
      "updated_at": "2026-07-15T10:00:00Z",
      "kota": {
        "id": 1,
        "name": "Jakarta"
      }
    }
  ]
}
```

### 3. AdminController - New Methods

#### getPendingRegistrationProviders()
**Endpoint:** `GET /api/admin/providers/pending-registration`

**Response:**
```json
{
  "success": true,
  "message": "Pending registration providers",
  "data": [
    {
      "id": 5,
      "name": "Budi Santoso",
      "email": "budi@example.com",
      "phone": "08123456789",
      "city_id": 1,
      "city_name": "Jakarta",
      "district_id": 1,
      "district_name": "Pusat",
      "provider_status": "pending",
      "profile": {
        "business_name": "Tukang Listrik Budi",
        "description": "Layanan perbaikan listrik",
        "address": "Jl. Merdeka No. 123"
      },
      "created_at": "2026-07-15T09:00:00Z"
    }
  ]
}
```

#### approveProviderRegistration(id)
**Endpoint:** `POST /api/admin/providers/{id}/approve-registration`

**Request Body:**
```json
{
  "notes": "Profil dan dokumen sudah diverifikasi dengan baik"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Provider registration approved",
  "data": {
    "id": 5,
    "provider_status": "approved",
    "approved_at": "2026-07-15T10:30:00Z"
  }
}
```

#### rejectProviderRegistration(id)
**Endpoint:** `POST /api/admin/providers/{id}/reject-registration`

**Request Body:**
```json
{
  "reason": "Data tidak lengkap / tidak sesuai dengan kriteria"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Provider registration rejected",
  "data": {
    "id": 5,
    "provider_status": "rejected",
    "rejected_at": "2026-07-15T10:30:00Z"
  }
}
```

### 4. Updated AuthController

#### register()
- Set `provider_status = 'pending'` untuk PROVIDER role
- Status provider akan `null` untuk CUSTOMER dan ADMIN

#### login()
- Return `provider_status` dalam response untuk PROVIDER role
- Format response:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
    "token_type": "Bearer",
    "user": {
      "id": 5,
      "name": "Budi Santoso",
      "email": "budi@example.com",
      "role": "PROVIDER",
      "provider_status": "pending"  // IMPORTANT
    }
  }
}
```

### 5. API Routes

**File:** `backend/routes/api.php`

```php
// Public routes
Route::get('/cities', [CityController::class, 'index'])->middleware('throttle:60,1');
Route::get('/cities/{id}', [CityController::class, 'show'])->middleware('throttle:60,1');
Route::get('/districts', [DistrictController::class, 'index'])->middleware('throttle:60,1');
Route::get('/districts/{id}', [DistrictController::class, 'show'])->middleware('throttle:60,1');

// Admin routes
Route::prefix('admin')->middleware('role:admin')->group(function () {
    // Cities
    Route::post('/cities', [CityController::class, 'store'])->middleware('throttle:10,1');
    Route::put('/cities/{id}', [CityController::class, 'update'])->middleware('throttle:10,1');
    Route::delete('/cities/{id}', [CityController::class, 'destroy'])->middleware('throttle:10,1');
    
    // Districts
    Route::post('/districts', [DistrictController::class, 'store'])->middleware('throttle:10,1');
    Route::put('/districts/{id}', [DistrictController::class, 'update'])->middleware('throttle:10,1');
    Route::delete('/districts/{id}', [DistrictController::class, 'destroy'])->middleware('throttle:10,1');
    
    // Provider Approval
    Route::get('/providers/pending-registration', [AdminController::class, 'getPendingRegistrationProviders']);
    Route::post('/providers/{providerId}/approve-registration', [AdminController::class, 'approveProviderRegistration']);
    Route::post('/providers/{providerId}/reject-registration', [AdminController::class, 'rejectProviderRegistration']);
});
```

---

## 📱 FRONTEND IMPLEMENTATION (Flutter)

### 1. Data Models

**File:** `mobile/lib/core/models/location_models.dart`

```dart
class CityData {
  final int id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  // ... constructors and methods
}

class DistrictData {
  final int id;
  final int cityId;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final CityData? city;
  // ... constructors and methods
}

enum ProviderApprovalStatus {
  pending,
  approved,
  rejected,
}
```

### 2. Riverpod Providers

**File:** `mobile/lib/features/home/location_providers.dart`

```dart
// Fetch all cities
final citiesProvider = FutureProvider<List<CityData>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final response = await apiService.getCities();
  return response.data;
});

// Fetch districts by city
final districtsByCityProvider = FutureProvider.family<List<DistrictData>, int>(
  (ref, cityId) async {
    final apiService = ref.read(apiServiceProvider);
    final response = await apiService.getDistrictsByCity(cityId);
    return response.data;
  }
);

// Selected city state
final selectedCityProvider = StateProvider<int?>((ref) => null);

// Selected district state
final selectedDistrictProvider = StateProvider<int?>((ref) => null);
```

### 3. API Service Methods

**File:** `mobile/lib/core/services/api_service.dart`

```dart
Future<CitiesResponse> getCities({String? search}) async {
  final params = <String, dynamic>{};
  if (search != null && search.isNotEmpty) {
    params['search'] = search;
  }
  final response = await dio.get('/api/cities', queryParameters: params);
  return CitiesResponse.fromJson(response.data);
}

Future<DistrictsResponse> getDistrictsByCity(int cityId, {String? search}) async {
  final params = <String, dynamic>{'city_id': cityId};
  if (search != null && search.isNotEmpty) {
    params['search'] = search;
  }
  final response = await dio.get('/api/districts', queryParameters: params);
  return DistrictsResponse.fromJson(response.data);
}
```

### 4. Cascading Dropdown Widget

**File:** `mobile/lib/shared/widgets/cascading_location_selector.dart`

#### Usage:
```dart
CascadingLocationSelector(
  onSelectionChanged: (cityId, districtId) {
    // Handle selection
    print('City: $cityId, District: $districtId');
  },
  initialCityId: user.cityId,
  initialDistrictId: user.districtId,
  isRequired: true,
  cityLabel: 'Pilih Kota',
  districtLabel: 'Pilih Kecamatan',
)
```

#### Features:
- ✅ Cascading behavior - District dropdown hanya aktif setelah city dipilih
- ✅ Loading state dengan spinner
- ✅ Error handling dengan message
- ✅ Search capability
- ✅ Initial value support
- ✅ Responsive design dengan Material 3

### 5. Auth Guard & Approval Screens

#### Awaiting Approval Screen
**File:** `mobile/lib/features/auth/awaiting_approval_screen.dart`

Menampilkan:
- ✅ Loading icon & status message
- ✅ Information tentang proses verifikasi
- ✅ Checklist items yang diverifikasi
- ✅ Contact support information
- ✅ Refresh status button
- ✅ Logout button
- ✅ Prevents back navigation (WillPopScope)

#### Provider Approval Guard
**File:** `mobile/lib/features/auth/provider_approval_guard.dart`

```dart
ProviderApprovalGuard(
  providerStatus: user.providerStatus,
  child: HomePage(), // Main screen
)
```

Behavior:
- Status = "pending" → AwaitingApprovalScreen
- Status = "rejected" → RegistrationRejectedScreen
- Status = "approved" → Child widget

### 6. Integration dengan Auth Flow

**Update di AuthController / main.dart:**

```dart
// After login/registration
if (user.role == 'PROVIDER' && user.providerStatus == 'pending') {
  // Redirect to approval screen
  Navigator.of(context).pushReplacementNamed('/awaiting-approval');
} else if (user.role == 'PROVIDER' && user.providerStatus == 'rejected') {
  // Redirect to rejected screen
  Navigator.of(context).pushReplacementNamed('/registration-rejected');
} else {
  // Go to home/dashboard
  Navigator.of(context).pushReplacementNamed('/home');
}
```

### 7. Update Profile dengan Location

**File:** `mobile/lib/features/home/edit_profile_dialog.dart` (atau existing profile screen)

```dart
// Di profile update form:
CascadingLocationSelector(
  onSelectionChanged: (cityId, districtId) {
    setState(() {
      _selectedCityId = cityId;
      _selectedDistrictId = districtId;
    });
  },
)

// Pada save:
await apiService.updateProviderProfile(
  cityId: _selectedCityId,
  districtId: _selectedDistrictId,
  // ... other fields
);
```

---

## 🧪 TESTING CHECKLIST

### Backend Testing
- [ ] Run migration: `php artisan migrate`
- [ ] Test GET /api/cities → returns empty list
- [ ] Test POST /api/admin/cities (admin auth required)
- [ ] Test GET /api/districts?city_id=1
- [ ] Test provider register → provider_status should be 'pending'
- [ ] Test provider login → provider_status should be in response
- [ ] Test GET /api/admin/providers/pending-registration
- [ ] Test POST /api/admin/providers/{id}/approve-registration
- [ ] Test POST /api/admin/providers/{id}/reject-registration
- [ ] Test cascade validation (city must exist, unique district per city)

### Frontend Testing
- [ ] Load cities dropdown → shows all cities
- [ ] Select city → districts dropdown becomes enabled
- [ ] Change city → districts list updates
- [ ] Select district → onSelectionChanged fires
- [ ] Provider login with pending status → shows AwaitingApprovalScreen
- [ ] Provider login with rejected status → shows RejectedScreen
- [ ] Provider login with approved status → shows HomePage
- [ ] Refresh button on approval screen works
- [ ] Logout button works from approval screen
- [ ] Back button disabled on approval screen

---

## 📊 API REFERENCE SUMMARY

### Public Endpoints
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/cities` | List all cities |
| GET | `/api/cities/{id}` | Get city detail |
| GET | `/api/districts` | List districts by city |
| GET | `/api/districts/{id}` | Get district detail |

### Admin Endpoints
| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| POST | `/api/admin/cities` | Create city | Admin |
| PUT | `/api/admin/cities/{id}` | Update city | Admin |
| DELETE | `/api/admin/cities/{id}` | Delete city | Admin |
| POST | `/api/admin/districts` | Create district | Admin |
| PUT | `/api/admin/districts/{id}` | Update district | Admin |
| DELETE | `/api/admin/districts/{id}` | Delete district | Admin |
| GET | `/api/admin/providers/pending-registration` | Get pending providers | Admin |
| POST | `/api/admin/providers/{id}/approve-registration` | Approve provider | Admin |
| POST | `/api/admin/providers/{id}/reject-registration` | Reject provider | Admin |

---

## 🚀 DEPLOYMENT STEPS

### 1. Backend
```bash
cd backend

# Run migration
php artisan migrate

# Create sample cities/districts (optional)
php artisan tinker
>>> App\Models\WilayahKota::create(['name' => 'Jakarta'])
>>> App\Models\WilayahKota::create(['name' => 'Surabaya'])

# Clear cache
php artisan cache:clear
php artisan config:cache
```

### 2. Frontend
```bash
cd mobile

# Get dependencies
flutter pub get

# Run
flutter run

# Or build release
flutter build apk --release
flutter build ios --release
```

---

## 📝 NOTES

1. **Rate Limiting:** All endpoints have throttle middleware (60-100 requests/min for public, 10-30 for admin)
2. **Validation:** All requests validated with FormRequest classes
3. **Notifications:** Admin approval/rejection triggers N8n webhook notifications
4. **Cascade Delete:** Deleting city cascades to districts and provider locations (set to NULL)
5. **Search:** Cities and districts support full-text search
6. **Responsive:** All Flutter widgets responsive untuk mobile & tablet

---

## 🔗 FILE REFERENCES

### Backend Files Created/Updated
- `backend/database/migrations/2026_07_15_000001_add_location_and_approval_to_users_table.php`
- `backend/app/Models/User.php` (updated)
- `backend/app/Http/Controllers/Api/CityController.php` (new)
- `backend/app/Http/Controllers/Api/DistrictController.php` (new)
- `backend/app/Http/Controllers/Api/AdminController.php` (updated)
- `backend/app/Http/Controllers/Api/AuthController.php` (updated)
- `backend/app/Http/Requests/StoreWilayahKotaRequest.php` (new)
- `backend/app/Http/Requests/UpdateWilayahKotaRequest.php` (new)
- `backend/app/Http/Requests/StoreWilayahKecamatanRequest.php` (new)
- `backend/app/Http/Requests/UpdateWilayahKecamatanRequest.php` (new)
- `backend/routes/api.php` (updated)

### Frontend Files Created/Updated
- `mobile/lib/core/models/location_models.dart` (new)
- `mobile/lib/features/home/location_providers.dart` (new)
- `mobile/lib/core/services/api_service.dart` (updated)
- `mobile/lib/shared/widgets/cascading_location_selector.dart` (new)
- `mobile/lib/features/auth/awaiting_approval_screen.dart` (new)
- `mobile/lib/features/auth/provider_approval_guard.dart` (new)

---

**✅ Implementation Complete!**
