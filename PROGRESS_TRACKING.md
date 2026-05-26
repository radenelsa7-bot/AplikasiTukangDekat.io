## Progress Tracking - Project Aplikasi TukangDekat

Tanggal: 2026-05-21

Dokumen ini mencatat progres backend dan frontend dalam satu tempat, supaya mudah dilacak dari awal sampai akhir.

## Sudah Selesai

### Backend
- Hardened `XenditPayoutGateway` untuk payout pipeline.
- Menyimpan response provider ke tabel `payout_provider_responses`.
- Menambahkan notifikasi `PayoutFailed`.
- Menambahkan job antrian `SendPayoutAlertWebhook`.
- Menulis unit test untuk adapter, monitoring, dan job.
- Memperbarui dokumentasi deploy/secrets dan runbook.
- Menyelesaikan `RELEASE_NOTES.md` dan `QA_CHECKLIST.md`.
- Menjalankan full PHPUnit test suite, semua lulus.
- Merilis tag `v1.0.0` dan memperbarui draft release menjadi release publik.
- Commit dan push perubahan ke `main` sudah dilakukan.
- ✅ **feature/backend-122-ci-staging**: Menambahkan GitHub Actions workflow `ci-staging.yml` untuk job integration/staging yang digate oleh secrets (`DEPLOY_KEY`). Job berjalan saat push/dispatch ke branch ini, melakukan: composer install, setup .env dari secrets, migrate, dan run tests. Fallback job informatif jika secrets tidak dikonfigurasi.

### Frontend
- Status frontend utama masih fokus pada tracking branch dan pemetaan issue.
- Branch tracking frontend sudah dibuat untuk memudahkan pemisahan task.
- Struktur progres frontend sudah dipetakan ke beberapa milestone: foundation, service flow, payment flow, dan polish/release.

### Manajemen Proyek
- Branch tracking backend/frontend sudah dibuat.
- Draft PR tracking sudah dibuat untuk beberapa grup task agar management lebih rapi.
- Issue terbuka di board GitHub sudah di-cross check dan dibagi lebih merata ke collaborator yang valid.
- Status board GitHub sudah dirapikan menjadi campuran `Done`, `In progress`, dan `Ready` supaya progres yang sudah selesai dan yang masih antri terlihat jelas.
- Pembagian issue sudah diseimbangkan ulang sehingga beban kerja tiap collaborator lebih rata.
- Seluruh issue open yang sempat masuk ke filter `No Assignees` pada board PM_uts sudah dibagikan; sisa tanpa assignee sekarang `0`.

## Evaluasi Akhir

### Backend
- Integration test network failure dan backoff sudah disiapkan dan divalidasi.
- Migrasi, queue worker, smoke test, dan post-deploy verification sudah tercatat sebagai checklist operasional.
- Monitoring/metrics produksi sudah ada baseline-nya lewat Sentry dan endpoint metrics.

### Frontend
- UI payout-alerts, build/tests frontend, dan update integrasi masih menjadi area verifikasi manual bila frontend lanjut dikerjakan.
- Tidak ada blocker baru dari sisi backend untuk melanjutkan task frontend.

### Kesimpulan
- Progress tracking sudah selaras dengan script setup.
- Daftar assignee dan branch tracking sudah konsisten.
- Tidak ada item kritis yang tersisa; yang ada hanya verifikasi manual jika scope frontend masih dibuka.

## Tracking Branch dan PR

### Backend Tracking Branch
- `feature/backend-89-90-foundation-tracking` - foundation, setup, auth, services, models.
- `feature/backend-101-103-core-api-tracking` - orders, DP auto-create, reviews.
- `feature/backend-109-111-payments-webhooks-tracking` - payment gateway, webhook, n8n integration.
- `feature/backend-119-124-finalization-deploy-tracking` - admin endpoints, hardening, deploy.

### Frontend Tracking Branch
- `feature/frontend-91-99-foundation-tracking` - setup, wireframe, login, home, register.
- `feature/frontend-104-106-service-flow-tracking` - form booking, detail layanan, provider profile.
- `feature/frontend-112-114-payment-flow-tracking` - pembayaran DP, pembayaran sisa, rating/review.
- `feature/frontend-116-125-polish-release-tracking` - integration, polish UI, build APK.

## Branch Tracking Referensi

Bagian ini dipertahankan sebagai arsip pemetaan branch/issue agar jejak kerja tetap mudah dibaca, bukan sebagai daftar pekerjaan yang masih menggantung.

### Backend
- `feature/backend-121-integration-backoff` - integration test untuk network failures dan backoff.
- `feature/backend-123-deploy-smoke` - migrasi staging, enable queue worker, dan smoke test post-deploy.
- `feature/backend-124-monitoring-alerts` - monitoring/metrics produksi dan alerting.

### Frontend
- `feature/frontend-125-alert-ui` - UI notifikasi payout untuk admin/treasurer.
- `feature/frontend-126-tests` - build dan run frontend tests.
- `feature/frontend-127-api-notes` - update API docs dan frontend integration notes.

### Status Repository
- Branch aktif saat ini: `main`
- Remote `main` sudah di-push
- Working tree bersih
- Setup script sudah di-cross check dan idempotent.

## Catatan

- Dokumen ini bersifat ringkas dan fokus pada backend/frontend.
- Jika ada perubahan besar, update bagian "Sudah Selesai" dan "Evaluasi Akhir" terlebih dahulu.
- Untuk repositori ini, evaluasi akhir lebih dulu sebelum menambah task baru agar tracking tetap bersih.
- Jika ada branch baru, taruh di bagian referensi ini dulu supaya tidak mengubah status akhir yang sudah selesai.
- Beberapa nama yang diberikan tidak sama persis dengan login GitHub yang valid, jadi board memakai login collaborator yang benar agar perubahan bisa tersimpan.

