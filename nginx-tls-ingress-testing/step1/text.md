Deploy a web Pod with TLS-enabled Ingress in namespace `testing-lab`.

Complete the following task:

1. Create a TLS Secret named `bingo-tls` from:
   - `/opt/course/10/bingo.crt`
   - `/opt/course/10/bingo.key`
2. Deploy a Pod named `web-pod` in namespace `testing-lab`.
3. Expose the Pod with a Service.
4. Create an Ingress using TLS with host `bingo.com`.
5. Ensure the Ingress uses Secret `bingo-tls`.
6. Redirect all HTTP traffic to HTTPS.

Notes

- Keep all resources in namespace `testing-lab`.
- You may choose the Service and Ingress names unless the task above fixes them.
