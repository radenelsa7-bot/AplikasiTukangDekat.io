Sentry integration (scaffold)
=============================

This document describes a minimal, non-invasive approach to enable Sentry error reporting for the Laravel backend.

Steps:

1. Add `SENTRY_DSN` to your environment (production/staging) — do NOT commit the DSN.

2. Install Sentry SDK on the deployment environment (example):

   composer require sentry/sentry-laravel

3. Add configuration (example in `.env`):

   SENTRY_LARAVEL_DSN=${SENTRY_DSN}
   SENTRY_TRACES_SAMPLE_RATE=0.0

4. (Optional) Register Sentry in `config/logging.php` as a channel and ensure `report()` in exception handler uses `if (app()->bound('sentry') ) { app('sentry')->captureException($e); }`.

5. Verify on staging by throwing a test exception or using `Sentry\init([...])` in tinker.

Notes
- This repo does not add the Sentry package automatically to avoid modifying composer.lock here; installing must be done where you control deployment.
- The recommended minimal change is to call Sentry from the exception handler when `SENTRY_LARAVEL_DSN` is present.
