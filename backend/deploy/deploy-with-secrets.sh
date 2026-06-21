#!/bin/bash
# Deploy TukangDekat Backend with Secrets Injection
# Usage: ./deploy-with-secrets.sh <environment> <gemini_api_key>
# Example: ./deploy-with-secrets.sh production sk-...

set -e

ENVIRONMENT=${1:-staging}
GEMINI_API_KEY=${2:-}

if [ -z "$GEMINI_API_KEY" ]; then
    echo "Error: GEMINI_API_KEY is required"
    echo "Usage: $0 <environment> <gemini_api_key>"
    exit 1
fi

echo "================================"
echo "Deploying to $ENVIRONMENT"
echo "================================"

# Create .env file with secrets injected
echo "Creating .env with secrets..."
cat > .env << EOF
APP_NAME=TukangDekat
APP_ENV=$ENVIRONMENT
APP_KEY=$(head -c 32 /dev/urandom | base64)
APP_DEBUG=false
APP_URL=https://api.tukangdekat.local

DB_CONNECTION=mysql
DB_HOST=${DB_HOST:-db.prod.local}
DB_PORT=${DB_PORT:-3306}
DB_DATABASE=${DB_DATABASE:-tukangdekat_prod}
DB_USERNAME=${DB_USERNAME:-app_user}
DB_PASSWORD=${DB_PASSWORD:-$(echo $RANDOM | md5sum | head -c 20)}

# Gemini API Configuration (INJECTED FROM SECRETS)
GEMINI_API_ENDPOINT=https://generativelanguage.googleapis.com/v1beta/models/gemini-1.0-pro:generateContent
GEMINI_API_KEY=$GEMINI_API_KEY
GEMINI_API_MODEL=gemini-1.0

# Chatbot configuration
CHATBOT_ORDER_CONTEXT_COUNT=1
CHATBOT_GEMINI_RETRY_TIMES=3
CHATBOT_GEMINI_BASE_SLEEP_MS=200
CHATBOT_MAX_HISTORY=100
CHATBOT_RATE_LIMIT_LIMIT=10
CHATBOT_RATE_LIMIT_PERIOD_SECONDS=60

# Other environment variables
LOG_CHANNEL=stack
LOG_LEVEL=info
CACHE_STORE=redis
QUEUE_CONNECTION=redis
SESSION_DRIVER=database
EOF

echo "✓ .env file created with secrets injected"

# Run migrations
echo "Running migrations..."
php artisan migrate --force --env=$ENVIRONMENT

# Clear caches
echo "Clearing caches..."
php artisan config:clear
php artisan cache:clear
php artisan view:clear

# Restart services
echo "Restarting services..."
systemctl restart pm-uas-app || true

# Health check
echo "Running health check..."
sleep 5
STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health || echo "000")
if [ "$STATUS" -eq 200 ]; then
    echo "✓ Application is healthy (HTTP $STATUS)"
else
    echo "✗ Application health check failed (HTTP $STATUS)"
    exit 1
fi

echo "================================"
echo "✓ Deployment completed successfully!"
echo "================================"
echo "Environment: $ENVIRONMENT"
echo "API Endpoint: http://localhost:8000/api"
echo "Gemini API: CONFIGURED"
