# REGIONALISASI & APPROVAL - QUICK START INTEGRATION GUIDE

**Purpose:** Step-by-step guide untuk mengintegrasikan fitur regionalisasi dan approval workflow ke dalam aplikasi yang sudah ada.

---

## 🎯 QUICK START STEPS

### STEP 1: Backend - Run Database Migration

```bash
cd backend

# Run migration
php artisan migrate

# Verify migration
php artisan tinker
>>> Schema::hasColumn('users', 'city_id')
>>> Schema::hasColumn('users', 'provider_status')
# Output: true for both
```

### STEP 2: Frontend - Update routing untuk Approval Guard

**File:** `mobile/lib/main.dart` (atau routing file)

Tambahkan routing untuk approval screens:

```dart
routes: {
  '/login': (_) => const SessionLoginPage(),
  '/home': (_) => HomePage(), // Default home
  '/awaiting-approval': (_) => const AwaitingApprovalScreen(),
  '/registration-rejected': (_) => const RegistrationRejectedScreen(),
  // ... other routes
}
```

### STEP 3: Frontend - Update Auth Logic

**File:** `mobile/lib/features/auth/auth_controller.dart` (StateNotifier atau Riverpod)

Update login/register logic untuk handle provider_status:

```dart
// Dalam login method:
if (loginResponse.user['role'] == 'PROVIDER') {
  final providerStatus = loginResponse.user['provider_status'];
  
  if (providerStatus == 'pending') {
    // Redirect to approval screen
    // context.go('/awaiting-approval') atau Navigator.pushNamed
  } else if (providerStatus == 'rejected') {
    // Redirect to rejected screen
  }
}
```

### STEP 4: Frontend - Wrap Home Route dengan Guard

**File:** `mobile/lib/main.dart` atau routing widget

```dart
// Before:
Route('/home', builder: (_) => const HomePage())

// After:
Route('/home', builder: (_) => ProviderApprovalGuard(
  providerStatus: userProviderStatus,
  child: const HomePage(),
))
```

---

## 📝 INTEGRATION EXAMPLES

### Example 1: Update Provider Profile dengan Location Selector

**File:** `mobile/lib/features/provider/edit_profile_screen.dart` (or similar)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/cascading_location_selector.dart';
import '../../features/home/location_providers.dart';

class EditProviderProfileScreen extends ConsumerStatefulWidget {
  const EditProviderProfileScreen({super.key});

  @override
  ConsumerState<EditProviderProfileScreen> createState() =>
      _EditProviderProfileScreenState();
}

class _EditProviderProfileScreenState
    extends ConsumerState<EditProviderProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController businessNameController;
  int? selectedCityId;
  int? selectedDistrictId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    businessNameController = TextEditingController();
    // TODO: Load initial profile data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Name field
            AppTextField(
              controller: nameController,
              label: 'Nama Lengkap',
              hintText: 'Masukkan nama lengkap Anda',
            ),
            const SizedBox(height: 16),

            // Business name field
            AppTextField(
              controller: businessNameController,
              label: 'Nama Bisnis',
              hintText: 'Nama layanan/bisnis Anda',
            ),
            const SizedBox(height: 24),

            // Cascading Location Selector
            CascadingLocationSelector(
              onSelectionChanged: (cityId, districtId) {
                setState(() {
                  selectedCityId = cityId;
                  selectedDistrictId = districtId;
                });
              },
              initialCityId: null, // TODO: Load from user profile
              initialDistrictId: null,
              isRequired: true,
              cityLabel: 'Pilih Kota Lokasi Kerja',
              districtLabel: 'Pilih Kecamatan',
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _saveProfile,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan Profil'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (selectedCityId == null || selectedDistrictId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kota dan kecamatan terlebih dahulu')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      await apiService.updateProviderProfile(
        businessName: businessNameController.text,
        cityId: selectedCityId,
        districtId: selectedDistrictId,
        // ... other fields
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil berhasil disimpan')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    businessNameController.dispose();
    super.dispose();
  }
}
```

---

### Example 2: Admin Panel - List & Approve Providers

**File:** `mobile/lib/features/admin/provider_approval_page.dart` (new)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProviderApprovalPage extends ConsumerWidget {
  const ProviderApprovalPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Approval Provider'),
      ),
      body: _ProviderApprovalList(),
    );
  }
}

class _ProviderApprovalList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Create provider for pending providers
    // final pendingProvidersAsync = ref.watch(pendingProvidersProvider);

    return Center(
      child: Text('Provider Approval List'),
      // pendingProvidersAsync.when(
      //   data: (providers) => ListView.builder(
      //     itemCount: providers.length,
      //     itemBuilder: (context, index) {
      //       final provider = providers[index];
      //       return Card(
      //         child: ListTile(
      //           title: Text(provider.name),
      //           subtitle: Text(provider.email),
      //           trailing: Row(
      //             mainAxisSize: MainAxisSize.min,
      //             children: [
      //               IconButton(
      //                 icon: const Icon(Icons.check, color: Colors.green),
      //                 onPressed: () => _approveProvider(context, ref, provider.id),
      //               ),
      //               IconButton(
      //                 icon: const Icon(Icons.close, color: Colors.red),
      //                 onPressed: () => _rejectProvider(context, ref, provider.id),
      //               ),
      //             ],
      //           ),
      //         ),
      //       );
      //     },
      //   ),
      //   loading: () => const CircularProgressIndicator(),
      //   error: (error, st) => Text('Error: $error'),
      // ),
    );
  }
}
```

---

### Example 3: Admin Backend - API Endpoints Test

