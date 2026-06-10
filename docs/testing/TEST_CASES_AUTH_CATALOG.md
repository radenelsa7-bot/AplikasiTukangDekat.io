# Test Cases: Authentication & Service Catalog API

**Version:** 1.0.0  
**Module:** Authentication & Service Catalog  
**Related FR:** FR-01, FR-02, FR-03, FR-04, FR-05, FR-06, FR-07, FR-08  
**Test Date:** Juni 2026  
**Tester:** Fatin Asyifa  
**Status:** Ready for Execution  

---

## 📋 Overview

Dokumen ini berisi test cases terstruktur untuk testing Authentication API dan Service Catalog API menggunakan Postman dan manual testing.

**Test Scope:**
- User Registration (FR-01)
- User Login (FR-02)
- Password Reset (FR-03)
- Token Management (FR-04)
- Role-Based Access (FR-05)
- List Services (FR-06)
- Filter Services (FR-07)
- Service Details (FR-08)

---

## Test Environment Setup

### Backend URL
```
Base URL: http://127.0.0.1:8000
API Version: v1
```

### Test Credentials

**Existing Users:**
```
Customer:
- Email: fajar@example.com
- Password: password123
- Role: customer

- Email: nabila@example.com
- Password: password123
- Role: customer

Provider:
- Email: andi.listrik@example.com
- Password: password123
- Role: provider

Admin:
- Email: admin@example.com
- Password: admin123
- Role: admin
```

---

## Test Case Suite 1: Authentication API

### TC-AUTH-001: User Registration - Valid Input
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-01

**Precondition:**
- Backend running
- New email not in database

**Test Steps:**
```
Endpoint: POST /api/v1/auth/register
Method: POST
Headers:
  Content-Type: application/json
  Accept: application/json

Body:
{
  "name": "Test User New",
  "email": "testuser.new@example.com",
  "password": "TestPass@123",
  "password_confirmation": "TestPass@123",
  "phone": "08123456789",
  "role": "customer"
}
```

**Expected Results:**
- ✅ Status Code: 201 Created
- ✅ Response contains:
  ```json
  {
    "message": "User registered successfully",
    "data": {
      "id": 10,
      "name": "Test User New",
      "email": "testuser.new@example.com",
      "phone": "08123456789",
      "role": "customer",
      "created_at": "2026-06-10T10:00:00Z"
    }
  }
  ```
- ✅ User entry created in database
- ✅ Verification email sent (check MailHog)
- ✅ User can login with new credentials

**Edge Cases:**
- Test dengan role "provider" → harus bisa register
- Test dengan special characters di name → harus accept
- Test dengan sudah existing email → harus return 422

---

### TC-AUTH-002: User Registration - Email Already Exists
**Priority:** HIGH  
**Type:** Negative Test  
**FR:** FR-01

**Test Steps:**
```
Endpoint: POST /api/v1/auth/register
Body:
{
  "name": "Duplicate Test",
  "email": "fajar@example.com",  // Sudah ada
  "password": "TestPass@123",
  "password_confirmation": "TestPass@123",
  "phone": "08111111111",
  "role": "customer"
}
```

**Expected Results:**
- ✅ Status Code: 422 Unprocessable Entity
- ✅ Response:
  ```json
  {
    "message": "The email has already been taken.",
    "errors": {
      "email": ["The email has already been taken."]
    }
  }
  ```
- ✅ No new user created

---

### TC-AUTH-003: User Registration - Invalid Password Format
**Priority:** HIGH  
**Type:** Negative Test  
**FR:** FR-01

**Test Steps:**
```
Body:
{
  "name": "Test User",
  "email": "newuser@example.com",
  "password": "weak",  // Too weak
  "password_confirmation": "weak",
  "phone": "08123456789",
  "role": "customer"
}
```

**Expected Results:**
- ✅ Status Code: 422
- ✅ Error message tentang password strength
- ✅ Password minimum 8 characters required

---

### TC-AUTH-004: User Login - Valid Credentials
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-02

