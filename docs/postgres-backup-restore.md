# PostgreSQL backup and restore

The `postgres-backup` CronJob creates a daily logical PostgreSQL dump and
uploads it to an encrypted S3-compatible object-storage destination. It is
committed with `spec.suspend: true`: no backup runs until a destination is
configured and a restore rehearsal succeeds.

## Backup contract

- Schedule: 02:15 UTC daily, with overlapping runs forbidden.
- Format: `pg_dump --format=custom`, suitable for `pg_restore`.
- Integrity: a SHA-256 sidecar file is uploaded with each dump.
- Destination: a private bucket with versioning, server-side encryption,
  lifecycle retention, and access limited to this backup workload.
- Recovery point objective: at most 24 hours after the job is enabled and
  independently observed as successful.
- Recovery time objective: establish from a measured restore rehearsal; do not
  infer it from dump size or Kubernetes resource limits.

The job mounts only an `emptyDir` for transfer. A completed dump is useful only
after the upload container has copied both the dump and checksum to object
storage. The local PostgreSQL PVC is not used as a backup destination because
it cannot recover a node or volume loss.

## Configure the destination

Create a dedicated bucket; do not reuse the Terraform state bucket. Enable
versioning, default encryption, public-access blocking, and a lifecycle policy
that matches the retention requirement. Create a least-privilege identity that
can write only to the selected backup prefix and read it for a restore.

The Job expects a Secret named `postgres-backup-destination` in
`py-wallet-data` with these keys:

| Key | Purpose |
| --- | --- |
| `AWS_ACCESS_KEY_ID` | Backup identity access key. |
| `AWS_SECRET_ACCESS_KEY` | Backup identity secret key. |
| `AWS_DEFAULT_REGION` | Bucket region. |
| `BACKUP_S3_BUCKET` | Private destination bucket name. |
| `BACKUP_S3_PREFIX` | Prefix reserved for PostgreSQL dumps. |

Create it only from a trusted terminal, seal it before committing, and never
put plaintext credentials in Git. Follow the same `kubectl create secret |
kubeseal` workflow as the Telegram secret runbook. Add the resulting encrypted
manifest to `manifests/postgres/kustomization.yaml` in the same reviewed change.

After Argo CD sync confirms the encrypted Secret is present, change only this
CronJob's `spec.suspend` to `false` in a reviewed Git commit. Do not enable it
with an imperative patch: Git must remain the source of truth.

## Restore rehearsal

Perform a rehearsal in an isolated database or non-production namespace. Never
restore over the live production database as a test.

1. Download the dump and checksum from the selected object key.
2. Verify the checksum before invoking PostgreSQL tools.
3. Restore to the isolated target with `pg_restore --clean --if-exists
   --no-owner`.
4. Verify schema revision, representative tables, application readiness and
   snapshot-service connectivity.
5. Record duration, dump timestamp, checksum result and observed data age in
   the operational change record.

For a controlled incident restore, first stop application writes and the
snapshot worker, choose the latest verified object, restore, verify the data,
then resume services in a reviewed sequence.

## Verification

Before merge, render and validate the repository:

```bash
rendered_dir="$(mktemp -d)"
scripts/render-manifests.sh "${rendered_dir}"
scripts/check-manifest-policy.sh "${rendered_dir}"
```

After configuration and Argo CD sync, check that the CronJob remains suspended
until the encrypted destination Secret and rehearsal evidence are ready:

```bash
kubectl -n py-wallet-data get cronjob postgres-backup
kubectl -n py-wallet-data get secret postgres-backup-destination
```

After enabling, inspect both containers for every first run and verify the
object and checksum in the destination before considering the backup usable.
