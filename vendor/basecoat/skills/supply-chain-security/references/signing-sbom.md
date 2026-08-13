# Artifact Signing and SBOM Generation

## Artifact Signing with Sigstore (Cosign)

```bash
IMAGE="registry.example.com/my-app:v1.0.0"

# Generate keypair (or use ambient OIDC)
cosign generate-key-pair

# Build and push image
docker build -t "$IMAGE" . && docker push "$IMAGE"

# Sign with private key
cosign sign --key cosign.key "$IMAGE"

# Verify signature
cosign verify --key cosign.pub "$IMAGE"

# Attach SBOM to image
syft "$IMAGE" -o json | cosign attach sbom --sbom - "$IMAGE"

# Verify SBOM attachment
cosign tree "$IMAGE"
```

## SBOM Generation (CycloneDX / SPDX)

```bash
APP_IMAGE="my-app:latest"
OUTPUT_DIR="sbom"
mkdir -p "$OUTPUT_DIR"

# CycloneDX format
syft "$APP_IMAGE" -o cyclonedx-json > "$OUTPUT_DIR/cyclonedx.json"

# SPDX format
syft "$APP_IMAGE" -o spdx-json > "$OUTPUT_DIR/spdx.json"

# Vulnerability scan from SBOM
grype "$APP_IMAGE" --output json > "$OUTPUT_DIR/vulnerabilities.json"

# Validate SBOM structure
jq '.' "$OUTPUT_DIR/cyclonedx.json" > /dev/null || exit 1
```
