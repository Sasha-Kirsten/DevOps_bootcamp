# Kubernetes Application Alerting with Prometheus and Alertmanager

## Portfolio scope

**Technologies:** Kubernetes, Prometheus Operator, kube-prometheus-stack, PromQL, Alertmanager, SMTP, Kustomize, and Helm.

This project defines a practical alerting baseline for a Kubernetes cluster managed by the Prometheus Operator:

- a `PrometheusRule` for sustained host CPU saturation and container crash loops;
- an `AlertmanagerConfig` that groups and routes platform alerts by labels;
- a runtime-only SMTP Secret workflow that never stores email credentials in Git;
- a deliberately separate test rule for proving end-to-end notification delivery.

It is designed as a **reusable configuration layer**, not a replacement for installing Prometheus itself. The currently verified local `minikube` environment has kube-prometheus-stack installed with the Prometheus Operator, Prometheus, and Alertmanager running. A fresh cluster still needs the installation steps below before server-side validation or applying these resources.

## Alerting architecture

```text
Node exporter / kube-state-metrics / application metrics
                         |
                         v
       PrometheusRule evaluates PromQL expressions
                         |
                         v
          Prometheus fires labelled alerts
                         |
                         v
AlertmanagerConfig groups and routes by team/severity
                         |
                         v
       SMTP receiver sends a notification
```

## Is Prometheus a sidecar?

No—Prometheus is a **separate monitoring application**. In this lab, the Prometheus Operator creates a dedicated Prometheus StatefulSet. Its Pod has two containers:

- `prometheus`: stores time-series data, scrapes targets, and evaluates `PrometheusRule` alerts;
- `config-reloader`: a sidecar that reloads Prometheus configuration when the Operator updates it.

Your application Pods do not contain Prometheus. They expose metrics (often on a `/metrics` HTTP endpoint), and Prometheus discovers and scrapes them through resources such as `ServiceMonitor`, `PodMonitor`, or `ScrapeConfig`.

Other monitoring components are also separate workloads: node-exporter is a DaemonSet running once per node, kube-state-metrics is a Deployment, and Alertmanager is its own StatefulSet. This separation lets the monitoring system continue observing application Pods independently.

## Project contents

| File | Purpose |
| --- | --- |
| `alert-rule.yaml` | Production-shaped `PrometheusRule` definitions for high host CPU and sustained crash loops. |
| `alert-manager-configurations.yaml` | Label-based Alertmanager email routing and notification grouping. |
| `create-smtp-secret.sh` | Prompts for SMTP credentials and creates `Secret/smtp-auth` without committing them. |
| `test-alert-rule.yaml` | **Opt-in** always-firing rule used only to prove the notification pipeline. |
| `kustomization.yaml` | Normal baseline; includes the rules and routing configuration, never the SMTP Secret or test alert. |
| `values-minikube-arm64.yaml` | Verified local profile for Apple Silicon Minikube; pins an ARM64-compatible Prometheus Operator and disables optional Grafana to save disk. |
| `email-secret.yaml` | Deprecated non-deployable reminder explaining why credentials stay out of Git. |

## What you must customize

Before applying this to any real environment, edit the following values:

1. **Rule selector label.** `release: monitoring` must match the installed Prometheus `spec.ruleSelector`.
2. **AlertmanagerConfig selector label.** `release: monitoring` must match Alertmanager `spec.alertmanagerConfigSelector`.
3. **SMTP receiver.** Replace `alerts@example.invalid`, `smtp.example.invalid:587`, and identity values with your provider values.
4. **Alert policy.** Tune alert thresholds, durations, `team`, severity, and runbook URLs for the environment. The included 85% CPU for 10 minutes is a conservative starting point—not universal truth.
5. **Application alerts.** Add separate rules for user-facing SLOs, queue depth, database errors, and deployment failures based on metrics your application actually exports.

## First-time setup commands

Run these commands from this directory. They install kube-prometheus-stack on a disposable Minikube cluster; this is a real cluster-changing operation and may require several minutes and meaningful local resources.

