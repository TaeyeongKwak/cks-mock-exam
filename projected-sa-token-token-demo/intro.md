This scenario prepares a Pod in the `default` namespace that currently relies on the default mounted ServiceAccount token.

Adaptation notes

- The default kubeadm playground is used without any extra node assumptions.
- The starter Pod manifest is staged at `/root/jwt-demo.yaml`.
- The goal is to disable automatic token mounting on the `default` ServiceAccount and replace the default token mount with a manual projected token volume.
