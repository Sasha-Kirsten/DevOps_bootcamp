# Third-Party Redis Provider Handoff Checklist

Complete this checklist with the Redis provider or platform team before installing the exporter. Keep passwords,
private certificates, tokens, and private endpoint details out of Git and ticket comments.

## Connection contract

- [ ] Provider hostname and port are confirmed.
- [ ] The provider confirms whether the URI is `redis://` or `rediss://` and whether TLS is mandatory.
- [ ] The provider confirms whether Redis ACL authentication requires a username as well as a password.
- [ ] A least-privilege, read-only monitoring credential is issued and has a documented rotation owner.
- [ ] The required metrics are confirmed: `INFO` access and any provider-specific command restrictions are known.

## Network and TLS contract

- [ ] DNS for the provider endpoint resolves from the Kubernetes network.
- [ ] The provider firewall/allow list permits TCP from the cluster's approved egress address or private network.
- [ ] Private endpoint, VPC/VNet peering, VPN, or approved egress is used instead of an exposed public endpoint.
- [ ] The provider certificate hostname matches the endpoint used by the exporter.
- [ ] If the provider uses a private CA, its CA certificate is supplied as a Kubernetes Secret and referenced through
      `redisTlsConfig.caCertFile`; `skipTlsVerification` stays `false`.

## Operations contract

- [ ] The Redis mode is known: standalone, replication, Sentinel, or Cluster.
- [ ] Alerts are reviewed for the provider's metrics; Cluster-only alerts remain disabled for non-Cluster deployments.
- [ ] The on-call team and runbook URL for `service: third-party-redis` are agreed.
- [ ] Provider maintenance windows and expected connection-error behaviour are documented.

## Evidence to retain

Keep redacted proof outside this repository:

1. Exporter target is `UP` in Prometheus.
2. `redis_up` is `1` for the expected exporter instance.
3. Dashboard panels return data for memory, clients, commands, and evictions where supported.
4. A controlled alert reaches the intended Alertmanager receiver.