#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------
# One‑command bootstrap script (Part 3)
# ---------------------------------------------------------------
# 1️⃣ Create (or reuse) a Kind cluster named "demo"
if ! kind get clusters | grep -q '^demo$'; then
  echo "Creating Kind cluster 'demo'..."
  kind create cluster --name demo \
  	--image kindest/node:v1.28.0 \
	--config kind-config.yaml \
  	--wait 5m
else
  echo "Kind cluster 'demo' already exists – reusing."
fi

# 2️⃣ Install ingress‑nginx controller (idempotent)
if ! kubectl get ns ingress-nginx >/dev/null 2>&1; then
  echo "Installing ingress‑nginx controller..."
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
  # Wait for the controller to become ready (max 2 min)
  kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=120s
else
  echo "Ingress controller already present."
fi

# 3️⃣ Build the Docker image and load it into Kind
IMG_NAME="my-service:dev"
echo "Building Docker image ${IMG_NAME}..."
docker build -t "${IMG_NAME}" ./service

echo "Loading image into Kind cluster..."
kind load docker-image "${IMG_NAME}" --name demo

# 4️⃣ Deploy (or upgrade) the Helm chart into namespace "demo"
NS=demo
if ! kubectl get ns "${NS}" >/dev/null 2>&1; then
  kubectl create namespace "${NS}"
fi

echo "Installing/upgrading Helm release 'demo'..."
helm upgrade --install demo ./chart \
  --namespace "${NS}" \
  --create-namespace \
  --set image.repository="${IMG_NAME%:*}" \
  --set image.tag="${IMG_NAME#*:}" \
  --set config.appName="demo-app" \
  --set config.version="1.0.0"

echo "✅ Setup complete."
