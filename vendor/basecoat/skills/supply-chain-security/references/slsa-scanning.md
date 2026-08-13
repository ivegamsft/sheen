# SLSA Provenance and Dependency Scanning

## SLSA Level 3 GitHub Actions Workflow

```yaml
name: SLSA Build & Release

on:
  push:
    tags:
      - v*

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      hashes: ${{ steps.hash.outputs.hashes }}
    steps:
      - uses: actions/checkout@v3

      - name: Build artifact
        run: |
          mkdir artifacts
          go build -o artifacts/my-app .
          sha256sum artifacts/* > artifacts/hashes.txt

      - id: hash
        run: echo "hashes=$(base64 -w0 artifacts/hashes.txt)" >> $GITHUB_OUTPUT

      - uses: actions/upload-artifact@v3
        with:
          name: artifacts
          path: artifacts/

  provenance:
    needs: build
    permissions:
      id-token: write
      contents: write
    uses: slsa-framework/slsa-github-generator/.github/workflows/generator_generic_slsa3.yml@v1.7.0
    with:
      base64-subjects: ${{ needs.build.outputs.hashes }}
      upload-assets: true
```

## Dependency Vulnerability Scanning

```python
import subprocess
import json

def scan_python_deps(requirements_file):
    """Scan Python dependencies with pip-audit."""
    result = subprocess.run(
        ["pip-audit", "--desc", "--format", "json", "--requirements", requirements_file],
        capture_output=True, text=True
    )
    vulnerabilities = json.loads(result.stdout)
    critical = [v for v in vulnerabilities if v['severity'] == 'critical']
    if critical:
        print(f"CRITICAL: Found {len(critical)} critical vulnerabilities")
        return False
    return True

def scan_container(image):
    """Scan container image with Trivy."""
    result = subprocess.run(
        ["trivy", "image", "--format", "json", image],
        capture_output=True, text=True
    )
    results = json.loads(result.stdout)
    total_vulns = sum(len(r.get('Results', [])) for r in results.get('Results', []))
    print(f"Container vulnerabilities: {total_vulns}")
    return total_vulns == 0
```

## References

- [SLSA Framework](https://slsa.dev/)
- [Sigstore Documentation](https://docs.sigstore.dev/)
- [CycloneDX SBOM](https://cyclonedx.org/)
- [SPDX Specification](https://spdx.dev/)
