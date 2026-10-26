# Monitor a Redis-Backed Application with Prometheus and Grafana

## Overview

This project adds application-level Redis monitoring to a Kubernetes cluster running the Prometheus Operator through the `kube-prometheus-stack` Helm chart.

The monitored Redis service is `redis-cart` in the `default` namespace. The `prometheus-redis-exporter` Helm chart connects to Redis, exposes Redis metrics, and creates a `ServiceMonitor` that Prometheus discovers. Grafana then visualises the stored Prometheus metrics, while Alertmanager routes fired alerts to email.

```text
Application ──> redis-cart Service (default namespace)
											 |
											 v
					Redis exporter (/metrics endpoint)
											 |
											 v
 ServiceMonitor (release: monitoring) ──> Prometheus
											 |
						Grafana dashboards and PrometheusRule alerts
											 |
											 v
						    AlertmanagerConfig ──> SMTP email
```

## Exporter Deployment Model

An exporter converts service-specific data into Prometheus metrics exposed at an HTTP `/metrics` endpoint.

| Component | Responsibility |
| --- | --- |
| Redis | Stores the application’s cache/session/cart data. |
| Redis exporter | Queries Redis and exposes metrics such as `redis_up`, memory usage, commands, clients, and replication information. |
| `ServiceMonitor` | Tells the Prometheus Operator which exporter Service and port to scrape. |
| Prometheus | Scrapes, stores, and evaluates metrics and alert rules. |
| Grafana | Queries Prometheus and presents dashboards; it does not scrape metrics itself. |
| Alertmanager | Groups, routes, deduplicates, silences, and sends notifications for fired alerts. |

### Sidecar versus standalone exporter

The Helm chart used here deploys the Redis exporter as a **standalone workload**, which connects to Redis through the Kubernetes Service DNS name. It is not a Grafana or Prometheus sidecar.

A sidecar exporter would be an additional container in the same Pod as Redis. That pattern can be appropriate when metrics are available only over `localhost`, but it couples exporter and application lifecycles. A standalone exporter is simpler for this learning project and can monitor Redis through the cluster network.

## Project Files

| File | Purpose |
| --- | --- |
| `redis-values.yaml` | Helm values for the Redis exporter, including the Redis endpoint and Prometheus discovery label. |
| `alert-rule.yaml` | `PrometheusRule` resources for Redis availability, cluster health, and memory alerts. |
| `alert-manager-configurations.yaml` | `AlertmanagerConfig` for grouping and routing Redis alerts to an SMTP email receiver. |
| `email-secret.yaml` | Secret template only; use it as documentation, not to commit a real Gmail App Password. |
| `ReadMe.md` | End-to-end installation, verification, dashboard, alerting, and troubleshooting guidance. |

## Prerequisites

- A Kubernetes cluster with `kube-prometheus-stack` installed in the `monitoring` namespace.
- Helm, `kubectl`, and access to the cluster.
- A reachable Redis Service. This project uses `redis-cart.default.svc.cluster.local:6379`.
- The `monitoring.coreos.com` CRDs supplied by the Prometheus Operator.
- An SMTP provider if email alerts are required. Gmail requires two-step verification and an **App Password**.

Verify the current environment:

```sh
kubectl get svc redis-cart -n default
kubectl get prometheus,alertmanager -n monitoring
kubectl api-resources --api-group=monitoring.coreos.com
```

The current Prometheus instance selects `ServiceMonitor` and `PrometheusRule` resources with this label:

```yaml
release: monitoring
```

That label is already set in `redis-values.yaml` and `alert-rule.yaml`.

## Install the Redis Exporter

Add and update the Prometheus Community chart repository:

```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

Install or upgrade the exporter in the `monitoring` namespace:

```sh
helm upgrade --install redis-exporter prometheus-community/prometheus-redis-exporter \
	--namespace monitoring \
	--create-namespace \
	--values redis-values.yaml
