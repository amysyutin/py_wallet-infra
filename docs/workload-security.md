# Workload isolation and runtime hardening

This document defines the runtime isolation boundary for the py_wallet
workloads. It applies to the API, frontend, snapshot service, migration Jobs
and PostgreSQL in the GitOps repository. It does not contain secret values or
change the sealed-secret workflow.

## Controls in this repository

### Non-root Python workloads

The API and snapshot-service images declare the `appuser` user in their
Dockerfiles. Their Deployments and migration Jobs therefore set
`runAsNonRoot: true`, use the `RuntimeDefault` seccomp profile, disable service
account token mounting, disallow privilege escalation, drop all Linux
capabilities, and mount the root filesystem read-only.

The Telegram daily balance Job already had the same controls. All Python
workloads avoid bytecode writes through `PYTHONDONTWRITEBYTECODE=1`, so no
writable root filesystem is required.

### NetworkPolicy ingress boundary

Kubernetes enforces a NetworkPolicy only when the installed CNI supports it.
These policies deliberately limit ingress first; unrestricted egress remains
necessary for DNS, PostgreSQL connections, image-independent application calls
and the snapshot service's external RPC providers. Egress can be reduced after
recording those destinations from a running cluster.

| Target | Allowed source | Port | Reason |
| --- | --- | --- | --- |
| API | `kube-system` | 8000 | Traefik routes `/api`. |
| API | `monitoring` | 8000 | Prometheus scrapes `/metrics`. |
| API | `py-wallet-dev` | 8000 | Internal scheduled jobs call the API. |
| Frontend | `kube-system` | 80 | Traefik routes browser traffic. |
| Snapshot service | `monitoring` | 8001 | Prometheus scrape. |
| Snapshot service | `py-wallet-dev` | 8001 | Internal health and service access. |
| PostgreSQL | API pod in `py-wallet-dev` | 5432 | Application database connection. |
| PostgreSQL | snapshot-service pod in `py-wallet-dev` | 5432 | Snapshot storage connection. |

The policies rely on Kubernetes' immutable namespace label
`kubernetes.io/metadata.name`. Before rollout, confirm that Traefik is in
`kube-system` and Prometheus is in `monitoring`:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik
kubectl get pods -n monitoring
kubectl get namespace --show-labels
```

If Traefik uses another namespace, update the `namespaceSelector` in the API
and frontend policies in the same pull request before merging. Do not loosen a
policy to every namespace as a substitute.

## Deliberate exceptions

The frontend image currently starts the stock NGINX image on port 80 and does
not declare a non-root user. PostgreSQL initialisation also needs ownership
handling for its data volume. This change does not force either image to run as
an unknown UID because that could break rollout or database initialisation.

The next hardening step is to publish a non-root frontend image that listens on
an unprivileged port and supplies writable `emptyDir` mounts only for NGINX
cache and pid files. PostgreSQL needs a separate tested change covering volume
ownership and its data directory before enabling `runAsNonRoot` or a read-only
root filesystem.

## Verification before merge

Run the repository checks:

```bash
rendered_dir="$(mktemp -d)"
scripts/render-manifests.sh "${rendered_dir}"
scripts/check-manifest-policy.sh "${rendered_dir}"
python3 scripts/check-grafana-dashboard.py
```

CI additionally runs Kubeconform against Kubernetes and repository CRD
schemas. After Argo CD sync, verify both the policy objects and the actual
traffic paths:

```bash
kubectl -n py-wallet-dev get networkpolicy
kubectl -n py-wallet-data get networkpolicy
kubectl -n py-wallet-dev rollout status deployment/py-wallet --timeout=120s
kubectl -n py-wallet-dev rollout status deployment/py-wallet-snapshot-service --timeout=120s
kubectl -n py-wallet-dev get endpoints py-wallet py-wallet-front py-wallet-snapshot-service
kubectl -n py-wallet-data get endpoints postgres
```

Confirm browser access to the frontend and `/api`, Prometheus target health,
and a successful snapshot run. If either route or scrape fails, inspect the
namespace and pod labels before changing a policy.

The validation workflow does not merge this kind of infrastructure pull
request. Auto-merge is limited to verified `deploy/` image-bump branches, so a
maintainer can review the workload-isolation change and these rollout checks
before merging it.
