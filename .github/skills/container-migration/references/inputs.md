# Container Migration — Inputs and Base Images

## Inputs

| Input | Required | Default | Description |
|---|---|---|---|
| `app_stack` | ✅ | — | `dotnet`, `python`, `java`, `node`, or `ruby` |
| `app_entry_point` | ✅ | — | Main entry point (e.g. `MyApp.dll`, `app.py`, `target/*.jar`, `server.js`) |
| `port` | ✅ | `<port>` | Port the app listens on |
| `target_platform` | ✅ | — | `aca` (Container Apps), `aks` (Kubernetes), or `acr-only` |
| `managed_identity` | ❌ | true | Wire up managed identity in container config |
| `app_name` | ❌ | — | Used for naming ACA/AKS resources |

## Base Images

| Stack | Build image | Runtime image |
|---|---|---|
| `dotnet` | `mcr.microsoft.com/dotnet/sdk:8.0` | `mcr.microsoft.com/dotnet/aspnet:8.0` |
| `python` | `python:3.12-slim` | `python:3.12-slim` |
| `java` | `eclipse-temurin:21-jdk-alpine` | `eclipse-temurin:21-jre-alpine` |
| `node` | `node:20-slim` | `node:20-slim` |
| `ruby` | `ruby:3.3-slim` | `ruby:3.3-slim` |