```

The exporter connects to:

```text
redis://redis-cart.default.svc.cluster.local:6379
```

If Redis requires authentication, do not place the password in `redis-values.yaml`. Create a Kubernetes Secret and consult the chart’s current values with `helm show values prometheus-community/prometheus-redis-exporter` to configure the supported secret reference.

## Verify Metric Collection

First confirm that the exporter and its ServiceMonitor exist:

```sh
kubectl get pods,svc -n monitoring | grep redis-exporter
kubectl get servicemonitor -n monitoring -l release=monitoring
kubectl get servicemonitor redis-exporter-prometheus-redis-exporter -n monitoring -o yaml
```

In the Prometheus UI, open **Status → Targets** and confirm that the Redis exporter target is `UP`. You can also query these metrics in the Prometheus expression browser:

```promql
redis_up
redis_memory_used_bytes
redis_connected_clients
rate(redis_commands_processed_total[5m])
```

If the exporter runs in `monitoring`, the fully qualified DNS name in `redis-values.yaml` prevents namespace-resolution problems.

## Grafana Dashboard Suggestions

Add Prometheus as the Grafana data source, then build or import a Redis dashboard. Useful panels include:

| Panel | PromQL example | Why it matters |
| --- | --- | --- |
| Redis availability | `redis_up` | Confirms the exporter can connect to Redis. |
| Memory used | `redis_memory_used_bytes` | Shows Redis memory growth. |
| Connected clients | `redis_connected_clients` | Reveals traffic changes and possible connection leaks. |
| Command throughput | `rate(redis_commands_processed_total[5m])` | Shows request activity. |
| Evicted keys | `rate(redis_evicted_keys_total[5m])` | Indicates memory pressure and cache churn. |
| Keyspace hits | `rate(redis_keyspace_hits_total[5m])` | Helps assess cache effectiveness. |

Use labels such as `namespace`, `service`, `instance`, and `job` as dashboard variables where available. Avoid hard-coding Pod names because Pods change during deployments.

## Run the Included Metrics Demo Application

The `demo-application/` directory contains a small Redis-backed cart API that is designed to work with this monitoring project. It reuses the existing `redis-cart` Service and exposes application metrics at `/metrics`.

| Endpoint | Purpose |
| --- | --- |
| `GET /` | Lists the service and available endpoints. |
| `GET /healthz` | Returns `200` only when the API can reach Redis. |
| `GET /cart/<user>` | Reads a user’s demo cart from Redis. |
| `POST /cart/<user>/<item>` | Adds an item to a user’s cart and generates request metrics. |
| `GET /metrics` | Prometheus metrics endpoint scraped through the included `ServiceMonitor`. |

Build the image from the demo directory:

```sh
cd demo-application
docker build -t redis-metrics-demo:1.0.0 .
```

The Kubernetes manifest uses the local image name `redis-metrics-demo:1.0.0`. Make the image available to your cluster before applying it:

- **Docker Desktop Kubernetes:** a locally built image is normally available directly.
- **kind:** run `kind load docker-image redis-metrics-demo:1.0.0`.
- **minikube:** run `minikube image load redis-metrics-demo:1.0.0`.
- **Remote cluster:** tag and push the image to a registry you control, then replace `image:` in `demo-application/kubernetes.yaml` with that immutable registry tag.

Deploy the API, its Service, and the ServiceMonitor:

```sh
kubectl apply -f kubernetes.yaml
kubectl rollout status deployment/redis-metrics-demo -n default
kubectl get servicemonitor redis-metrics-demo -n monitoring
```

Access the API locally and create sample traffic in a separate terminal:

```sh
kubectl port-forward service/redis-metrics-demo -n default 8081:8080
curl http://localhost:8081/healthz
curl -X POST http://localhost:8081/cart/aleksander/book
curl -X POST http://localhost:8081/cart/aleksander/keyboard
curl http://localhost:8081/cart/aleksander
curl http://localhost:8081/metrics
```

After Prometheus completes a scrape (the ServiceMonitor interval is 30 seconds), use these application-level queries in Prometheus or Grafana:

```promql
demo_cart_redis_available
sum(rate(demo_cart_requests_total[5m])) by (endpoint, status)
histogram_quantile(0.95, sum(rate(demo_cart_request_duration_seconds_bucket[5m])) by (le, endpoint))
demo_cart_items
```

> The demo includes a `user` label on `demo_cart_items` to make the sample easy to understand. Do not use unbounded identifiers such as individual user IDs in production metric labels, because they create high-cardinality time series and can increase Prometheus memory use.

The Prometheus target should appear as the `redis-metrics-demo` ServiceMonitor target under **Status → Targets**. If it does not, confirm that the ServiceMonitor remains in the `monitoring` namespace and has the `release: monitoring` label.

## Configure Redis Alerts

`alert-rule.yaml` contains a `PrometheusRule` selected by the active Prometheus instance through `release: monitoring`.

| Alert | Severity | Condition | Intent |
| --- | --- | --- | --- |
| `RedisDown` | critical | `redis_up == 0` for 1 minute | Detects an exporter connection failure or unavailable Redis instance. |
| `RedisClusterSlotFail` | warning | Failed Redis Cluster slots for 5 minutes | Detects unavailable keyspace shards. This metric applies only to Redis Cluster mode. |
| `RedisOutOfSystemMemory` | warning | Redis consumes over 90% of system memory for 2 minutes | Detects imminent memory exhaustion. |

> `redis_cluster_slots_fail` is not normally exposed by a standalone, non-cluster Redis server. Remove or disable `RedisClusterSlotFail` if `redis-cart` is not running in Redis Cluster mode.

Validate and apply the rule:

```sh
kubectl apply --dry-run=server -f alert-rule.yaml
kubectl apply -f alert-rule.yaml
kubectl get prometheusrule -n monitoring
```

## Configure Alertmanager Email

`alert-manager-configurations.yaml` uses the `AlertmanagerConfig` API version supported by this cluster:

```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
```

The active Alertmanager has an empty `alertmanagerConfigSelector`, so it can select configurations in its permitted namespaces. Confirm this before relying on the route:

```sh
kubectl get alertmanager -n monitoring -o yaml
```

Create the email Secret without committing the actual value:

```sh
kubectl create secret generic gmail-auth \
	--namespace monitoring \
	--from-literal=password='<gmail-app-password>'
