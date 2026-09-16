# Runtime alerting

This repository defines Prometheus alert conditions for the public API,
snapshot pipeline and TLS certificate. Alert routing is configured by the
cluster's Alertmanager and is intentionally not stored with application
credentials in this repository.

## Alert policy

| Alert | Threshold | Severity | Response |
| --- | --- | --- | --- |
| `PyWalletApiTargetDown` | API scrape unavailable for 5 minutes | critical | Check the API Deployment, endpoints, ServiceMonitor and ingress. |
| `PyWalletApiHigh5xxRate` | 5xx rate over 5% for 10 minutes with traffic above 0.1 requests/s | warning | Inspect API logs, recent deploys, database readiness and request latency. |
| `PyWalletSnapshotServiceTargetDown` | Snapshot scrape unavailable for 10 minutes | warning | Check the singleton Deployment, Service and ServiceMonitor. |
| `PyWalletSnapshotQueueStalled` | Oldest pending job exceeds 15 minutes for 15 minutes | warning | Inspect queue depth, worker logs, database connectivity and external RPC health. |
| `PyWalletTlsCertificateExpiringSoon` | Certificate expires within 7 days | warning | Verify cert-manager renewal status and ACME challenge routing. |
| `PyWalletTlsCertificateExpiringCritical` | Certificate expires within 24 hours | critical | Treat renewal as an immediate incident. |

The API error-rate rule requires sustained traffic so a single low-volume
failure does not trigger a page. Snapshot partial outcomes are intentionally
not an alert by themselves: partial completion can be an honest result of
multi-chain collection and should be investigated through the dashboard before
changing a threshold.

## Triage

Start by checking the deployed revision and target health:

```bash
kubectl -n py-wallet-dev get deployment,service,endpoints
kubectl -n py-wallet-dev get pods -o wide
kubectl -n monitoring get prometheusrule py-wallet-runtime
```

For an API alert, review the API readiness endpoint, recent Argo CD sync state,
and database connectivity. For a snapshot alert, check the single worker's
logs, its `snapshot_worker_*` metrics, and the external RPC provider state.
For a TLS alert, inspect the Certificate and CertificateRequest resources:

```bash
kubectl -n py-wallet-dev describe certificate py-wallet-tls
kubectl -n py-wallet-dev get certificaterequest,order,challenge
```

## SLO boundary

These alerts are operational thresholds, not yet a published availability or
freshness SLO. Define an SLO only after collecting enough production data to
set a user-facing objective, error budget, measurement window and alert
delivery route. The dashboard remains the source for observed API latency,
snapshot queue age and persisted wallet-summary freshness.

## Verification

Render and validate the repository before merge:

```bash
rendered_dir="$(mktemp -d)"
scripts/render-manifests.sh "${rendered_dir}"
scripts/check-manifest-policy.sh "${rendered_dir}"
python3 scripts/check-grafana-dashboard.py
```

After Argo CD sync, verify that Prometheus loads the rule and that all alerts
are inactive under healthy conditions. Use a non-production environment for a
controlled target outage or certificate fixture; do not simulate failure in a
production workload merely to test the notification route.
