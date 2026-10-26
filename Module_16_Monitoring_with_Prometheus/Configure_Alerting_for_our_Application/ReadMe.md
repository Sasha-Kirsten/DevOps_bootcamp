# Configure Application Alerting with Prometheus and Alertmanager

## Overview

This project demonstrates the alerting flow in a Kubernetes cluster running the Prometheus Operator through the `kube-prometheus-stack` Helm chart:

1. A `PrometheusRule` evaluates PromQL expressions.
2. Prometheus fires an alert when a rule remains true for its configured duration.
3. Alertmanager groups, routes, deduplicates, and silences alerts.
4. An `AlertmanagerConfig` selects a receiver and sends an email notification through SMTP.

```text
Node / Kubernetes metrics
					 |
					 v
PrometheusRule evaluates PromQL
					 |
					 v
Prometheus fires alert labels and annotations
					 |
					 v
AlertmanagerConfig routes matching alerts
					 |
					 v
SMTP receiver sends email notification
```

> **Learning project:** The supplied manifests are starter files. Read **Before You Apply** before applying them to the cluster. The cluster API versions below were verified on this environment.

## Project Files

| File | Purpose |
| --- | --- |
| `alert-rule.yaml` | Intended Prometheus alert rules, such as host CPU load and Pod crash-loop alerts. |
| `alert-manager-configurations.yaml` | Alertmanager routing and SMTP receiver configuration. |
| `email-secret.yaml` | Placeholder Kubernetes Secret for the SMTP password or Gmail App Password. |
| `alert.yaml` | Reserved for additional application-specific alert rules. |
| `ReadMe.md` | Setup, validation, troubleshooting, and security guidance. |

## Kubernetes Resource Types

The Prometheus Operator adds custom resources to Kubernetes. Each resource has a distinct purpose:

| Resource | API version in this cluster | Purpose |
| --- | --- | --- |
| `PrometheusRule` | `monitoring.coreos.com/v1` | Defines Prometheus recording and alerting rules. |
| `Alertmanager` | `monitoring.coreos.com/v1` | Configures an Alertmanager instance managed by the operator. |
| `AlertmanagerConfig` | `monitoring.coreos.com/v1alpha1` | Defines routes and receivers for an existing Alertmanager instance. |

The installed APIs can be checked at any time:

```sh
kubectl api-resources --api-group=monitoring.coreos.com
kubectl get crd alertmanagers.monitoring.coreos.com \
	alertmanagerconfigs.monitoring.coreos.com \
	prometheusrules.monitoring.coreos.com \
	-o jsonpath='{range .items[*]}{.metadata.name}{": "}{range .spec.versions[*]}{.name}{" "}{end}{"\n"}{end}'
```

## Prerequisites

Before configuring alerts, make sure you have:

- A Kubernetes cluster with `kube-prometheus-stack` and the Prometheus Operator installed.
- `kubectl`, Helm, and access to the `monitoring` namespace.
- Prometheus successfully scraping the metrics used by the alert expressions.
- An SMTP provider. For Gmail, enable two-step verification and generate an **App Password**; do not use the regular Google account password.
- Permissions to create `PrometheusRule`, `AlertmanagerConfig`, and Secret resources in the target namespace.

Check the monitoring components first:

```sh
kubectl get pods -n monitoring
kubectl get prometheus,alertmanager -n monitoring
kubectl get crd | grep monitoring.coreos.com
```

## Alert Rule Workflow

Alert rules belong in a `PrometheusRule`, not a `Prometheus` resource. A valid rule starts with this resource header:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
	name: application-alert-rules
	namespace: monitoring
	labels:
		release: monitoring
```

The `release: monitoring` label is common for a Helm release named `monitoring`, but selectors differ by chart configuration. Confirm the selector used by the installed Prometheus resource before applying rules:

```sh
kubectl get prometheus -n monitoring -o yaml
```

Every alert rule needs an alert name, PromQL expression, duration, labels, and annotations. For example:

```yaml
groups:
	- name: application.rules
		rules:
			- alert: HostHighCpuLoad
				expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[2m])) * 100) > 50
				for: 2m
				labels:
					severity: warning
				annotations:
					summary: Host CPU load is high
					description: CPU utilisation has remained above 50% for two minutes.
```

Choose thresholds appropriate for the environment. A 50% CPU threshold is useful for demonstrating an alert, but it is usually too sensitive for production.

## Alertmanager Email Routing

Email routing belongs in an `AlertmanagerConfig`, not an `Alertmanager` resource. The project file uses the API version supported by this cluster:

```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
	name: main-rules-alert-config
	namespace: monitoring