```

Update the receiver fields in `alert-manager-configurations.yaml` with a real sender and recipient, then validate and apply it:

```sh
kubectl apply --dry-run=server -f alert-manager-configurations.yaml
kubectl apply -f alert-manager-configurations.yaml
kubectl get alertmanagerconfig -n monitoring
```

## End-to-End Verification

Verify the system in this order:

1. **Redis:** `kubectl get svc redis-cart -n default` confirms the Service exists.
2. **Exporter:** confirm its Pod is ready and logs do not report authentication or DNS failures.
3. **Prometheus target:** confirm the exporter target is `UP` in **Status → Targets**.
4. **Metrics:** query `redis_up` and confirm it returns `1` for the intended target.
5. **Rules:** confirm the `PrometheusRule` is listed and its rules appear in the Prometheus **Alerts** page.
6. **Grafana:** confirm dashboard panels show live Redis time series.
7. **Alertmanager:** test a controlled alert and confirm it appears with the expected receiver.
8. **Email:** confirm delivery and check spam/quarantine policies if it is not received.

For local UI access, run port-forwarding in separate terminals:

```sh
kubectl port-forward service/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
kubectl port-forward service/monitoring-grafana -n monitoring 8080:80
kubectl port-forward service/monitoring-kube-prometheus-alertmanager -n monitoring 9093:9093
```

Then open:

- Prometheus: `http://localhost:9090`
- Grafana: `http://localhost:8080`
- Alertmanager: `http://localhost:9093`

## Troubleshooting

| Symptom | Likely cause | Check |
| --- | --- | --- |
| Exporter Pod does not start | Invalid chart values or Redis authentication failure. | `kubectl logs -n monitoring deploy/redis-exporter-prometheus-redis-exporter` |
| Prometheus target is missing | `ServiceMonitor` lacks `release: monitoring`, or the Service/port selector does not match. | `kubectl get servicemonitor -n monitoring -o yaml` |
| `redis_up` is `0` | Exporter cannot resolve, reach, or authenticate to Redis. | Exporter logs; Redis Service name, namespace, port, and password. |
| Redis cluster alert never appears | Redis is not in cluster mode or the metric is absent. | Query `redis_cluster_slots_fail` in Prometheus. |
| Rule is not visible in Prometheus | `PrometheusRule` has the wrong kind or is missing `release: monitoring`. | `kubectl get prometheusrule -n monitoring -o yaml` |
| No email arrives | Incorrect SMTP settings, missing Secret, or AlertmanagerConfig is not selected. | Alertmanager UI/logs and `kubectl get secret gmail-auth -n monitoring` |
| Grafana has no data | Prometheus target is down or the dashboard query uses mismatched labels. | Prometheus targets and direct PromQL queries. |

## Security and Operations Guidance

- Never commit Redis passwords, Gmail App Passwords, or kubeconfig files to Git.
- Use a Kubernetes Secret, External Secrets Operator, SOPS, or Sealed Secrets for sensitive values.
- Use immutable image versions and keep chart versions pinned for reproducible deployments.
- Tune alert thresholds from real baseline traffic and memory behaviour; do not keep demonstration thresholds blindly.
- Add runbook URLs to alert annotations so responders know how to investigate each condition.
- Route critical and warning alerts differently as the project grows, ideally by `severity`, `team`, `service`, and `environment` labels.
- Test alerts, receiver routes, and dashboard queries after every monitoring-stack upgrade.

## Resources

- [Prometheus Redis Exporter Helm chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-redis-exporter)
- [Prometheus Operator ServiceMonitor documentation](https://prometheus-operator.dev/docs/developer/getting-started/#using-servicemonitors)
- [Prometheus alerting rules documentation](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- [Alertmanager configuration documentation](https://prometheus.io/docs/alerting/latest/configuration/)
- [Grafana documentation](https://grafana.com/docs/grafana/latest/)