# orca (internal)

The orchestration layer your AI agents are missing.

## Repos

| Repo | Description |
|------|-------------|
| [`.github`](https://github.com/orcastration-ai/.github) | Reusable GitHub Actions workflows, org profile |
| [`infra`](https://github.com/orcastration-ai/infra) | Terraform IaC — shared AWS resources for all services |
| [`orcastration.ai`](https://github.com/orcastration-ai/orcastration.ai) | Marketing website (Astro) |
| [`design.orcastration.ai`](https://github.com/orcastration-ai/design.orcastration.ai) | Shared design system — Storybook + npm package (Lit web components) |
| [`wiki.orcastration.ai`](https://github.com/orcastration-ai/wiki.orcastration.ai) | Business planning docs (VitePress, dev-only) |

**Planned:** api, registry, docs, app, orca-cli, console, blog, status, auth, investors, mobile app

## Environments

| Environment | Account ID | AWS Profile | Domain |
|-------------|-----------|-------------|--------|
| dev | `688365519974` | `orca-dev` | `dev.orcastration.ai` |
| prod | `654158184354` | `orca-prod` | `orcastration.ai` |

Region is always `us-east-1`.

## Tooling

- **Node.js 22** — see `.nvmrc` in each repo
- **pnpm 10** — all Node projects use pnpm
- **Terraform >= 1.5** — for `infra/`

## Deployment

All static sites follow the same flow:

1. Build produces `dist/`
2. CI uses reusable workflows from `.github` (`primary-static-site.yml`, `deploy-static-site.yml`)
3. Push to `main` deploys to **dev**; git tag `v*` deploys to **prod**
4. Deploy reads bucket name and CloudFront distribution ID from SSM at `/orca/<env>/sites/<site-id>/`
5. `aws s3 sync` to bucket, then CloudFront invalidation
