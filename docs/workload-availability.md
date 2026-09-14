# Workload availability during voluntary disruption

This policy covers voluntary disruptions initiated by Kubernetes operators,
including node drain, cluster upgrades and voluntary pod eviction. It does not
replace readiness checks, rollout monitoring, or recovery from a node failure.

## API

The API runs two replicas with `maxUnavailable: 0` during a rolling update. Its
PodDisruptionBudget requires at least one ready API pod to remain available.
Kubernetes can therefore evict one replica for planned maintenance but will
not approve a second voluntary eviction until the replacement is ready.

The API request is 100m CPU and 128Mi memory per pod. The minimum planned
capacity is consequently 200m CPU and 256Mi memory before ingress, monitoring
and database workloads are considered.

## Frontend

The frontend now runs two replicas instead of one. Its PodDisruptionBudget also
requires one ready pod. This prevents planned maintenance from removing the
only browser entry point and preserves one available replica during an update
or voluntary eviction.

The frontend request is 25m CPU and 32Mi memory per pod, so the second replica
adds 25m CPU and 32Mi memory of requested cluster capacity.

## Snapshot service

The snapshot service intentionally remains a singleton. It owns scheduled
collection work; adding a second replica without a leader-election or
distributed-lock contract could produce duplicate work and misleading
freshness data. A PodDisruptionBudget with `minAvailable: 1` would also block a
node drain indefinitely because there is no second healthy replica.

Planned maintenance therefore restarts this service once. The service's job
handling must remain idempotent, and its health and freshness metrics must be
checked after the replacement becomes ready.

## HPA decision

No HorizontalPodAutoscaler is introduced in this change. CPU targets without a
production load baseline can make capacity and cost less predictable. Introduce
an API HPA only after recording sustained CPU and latency data, confirming that
metrics-server is available, and choosing a tested minimum/maximum replica
range. The frontend may use the same process. The snapshot service must remain
outside HPA until its scheduler has explicit singleton coordination.

## Verification

Before merging, render and validate every repository root:

```bash
rendered_dir="$(mktemp -d)"
scripts/render-manifests.sh "${rendered_dir}"
scripts/check-manifest-policy.sh "${rendered_dir}"
```

After Argo CD sync, check the objects and a controlled disruption in a
non-production environment:

```bash
kubectl -n py-wallet-dev get poddisruptionbudget
kubectl -n py-wallet-dev get deployment py-wallet py-wallet-front py-wallet-snapshot-service
kubectl -n py-wallet-dev get pods -l app=py-wallet
kubectl -n py-wallet-dev get pods -l app=py-wallet-front
```

Confirm that a voluntary eviction leaves one API and one frontend pod ready,
then confirm a snapshot run and its freshness metric after the singleton pod is
replaced.
