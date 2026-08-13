# Container Migration — Anti-Patterns and Related Skills

## Anti-Patterns

- **Never use `:latest`** image tags in production — always pin to digest or SHA
- **Always set CPU/memory resource limits** — unbounded containers starve neighbours
- **Never run as root** — always `USER appuser` in the Dockerfile runtime stage
- **Never store secrets in Dockerfile** — use Key Vault references or mounted secrets
- **Never use `ADD` for local files** when `COPY` suffices — `ADD` has implicit extraction behaviour

## Related Skills and Agents

- `azure-linux-app-service` skill — App Service alternative when containerization is not required
- `legacy-modernization` agent — determines whether containerization is the right modernization path
- `java-spring-boot.instructions.md` — layered JARs pattern for Java multi-stage builds
