Validate the integrity of the staged Kubernetes server binaries on worker node `node01`.

Complete the following task:

1. Compare the sha512 checksum of each binary in `/opt/candidate/15a/binaries` against the provided verified values.
2. Delete every binary whose checksum does not match the expected value.

Expected hashes

- `kube-apiserver` -> `a3b9e5c4f7d21e89bc317f0e91a7c845df1100d2fb8cc63dff9e40a9e5a2a3c6bb8aa4e4579de9b136d65b18b7d6eae4c3f26de982e537a0a4a1ef8bb1c27c5f`
- `kube-controller-manager` -> `b7a223f9918b94e5d6479fcf41da0cd2d93ce0fd102e5c770d1c9b6c82e1a2ad84cbbd54cdd7a4a98fd6133b0b5e6a981a45b0a9cbf24a93980f89ac56c9f47f`
- `kube-proxy` -> `4d9917ea90a3f8ccbe3a607f5c9aeeecb7113a9c02a8e55c5bda6f73dd6b5a7c1b928d0169ea3a8b2c5ddbc0285d54a9d76c9c36f7b8ab7b17d5d8f39d1444a2`
- `kubelet` -> `8f1c29d7c8b2f491d512accb04a6d028dcdb3fc6a5b7b890f432e77e3217a90d92c2b4a3d98c8d49e19d3f80ad29348db216d31cbf96f82d19976f3251d9b887`

Notes

- The verified values are also staged on `node01` at `/opt/candidate/15a/verified-sha512.txt`.
- Perform the cleanup on `node01`, not on `controlplane`.

<details>
<summary>Reference Answer Commands</summary>

```bash
ssh node01 'cd /opt/candidate/15a && while read -r sum name; do current=$(sha512sum binaries/$name | awk "{print \$1}"); if [ "$current" != "$sum" ]; then rm -f binaries/$name; fi; done < verified-sha512.txt'
ssh node01 'ls -l /opt/candidate/15a/binaries'
```

</details>

