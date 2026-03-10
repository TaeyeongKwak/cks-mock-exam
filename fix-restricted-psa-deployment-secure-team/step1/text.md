The namespace `secure-lab` enforces the Pod Security Admission `restricted` profile.

The staged Deployment manifest `/root/masters/restricted-fix.yaml` violates that policy and cannot run as-is.

Complete the following task:

1. Edit `/root/masters/restricted-fix.yaml`.
2. Fix all Pod Security Admission `restricted` violations in the Deployment.
3. Apply the updated manifest so the Deployment runs successfully in namespace `secure-lab`.

Notes

- Keep the Deployment in namespace `secure-lab`.
- You only need to edit the staged manifest and apply it.
