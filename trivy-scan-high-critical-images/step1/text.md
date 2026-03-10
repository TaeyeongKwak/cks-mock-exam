Use Trivy to scan the staged images for `HIGH` and `CRITICAL` vulnerabilities.

Requirements

- Images to scan are listed in `/opt/scan-images.txt`.
- Only consider severities `HIGH` and `CRITICAL`.
- Save the final output to `/opt/scan-high-critical.txt`.

Notes

- The source task text says "two" images, but this scenario uses the full staged image list.
- You may scan the images one by one or with a loop.
- The saved output should clearly show results for each staged image.
