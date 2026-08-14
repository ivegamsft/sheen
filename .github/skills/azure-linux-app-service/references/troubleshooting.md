# Azure Linux App Service — Common Failure Patterns

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Container keeps restarting / 503 on startup | Startup command incorrect or app crashes before binding | Check `az webapp log tail`; verify startup file path and bind address (`0.0.0.0`) |
| `ModuleNotFoundError` on Python app | `requirements.txt` missing or not at repo root | Ensure `requirements.txt` is at root; redeploy with zip including it |
| Wrong Python/Node version | Runtime not explicitly set | Run `az webapp config set --linux-fx-version "PYTHON\|3.11"` |
| Health check failing | Endpoint not yet available at startup | Increase startup timeout or fix health check path |
| App Settings not visible at runtime | Slot-sticky settings deployed to wrong slot | Verify setting stickiness and target slot |
