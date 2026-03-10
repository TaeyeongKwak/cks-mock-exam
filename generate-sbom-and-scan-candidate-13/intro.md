This scenario rewrites an SBOM generation and scanning task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- The working directory for outputs is `/opt/candidate/13a`.
- An existing SPDX-JSON SBOM is already staged at `/opt/candidate/13a/sbom_check.json`.

Adaptation notes

- The default playground does not ship a `bom` CLI by default.
- To preserve the original task intent, this scenario stages `/usr/local/bin/bom` as a small helper wrapper for SBOM generation.
- `trivy` is installed during scenario setup and is used both by the helper and for the required SBOM vulnerability scan.

Success criteria

- `/opt/candidate/13a/sbom1.json` is a valid SPDX-JSON SBOM for `registry.k8s.io/kube-apiserver:v1.32.0`.
- `/opt/candidate/13a/sbom2.json` is a valid CycloneDX SBOM for `registry.k8s.io/kube-controller-manager:v1.32.0`.
- `/opt/candidate/13a/sbom_result.json` is valid JSON output from scanning `/opt/candidate/13a/sbom_check.json` with Trivy.
