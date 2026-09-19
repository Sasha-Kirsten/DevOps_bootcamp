### Overview
# Mosquitto with ConfigMap and Secret Volumes — Beginner Notes

## The goal in one sentence

Run a Mosquitto MQTT broker in Kubernetes, mount its normal configuration from a **ConfigMap**, and mount its login-password file from a **Secret**.

Do not try to build everything at once. Complete one baby step, check it works, then continue.

## What each Kubernetes object does

| Object | Simple explanation | Used for in this project |
| --- | --- | --- |
| `ConfigMap` | Stores normal, non-secret text configuration. | Holds `mosquitto.conf`. |
| `Secret` | Stores sensitive data. Values are encoded, not encrypted. | Holds Mosquitto's password file. |
| `Deployment` | Tells Kubernetes which container to run and how it should be configured. | Runs the Mosquitto Docker image. |
| `Service` | Gives Pods a stable name and port inside the cluster. | Lets clients use `mosquitto-service:1883`. |
| `volume` | Makes ConfigMap or Secret data available as files in a container. | Mounts the configuration and password file where Mosquitto expects them. |

## The finished flow

```text
MQTT client Pod
	|
	| mqtt://mosquitto-service:1883
	v
Kubernetes Service
	|
	v
Mosquitto Pod
   |          |
   v          v
ConfigMap    Secret
config file  password file
```

## Baby steps

### Step 1 — Read the configuration first

Open `config.yaml`. It contains the resources required for the demo, in the order you should understand them:

1. ConfigMap
2. Secret
3. Deployment
4. Service

Read the comments before editing anything. The original generic `XXXX` template has been replaced because it was not related to Mosquitto.

### Step 2 — Understand `mosquitto.conf`

The ConfigMap contains this important Mosquitto configuration:

```conf
listener 1883
allow_anonymous false
password_file /mosquitto/config/passwords
```

It means:

- Listen for MQTT connections on port `1883`.
- Reject clients that do not provide credentials.
- Look for the credentials file at `/mosquitto/config/passwords`.

That path must exactly match the Secret volume mount in the Deployment.

### Step 3 — Create a real password file

Mosquitto does **not** use a plain `username=password` file. It requires a password hash created with `mosquitto_passwd`.

Create a local password file for a test user, for example `demo-user`. Then copy the generated, hashed file content into the `stringData.passwords` section of the Secret in `config.yaml`.

**Learning rule:** Never commit a real password file to a public repository. Use a throwaway credential only for this local exercise. In production, create the Secret through a secure secret-management workflow.

### Step 4 — Check the volume mounts

In the Deployment, find `volumeMounts` and `volumes`.

- The `ConfigMap` mount places `mosquitto.conf` at `/mosquitto/config/mosquitto.conf`.
- The `Secret` mount places the `passwords` file at `/mosquitto/config/passwords`.

Kubernetes creates these files when the Pod starts. You do not need to build a custom Docker image just to add configuration or credentials.

### Step 5 — Apply the manifest

Once you have added a safe test password hash, apply all four resources:

```sh
kubectl apply -f config.yaml
kubectl get configmap,secret,deployment,pods,service
kubectl rollout status deployment/mosquitto
```

If the Pod does not start, inspect its events before changing the YAML:

```sh
kubectl describe pod -l app=mosquitto
kubectl logs deployment/mosquitto
```

### Step 6 — Test a client connection

The Service is `ClusterIP`, which means it is available only inside the Kubernetes cluster. A client Pod should connect to:

```text
mosquitto-service:1883
```

Test these two outcomes:

1. A connection without a username/password is rejected.
2. A connection using your test username and password can publish and subscribe to the same MQTT topic.

For a short local experiment, you can also forward the broker port:

```sh
kubectl port-forward service/mosquitto-service 1883:1883
```

Then point a local MQTT client at `localhost:1883`.

## Common beginner mistakes

| Problem | What to check |
| --- | --- |
| Mosquitto starts without requiring a password | Ensure `allow_anonymous false` is in the ConfigMap and the ConfigMap is mounted at the expected path. |
| Pod reports that `passwords` is missing | Confirm the Secret key is called `passwords` and its mount uses the same key. |
| Client cannot connect | Check the Service selector is `app: mosquitto`, port `1883` is used, and the Pod is Ready. |
| Password is rejected | Regenerate it with `mosquitto_passwd`; do not manually type a plain-text value into the password file. |
| Service has no endpoints | Compare the Service selector with the Pod label in the Deployment. They must match exactly. |

## When you are ready for the next level

After the basic demo works, consider adding:

- A PersistentVolumeClaim for `/mosquitto/data` if MQTT persistence is required.
- Resource requests and limits.
- Readiness and liveness probes.
- TLS certificates and secure MQTT on port `8883`.
- NetworkPolicies limiting which Pods can connect to the broker.

## Cleanup

Remove every resource created by this exercise:

```sh
kubectl delete -f config.yaml
```

### Prerequisites
Technologies used: Kubernetes, Docker and Mosquitto.

### Contents
Project Description:
1. Define configuration and passwords for Mosquitto message broker with ConfigMap and Secret Volume types.

### Getting Started


### Resources