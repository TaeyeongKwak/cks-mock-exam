This scenario rewrites a Kubernetes TLS Ingress task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `testing-lab` already exists.
- TLS source files are staged at `/opt/course/10/bingo.crt` and `/opt/course/10/bingo.key`.

Adaptation notes

- The default playground may not include a running Ingress controller. This scenario scores the Kubernetes resources that would be consumed by a standard nginx-style Ingress setup.
- HTTP-to-HTTPS redirection is verified through the common nginx Ingress annotation `nginx.ingress.kubernetes.io/ssl-redirect: "true"`.

Success criteria

- A TLS Secret named `bingo-tls` exists in namespace `testing-lab`.
- Pod `web-pod` runs in namespace `testing-lab`.
- A Service exposes the Pod.
- An Ingress in `testing-lab` uses host `bingo.com`, references Secret `bingo-tls`, and redirects HTTP to HTTPS.
