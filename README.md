# DevOps Take‑Home Assignment – Enterprise Bot GmbH

## Overview
This repository implements the full assignment:
1. **Service** – a tiny Flask app (`service/app.py`) exposing `GET /` and `GET /healthz`.
2. **Docker image** – multi‑stage Dockerfile (`service/Dockerfile`) that builds the app, runs it as a non‑root user and pins the base image.
3. **Helm chart** (`chart/`) that deploys the service with configurable replicas, probes, resources, a ConfigMap for `APP_NAME`/`VERSION`, a Service and an Ingress (`demo.local`).
4. **`setup.sh`** – an idempotent script that creates a Kind cluster, installs `ingress-nginx`, builds the image, loads it into Kind and installs the chart.
5. **Lab** – the supplied `lab/` folder with a deliberately broken chart. All six defects have been fixed and documented in `lab/FINDINGS.md`.
6. **Answers** – `ANSWERS.md` contains the risk‑analysis answer.
7. **README** – this file, plus a short usage section at the bottom.
8. **Bonus** – optional GitHub Actions CI workflow (`.github/workflows/ci.yml`).

## Quick start – verify everything works
```bash
# Make the helper script executable
chmod +x setup.sh

# Run the one‑command installer (first run)
./setup.sh

# Run it again to prove idempotency (second run should also exit cleanly)
./setup.sh
```

### Verify the service
Add the Ingress hostname to your hosts file (Linux/macOS: `/etc/hosts`, Windows: `C:\Windows\System32\drivers\etc\hosts`):
```
127.0.0.1 demo.local
```
Then execute:
```bash
curl http://demo.local/
# Expected output (JSON) e.g.:
# {"app":"demo-app","version":"1.0.0","pod":"my-service-xxxx"}

curl -I http://demo.local/healthz   # should return HTTP 200
```
If you see the JSON and a 200 status, the service and Ingress are working.

### Verify the lab
```bash
cd lab
./scenario.sh up      # (re‑applies the fixed chart)
./scenario.sh verify  # should report 0 failing checks
```
All checks must pass. The `lab/FINDINGS.md` file contains one entry per defect, showing the symptom, cause, fix, and how the issue was discovered.

## Resource requests & limits (why?)
| Component | Requests | Limits | Rationale |
|-----------|----------|--------|-----------|
| Flask container | `100m` CPU, `128Mi` memory | `250m` CPU, `256Mi` memory | Small micro‑service – enough head‑room for occasional spikes while keeping the pod lightweight. |

## What we deliberately skipped & associated risk
| Skipped feature | Reason | Risk |
|----------------|--------|------|
| Horizontal Pod Autoscaler (HPA) | Not required for the assignment; would add extra complexity. | Under sudden load the two replicas could become saturated. |
| TLS termination on the Ingress | Out of scope; would require certificates and extra configuration. | Traffic is unencrypted – not suitable for production exposure. |
| Full CI/CD pipeline (bonus) | Optional – provided as an extra file but not required to pass the harness. | No automated gate to catch regressions; manual testing required. |

## Production‑grade improvements
- Add an **HPA** with sensible CPU utilization thresholds.
- Provision **TLS** via cert‑manager and Let’s Encrypt.
- Store the Docker image in a private registry and sign it.
- Harden the pod further (read‑only rootfs – already present; drop all capabilities – already present).
- Implement a full CI/CD pipeline (the optional GitHub Actions workflow is already provided).

## How I used AI
I consulted the Antigravity AI assistant for:
- Boiler‑plate generation of the Flask service, Dockerfile, Helm chart, and `setup.sh` script.
- Guidance on fixing the six defects in the supplied lab chart.
- Review of resource‑request sizing and idempotent scripting patterns.
All AI‑generated snippets were manually inspected, tested locally, and adjusted as needed before committing.

---
## How to run the project locally (full checklist)
1. Install the required tools (Docker, Kind, `kubectl`, `helm`).
2. Clone the repository.
3. Execute `chmod +x setup.sh && ./setup.sh`.
4. Add `127.0.0.1 demo.local` to your hosts file.
5. Verify the service with the `curl` commands above.
6. Run the lab verification (`cd lab && ./scenario.sh up && ./scenario.sh verify`).
7. Review `lab/FINDINGS.md` to see the defect‑by‑defect troubleshooting work.

Enjoy!
