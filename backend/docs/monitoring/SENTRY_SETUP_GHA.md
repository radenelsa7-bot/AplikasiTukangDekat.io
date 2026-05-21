Contoh pengaturan channel `sentry` dan snippet GitHub Actions
=============================================================

1) Contoh potongan yang dapat ditambahkan ke `config/logging.php`:

```php
'sentry' => [
    'driver' => 'sentry',
    'level' => env('SENTRY_LOG_LEVEL', 'error'),
],

// lalu di 'channels' atau stack:
'stack' => [
    'driver' => 'stack',
    'channels' => ['single', 'sentry'],
    'ignore_exceptions' => false,
],
```

2) Contoh GitHub Actions workflow (CI) untuk meng-install dependensi dan menjalankan test dengan `SENTRY_LARAVEL_DSN` disuntikkan dari secret:

```yaml
name: CI

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
      - name: Install composer dependencies
        working-directory: backend
        run: composer install --no-progress --no-suggest --prefer-dist --no-interaction
      - name: Run tests
        env:
          SENTRY_LARAVEL_DSN: ${{ secrets.SENTRY_LARAVEL_DSN }}
        working-directory: backend
        run: ./vendor/bin/phpunit --testdox
```

3) Catatan:
- Pastikan menambahkan `SENTRY_LARAVEL_DSN` ke repository secrets (GitHub -> Settings -> Secrets).
- Jangan commit DSN atau secrets ke kode sumber.