**Test Steps:**
```
Endpoint: POST /api/v1/auth/login
Method: POST
Headers:
  Content-Type: application/json
  Accept: application/json

Body:
{
  "email": "fajar@example.com",
  "password": "password123"
}
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Response contains:
  ```json
  {
    "message": "Login successful",
    "data": {
      "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
      "user": {
        "id": 2,
        "name": "Fajar",
        "email": "fajar@example.com",
        "phone": "08123456789",
        "role": "customer",
        "avatar_url": null
      }
    }
  }
  ```
- ✅ JWT Token valid
- ✅ Token dapat digunakan untuk authenticated requests

**Verification:**
1. Copy token dari response
2. Test authenticated endpoint dengan token:
   ```
   GET /api/v1/user/profile
   Headers:
     Authorization: Bearer {token}
   ```
3. ✅ Status 200 dan user data returned

---

### TC-AUTH-005: User Login - Invalid Password
**Priority:** HIGH  
**Type:** Negative Test  
**FR:** FR-02

**Test Steps:**
```
Body:
{
  "email": "fajar@example.com",
  "password": "wrongpassword"
}
```

**Expected Results:**
- ✅ Status Code: 401 Unauthorized
- ✅ Response:
  ```json
  {
    "message": "Invalid credentials",
    "errors": {}
  }
  ```
- ✅ No token returned

---

### TC-AUTH-006: User Login - Email Not Found
**Priority:** HIGH  
**Type:** Negative Test  
**FR:** FR-02

**Test Steps:**
```
Body:
{
  "email": "notexist@example.com",
  "password": "password123"
}
```

**Expected Results:**
- ✅ Status Code: 401
- ✅ Message: "Invalid credentials"

---

### TC-AUTH-007: Access Protected Endpoint Without Token
**Priority:** HIGH  
**Type:** Negative Test  
**FR:** FR-04, FR-05

**Test Steps:**
```
Endpoint: GET /api/v1/user/profile
Headers:
  (No Authorization header)
```

**Expected Results:**
- ✅ Status Code: 401 Unauthorized
- ✅ Response:
  ```json
  {
    "message": "Unauthenticated"
  }
  ```

---

### TC-AUTH-008: Access Protected Endpoint With Invalid Token
**Priority:** HIGH  
**Type:** Negative Test  
**FR:** FR-04

**Test Steps:**
```
Endpoint: GET /api/v1/user/profile
Headers:
  Authorization: Bearer invalid.token.here
```

**Expected Results:**
- ✅ Status Code: 401
- ✅ Message: "Unauthenticated" atau "Invalid token"

---

### TC-AUTH-009: Access Protected Endpoint With Valid Token
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-04

**Test Steps:**
```
Endpoint: GET /api/v1/user/profile
Headers:
  Authorization: Bearer {valid_jwt_token}
  Accept: application/json
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Response berisi user profile data
- ✅ User hanya bisa akses data miliknya sendiri

---

### TC-AUTH-010: Password Reset - Request Reset
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-03

**Test Steps:**
```
Endpoint: POST /api/v1/auth/forgot-password
Body:
{
  "email": "fajar@example.com"
}
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Response:
  ```json
  {
    "message": "Password reset link sent to your email"
  }
  ```
- ✅ Email dikirim ke fajar@example.com (check MailHog)
- ✅ Email berisi reset link dengan token

---

### TC-AUTH-011: Logout
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-04

**Test Steps:**
```
Endpoint: POST /api/v1/auth/logout
Headers:
  Authorization: Bearer {valid_jwt_token}
  Accept: application/json
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Response:
  ```json
  {
    "message": "Logged out successfully"
  }
  ```
- ✅ Token tidak bisa digunakan lagi untuk authenticated requests
- ✅ Next request dengan token → 401 Unauthorized

---

### TC-AUTH-012: Role-Based Access - Customer accessing Provider Endpoint
**Priority:** HIGH  
**Type:** Negative Test  
**FR:** FR-05

**Test Steps:**
```
1. Login sebagai customer (fajar@example.com)
2. Get token dari login response
3. Try access provider endpoint:
   GET /api/v1/provider/dashboard
   Headers:
     Authorization: Bearer {customer_token}
```

**Expected Results:**
- ✅ Status Code: 403 Forbidden
- ✅ Response:
  ```json
  {
    "message": "Access denied. Provider role required."
  }
  ```

---

### TC-AUTH-013: Role-Based Access - Provider Can Access Provider Endpoint
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-05

