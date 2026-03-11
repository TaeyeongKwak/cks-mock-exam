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

<details>
<summary>Reference Answer Commands</summary>

```bash
kubectl create secret tls bingo-tls -n testing-lab --cert=/opt/course/10/bingo.crt --key=/opt/course/10/bingo.key
kubectl run web-pod -n testing-lab --image=nginx --restart=Never --port=80
kubectl expose pod web-pod -n testing-lab --name=web-pod-svc --port=80 --target-port=80
cat <<'EOF' >/tmp/bingo-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: bingo-ingress
  namespace: testing-lab
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - bingo.com
    secretName: bingo-tls
  rules:
  - host: bingo.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-pod-svc
            port:
              number: 80
EOF
kubectl apply -f /tmp/bingo-ingress.yaml
kubectl wait --for=condition=Ready pod/web-pod -n testing-lab --timeout=180s
```

</details>

