# Monitor a Third-Party Redis Service with Prometheus and Grafana

## Overview

This project is a skeleton for monitoring a Redis instance managed by a third-party provider—for example, a managed cloud Redis service or an external Redis cluster. It uses the Prometheus Redis exporter as a standalone Kubernetes workload.

The exporter connects to the provider’s Redis endpoint, translates Redis information into Prometheus metrics, and exposes those metrics through `/metrics`. The Prometheus Operator discovers the exporter through a `ServiceMonitor`; Grafana queries Prometheus to visualise the resulting time series.

```text
Third-party managed Redis
					|
					| TLS/authenticated network connection
					v
Redis exporter running in Kubernetes
					|
					v
ServiceMonitor (release: monitoring)
					|
					v
Prometheus ──> Grafana dashboards
		 |
		 v
PrometheusRule ──> Alertmanager notification routes
```

## Why a Standalone Exporter?

Third-party services cannot normally be modified to add a sidecar container. Instead, the Redis exporter runs inside the Kubernetes cluster and connects to the external endpoint over the network.

Before deployment, confirm that the exporter’s namespace can reach the provider endpoint through DNS, firewall rules, VPC/VNet peering, private endpoints, VPN, or approved public egress. Most managed Redis services should be accessed through private networking whenever possible.

## Project Files

| File | Purpose |
| --- | --- |
| `redis-exporter-values.yaml` | Helm values template for the Redis endpoint, TLS, authentication, and Prometheus ServiceMonitor discovery. |
| `redis-auth-secret.example.yaml` | Secret structure example. Never add a real password to this file. |
| `redis-alert-rules.yaml` | Starter `PrometheusRule` with availability and memory alerts. |
| `provider-connection-checklist.md` | Non-secret questions and acceptance criteria for the Redis provider or platform team. |
| `validate.sh` | Renders a configured exporter version and runs server-side schema checks without installing it. |
| `.gitignore` | Prevents local connection details and real Secret manifests from being committed. |
| `ReadMe.md` | Setup, validation, dashboard, security, and troubleshooting guide. |

## Prerequisites

- A Kubernetes cluster with `kube-prometheus-stack` and the Prometheus Operator installed.
- Helm and `kubectl` access to the cluster.
- DNS and network connectivity from the `monitoring` namespace to the third-party Redis endpoint.
- Redis connection information from the provider: hostname, port, TLS requirements, certificate requirements, username, and password or access token.
- Read-only Redis credentials where the provider supports access control lists.
- The `prometheus-community/prometheus-redis-exporter` chart repository.

Verify the Prometheus Operator resources:

```sh
kubectl api-resources --api-group=monitoring.coreos.com
kubectl get prometheus -n monitoring -o yaml
```

The active Prometheus instance in this learning environment selects `ServiceMonitor` and `PrometheusRule` objects with:

```yaml
release: monitoring
```

The skeleton includes that label on both resources.

## The Remaining Piece: Provider-Specific Connectivity

The Kubernetes and Prometheus configuration is ready. The remaining work cannot be completed honestly without a real
third-party Redis service because it depends on facts only the provider or platform team can supply:

1. Private hostname and port.
2. Network path from the `monitoring` namespace: private endpoint, peering, VPN, or approved egress plus firewall rules.
3. TLS mode and CA certificate, if the provider does not use a public CA.
4. A read-only Redis ACL username/password or access token, including rotation ownership.
5. Redis topology and provider-supported metrics so alerts can be tuned correctly.

Use `provider-connection-checklist.md` as the handoff document. Do not deploy the exporter with the placeholder endpoint:
that would create a permanently failing target and a misleading `RedisDown` alert.

## Configure the Redis Exporter

Copy the values template to an ignored local file:

```sh
cp redis-exporter-values.yaml redis-exporter-values.local.yaml
```

Edit the local file and replace:

```yaml
redisAddress: redis://replace-with-third-party-redis-hostname:6379
```

with the endpoint provided by the vendor. Enable TLS when required:

```yaml
redisTlsConfig:
	enabled: true
	skipTlsVerification: false
```

Do not disable certificate verification in a production environment. If the vendor uses a private CA, configure the exporter according to the chart’s current TLS/CA support rather than setting `skipTlsVerification: true`.

The chart accepts a CA certificate from a Kubernetes Secret. Create the Secret outside Git, then fill in the existing
`caCertFile` fields in the ignored local values file:

```sh
kubectl create secret generic third-party-redis-ca \
	--namespace monitoring \
	--from-file=ca.crt=/secure/path/provider-ca.crt
```

```yaml
redisTlsConfig:
	enabled: true
	skipTlsVerification: false
	caCertFile:
		secret:
			name: third-party-redis-ca
			key: ca.crt
```

## Configure Authentication Securely

If the Redis service requires a password, create the Secret directly instead of committing a real secret manifest:

```sh
kubectl create secret generic third-party-redis-auth \
	--namespace monitoring \
	--from-literal=password='<third-party-redis-password>'
```

Then enable authentication in `redis-exporter-values.local.yaml`:

```yaml
auth:
	enabled: true
	secret:
		name: third-party-redis-auth
		key: password
	# Set when the vendor requires Redis ACL authentication.
	redisUser: monitoring-exporter
```

For GitOps or production deployment, use External Secrets Operator, SOPS, Sealed Secrets, or an approved CI/CD secret store. The secret should be scoped to the `monitoring` namespace and grant only the exporter’s required access.

## Install the Exporter

Add the Helm repository once, then update its index:

