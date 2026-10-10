# Findings — Part 4 debug lab

## Defect 1
**Symptom:** ServiceAccount reporter cannot list pods (verify output).
**Cause:** RoleBinding bound to `default` ServiceAccount.
**Fix:** Updated `templates/rbac.yaml` to bind to `reporter` ServiceAccount.
**How I found it:** `kubectl auth can-i list pods -n debug-lab --as=system:serviceaccount:debug-lab:reporter` returned *no*; inspected RBAC.

## Defect 2
**Symptom:** Backend pods never become Ready; health probe failures.
**Cause:** Probe used wrong port (default 80) while container serves on 8080.
**Fix:** Set `common.port: 8080` in `values.yaml` (used by probes and services).
**How I found it:** `kubectl describe pod backend-...` showed failing probe on port 80.

## Defect 3
**Symptom:** ImagePullBackOff for workloads.
**Cause:** `image.pullPolicy` defaulted to `Never`.
**Fix:** Set `pullPolicy: IfNotPresent` in `values.yaml`.
**How I found it:** `kubectl get pods` displayed `ImagePullBackOff`.

## Defect 4
**Symptom:** `scenario.sh verify` reports "migrate Job has not completed".
**Cause:** Job was named `migration` but script expects `migrate`.
**Fix:** Ensured Job name is `migrate` in `templates/migrate-job.yaml`.
**How I found it:** Checked Job manifest and verification script line 57.

## Defect 5
**Symptom:** Resource‑related checks failed (missing requests/limits).
**Cause:** No resources block for many components.
**Fix:** Added reasonable `requests`/`limits` for all components in `values.yaml`.
**How I found it:** Ran `kubectl top` and saw errors; examined chart values.

## Defect 6
**Symptom:** Services had no endpoints – pods not selected.
**Cause:** Service selectors didn’t match Deployment labels.
**Fix:** Ensured `{{ include "lab.labels" . }}` adds the same `app` label to Deployments and Services.
**How I found it:** `kubectl get svc backend -o yaml` showed empty selector; compared labels.
