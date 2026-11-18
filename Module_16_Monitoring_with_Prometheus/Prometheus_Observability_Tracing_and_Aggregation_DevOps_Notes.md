# Prometheus, Observability, Tracing, and Aggregation — Theory + Practical DevOps Notes

## Why observability matters in DevOps
Modern systems are distributed, dynamic, and failure-prone. Observability helps teams answer:
- **What is broken?**
- **Where is it broken?**
- **Why is it broken?**
- **How fast can we recover?**

Strong observability reduces MTTR, improves reliability, and enables safer deployments.

---

## 1) Core observability theory

### Telemetry pillars
1. **Metrics** (numeric time series)
2. **Logs** (event records)
3. **Traces** (request path across services)

These are complementary:
- Metrics detect and quantify issues quickly.
- Logs provide detailed event context.
- Traces reveal cross-service latency and failure propagation.

### Signals + context
Good observability combines telemetry with metadata:
- service name
- environment
- version/revision
- region/cluster/namespace
- team ownership

---

## 2) Prometheus fundamentals (theory)

### Prometheus model
Prometheus is pull-based:
- targets expose `/metrics`
- Prometheus scrapes at intervals
- time series stored with labels
- PromQL queries evaluate health and behavior

### Key components
- **Prometheus server**: scrape, store, query, evaluate alerts
- **Alertmanager**: route, group, silence, deduplicate alerts
- **Exporters**: convert system/app metrics into Prometheus format
- **ServiceMonitor/PodMonitor** (Operator): declarative scrape discovery in Kubernetes

### Time series identity
Each metric series is:
$$
\text{metric name} + \text{label set}
$$

Example:
`http_requests_total{service="api",method="GET",status="200"}`

---

## 3) Prometheus metric types (practical)

1. **Counter**: monotonically increasing value (e.g., requests total)
2. **Gauge**: point-in-time value (e.g., memory usage)
3. **Histogram**: bucketed distribution (latency, payload sizes)
4. **Summary**: client-side quantiles (less aggregatable across instances)

Prefer **histograms** for distributed latency SLO calculations.

---

## 4) PromQL practical examples

### Availability
```promql
up
```

### Error rate (5xx)
```promql
sum(rate(http_requests_total{status=~"5.."}[5m]))
/
sum(rate(http_requests_total[5m]))
```

### Request throughput
```promql
sum(rate(http_requests_total[5m])) by (service)
```

### P95 latency from histogram
```promql
histogram_quantile(
  0.95,
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le, service)
)
```

### Kubernetes restart spikes
```promql
sum(increase(kube_pod_container_status_restarts_total[15m])) by (namespace, pod)
```

### Redis health
```promql
redis_up
```

---

## 5) Alerting theory and practical design

### Alert quality principles
- actionable
- low noise
- tied to user/business impact
- includes runbook/context in annotations

### Severity levels
- `critical`: urgent user impact
- `warning`: degradation/risk trend
- `info`: visibility-only signals

### Example `PrometheusRule`
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: app-alert-rules
  namespace: monitoring
  labels:
    release: monitoring
spec:
  groups:
    - name: app.slo.rules
      rules:
        - alert: HighErrorRate
          expr: |
            (
              sum(rate(http_requests_total{status=~"5.."}[5m]))
              /
              sum(rate(http_requests_total[5m]))
            ) > 0.02
          for: 10m
          labels:
            severity: warning
            service: api
            team: platform
          annotations:
            summary: "High 5xx error rate"
            description: "5xx ratio has exceeded 2% for 10 minutes."
            runbook_url: "https://internal.example/runbooks/high-error-rate"
```

---

## 6) Alertmanager routing example

```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
  name: platform-routes
  namespace: monitoring
spec:
  route:
    groupBy: ["alertname", "service", "severity"]
    groupWait: 30s
    groupInterval: 5m
    repeatInterval: 2h
    receiver: default-email
    routes:
      - matchers:
          - name: severity
            value: critical
        receiver: oncall-pager
  receivers:
    - name: default-email
      emailConfigs:
        - to: "platform-team@example.com"
          from: "alerts@example.com"
          smarthost: "smtp.example.com:587"
          authUsername: "alerts@example.com"
          authPassword:
            name: smtp-auth
            key: password
    - name: oncall-pager
      webhookConfigs:
        - url: "https://pager.example/api/alerts"
```

---

## 7) Grafana usage in DevOps

Grafana is a visualization/query layer over telemetry backends.

### Practical dashboard strategy
Build dashboards by question:
1. Is service healthy? (`up`, error rate)
2. Is performance acceptable? (P95/P99 latency)
3. Is capacity close to limits? (CPU/memory/queue)
4. Are dependencies healthy? (DB/cache/broker signals)

### Good panel set for a service
- availability (`up`)
- request rate
- 4xx/5xx rates
- P95/P99 latency
- saturation (CPU/memory)
- dependency status (e.g., `redis_up`)

Avoid dashboard sprawl; keep curated operational views.

---

## 8) Logging and aggregation tools

### Logging goals
- centralization
- searchability
- correlation with traces/metrics
- retention controls

### Common stacks
- **Loki + Grafana**
- **ELK/OpenSearch**
- **CloudWatch Logs / managed logging**

### Structured logging format
Prefer JSON logs with fields:
- timestamp
- level
- service
- environment
- trace_id/span_id (for correlation)
- message

Example log event:
```json
{
  "timestamp": "2026-11-18T10:15:33Z",
  "level": "ERROR",
  "service": "checkout-api",
  "trace_id": "b8e8e36f9a7c4f8f",
  "path": "/checkout",
  "status": 500,
  "message": "payment provider timeout"
}
```

---

## 9) Tracing fundamentals (OpenTelemetry)

### Trace model
- **Trace**: full request journey
- **Span**: one operation inside trace
- parent-child relationships link spans across services

### Why tracing is critical
- detects latency bottlenecks across services
- isolates failing hop quickly
- proves dependency impact chains

### Common backends
- Jaeger
- Tempo
- Zipkin
- cloud-native tracing services

---

## 10) OpenTelemetry practical setup (high-level)

### App instrumentation flow
1. Instrument app with OTel SDK/auto-instrumentation.
2. Export spans/metrics/logs to OTel Collector.
3. Collector forwards to Prometheus-compatible metrics and tracing/log backends.

### OpenTelemetry Collector snippet
```yaml
receivers:
  otlp:
    protocols:
      grpc:
      http:

