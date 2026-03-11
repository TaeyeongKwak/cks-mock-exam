This scenario rewrites a Kubernetes TLS Ingress task for the default Killercoda playground.

Environment notes

- The terminal starts on `controlplane`.
- Namespace `testing-lab` already exists.
- TLS source files are staged at `/opt/course/10/bingo.crt` and `/opt/course/10/bingo.key`.

Success criteria

- A TLS Secret named `bingo-tls` exists in namespace `testing-lab`.
- Pod `web-pod` runs in namespace `testing-lab`.
- A Service exposes the Pod.
- An Ingress in `testing-lab` uses host `bingo.com`, references Secret `bingo-tls`, and redirects HTTP to HTTPS.
