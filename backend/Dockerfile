# 1. Menggunakan image PHP 8.3 dengan FPM (Laravel 12 butuh minimal PHP 8.2)
FROM php:8.3-fpm-alpine

# 2. Install sistem dependencies menggunakan APK (Sistem bawaan Alpine Linux)
RUN apk update && apk add --no-cache \
    git \
    curl \
    libpng-dev \
    oniguruma-dev \
    libxml2-dev \
    zip \
    unzip

# Install PHP extensions yang dibutuhkan Laravel
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd

# 3. Ambil Composer terbaru resmi dari Docker Hub
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 4. Set direktori kerja di dalam kontainer
WORKDIR /var/www

# 5. Salin semua file dari folder backend lokal ke dalam kontainer
COPY . /var/www

# 6. Jalankan composer install untuk mengunduh vendor Laravel
RUN composer install --no-interaction --optimize-autoloader --no-dev

# 7. Berikan hak akses (permission) folder storage ke Docker (-R artinya Recursive)
RUN chown -R www-data:www-data /var/www/storage /var/www/bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]
