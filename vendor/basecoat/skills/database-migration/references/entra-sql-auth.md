# Entra-Only SQL Authentication

Use Microsoft Entra ID (formerly Azure AD) as the sole authentication mechanism for
Azure SQL — no SQL logins, no passwords.

## Create an Entra User from External Provider

Run in the target database while connected as an Entra admin:

```sql
CREATE USER [username-or-spn-display-name] FROM EXTERNAL PROVIDER;
ALTER ROLE db_datareader ADD MEMBER [username-or-spn-display-name];
ALTER ROLE db_datawriter ADD MEMBER [username-or-spn-display-name];
```

The display name must match the Entra object (user UPN or service principal display name) exactly.

## Managed Identity Connection Strings

User-assigned managed identity:

```text
Server=<server>.database.windows.net;Database=<db>;
Authentication=Active Directory Managed Identity;
User Id=<client-id-of-user-assigned-identity>;
```

System-assigned managed identity (omit `User Id`):

```text
Server=<server>.database.windows.net;Database=<db>;
Authentication=Active Directory Managed Identity;
```

## Service Principal vs Managed Identity

| Criterion | Service Principal | Managed Identity |
|-----------|------------------|-----------------|
| Secret rotation | Required (client secret or cert) | None — platform-managed |
| Scope | Cross-tenant, external CI/CD | Same Azure tenant only |
| Best for | GitHub Actions, external pipelines | App Service, AKS, Azure Functions |
| Overhead | Secret lifecycle management | Zero credential overhead |

Prefer managed identity for workloads running inside Azure.
Use a service principal only when the caller is outside Azure.

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `Principal '…' could not be found` | SID not yet propagated from Entra | Wait 1–2 min after creating Entra object; retry `CREATE USER` |
| `Login failed for user '<token-identified principal>'` | No Entra admin set on SQL server | `az sql server ad-admin create …` |
| `Cannot open server … requested by the login` | Client IP not in firewall | `az sql server firewall-rule create --start-ip … --end-ip …` |
| `AADSTS700016: Application not found` | Wrong client ID or wrong tenant | Verify `User Id` matches managed identity client ID |
