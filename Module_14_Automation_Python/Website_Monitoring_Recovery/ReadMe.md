# Demo Project: Website Monitoring and Recovery

## Overview

This project demonstrates the building blocks of a website-monitoring and recovery workflow using Python. The intended setup is a Linux server on Linode that runs a containerised application with Docker. A Python script requests the application's HTTP endpoint, sends an email alert when the site is unhealthy, and remotely restarts the application service as an initial recovery action.

The intended end-to-end workflow is:

1. Create and secure a Linux server on a cloud platform such as Linode.
2. Install Docker and run the application as a container on that server.
3. Monitor a website endpoint with Python and validate its HTTP response.
4. Send an email notification when the response indicates an outage.
5. Attempt automatic recovery by restarting the application service, then verify that it is healthy again.

> **Current repository status:** `main.py` contains a learning skeleton only. It performs one HTTP request using `requests`, sends an email using Gmail SMTP for a non-200 response, and contains a Paramiko-based attempt to restart `my_application.service`. The website URL, SSH hostname, username, and password are empty placeholders. Linode provisioning, Docker installation/container deployment, continuous monitoring, and server reboot recovery are not implemented yet.

## Technologies Used

| Technology | Purpose |
| --- | --- |
| Python | Runs the monitor, alerting, and recovery logic. |
| Requests | Sends HTTP requests to check website availability. |
| SMTP / Gmail | Sends the current email notification. |
| Paramiko | Connects to a remote Linux server over SSH to execute a restart command. |
| Linode | Intended cloud platform for the Linux server; no Linode API calls exist in the current script. |
| Linux | Hosts the application service and Docker runtime. |
| Docker | Intended runtime for the application container; not managed by the current script. |

## What `main.py` Currently Does

The script has two separate demonstration sections.

### HTTP check and email notification

1. Reads `EMAIL_ADDRESS` and `EMAIL_PASSWORD` from environment variables.
2. Calls `requests.get("")` with an empty URL placeholder.
3. Prints a success message only when the response status is exactly `200`.
4. For every other HTTP response, starts a TLS connection to `smtp.gmail.com:587`, signs in, and emails an alert to the same email address.

### Recovery attempt over SSH

The `try` block demonstrates the intended recovery path:

1. Makes another HTTP request with an empty URL placeholder.
2. Enters the recovery branch unconditionally because it currently uses `if False`.
3. Creates a Paramiko SSH client and runs:

	```text
	sudo systemctl restart my_application.service
	```

4. Prints standard output and closes the connection.

This is an **application service restart**, not a server restart. The script does not execute a host reboot and does not verify recovery after running the restart command.

## Current Limitations and Important Corrections

Before running this script against a real server, address these items:

1. **Set the monitored URL.** Both `requests.get("")` calls will fail until they use a real HTTPS health endpoint, such as `https://example.com/healthz`.
2. **Use a real health decision.** `if False` always selects the outage/recovery branch. Replace it with a condition based on the response, exceptions, and an agreed healthy status range such as $200 \leq status\_code < 400$.
3. **Add request timeouts.** `requests.get()` has no timeout today and can hang. Use separate connection/read timeouts and handle `requests.RequestException`.
4. **Do not use `AutoAddPolicy()` in production.** It trusts any SSH host key and enables man-in-the-middle attacks. Verify host keys with a managed `known_hosts` file and `RejectPolicy()`.
5. **Do not use passwords in source code.** The current SSH password field is empty, but it must not be replaced with a committed password. Prefer a dedicated automation user, SSH key/certificate, or a cloud-native remote-execution service.
6. **Avoid broad passwordless sudo.** Permit the automation identity to restart only the required service through a narrowly scoped `sudoers` rule.
7. **Capture failures.** Read standard error and the SSH command exit status; a restart command can fail even when standard output is empty.
8. **Verify after recovery.** Repeat the health check after a bounded delay and report whether the application truly recovered.
9. **Prevent alert and restart storms.** Add retry thresholds, cooldowns, deduplication, and a maximum number of automated recovery attempts.

## Suggested Project Structure

```text
Website_Monitoring_Recovery/
├── main.py                 # Monitor/alert/recovery application
├── requirements.txt        # Pinned Python dependencies
├── .env.example            # Names only; never real credentials
├── tests/                  # HTTP, SMTP, and SSH client unit tests
├── deployment/
│   ├── docker-compose.yaml # Application service definition
│   └── systemd/            # Optional monitor/service units
└── ReadMe.md
```

Do not commit `.env`, SSH private keys, Gmail app passwords, Linode API tokens, server IP addresses for private environments, or production logs.

## Prerequisites

Before completing or running the project, you need:

- A Linux server on Linode or another cloud provider.
- A DigitalOcean/Linode-style cloud firewall or host firewall that permits only required inbound traffic.
- Docker and Docker Compose installed on the remote server.
- An application container with an HTTP health endpoint, for example `/healthz`.
- Python 3 and isolated dependencies on the monitoring machine or service runner.
- A Gmail account using an **App Password** for SMTP, or an approved transactional-email provider.
- A dedicated remote automation user that can run only the required application restart command.
- SSH host-key verification configured for the remote host.

