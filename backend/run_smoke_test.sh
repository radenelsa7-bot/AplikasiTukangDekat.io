#!/bin/bash
cd /var/www/html
php artisan test tests/Feature/SmokeTestFeature.php --colors=never
echo "Exit code: $?"
