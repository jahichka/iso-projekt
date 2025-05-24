#!/bin/bash

echo "Setting up Notes App..."

docker network create notes-network || true

echo "Building frontend image..."
docker build -t notes-frontend ./frontend

echo "Building backend image..."
docker build -t notes-backend ./backend

echo "Pulling MongoDB image..."
docker pull mongo:latest

docker volume create mongodb_data || true

echo "Setup complete!"
