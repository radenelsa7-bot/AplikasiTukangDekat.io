# Quick Start - Live Tracking Map Testing

## 🚀 Prerequisites

### Backend Setup
```bash
cd backend

# Install dependencies
composer install

# Setup database
php artisan migrate

# Seed test data (optional)
php artisan db:seed

# Start server
php artisan serve
# Server runs on http://localhost:8000
```

### Mobile Setup
```bash
cd mobile

# Get dependencies
flutter pub get

# Run on device/emulator
flutter run

# Or run on specific device
flutter run -d chrome  # Web
flutter run -d emulator-5554  # Android emulator
```

## 📋 Pre-Test Checklist

- [ ] Backend running on http://localhost:8000
- [ ] Mobile app installed and running
- [ ] Network connection stable
- [ ] GPS enabled (for location picker)
- [ ] Test user account created
- [ ] Test order exists with provider assigned

## 🧪 Quick Test Scenarios

### Test 1: Display Tracking Map (5 mins)
```
1. Open app and login as CUSTOMER
2. Go to Orders
3. Tap any order with status "ACCEPTED" or higher
4. Scroll to "Tracking Lokasi" section
5. Verify: Map displays with markers
```

**Expected:** Orange (customer) and Green (provider) markers visible on map

### Test 2: Marker Interaction (3 mins)
```
1. On same order tracking page
2. Tap customer marker (orange dot)
3. Verify info popup shows
4. Tap provider marker (green dot)
5. Verify different popup shows
```

**Expected:** SnackBar shows location name and coordinates

### Test 3: Zoom Control (2 mins)
```
1. On tracking map
2. Tap "+" button (zoom in)
3. Verify map zooms in
4. Tap "-" button (zoom out)
5. Verify map zooms out
6. Try pinch zoom on map
```

**Expected:** Map zooms smoothly with constraints (5-18 zoom levels)

### Test 4: Pan/Drag (2 mins)
```
1. On tracking map
2. Drag map in different directions
3. Verify map pans smoothly
4. Verify no jittering or lag
```

**Expected:** Smooth map movement without lag

### Test 5: Auto-Refresh (5 mins)
```
1. Open tracking page
2. Note provider marker position
3. In another window, update provider location:
   - Option A: Use provider app to update location
   - Option B: Use API directly:
     curl -X POST http://localhost:8000/api/profile/update \
     -H "Authorization: Bearer {provider_token}" \
     -d "latitude=-6.1300&longitude=106.5750"
4. Wait 5 seconds
5. Verify: Provider marker moves to new location smoothly
6. Verify: Update timestamp changes
```

**Expected:** Provider marker animates to new location with smooth transition

### Test 6: No Location Fallback (2 mins)
```
1. Create new order without provider assigned
2. Go to order tracking page
3. Verify: Fallback message "Lokasi belum tersedia"
4. Verify: No errors in logs
```

**Expected:** Graceful fallback UI when no location available

## 🔍 Advanced Testing

### Memory Leak Test
```
1. Open DevTools: devtools
2. Open Memory profiler
3. Take heap snapshot
4. Open tracking page
5. Wait 30 seconds
6. Take another snapshot
7. Verify: Memory increase < 5MB
8. Navigate away
9. Force garbage collection
10. Verify: Memory returns to baseline
```

### Performance Test
```
1. Use Performance tab in DevTools
2. Record timeline while:
   - Opening tracking page
   - Zooming in/out
   - Panning map
   - Tapping markers
3. Verify: Frame rate stays at 60 FPS
4. Verify: No janky frames
```

### API Response Test
```bash
# Get order with tracking data
curl -H "Authorization: Bearer {token}" \
  http://localhost:8000/api/orders/1 | jq .data

# Expected response should include:
# - provider.full_name
# - customer_latitude, customer_longitude
# - provider_latitude, provider_longitude
# - All fields are present and numeric
```

## 🐛 Troubleshooting

### Map Not Loading
**Problem:** Blank map or loading forever
**Solution:**
1. Check internet connection
2. Verify OpenStreetMap tiles accessible
3. Check browser console for CORS errors
4. Try refresh page

### Markers Not Visible
**Problem:** Map shows but no markers
**Solution:**
1. Verify order has valid coordinates
2. Check API response has location data
3. Zoom to fit markers (may be outside visible area)
4. Check zoom level (try zoom in/out)

### Auto-Refresh Not Working
**Problem:** Provider marker doesn't update
**Solution:**
1. Verify `enableAutoRefresh: true` in code
2. Check network is working (API calls visible in Network tab)
3. Verify backend returns updated coordinates
4. Check device time is correct (affects polling)

### Performance Issues
**Problem:** Janky or laggy panning
**Solution:**
1. Reduce zoom level
2. Disable auto-refresh temporarily
3. Close other apps
4. Check device storage (not full)
5. Upgrade Flutter/Dart packages

### App Crashes
**Problem:** App crashes when opening tracking
**Solution:**
1. Check device logs: `flutter logs`
2. Verify API response is valid JSON
3. Check order data is not corrupted
4. Try force-stop app and restart
5. Check for null reference errors

## 📊 Monitoring

### Network Tab (Browser DevTools)
Monitor API calls:
- `/api/orders/{orderId}` should be called every 5 seconds
- Response should be < 1 second
- No 5xx errors

### Console Tab
Check for:
- JavaScript errors
- WebSocket connection issues
- Memory warnings

### Device Logs
```bash
flutter logs
```
Check for:
- Dart exceptions
- Platform-specific errors
- Network errors

## ✅ Acceptance Criteria

Feature is complete when:
- [ ] Map displays correctly
- [ ] Markers show customer and provider
- [ ] Route line connects locations
- [ ] Tap marker shows info popup
- [ ] Zoom controls work (+/-)
- [ ] Pinch zoom works
- [ ] Pan/drag works smoothly
- [ ] Auto-refresh every 5 seconds
- [ ] Provider marker animates smoothly to new location
- [ ] No memory leaks (heap snapshot stable)
- [ ] 60 FPS performance maintained
- [ ] All API responses correct format
- [ ] No crashes or errors

## 📞 Support

If issues occur:
1. Check [LIVE_TRACKING_TESTING_GUIDE.md](./LIVE_TRACKING_TESTING_GUIDE.md)
2. Check device logs: `flutter logs`
3. Check API response: Open Network tab
4. Verify backend is running: `curl http://localhost:8000`
5. Review implementation in [LIVE_TRACKING_IMPLEMENTATION.md](./LIVE_TRACKING_IMPLEMENTATION.md)

## 🎯 Next Steps

1. **Run all test scenarios** above
2. **Verify all acceptance criteria** passed
3. **Report any issues** found
4. **Document results** in test report
5. **Deploy to staging** after QA approval
6. **Deploy to production** after final verification

---

**Last Updated:** 2026-07-15
**Status:** Ready for Testing
