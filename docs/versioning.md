# Versioning and product releases

Every component follows Semantic Versioning and owns its version independently.
Before `1.0.0`, patch releases contain compatible fixes and minor releases may
contain features or breaking contract changes.

| Repository | Version source | Release artifact |
|---|---|---|
| `py_wallet` | `VERSION` | Git tag, GitHub Release, GHCR image |
| `py_wallet-front` | `VERSION`, `package.json` | Git tag, GitHub Release, GHCR image |
| `py_wallet-snapshot-service` | `VERSION`, `pyproject.toml` | Git tag, GitHub Release, GHCR image |
| `py_wallet-infra` | `VERSION` | Product manifest, Git tag, GitHub Release |
| `py_wallet-doc` | `VERSION` | Git tag and GitHub Release |

Git tags are immutable and use `vX.Y.Z`. Deployments continue to use an exact
commit SHA. A component release workflow only gives an already tested SHA image
its SemVer tag; it does not rebuild the source.

## Product release procedure

1. Merge and deploy the selected component revisions.
2. Verify that each SHA image exists and the GitOps applications are healthy.
3. Update `releases/vX.Y.Z.yaml` with the exact deployed SHAs.
4. Tag the matching component commits with their component versions.
5. Change the product manifest from `candidate` to `released` and add
   `releasedAt` in `YYYY-MM-DD` format.
6. Merge the manifest, then tag this repository with the product `vX.Y.Z` tag.
7. Tag the matching documentation revision.

The infra release workflow refuses to publish a candidate manifest. Existing
release tags must never be moved or reused.
