#!/bin/bash

echo "Deleting Notes App..."

./scripts/stop.sh

echo "Removing Docker images..."
docker rmi notes-frontend || true
docker rmi notes-backend || true

echo "Removing Docker network..."
docker network rm notes-network || true

# echo "Removing MongoDB volume..."
# docker volume rm mongodb_data || true

echo "Deletion complete!"