**Using Postman or similar:**

#### Test: Get All Cities
```
GET http://localhost:8000/api/cities
Headers:
  Accept: application/json
```

**Response:**
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

#### Test: Create City (Admin only)
```
POST http://localhost:8000/api/admin/cities
Headers:
  Authorization: Bearer {admin_token}
  Content-Type: application/json

Body:
{
  "name": "Surabaya"
}
```

#### Test: Get Districts by City
```
GET http://localhost:8000/api/districts?city_id=1
Headers:
  Accept: application/json
```

#### Test: Provider Registration with Location
```
POST http://localhost:8000/api/auth/register
Headers:
  Content-Type: application/json

Body:
{
  "name": "Budi Santoso",
  "email": "budi@example.com",
  "phone": "08123456789",
  "password": "password123",
  "role": "PROVIDER",
  "business_name": "Tukang Listrik Budi",
  "category_id": 1
}
```

**Response (perhatikan provider_status):**
```json
{
  "success": true,
  "message": "User registered successfully",
  "data": {
    "user": {
      "id": 5,
      "name": "Budi Santoso",
      "email": "budi@example.com",
      "role": "PROVIDER"
    }
  },
  "status_code": 201
}
```

#### Test: Login dan Check Provider Status
```
POST http://localhost:8000/api/auth/login
Headers:
  Content-Type: application/json

Body:
{
  "email": "budi@example.com",
  "password": "password123"
}
```

**Response (perhatikan provider_status):**
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
      "provider_status": "pending"
    }
  },
  "status_code": 200
}
```

#### Test: Approve Provider Registration
```
POST http://localhost:8000/api/admin/providers/5/approve-registration
Headers:
  Authorization: Bearer {admin_token}
  Content-Type: application/json

Body:
{
  "notes": "Profil sudah lengkap dan terverifikasi"
}
```

---

## 🔄 WORKFLOW DIAGRAM

```
┌─────────────────────────────────────────┐
│      PROVIDER REGISTRATION FLOW         │
└─────────────────────────────────────────┘

1. Provider Registers
   ├─ POST /api/auth/register
   ├─ provider_status = 'pending' (set in backend)
   └─ Response includes provider_status

2. Provider Logs In
   ├─ POST /api/auth/login
   ├─ Response includes provider_status = 'pending'
   └─ Mobile: Check provider_status

3. Mobile Auth Guard Checks Status
   ├─ If status == 'pending'
   │  └─ Show AwaitingApprovalScreen (blocking)
   ├─ If status == 'rejected'
   │  └─ Show RejectionScreen
   └─ If status == 'approved'
      └─ Show HomePage (normal flow)

4. Admin Reviews Provider
   ├─ GET /api/admin/providers/pending-registration
   ├─ Admin sees pending providers with location info
   └─ Admin clicks Approve or Reject

5. Admin Approves
   ├─ POST /api/admin/providers/{id}/approve-registration
   ├─ provider_status = 'approved'
   └─ Webhook notification sent to provider

6. Provider Logs In Again
   ├─ provider_status = 'approved'
   ├─ Auth guard passes (provider_status != 'pending')
   └─ Provider can access home page & services
```

---

## 🧩 MODULAR COMPONENT USAGE

### Reusable: CascadingLocationSelector

```dart
// Use case 1: Registration form
CascadingLocationSelector(
  onSelectionChanged: (cityId, districtId) {
    // Save for later registration
  },
  isRequired: true,
)

// Use case 2: Edit profile
CascadingLocationSelector(
  onSelectionChanged: (cityId, districtId) {
    // Update provider profile
  },
  initialCityId: provider.cityId,
  initialDistrictId: provider.districtId,
  isRequired: true,
)

// Use case 3: Filter providers by location (customer view)
CascadingLocationSelector(
  onSelectionChanged: (cityId, districtId) {
    // Filter available providers
  },
  isRequired: false, // Optional filter
)
```

---

## ⚙️ CONFIGURATION

### API Base URL (if needed)

**File:** `mobile/lib/config/api_config.dart`

```dart
class ApiConfig {
  static const String baseUrl = 'http://10.0.2.2:8000'; // For emulator
  // static const String baseUrl = 'http://localhost:8000'; // For iOS simulator
  // static const String baseUrl = 'https://api.tukangdekat.com'; // Production
}
```

### Rate Limiting Expectations

- Public endpoints (GET /cities, /districts): 60 req/min
- Admin endpoints (POST/PUT/DELETE): 10 req/min
- If rate limited, exponential backoff akan automatic (retry interceptor)

---

## 🐛 TROUBLESHOOTING

### Issue: "Column city_id not found in users table"

**Solution:**
```bash
php artisan migrate
php artisan cache:clear
```

### Issue: Provider sees "Awaiting Approval" screen forever

**Solution:** Check admin panel → approve the provider
```
POST /api/admin/providers/{id}/approve-registration
```

### Issue: Cascading dropdown shows empty districts

**Solution:** Make sure city_id is selected first, then districts API is called with city_id parameter

### Issue: "Cannot update provider" error when updating location

**Solution:** Make sure both city_id and district_id are valid IDs that exist in database

---

## 📚 FURTHER READING

- Main Documentation: [REGIONALISASI_APPROVAL_IMPLEMENTATION.md](REGIONALISASI_APPROVAL_IMPLEMENTATION.md)
- Database Schema: Check migration file `2026_07_15_000001_add_location_and_approval_to_users_table.php`
- API Endpoints: See routes in `backend/routes/api.php`

---

✅ **Ready to integrate!** Follow these steps and your regionalization + approval system will be working.
