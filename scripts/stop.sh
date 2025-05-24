#!/bin/bash

echo "Stopping Notes App..."

echo "Stopping frontend..."
docker stop notes-frontend || true
docker rm notes-frontend || true

echo "Stopping backend..."
docker stop notes-backend || true
docker rm notes-backend || true

echo "Stopping MongoDB..."
docker stop notes-mongodb || true
docker rm notes-mongodb || true

echo "All services stopped!"
