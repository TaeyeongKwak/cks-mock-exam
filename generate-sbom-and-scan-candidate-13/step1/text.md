Generate the requested SBOM documents and scan the staged SBOM.

Tasks

1. Generate an SPDX-JSON SBOM for `registry.k8s.io/kube-apiserver:v1.32.0` and save it to `/opt/candidate/13a/sbom1.json`.
2. Generate a CycloneDX SBOM for `registry.k8s.io/kube-controller-manager:v1.32.0` and save it to `/opt/candidate/13a/sbom2.json`.
3. Scan the existing SPDX-JSON SBOM at `/opt/candidate/13a/sbom_check.json` for known vulnerabilities and save the JSON result to `/opt/candidate/13a/sbom_result.json`.

Notes

- Use `bom` for SBOM generation and `trivy` for the SBOM vulnerability scan.
- The staged `bom` helper supports:
  - `bom generate --format spdx-json --output <file> <image>`
  - `bom generate --format cyclonedx --output <file> <image>`
- Keep the output paths exactly as requested.

<details>
<summary>Reference Answer Commands</summary>

```bash
bom generate --format spdx-json --output /opt/candidate/13a/sbom1.json registry.k8s.io/kube-apiserver:v1.32.0
bom generate --format cyclonedx --output /opt/candidate/13a/sbom2.json registry.k8s.io/kube-controller-manager:v1.32.0
trivy sbom --format json -o /opt/candidate/13a/sbom_result.json /opt/candidate/13a/sbom_check.json
ls -l /opt/candidate/13a/sbom1.json /opt/candidate/13a/sbom2.json /opt/candidate/13a/sbom_result.json
```

</details>