```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

Render the chart before installation:

```sh
bash validate.sh redis-exporter-values.local.yaml
```

`validate.sh` pins the currently verified chart version (`6.37.0`), checks that the endpoint placeholder has been
replaced, renders the chart, and performs server-side validation. It does **not** make a connection to Redis.

Install or upgrade the exporter:

```sh
helm upgrade --install third-party-redis-exporter prometheus-community/prometheus-redis-exporter \
	--version 6.37.0 \
	--namespace monitoring \
	--create-namespace \
	--values redis-exporter-values.local.yaml
```

## Configure Alert Rules

`redis-alert-rules.yaml` supplies two starter alerts:

| Alert | Condition | Purpose |
| --- | --- | --- |
| `ThirdPartyRedisDown` | `redis_up == 0` for two minutes | Detects exporter connection failure or an unavailable Redis service. |
| `ThirdPartyRedisHighMemoryUsage` | Redis uses more than 85% of available system memory for ten minutes | Detects memory pressure before capacity is exhausted. |

The `redis_cluster_slots_fail` example is commented out because it applies only to Redis Cluster mode. Enable it only when the third-party service exposes Redis Cluster metrics.

Validate and apply the alert rules:

```sh
kubectl apply --dry-run=server -f redis-alert-rules.yaml
kubectl apply -f redis-alert-rules.yaml
```

Update your existing `AlertmanagerConfig` to route alerts using labels such as:

```yaml
service: third-party-redis
severity: critical
```

## Verify Metrics and Grafana Dashboards

Confirm the exporter Pod, Service, and `ServiceMonitor`:

```sh
kubectl get pods,svc -n monitoring | grep third-party-redis-exporter
kubectl get servicemonitor -n monitoring -l release=monitoring
kubectl get servicemonitor -n monitoring -o yaml
```

In Prometheus, open **Status → Targets** and confirm the exporter is `UP`. Then query:

```promql
redis_up
redis_memory_used_bytes
redis_connected_clients
rate(redis_commands_processed_total[5m])
rate(redis_evicted_keys_total[5m])
```

### Test in layers

Run the following checks in order. This makes failures easy to attribute instead of treating monitoring as a single
black box.

1. **Static configuration:** run `bash validate.sh redis-exporter-values.local.yaml` before installation.
2. **Exporter rollout:** after installation, wait for the Deployment and inspect its logs:

	```sh
	kubectl rollout status deployment/third-party-redis-exporter-prometheus-redis-exporter \
	  -n monitoring --timeout=180s
	kubectl logs deployment/third-party-redis-exporter-prometheus-redis-exporter -n monitoring
	```

3. **Connectivity and authentication:** query `redis_up` in Prometheus. A value of `1` proves the exporter can reach
	and authenticate to Redis; `0` means inspect DNS, firewall, TLS, and ACL settings before changing alerts.
4. **Scrape discovery:** open Prometheus **Status → Targets** and verify the exporter target is `UP`.
5. **Alert rule loading:** apply `redis-alert-rules.yaml`, then verify it appears in the Prometheus **Alerts** page.
6. **Notification routing:** after the existing SMTP route is configured, temporarily create a controlled test rule in
	a non-production environment, prove it reaches Alertmanager and the receiver, then delete it. Do not manufacture a
	provider outage merely to test email.

The current local stack has Grafana disabled to conserve Minikube storage. Prometheus and Alertmanager verification
remain fully valid without Grafana; add dashboard validation later when Grafana is enabled and storage is available.

Use those metrics in Grafana panels for availability, memory consumption, client connections, command throughput, and evicted keys. Add provider/environment labels where available and avoid using secrets, customer identifiers, or unbounded IDs as Prometheus labels.

## Troubleshooting

| Symptom | Likely cause | Check |
| --- | --- | --- |
| Exporter cannot connect | DNS, firewall, peering, TLS, port, or credentials are incorrect. | Exporter Pod logs and provider network rules. |
| `redis_up` is `0` | Redis is unavailable or the exporter cannot authenticate. | Endpoint URI, TLS settings, Secret name/key, and vendor ACLs. |
| Target is missing from Prometheus | ServiceMonitor is not selected or its Service selector/port does not match. | `kubectl get servicemonitor -n monitoring -o yaml` and Prometheus selectors. |
| TLS handshake error | Wrong protocol, CA chain, hostname, or TLS verification setting. | Exporter logs and provider TLS documentation. |
| No Grafana data | Prometheus target is down or the dashboard query uses unexpected labels. | Prometheus targets and direct PromQL query. |
| Alert rule is ignored | Rule lacks the `release: monitoring` label or the Prometheus selector changed. | `kubectl get prometheus -n monitoring -o yaml`. |

## Security and Operations Guidance

- Prefer private endpoints, peering, VPN, or VPC/VNet integration over public Redis endpoints.
- Use least-privilege Redis ACL credentials and rotate them regularly.
- Keep third-party hostnames, passwords, tokens, certificates, and kubeconfig files out of Git.
- Keep TLS verification enabled and trust a provider CA rather than skipping certificate checks.
- Pin Helm chart versions before production rollout and test upgrades in a non-production environment.
- Add alert runbooks and route critical alerts to an on-call channel as the system matures.
- Review exporter logs after network or provider changes and regularly test notification paths.

## Resources

- [Prometheus Redis Exporter Helm chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-redis-exporter)
- [Redis exporter project](https://github.com/oliver006/redis_exporter)
- [Prometheus Operator ServiceMonitor documentation](https://prometheus-operator.dev/docs/developer/getting-started/#using-servicemonitors)
- [Prometheus alerting rules documentation](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- [Kubernetes Secrets documentation](https://kubernetes.io/docs/concepts/configuration/secret/)