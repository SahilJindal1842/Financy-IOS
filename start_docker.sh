#!/bin/bash
echo "Waiting for Docker daemon..."
while ! docker info > /dev/null 2>&1; do
    sleep 2
done
echo "Docker is up! Starting Postgres..."
cd Backend && docker compose up -d
