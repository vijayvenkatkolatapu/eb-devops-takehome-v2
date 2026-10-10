# Answers

## Q1 – Migrating 40 Ingress objects from ingress-nginx (EOL) to the Kubernetes Gateway API (zero‑downtime)

- **Inventory & version lock**
  - Export all existing Ingress resources: `kubectl get ingress -A -o yaml > all-ingresses.yaml`.
  - Record the current ingress‑nginx Helm version to keep the environment reproducible.

- **Install the Gateway API CRDs**
  - `kubectl kustomize github.com/kubernetes-sigs/gateway-api/config/crd?ref=v1.2.0 | kubectl apply -f -`
  - Verify with `kubectl get crd gateways.networking.x-k8s.io`.

- **Create a shared Gateway**
  - Deploy a single `Gateway` in a common namespace (e.g., `ingress-gateway`).
  - Map the external load‑balancer IP/host to the Gateway’s listener on port 80 (or 443).
  - The existing ingress‑nginx controller continues to serve traffic during this step.

- **Convert each Ingress → HTTPRoute** (automated script)
  - For every Ingress generate an equivalent `HTTPRoute` that references the shared Gateway, copying `host`, `path`, and backend service name/port.
  - Apply the generated routes with `kubectl apply -f <generated>.yaml` while **keeping the original Ingress** (do not delete yet) to allow instant rollback.

- **Test routing**
  - Pick a small subset (e.g., 5 services). Disable their Ingress (`kubectl annotate ingress <name> ingress.kubernetes.io/ignore=true`).
  - Verify requests still succeed via the Gateway: `curl -H "Host: <host>" http://<gateway‑lb>/`.
  - Validate health checks, TLS termination, and any custom annotations.

- **Gradual cut‑over**
  - Once a route is confirmed, delete the corresponding Ingress.
  - Continue the process until all 40 have been migrated.
  - Monitor controller logs and service metrics for regressions throughout.

- **Expected breakages & mitigation**
  - **Annotations** – ingress‑nginx specific annotations (e.g., `rewrite-target`, `whitelist-source-range`) have no direct Gateway equivalent; map them to `Filters` or `Policies` or implement via sidecars.
  - **TLS** – Ingress TLS secrets must be referenced in the Gateway listener; missing secrets cause 502 errors, so copy them beforehand.
  - **Host‑based routing** – Ensure the Gateway listener’s `hostname` matches the Ingress `host` field; mismatches result in 404.
  - **Custom NGINX modules** – Features like `ngx_http_lua_module` are unsupported; replace with native Kubernetes constructs or external sidecars.

- **Rollback plan**
  - Keep a Git‑tracked manifest of the original Ingress objects.
  - If a route fails, re‑apply the Ingress and delete the faulty HTTPRoute; DNS and load‑balancer stay unchanged, guaranteeing instant traffic restoration.

- **Post‑migration**
  - Remove the ingress‑nginx deployment and Helm release.
  - Enable autoscaling for the Gateway controller, add observability (Prometheus metrics), and update documentation to reflect the new API.

*Risk assessment:* The biggest risk is loss of custom NGINX annotations that have no Gateway counterpart; they must be carefully mapped or removed before decommissioning ingress‑nginx.