**Test Steps:**
```
1. Login sebagai provider (andi.listrik@example.com)
2. Get token
3. Access provider endpoint:
   GET /api/v1/provider/dashboard
   Headers:
     Authorization: Bearer {provider_token}
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Response berisi provider dashboard data

---

## Test Case Suite 2: Service Catalog API

### TC-CATALOG-001: Get All Services - Without Filter
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-06

**Test Steps:**
```
Endpoint: GET /api/v1/services
Method: GET
Headers:
  Accept: application/json

Query Parameters: (none)
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Response structure:
  ```json
  {
    "message": "Services retrieved successfully",
    "data": [
      {
        "id": 1,
        "name": "Teknisi Listrik",
        "category": "Electrical",
        "description": "...",
        "price": 150000,
        "duration_minutes": 60,
        "rating": 4.8,
        "total_reviews": 25,
        "provider": {
          "id": 2,
          "name": "Andi",
          "avatar_url": null
        }
      },
      // ... more services
    ],
    "pagination": {
      "total": 12,
      "per_page": 10,
      "current_page": 1,
      "last_page": 2
    }
  }
  ```
- ✅ Minimal 3 services dalam response
- ✅ Pagination available jika >10 services
- ✅ Setiap service menampilkan: id, name, category, price, rating, provider

---

### TC-CATALOG-002: Get All Services - With Pagination
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-06

**Test Steps:**
```
Endpoint: GET /api/v1/services?page=2&per_page=5
Query Parameters:
  page: 2
  per_page: 5
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Response contains 5 items
- ✅ Pagination info:
  ```json
  "pagination": {
    "current_page": 2,
    "per_page": 5,
    "last_page": 3
  }
  ```

---

### TC-CATALOG-003: Get All Services - Sort by Rating (Highest First)
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-06

**Test Steps:**
```
Endpoint: GET /api/v1/services?sort=rating&order=desc
Query Parameters:
  sort: rating
  order: desc
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Services diurutkan berdasarkan rating (tertinggi di awal)
- ✅ First service memiliki rating lebih tinggi dari second

---

### TC-CATALOG-004: Get All Services - Sort by Price (Lowest First)
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-06

**Test Steps:**
```
Endpoint: GET /api/v1/services?sort=price&order=asc
Query Parameters:
  sort: price
  order: asc
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Services diurutkan berdasarkan price (terendah di awal)
- ✅ First service price ≤ second service price

---

### TC-CATALOG-005: Filter Services by Category
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-07

**Test Steps:**
```
Endpoint: GET /api/v1/services?category=Electrical
Query Parameters:
  category: Electrical
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Hanya services dengan category "Electrical" yang di-return
- ✅ Setiap service memiliki category: "Electrical"

---

### TC-CATALOG-006: Filter Services by Price Range
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-07

**Test Steps:**
```
Endpoint: GET /api/v1/services?min_price=100000&max_price=200000
Query Parameters:
  min_price: 100000
  max_price: 200000
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Semua services memiliki price >= 100000 dan <= 200000
- ✅ Jika tidak ada yang matching → data: []

---

### TC-CATALOG-007: Filter Services by Multiple Criteria
**Priority:** MEDIUM  
**Type:** Positive Test  
**FR:** FR-07

**Test Steps:**
```
Endpoint: GET /api/v1/services?category=Electrical&min_price=100000&max_price=250000&sort=rating&order=desc
Query Parameters:
  category: Electrical
  min_price: 100000
  max_price: 250000
  sort: rating
  order: desc
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Services filtered by category AND price range
- ✅ Results sorted by rating descending

---

### TC-CATALOG-008: Search Services by Name
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-07

