# GitHub Actions Workflow Template

Use this template as the starting point for any new CI/CD pipeline. Adapt stages and steps to match the project's language, framework, and deployment target.

## Workflow Structure

```yaml
name: CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  contents: read
  id-token: write  # Required for OIDC authentication

concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}

env:
  REGISTRY: <registry-url>          # e.g., ghcr.io/org/repo
  IMAGE_NAME: <image-name>

jobs:
  lint:
    name: Lint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<pinned-sha>
      - name: Set up runtime
        # Pin to a specific version of the language setup action
        uses: actions/setup-node@<pinned-sha>  # Adapt to language
        with:
          node-version-file: '.node-version'   # Adapt to language
      - name: Install dependencies
        run: npm ci                             # Adapt to package manager
      - name: Run linter
        run: npm run lint                       # Adapt to lint command

  test:
    name: Test
    runs-on: ubuntu-latest
    needs: [lint]
    steps:
      - uses: actions/checkout@<pinned-sha>
      - name: Set up runtime
        uses: actions/setup-node@<pinned-sha>
        with:
          node-version-file: '.node-version'
      - name: Install dependencies
        run: npm ci
      - name: Run tests
        run: npm test
      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@<pinned-sha>
        with:
          name: test-results
          path: test-results/

  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest
    needs: [lint]
    steps:
      - uses: actions/checkout@<pinned-sha>
      - name: Run dependency vulnerability scan
        # Replace with your preferred scanner (Trivy, Snyk, Dependabot, etc.)
        run: echo "Run dependency scan here"
      - name: Run SAST
        # Replace with your preferred SAST tool (CodeQL, Semgrep, etc.)
        run: echo "Run static analysis here"

  build:
    name: Build
    runs-on: ubuntu-latest
    needs: [test, security-scan]
    outputs:
      image-tag: ${{ steps.meta.outputs.tags }}
    steps:
      - uses: actions/checkout@<pinned-sha>
      - name: Generate image metadata
        id: meta
        # Use docker/metadata-action or equivalent to produce tags
        run: |
          echo "tags=${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}" >> "$GITHUB_OUTPUT"
      - name: Build container image
        run: |
          docker build \
            --tag "${{ steps.meta.outputs.tags }}" \
            --file Dockerfile \
            .
      - name: Scan image for vulnerabilities
        run: echo "Run image vulnerability scan here"
      - name: Push image to registry
        if: github.ref == 'refs/heads/main'
        run: |
          docker push "${{ steps.meta.outputs.tags }}"

  deploy-staging:
    name: Deploy to Staging
    runs-on: ubuntu-latest
    needs: [build]
    if: github.ref == 'refs/heads/main'
    environment:
      name: staging
      url: <staging-url>
    steps:
      - uses: actions/checkout@<pinned-sha>
      - name: Authenticate to cloud
        # Use OIDC / workload identity — no long-lived secrets
        run: echo "Authenticate via OIDC here"
      - name: Deploy to staging
        run: echo "Deploy image ${{ needs.build.outputs.image-tag }} to staging"
      - name: Run smoke tests
        run: echo "Run smoke tests against staging"

  deploy-production:
    name: Deploy to Production
    runs-on: ubuntu-latest
    needs: [deploy-staging]
    environment:
      name: production
      url: <production-url>
    steps:
      - uses: actions/checkout@<pinned-sha>
      - name: Authenticate to cloud
        run: echo "Authenticate via OIDC here"
      - name: Deploy to production
        run: echo "Deploy image ${{ needs.build.outputs.image-tag }} to production"
      - name: Run smoke tests
        run: echo "Run smoke tests against production"
      - name: Notify deployment complete
        if: success()
        run: echo "Send deployment notification"
```

## Runner Selection (`runs-on`)

Choose `runs-on` based on what the job actually needs. Defaulting all jobs to `ubuntu-latest` wastes self-hosted capacity and accumulates GitHub-hosted minutes unnecessarily.

### Decision tree

```text
Does the job need a managed identity, private network, or Key Vault?
  YES → self-hosted runner group
  NO  → Does it do heavy compute (image build, large compile)?
          YES → self-hosted runner group
          NO  → GitHub-hosted (ubuntu-latest)
```

### Routing patterns

```yaml
# Lightweight CI (lint, test, scan) — fast cold-start, no private network needed
runs-on: ubuntu-latest

# Deployment / cloud access — managed identity required
runs-on:
  group: <runner-group-name>
  labels: [self-hosted, linux, x64]

# Configurable via repository variable — set USE_SELF_HOSTED=true to engage self-hosted pool.
# fromJson() is required because GitHub Actions expressions must evaluate to a single
# scalar or object; the object form of runs-on cannot be written as a plain string.
runs-on: >-
  ${{
    vars.USE_SELF_HOSTED == 'true'
      && fromJson('{"group":"<runner-group-name>","labels":["self-hosted","linux","x64"]}')
      || 'ubuntu-latest'
  }}
```

Always add `timeout-minutes` to self-hosted jobs so the workflow fails fast when the runner pool is scaled to zero rather than waiting indefinitely.

See [references/runner-routing.md](references/runner-routing.md) for the decision matrix, hybrid pipeline pattern, and anti-patterns.

## Customization Notes

- **Pin all action versions** to full commit SHAs, not tags. Example: `actions/checkout@a5ac7e51b41094c92402da3b24376905380afc29` instead of `actions/checkout@v4`.
- **Adapt language steps** — replace Node.js setup, `npm ci`, and `npm run` commands with the project's language and package manager.
- **Add caching** — use `actions/cache` or the built-in cache support of setup actions to speed up dependency installation.
- **Configure environment protection rules** in GitHub repository settings: require reviewers, wait timers, and branch restrictions for staging and production environments.
- **Secrets** — store all credentials in GitHub Actions secrets or use OIDC for cloud provider authentication. Never hardcode secrets in workflow files.
