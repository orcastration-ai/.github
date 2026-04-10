# .github

This is the [special `.github` repository](https://docs.github.com/en/organizations/collaborating-with-groups-in-organizations/customizing-your-organizations-profile) for the `orcastration-ai` organization.

It serves two purposes:

1. **Organization profile** — `profile/README.md` is displayed on the [org homepage](https://github.com/orcastration-ai).
2. **Member profile** — `profile/README-member.md` is shown to org members on the org homepage.
3. **Shared workflows** — reusable GitHub Actions workflows in `.github/workflows/` that other repos call via `workflow_call`.

## Shared Workflows

| Workflow | Purpose |
|----------|---------|
| `primary-static-site.yml` | Lint, test, and build pipeline for static sites |
| `deploy-static-site.yml` | Build, S3 sync, and CloudFront invalidation for static sites |

### Usage

Calling repos need only thin workflow files:

```yaml
# .github/workflows/primary.yml
name: Primary
on:
  push:
    branches: [main]
  pull_request:
jobs:
  primary:
    uses: orcastration-ai/.github/.github/workflows/primary-static-site.yml@main
```

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  workflow_dispatch:
  workflow_run:
    workflows: [Primary]
    types: [completed]
    branches: [main]
  push:
    tags: ["v*"]
permissions:
  id-token: write
  contents: write
jobs:
  deploy:
    uses: orcastration-ai/.github/.github/workflows/deploy-static-site.yml@main
    with:
      site-id: my-site
```