Install the current Python dependencies in a virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install requests paramiko
```

Set credentials outside Git. For the current Gmail example, use environment variables:

```text
EMAIL_ADDRESS=<sender-address>
EMAIL_PASSWORD=<gmail-app-password>
```

Use an App Password rather than an account password. A production system should retrieve secrets from a dedicated secret manager and ensure logs never emit their values.

## Implementation Steps

### 1. Create and secure the application server

Create a Linode with a supported Linux distribution. Configure SSH-key-only access, disable password authentication, and use a firewall to expose only the application through HTTPS. Keep SSH limited to the administration network, VPN, or CI/CD runner.

### 2. Run the application with Docker

Install Docker from a trusted source, then deploy the application with a reviewed Compose file or another container orchestrator. Configure:

- Pinned images by version or digest, not only `latest`.
- Container health checks.
- Restart policy such as `unless-stopped` or `on-failure`.
- Resource limits and log rotation.
- Secrets injected at runtime rather than embedded in images or Compose files.

If Docker itself restarts failed containers, the Python script should avoid duplicating that responsibility unless there is a documented reason to perform a higher-level recovery action.

### 3. Implement safe HTTP monitoring

Move the website URL, success-status range, timeout, check interval, retry count, and recovery cooldown to command-line arguments or environment variables. Encapsulate the HTTP request in a function that returns a clear healthy/unhealthy result and catches timeouts, DNS failures, TLS errors, and connection failures.

Run the monitor periodically with a managed scheduler or service rather than an unmanaged tight infinite loop. For production, consider a service manager, a scheduled job, or an external availability-monitoring platform.

### 4. Send actionable notifications

Send an alert only after a defined number of consecutive failed checks. Include the UTC timestamp, endpoint, HTTP status or exception, attempt count, and recovery result. Send a separate recovery notification when the service becomes healthy again.

For Gmail, use SMTP STARTTLS as shown in the learning code, but use an App Password and handle authentication/SMTP exceptions. For a production service, a transactional provider and centralized alerting system are generally more appropriate.

### 5. Implement controlled recovery

Prefer restarting the Docker container or Compose project through a narrow, authenticated operational interface. If SSH is retained for this learning project:

1. Use a dedicated, non-root automation account and SSH key or certificate.
2. Strictly validate the server host key.
3. Allow a fixed restart command only, such as `systemctl restart my_application.service`.
4. Enforce a cooldown and maximum restart count.
5. Run a post-restart health check before declaring recovery successful.
6. Escalate to a human instead of rebooting the server automatically after repeated failures.

Automatic host reboots can worsen an outage or hide the root cause, so they should require a separately reviewed runbook and safeguards. The current code does **not** reboot the server.

## Verification

After completing the missing implementation, validate each outcome safely in a non-production environment:

1. A healthy endpoint returns the success message without sending an alert or executing recovery.
2. A controlled unhealthy endpoint triggers one alert containing useful diagnostic context.
3. The SSH recovery identity can restart only the intended application service.
4. The script verifies that the endpoint is healthy after restart and sends a recovery notification.
5. An unknown SSH host key, invalid credential, command failure, or request timeout produces a clear error without weakening security controls.
6. Repeated failures respect the retry threshold, cooldown, and maximum recovery attempts.
7. Docker restarts the container according to its configured restart policy after an application process failure.

Do not simulate outages by taking down a production service. Use a staging endpoint or a disposable container instead.

## Production Hardening Checklist

- [ ] Configure all URLs, timeouts, intervals, recipients, and service names outside source code.
- [ ] Add HTTP timeouts, exception handling, retries with backoff, and structured logging.
- [ ] Require several consecutive failed checks before alerting or recovering.
- [ ] Use SSH host-key verification and keys/certificates; never `AutoAddPolicy()` or plaintext passwords.
- [ ] Scope sudo to one required restart action and record recovery audit logs.
- [ ] Verify recovery with a post-restart health check and alert when recovery fails.
- [ ] Add cooldowns, maximum restart counts, and human escalation to prevent restart loops.
- [ ] Store email and cloud credentials in a secret manager; never commit them.
- [ ] Use HTTPS and validate TLS certificates for the monitored endpoint.
- [ ] Add unit tests by mocking `requests`, SMTP, and Paramiko; add dependency pinning and security scans.
- [ ] Prefer provider/managed monitoring and alerting for business-critical services.

## Resources

- [Requests documentation](https://requests.readthedocs.io/)
- [Paramiko documentation](https://www.paramiko.org/)
- [Docker health checks](https://docs.docker.com/reference/dockerfile/#healthcheck)
- [Docker restart policies](https://docs.docker.com/engine/containers/start-containers-automatically/)
- [Linode Cloud Firewall documentation](https://www.linode.com/docs/products/networking/cloud-firewall/)
- [Google Account App Passwords](https://support.google.com/accounts/answer/185833)