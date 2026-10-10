#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT}"

CLUSTER="demo"
RELEASE="demo"
NS="demo"
IMG_REPO="my-service"
IMG_TAG="dev"
IMG="${IMG_REPO}:${IMG_TAG}"
INGRESS_MANIFEST="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.3/deploy/static/provider/kind/deploy.yaml"

if ! kind get clusters | grep -qx "${CLUSTER}"; then
  echo "Creating kind cluster '${CLUSTER}'..."
  kind create cluster --name "${CLUSTER}" --config "${ROOT}/kind-config.yaml" --wait 5m
else
  echo "Kind cluster '${CLUSTER}' already exists — reusing."
  kubectl cluster-info --context "kind-${CLUSTER}" >/dev/null
fi

echo "Installing/updating ingress-nginx..."
kubectl apply -f "${INGRESS_MANIFEST}"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo "Building image ${IMG}..."
docker build -t "${IMG}" "${ROOT}/service"
echo "Loading image into kind..."
kind load docker-image "${IMG}" --name "${CLUSTER}"

echo "Installing/upgrading Helm release '${RELEASE}' in namespace '${NS}'..."
helm upgrade --install "${RELEASE}" "${ROOT}/chart" \
  --namespace "${NS}" \
  --create-namespace \
  --set image.repository="${IMG_REPO}" \
  --set image.tag="${IMG_TAG}" \
  --set image.pullPolicy=IfNotPresent \
  --wait --timeout 180s

echo "Setup complete."