```sh
kubectl config current-context
minikube status
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values values-minikube-arm64.yaml \
  --wait \
  --timeout 12m
```

This profile was required on the verified Apple Silicon Minikube environment because the chart's default Prometheus Operator image (`v0.95.1`) did not publish a `linux/arm64` manifest. It also disables Grafana, which is not required for alerting and saves approximately 1.4 GB of local image storage. For a larger cluster or an AMD64 node, omit the `--values` option if you want the chart defaults, including Grafana.

Check storage before installing: Prometheus needs writable local space even for a small lab.

```sh
minikube status
minikube ssh -- 'df -h / /var'
```

Confirm the Operator and custom-resource APIs are available:

```sh
kubectl get pods -n monitoring
kubectl api-resources --api-group=monitoring.coreos.com
kubectl get prometheus,alertmanager -n monitoring
```

## Confirm selectors before deployment

The labels on the custom resources must match the selectors of the installed stack. Inspect them before applying the project:

```sh
kubectl get prometheus -n monitoring -o yaml
kubectl get alertmanager -n monitoring -o yaml
```

Look for `spec.ruleSelector` on the Prometheus resource and `spec.alertmanagerConfigSelector` on the Alertmanager resource. Update the `release: monitoring` label in both project manifests only when your installation uses a different selector.

## Configure SMTP safely

After replacing the placeholder SMTP addresses, identity, and server in `alert-manager-configurations.yaml`, create the SMTP password Secret interactively:

```sh
bash create-smtp-secret.sh
kubectl get secret smtp-auth -n monitoring
```

The helper prompts with hidden input. If you cancel the prompt or enter an empty password, it exits clearly and does not create a Secret. Confirm the Secret before applying the routing configuration:

```sh
kubectl get secret smtp-auth -n monitoring
```

If `kubectl describe alertmanagerconfig application-email-routing -n monitoring` reports `secrets "smtp-auth" not found`, run the helper again successfully. The Alertmanager Operator will reconcile the existing configuration once the Secret exists.

For Gmail, use an App Password created for a two-factor-authenticated account—not your normal account password. For shared or production environments, replace this local shell workflow with External Secrets, SOPS, Sealed Secrets, or the organization’s approved secret manager.

## Validate before applying

Static rendering does not require the cluster CRDs:

```sh
kubectl kustomize . > /tmp/application-alerting.yaml
bash -n create-smtp-secret.sh
```

After kube-prometheus-stack is installed, validate against the server schemas without persisting resources:

```sh
kubectl apply --dry-run=server -f alert-rule.yaml
kubectl apply --dry-run=server -f alert-manager-configurations.yaml
```

## Apply and verify rules

Apply only the normal baseline after selector and SMTP configuration are complete:

```sh
kubectl apply -k .
kubectl get prometheusrule,alertmanagerconfig -n monitoring
kubectl describe prometheusrule application-alert-rules -n monitoring
kubectl describe alertmanagerconfig application-email-routing -n monitoring
```

To inspect the Prometheus and Alertmanager user interfaces locally, first discover the exact Service names, then forward them in separate terminals:

```sh
kubectl get svc -n monitoring
kubectl port-forward service/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
kubectl port-forward service/monitoring-kube-prometheus-alertmanager -n monitoring 9093:9093
```

Open `http://localhost:9090/alerts` for rule state and `http://localhost:9093` for Alertmanager routing state.

Grafana is disabled by `values-minikube-arm64.yaml`. Enable it later only when your Minikube/Docker Desktop disk has sufficient headroom.

## Add Grafana later

Grafana is a **separate Deployment**, not a sidecar in Prometheus or in your application Pods. It uses Prometheus as a data source to visualize metrics and dashboards; Prometheus and Alertmanager keep working without it.

The local ARM64 profile intentionally disables Grafana because the current Minikube disk has only about 1.2 GB free, while the Grafana image and its dashboard sidecars need more space. Before enabling it, expand Docker Desktop's disk image or reclaim unused Minikube workloads/images. Aim for at least 3 GB of free Minikube storage:

