This scenario rewrites a container image scanning task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Trivy is installed during scenario setup.
- The image list is staged at `/opt/scan-images.txt`.
- Save your final scan output to `/opt/scan-high-critical.txt`.

Adaptation notes

- The source text says "two container images" but lists five images. This scenario treats the explicit five-image list as authoritative.
- The verification checks that all staged images were scanned with Trivy and that the saved output is filtered to `HIGH` and `CRITICAL` findings.

Success criteria

- Trivy scans all staged images.
- Only `HIGH` and `CRITICAL` severities are included in the saved output.
- The final output is stored at `/opt/scan-high-critical.txt`.
