#!/bin/bash

echo "Starting Notes App..."

echo "Starting MongoDB..."
docker run --name notes-mongodb \
  --network notes-network \
  -v mongodb_data:/data/db \
  -d \
  mongo:latest

echo "Waiting for MongoDB to start..."
sleep 5

echo "Starting backend service..."
docker run --name notes-backend \
  --network notes-network \
  -p 3000:3000 \
  -e MONGO_URI=mongodb://notes-mongodb:27017/noteapp \
  -v $(pwd)/backend:/app \
  -v /app/node_modules \
  -d \
  notes-backend

echo "Starting frontend service with hot reload..."
docker run --name notes-frontend \
  --network notes-network \
  -p 8080:8080 \
  -v $(pwd)/frontend:/app \
  -v /app/node_modules \
  --user "$(id -u):$(id -g)" \
  -d \
  notes-frontend

echo "All services started!"
echo "Frontend is available at http://localhost:8080"
echo "Backend API is available at http://localhost:3000/api"