```sh
minikube ssh -- 'df -h / /var'
```

When adequate space is available, enable Grafana while preserving the verified ARM64 Operator settings:

```sh
helm upgrade monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --reuse-values \
  --set grafana.enabled=true \
  --wait \
  --timeout 12m
kubectl rollout status deployment/monitoring-grafana -n monitoring --timeout=180s
```

Retrieve the generated Grafana administrator password and open the UI:

```sh
kubectl get secret monitoring-grafana -n monitoring \
  -o jsonpath='{.data.admin-password}' | base64 -D; echo
kubectl port-forward service/monitoring-grafana -n monitoring 3000:80
```

Open `http://localhost:3000`. The chart automatically provisions Prometheus as Grafana's data source. Disable Grafana again if local storage pressure returns:

```sh
helm upgrade monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --reuse-values \
  --set grafana.enabled=false \
  --wait \
  --timeout 12m
```

## Test notification routing deliberately

`test-alert-rule.yaml` uses `vector(1)`, so it fires after one minute and can send a real email. Apply it only after confirming SMTP routing is safe:

```sh
kubectl wait --for=condition=Established crd/prometheusrules.monitoring.coreos.com --timeout=60s
kubectl apply -f test-alert-rule.yaml
kubectl get prometheusrule application-alert-test-rule -n monitoring
```

Verify the alert in Prometheus and Alertmanager, then delete the test immediately:

```sh
kubectl delete -f test-alert-rule.yaml
```

## Troubleshooting

| Symptom | Cause and next check |
| --- | --- |
| `the server doesn't have a resource type "prometheus"` | kube-prometheus-stack or its CRDs are not installed. Run the first-time setup commands and inspect `kubectl api-resources --api-group=monitoring.coreos.com`. |
| Rule exists but does not appear in Prometheus | `PrometheusRule` labels do not match `Prometheus.spec.ruleSelector`. Inspect the selector and rule labels. |
| Alert appears in Prometheus but no email arrives | The `AlertmanagerConfig` is not selected, the SMTP Secret is missing, or receiver settings are wrong. Inspect Alertmanager configuration and logs. |
| `no matches for kind` for AlertmanagerConfig | The operator/CRD version differs from this project. Check `kubectl api-resources --api-group=monitoring.coreos.com` and use the served version. |
| Port-forward exits | Confirm the Service name and ready pods with `kubectl get svc,pods -n monitoring`; choose another local port if it is occupied. |
| Operator `ErrImagePull` with `no matching manifest for linux/arm64` | The default operator image does not support the node architecture. Use `values-minikube-arm64.yaml` or select a chart/image combination that publishes the required architecture. |
| Prometheus exits with `no space left on device` | Reclaim unused Minikube images, disable optional local components such as Grafana, or enlarge Docker Desktop/Minikube storage before retrying. |

## Industry-ready improvements

- Route by `team`, `service`, `environment`, and `severity`, with documented ownership and escalation policy.
- Include `runbook_url`, dashboards, expected impact, and immediate mitigation in every alert annotation.
- Alert on user-facing SLO burn rates and error budgets rather than infrastructure symptoms alone.
- Deduplicate notifications with grouping; use different repeat intervals and escalation paths for warning versus critical alerts.
- Validate alert rules in CI with `promtool` and run synthetic alert-routing tests in a non-production environment.
- Store credentials in a managed secret system, rotate them, and protect Alertmanager configuration changes through review and RBAC.
- Add receiver health monitoring so a broken SMTP integration is detected before a real incident.

## Cleanup

Remove only the configuration managed by this project:

```sh
kubectl delete -k .
kubectl delete secret smtp-auth -n monitoring
```

If this is a disposable local lab and you also want to remove the monitoring stack:

```sh
helm uninstall monitoring -n monitoring
kubectl delete namespace monitoring
```
