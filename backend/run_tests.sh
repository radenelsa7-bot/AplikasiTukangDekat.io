#!/bin/bash
set -e

cd /var/www/html

echo "============================================"
echo "BACKEND TEST SUITE EXECUTION"
echo "============================================"
echo ""

echo "Starting test execution..."
echo ""

# Run all tests with verbose output
php artisan test --no-interaction 2>&1

echo ""
echo "============================================"
echo "TEST EXECUTION COMPLETE"
echo "============================================"
