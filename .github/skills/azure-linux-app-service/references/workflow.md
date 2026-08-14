# Azure Linux App Service — Workflow

## 1. Runtime and Startup Command

Set the Linux runtime and startup command before first deploy:

```bash
az webapp config set \
  --resource-group <rg> --name <app> \
  --linux-fx-version "PYTHON|3.11" \
  --startup-file "gunicorn --bind=0.0.0.0:8000 --timeout 600 myapp:app"
```

Startup command examples:

- Python (Gunicorn): `gunicorn --bind=0.0.0.0:8000 --timeout 600 myapp:app`
- Ruby (Puma): `bundle exec puma -C config/puma.rb`
- Node.js: `node server.js` or `npm start`

## 2. App Settings (Environment Variables)

Inject secrets and config as App Settings — never bake them into code:

```bash
az webapp config appsettings set \
  --resource-group <rg> --name <app> \
  --settings DATABASE_URL="<value>" SECRET_KEY="<value>" NODE_ENV="production"
```

Use Key Vault references for sensitive values:

```bash
--settings DATABASE_URL="@Microsoft.KeyVault(SecretUri=https://<kv>.vault.azure.net/secrets/<name>/)"
```

## 3. Health Check Endpoint

Configure health checks so the platform routes traffic away from unhealthy instances:

```bash
az webapp config set \
  --resource-group <rg> --name <app> \
  --generic-configurations '{"healthCheckPath": "/health"}'
```

The `/health` endpoint must return HTTP 200. Path is checked every 2 minutes;
instances failing for 10 minutes are replaced.

## 4. Deployment Slots and Slot Swap

Create a staging slot and deploy there before swapping to production:

```bash
# Create slot
az webapp deployment slot create \
  --resource-group <rg> --name <app> --slot staging

# Deploy to staging
az webapp deploy \
  --resource-group <rg> --name <app> --slot staging \
  --src-path ./app.zip --type zip

# Validate staging, then swap
az webapp deployment slot swap \
  --resource-group <rg> --name <app> \
  --slot staging --target-slot production
```

Mark App Settings as "Deployment slot setting" (sticky) to keep slot-specific
config (e.g., `ASPNETCORE_ENVIRONMENT=Staging`) from being swapped.

## 5. Code Deploy vs Container Deploy

| Criterion | Code deploy | Container deploy |
|-----------|-------------|-----------------|
| Build control | Platform builds on startup | You build the image |
| Cold start | Slower (build on first start) | Faster (pre-built image) |
| Runtime customization | Limited to supported stacks | Full Dockerfile control |
| Best for | Standard stacks, quick iteration | Custom runtimes, OS packages |

For container deploy:

```bash
az webapp config container set \
  --resource-group <rg> --name <app> \
  --docker-custom-image-name <acr>.azurecr.io/<image>:<tag> \
  --docker-registry-server-url https://<acr>.azurecr.io
```

## 6. Log Streaming

Stream live logs to diagnose startup or runtime errors:

```bash
az webapp log tail --resource-group <rg> --name <app>
```

Enable detailed logging first if logs are sparse:

```bash
az webapp log config \
  --resource-group <rg> --name <app> \
  --application-logging filesystem \
  --level information \
  --web-server-logging filesystem
```
