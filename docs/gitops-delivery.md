# GitOps delivery

Application repositories build immutable images tagged with the merged commit SHA. Their
main-build workflows use a dedicated `GITOPS_BOT_TOKEN` to create an image-bump pull
request in `py_wallet-infra`. The token must have access only to `py_wallet-infra` with:

- Contents: read and write
- Pull requests: read and write

It must not have administration permission or Kubernetes access. The token is stored as
an Actions secret named `GITOPS_BOT_TOKEN` in each application repository.

Infra pull requests are rendered and checked with kubeconform and repository policies.
Only a successful validation enables squash auto-merge. Argo CD then reconciles
`py_wallet-infra/main`; application CI never applies manifests to the cluster directly.

After an infra merge, verify both Argo state and the running immutable images:

```bash
scripts/verify-rollout.sh
```

The verifier requires a Kubernetes identity limited to read/watch access for Argo CD
Applications and workload Deployments. It does not require permission to create, update,
patch, or delete cluster resources.
