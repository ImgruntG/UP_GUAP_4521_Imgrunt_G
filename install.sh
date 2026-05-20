#!/bin/bash

set -e

IMAGE_TAR="paperio-image.tar"
IMAGE_NAME="paperio-image"
CONTAINER_NAME="game"
PORT="3000"

echo "=== INSTALLING DOCKER ==="

if ! command -v docker &> /dev/null
then
    apt update
    apt install -y docker.io curl
    systemctl enable docker
    systemctl start docker
fi

echo "=== CHECKING IMAGE FILE ==="

if [ ! -f "$IMAGE_TAR" ]; then
    echo "ERROR: $IMAGE_TAR not found in current directory"
    exit 1
fi

echo "=== LOADING DOCKER IMAGE ==="

docker load -i "$IMAGE_TAR"

echo "=== REMOVING OLD CONTAINER ==="

docker rm -f "$CONTAINER_NAME" 2>/dev/null || true

echo "=== STARTING CONTAINER ==="

docker run -d \
    --restart unless-stopped \
    -p $PORT:$PORT \
    --name "$CONTAINER_NAME" \
    "$IMAGE_NAME" \
    bash -c "cd /var/www/paperio && node server.js"

echo "WAITING FOR SERVER..."
sleep 5

echo "=== CHECKING CONTAINER ==="

if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "ERROR: container not running"
    docker logs "$CONTAINER_NAME"
    exit 1
fi

IP=$(hostname -I | awk '{print $1}')

echo "=== CHECKING GAME SERVER ==="

if curl -s "http://127.0.0.1:$PORT" > /dev/null; then
    echo ""
    echo "=================================="
    echo "GAME SERVER IS RUNNING"
    echo "http://$IP:$PORT"
    echo "=================================="
else
    echo "ERROR: server not responding"
    docker logs "$CONTAINER_NAME"
    exit 1
fi