```

The Alertmanager instance must be configured to select `AlertmanagerConfig` objects with matching labels. Inspect its selector:

```sh
kubectl get alertmanager -n monitoring -o yaml
```

If an `alertmanagerConfigSelector` is defined, add labels to `alert-manager-configurations.yaml` that match it. If the selector is empty or omitted, confirm the Helm chart behaviour before relying on the configuration.

The receiver route should use the same label values emitted by the Prometheus rule. For example, routing on `alertname: HostHighCpuLoad` only works when the alert rule name is exactly `HostHighCpuLoad`.

## Configure the Email Secret Safely

`email-secret.yaml` is a template only. Do **not** commit a real Gmail App Password, even base64 encoded—base64 is encoding, not encryption.

For a local learning cluster, create the Secret from the command line instead:

```sh
kubectl create secret generic gmail-auth \
	--namespace monitoring \
	--from-literal=password='<gmail-app-password>'
```

For GitOps or shared environments, use an approved secret-management solution such as External Secrets Operator, Sealed Secrets, SOPS, or a CI/CD secret store.

Confirm the Secret exists without printing its value:

```sh
kubectl get secret gmail-auth -n monitoring
```

## Before You Apply

Complete these corrections before applying the current starter manifests:

- [ ] Change `kind: Prometheus` to `kind: PrometheusRule` in `alert-rule.yaml`.
- [ ] Keep `apiVersion: monitoring.coreos.com/v1` for `PrometheusRule`.
- [ ] Remove or complete the second, empty alert rule in `alert-rule.yaml`; empty `alert`, `expr`, `for`, labels, and annotations are invalid.
- [ ] Check alert-rule labels against the Prometheus `ruleSelector` configuration.
- [ ] Check `AlertmanagerConfig` labels against the Alertmanager `alertmanagerConfigSelector` configuration.
- [ ] Set real SMTP addresses in `to`, `from`, `authUsername`, and `authIdentity`.
- [ ] Use a real Secret named `gmail-auth` in the `monitoring` namespace with a `password` key.
- [ ] Use a Gmail App Password, not an account password.
- [ ] Test SMTP delivery with a controlled alert before relying on the notification route.

## Validate and Apply

Validate the manifest shapes against the cluster before making changes:

```sh
kubectl apply --dry-run=server -f alert-rule.yaml
kubectl apply --dry-run=server -f alert-manager-configurations.yaml
```

After completing the manifests and creating the Secret, apply them in this order:

```sh
kubectl apply -f email-secret.yaml
kubectl apply -f alert-rule.yaml
kubectl apply -f alert-manager-configurations.yaml
```

For real credentials, use the `kubectl create secret` command shown above instead of applying `email-secret.yaml` from Git.

## Verification and Troubleshooting

Check that Kubernetes accepted the custom resources:

```sh
kubectl get prometheusrule -n monitoring
kubectl get alertmanagerconfig -n monitoring
kubectl describe prometheusrule application-alert-rules -n monitoring
kubectl describe alertmanagerconfig main-rules-alert-config -n monitoring
```

Open the Prometheus UI and check the **Alerts** page. Open the Alertmanager UI and check that the alert appears under the expected receiver route.

If you use local port forwarding, run it in a separate terminal and leave it running:

```sh
kubectl port-forward service/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
kubectl port-forward service/monitoring-kube-prometheus-alertmanager -n monitoring 9093:9093
```

Typical problems:

| Symptom | Likely cause | Check |
| --- | --- | --- |
| `no matches for kind` | Wrong API version, kind, or missing CRD. | `kubectl api-resources --api-group=monitoring.coreos.com` |
| Rule exists but is not visible in Prometheus | `PrometheusRule` labels do not match the Prometheus rule selector. | `kubectl get prometheus -n monitoring -o yaml` |
| Alert fires but no email arrives | Receiver configuration is not selected, SMTP details are wrong, or the Secret is missing. | Alertmanager logs and `kubectl get secret gmail-auth -n monitoring` |
| Alert stays inactive | Expression has no matching metrics or threshold is not crossed. | Prometheus query page and target status |
| Port-forward stops immediately | Service/pod name is wrong, pod is not ready, or another process owns the local port. | `kubectl get svc,pods -n monitoring` |

## Security and Operations Guidance

- Keep SMTP passwords, kubeconfig files, and cloud credentials out of Git and shell history.
- Use a dedicated alert receiver address or notification channel for each environment.
- Route by labels such as `severity`, `team`, `service`, and `environment`; do not route only by alert name as the system grows.
- Add `groupBy`, `groupWait`, and `groupInterval` settings to reduce notification noise.
- Use warning and critical thresholds with documented runbooks in alert annotations.
- Test every alert rule, notification route, and escalation path regularly.
- Review Alertmanager and Prometheus logs after configuration changes.

## Resources

- [Prometheus alerting rules documentation](https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/)
- [Alertmanager configuration documentation](https://prometheus.io/docs/alerting/latest/configuration/)
- [Prometheus Operator API reference](https://prometheus-operator.dev/docs/api-reference/api/)
- [kube-prometheus-stack chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [Kubernetes Secrets documentation](https://kubernetes.io/docs/concepts/configuration/secret/)