**Test Steps:**
```
Endpoint: GET /api/v1/services?search=Listrik
Query Parameters:
  search: Listrik
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Response contains services dengan nama mengandung "Listrik"
- ✅ Case-insensitive search

---

### TC-CATALOG-009: Get Service Details by ID
**Priority:** HIGH  
**Type:** Positive Test  
**FR:** FR-08

**Test Steps:**
```
Endpoint: GET /api/v1/services/1
Method: GET
```

**Expected Results:**
- ✅ Status Code: 200 OK
- ✅ Response structure:
  ```json
  {
    "message": "Service details retrieved",
    "data": {
      "id": 1,
      "name": "Teknisi Listrik",
      "category": "Electrical",
      "description": "Layanan perbaikan dan instalasi listrik profesional",
      "price": 150000,
      "duration_minutes": 60,
      "rating": 4.8,
      "total_reviews": 25,
      "provider": {
        "id": 2,
        "name": "Andi",
        "email": "andi.listrik@example.com",
        "phone": "08123456789",
        "avatar_url": null,
        "rating": 4.8,
        "total_services": 15,
        "total_completed_orders": 150,
        "response_time": "< 2 jam"
      },
      "reviews": [
        {
          "id": 1,
          "rating": 5,
          "review": "Kerja profesional dan cepat",
          "reviewer_name": "Fajar",
          "created_at": "2026-05-20T10:00:00Z"
        },
        // ... more reviews
      ]
    }
  }
  ```
- ✅ Berisi detail lengkap service
- ✅ Berisi info provider
- ✅ Berisi reviews dari customers

---

### TC-CATALOG-010: Get Service Details - Invalid Service ID
**Priority:** MEDIUM  
**Type:** Negative Test  
**FR:** FR-08

**Test Steps:**
```
Endpoint: GET /api/v1/services/9999
```

**Expected Results:**
- ✅ Status Code: 404 Not Found
- ✅ Response:
  ```json
  {
    "message": "Service not found"
  }
  ```

---

### TC-CATALOG-011: Get Service Details - Non-numeric ID
**Priority:** MEDIUM  
**Type:** Negative Test  
**FR:** FR-08

**Test Steps:**
```
Endpoint: GET /api/v1/services/invalid
```

**Expected Results:**
- ✅ Status Code: 400 Bad Request atau 404
- ✅ Appropriate error message

---

## Manual Testing Checklist

### Pre-Test Checklist
- [ ] Backend running (http://127.0.0.1:8000)
- [ ] Postman installed and imported API collection
- [ ] Test credentials available
- [ ] MailHog running for email verification
- [ ] Database seeded with test data

### Test Execution Checklist

**Authentication Flow:**
- [ ] TC-AUTH-001: Successful registration
- [ ] TC-AUTH-002: Duplicate email handling
- [ ] TC-AUTH-003: Invalid password format
- [ ] TC-AUTH-004: Login with valid credentials
- [ ] TC-AUTH-005: Login with invalid password
- [ ] TC-AUTH-006: Login with non-existent email
- [ ] TC-AUTH-007: Access protected endpoint without token
- [ ] TC-AUTH-008: Access with invalid token
- [ ] TC-AUTH-009: Access with valid token
- [ ] TC-AUTH-010: Password reset request
- [ ] TC-AUTH-011: Logout functionality
- [ ] TC-AUTH-012: Role-based access (negative)
- [ ] TC-AUTH-013: Role-based access (positive)

**Service Catalog Flow:**
- [ ] TC-CATALOG-001: Get all services
- [ ] TC-CATALOG-002: Pagination working
- [ ] TC-CATALOG-003: Sort by rating
- [ ] TC-CATALOG-004: Sort by price
- [ ] TC-CATALOG-005: Filter by category
- [ ] TC-CATALOG-006: Filter by price range
- [ ] TC-CATALOG-007: Multiple filters
- [ ] TC-CATALOG-008: Search by name
- [ ] TC-CATALOG-009: Get service details
- [ ] TC-CATALOG-010: Invalid service ID
- [ ] TC-CATALOG-011: Non-numeric ID

---

## Postman Collection

Postman collection tersimpan di: `docs/postman/TukangDekat_API.postman_collection.json`

**How to use:**
1. Import file di Postman
2. Select environment: `TukangDekat.postman_environment.json`
3. Run individual requests atau full test suite
4. Check test results dan response

---

## Execution Report

| Test Case | Status | Notes | Date |
|-----------|--------|-------|------|
| TC-AUTH-001 | PENDING | - | - |
| TC-AUTH-002 | PENDING | - | - |
| TC-AUTH-003 | PENDING | - | - |
| ... | ... | ... | ... |

---

## Bugs Found

Document semua bugs yang ditemukan menggunakan format:

```
BUG-AUTH-001: Login tidak return token
Priority: Critical
Steps: Login dengan valid credentials
Actual: Token tidak di-return dalam response
Expected: Token harus di-return
Status: Open
```

---

**Document Version History:**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0.0 | Juni 2026 | Fatin Asyifa | Initial version - Auth & Catalog test cases |