processors:
  batch:

exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"
  otlp/tempo:
    endpoint: tempo.monitoring.svc.cluster.local:4317
    tls:
      insecure: true

service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [prometheus]
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [otlp/tempo]
```

---

## 11) Correlating metrics, logs, and traces

Golden workflow during incidents:
1. Alert fires from metric threshold.
2. Identify impacted service/endpoint from dashboard.
3. Pivot to trace for high-latency/error requests.
4. Pivot from trace ID to logs.
5. Identify root cause and rollback/fix.

This triad dramatically reduces time-to-diagnosis.

---

## 12) SLI/SLO theory for DevOps

### Core SLIs
- availability
- latency
- error rate
- durability/correctness

### Example SLOs
- availability: 99.9%
- P95 latency < 300ms
- error rate < 1%

### Error budget idea
If error budget is exhausted, prioritize reliability work over feature velocity.

---

## 13) Kubernetes observability patterns

### Discovery patterns
- ServiceMonitor for service-level scrape
- PodMonitor for pod-level scrape

### Labeling convention (recommended)
- `app.kubernetes.io/name`
- `app.kubernetes.io/instance`
- `environment`
- `team`
- `service`

Consistent labels improve filtering, alert routing, and dashboard reuse.

---

## 14) High-cardinality risk and metric hygiene

### Avoid these labels in metrics
- user IDs
- request IDs
- full URLs with dynamic IDs
- session tokens

High-cardinality labels increase Prometheus memory/cost and degrade query performance.

Good practice:
- bounded label sets
- aggregate where possible
- standardize metric naming and units

Naming examples:
- `http_requests_total`
- `http_request_duration_seconds_bucket`
- `process_resident_memory_bytes`

---

## 15) DevOps observability CI/CD checks

Add pipeline checks:
1. lint Prometheus rules (`promtool check rules`)
2. validate dashboards as code (JSON lint, schema)
3. verify alert routes in non-prod
4. smoke-test key metrics after deploy

Example rule lint:
```bash
promtool check rules alert-rule.yaml
```

---

## 16) Troubleshooting runbook

### Target missing in Prometheus
- verify ServiceMonitor labels match Prometheus selectors
- check Service selector and port names

### `up == 0`
- endpoint unreachable
- DNS or auth/TLS issue
- exporter crash

### Alert not firing
- expression not true
- insufficient `for` duration
- wrong labels/route matcher

### Email/pager not receiving
- Alertmanager route mismatch
- receiver config invalid
- secret missing

### Query too slow
- high-cardinality labels
- inefficient regex-heavy queries
- too long lookback windows

---

## 17) Security and governance for observability

- keep secrets out of Git (SMTP passwords, API tokens)
- use RBAC for dashboards and query access
- redact PII in logs/traces
- enforce telemetry retention and access policies
- secure endpoints with TLS/auth where applicable
- separate dev/staging/prod observability resources

---

## 18) Anti-patterns to avoid

- alerting on every technical blip (noise floods)
- no runbook links in critical alerts
- dashboards without ownership
- mutable ad-hoc production dashboards only
- logs without correlation IDs
- tracing enabled everywhere with no sampling strategy

---

## 19) Practical observability checklist

- [ ] Metrics, logs, traces configured for each service
- [ ] SLI/SLO definitions documented
- [ ] Actionable alert rules with severities and runbooks
- [ ] Alert routing and escalation tested
- [ ] Dashboards for service health, latency, error, saturation
- [ ] Correlation IDs/trace IDs in logs
- [ ] Rule/dash linting integrated into CI
- [ ] Retention and cost controls configured

---

## 20) Suggested additions for Module 16

Useful next files to add:
- `runbooks/redis-alert-runbook.md`
- `runbooks/prometheus-target-down-runbook.md`
- `dashboards/redis-overview.json`
- `dashboards/app-slo.json`
- `alerts/application-slo-rules.yaml`
- `otel/collector-config.yaml`

These make your observability projects more production-minded and portfolio-ready.

---

## References

- Prometheus docs: https://prometheus.io/docs/
- PromQL docs: https://prometheus.io/docs/prometheus/latest/querying/basics/
- Alertmanager docs: https://prometheus.io/docs/alerting/latest/alertmanager/
- Prometheus Operator docs: https://prometheus-operator.dev/
- Grafana docs: https://grafana.com/docs/
- OpenTelemetry docs: https://opentelemetry.io/docs/
- Jaeger docs: https://www.jaegertracing.io/docs/
- Tempo docs: https://grafana.com/docs/tempo/
- Loki docs: https://grafana.com/docs/loki/
