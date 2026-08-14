# Azure Linux App Service — Examples

## Python FastAPI on App Service Linux

```bash
az webapp create \
  --resource-group myRG --name myapp \
  --plan myPlan --runtime "PYTHON|3.11"

az webapp config set \
  --resource-group myRG --name myapp \
  --startup-file "gunicorn --bind=0.0.0.0:8000 --timeout 600 main:app"

az webapp config appsettings set \
  --resource-group myRG --name myapp \
  --settings DATABASE_URL="$DB_URL" ENVIRONMENT="production"

az webapp deploy \
  --resource-group myRG --name myapp \
  --src-path ./dist.zip --type zip
```

## Node.js Express with Staging Slot

```bash
az webapp deployment slot create \
  --resource-group myRG --name myapp --slot staging

az webapp config set \
  --resource-group myRG --name myapp --slot staging \
  --linux-fx-version "NODE|20-lts" \
  --startup-file "node server.js"

az webapp deploy \
  --resource-group myRG --name myapp --slot staging \
  --src-path ./app.zip --type zip

# After validation:
az webapp deployment slot swap \
  --resource-group myRG --name myapp \
  --slot staging --target-slot production
```
