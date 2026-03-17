#!/usr/bin/env bash
# Test Docker Compose Configuration

echo "Testing Docker Compose configuration..."
echo ""

# Test staging
echo "Testing staging configuration..."
docker compose -f docker-compose.yml -f docker-compose.staging.yml config > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Staging configuration is VALID"
else
    echo "❌ Staging configuration has errors"
    exit 1
fi

# Test production
echo "Testing production configuration..."
docker compose -f docker-compose.yml -f docker-compose.production.yml config > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "✅ Production configuration is VALID"
else
    echo "❌ Production configuration has errors"
    exit 1
fi

echo ""
echo "✅ All configurations are valid!"
echo ""
echo "Next step: Run 'docker compose up -d' to start services"
