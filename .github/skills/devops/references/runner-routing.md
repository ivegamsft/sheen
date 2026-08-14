# Runner Routing Reference

Use this reference when choosing between GitHub-hosted and self-hosted runners.

## Choose GitHub-hosted runners when

- The job only needs public internet access
- The job is lightweight CI such as lint, unit tests, or markdown validation
- Fast startup time matters more than custom network access

## Choose self-hosted runners when

- The job needs private network access
- The job uses managed identity, private endpoints, or internal package feeds
- The job requires special hardware, licensed software, or long-running build capacity

## Recommended hybrid pattern

- Run lint, unit tests, and documentation checks on GitHub-hosted runners
- Run deployments and network-constrained integration tests on self-hosted runners
- Add `timeout-minutes` to self-hosted jobs so workflows fail fast when capacity is unavailable

## Anti-patterns

- Routing every job to self-hosted runners by default
- Using self-hosted runners without a timeout or capacity plan
- Mixing deployment credentials into GitHub-hosted jobs when a self-hosted deploy stage is available
