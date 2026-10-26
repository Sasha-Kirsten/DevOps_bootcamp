# Demo Project: Health Check EC2 Status Checks

## Overview

This project demonstrates the first step in automating Amazon EC2 health monitoring with Python and Boto3. The script queries EC2 in a configured AWS Region, prints each discovered instance's lifecycle state, and then prints the available **instance** and **system** status checks.

The intended complete workflow is:

1. Provision EC2 instances with Terraform.
2. Run a Python/Boto3 script that retrieves and prints EC2 status information.
3. Extend the script to repeat the checks at a defined interval and report unhealthy instances.

> **Current repository status:** `main.py` contains a one-time query for the hard-coded `us-east-1` Region. Terraform configuration and continuous polling are not included yet. In addition, the current instance loop needs correction before it can print the intended lifecycle-state results; see [Known limitations and next steps](#known-limitations-and-next-steps).

## Technologies Used

| Technology | Purpose |
| --- | --- |
| Python | Runs the monitoring script. |
| Boto3 | AWS SDK for Python used to call the EC2 API. |
| AWS EC2 | Service whose instance state and status checks are queried. |
| Terraform | Intended tool for repeatable EC2 provisioning; not yet present in this directory. |

## What the Current Script Does

`main.py` creates an EC2 client for `us-east-1` and calls:

- `describe_instances()` to retrieve EC2 reservations and instances.
- `describe_instance_status()` to retrieve EC2 **instance status** and **system status** checks.

The intended console output is similar to:

```text
Instance ID: i-0123456789abcdef0, State: running
Instance ID: i-0123456789abcdef0, Instance Status: ok, System Status: ok
```

### Understanding the reported values

| Value | Meaning |
| --- | --- |
| Instance state | Lifecycle state such as `pending`, `running`, `stopping`, `stopped`, `shutting-down`, or `terminated`. |
| Instance status | Health of the EC2 instance's software/network reachability checks. |
| System status | Health of the underlying AWS infrastructure supporting the instance. |

`describe_instance_status()` returns status checks primarily for running instances and, by default, does not include every non-running instance. This is why lifecycle state and health checks should be interpreted separately.

## Project Structure

```text
Health_Check_EC2_status/
├── main.py       # One-time EC2 state/status query
└── ReadMe.md     # Project instructions and next steps
```

A completed version can add Terraform, tests, and dependency metadata:

```text
Health_Check_EC2_status/
├── main.py
├── requirements.txt
├── tests/
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── ReadMe.md
```

## Prerequisites

Before running the script, make sure you have:

- Python 3 installed.
- `boto3` installed in an isolated virtual environment.
- AWS credentials available through an AWS profile, environment variables, or an IAM role.
- Permission to query EC2 in the chosen Region.
- At least one EC2 instance in `us-east-1`, or an updated Region configuration that matches your instances.

Install the SDK:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install boto3
```

Use short-lived credentials or an IAM role whenever possible. Do not commit AWS access keys, secret keys, or a real `.env` file to Git.

### Minimum IAM permissions

The script needs read-only permissions equivalent to:

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"ec2:DescribeInstances",
				"ec2:DescribeInstanceStatus"
			],
			"Resource": "*"
		}
	]
}
```

Apply least privilege at the account, environment, and role level. These describe APIs do not support resource-level restrictions in the same way as many mutating EC2 APIs, so scope the identity and AWS account access carefully.

## Run the Script

After correcting the loop described below, run:

```bash
python3 main.py
```

The script currently queries only `us-east-1` because that Region is hard-coded in both Boto3 client/resource creation. A production-ready version should accept the Region as a command-line argument or environment variable and validate it before use.

## Known Limitations and Next Steps

### 1. Correct the instance iteration

`describe_instances()` returns a list of instances for each reservation. The current code assigns the first instance to `instance` and then loops over that dictionary:

```python
instance = reservation['Instances'][0]
for instance in instance:
```

Iterating over a dictionary yields its keys, not an EC2 instance object. The next implementation step is to iterate over `reservation['Instances']` directly, then read `InstanceId` and `State` from each instance dictionary. This also ensures multiple instances in the same reservation are handled correctly.

### 2. Remove the unused EC2 resource

`ec_resource` is created but never used. Either remove it and use only the EC2 client, or use the resource interface consistently. For this reporting script, the client is sufficient.

### 3. Provision instances with Terraform

Add a `terraform/` directory that provisions a clearly tagged test EC2 instance. Keep Terraform state remote and encrypted for a shared environment, do not open SSH broadly, and expose only non-sensitive outputs such as instance IDs or private addresses.

Use consistent tags such as `Project`, `Environment`, and `ManagedBy = Terraform`. The Python script can then filter results by those tags to avoid reporting every instance in a shared AWS account.

### 4. Add continuous checks

Wrap the query in a function and run it on a fixed interval using `time.sleep(interval_seconds)`. Make the interval configurable with a command-line argument or environment variable rather than hard-coding it.

For long-running production monitoring, prefer an event-driven or managed observability design over an unmanaged infinite loop on a laptop. Suitable options include Amazon CloudWatch alarms, EventBridge, a container/service with health supervision, or a scheduled job that sends results to a monitoring platform.

### 5. Handle AWS API pagination and errors

Use the EC2 paginator for `describe_instances` so every instance is processed in large accounts. Catch and report expected Boto3 exceptions such as missing credentials, access denied, invalid Region, throttling, and transient network failures. Use retry/backoff rather than rapidly repeating failed API calls.

### 6. Produce actionable output

Replace ad-hoc `print()` statements with structured logging. Include a timestamp, AWS account/Region, instance ID, tags, lifecycle state, and status-check result. Return a non-zero exit code or send an alert only for agreed unhealthy conditions, such as a running instance with an impaired instance or system check.

## Verification

Once the loop is corrected and credentials are configured, verify:

1. The script lists every intended EC2 instance, including multiple instances in a reservation.
2. Each line has an instance ID and lifecycle state.
3. Running instances with completed health checks display their instance and system status.
4. A stopped instance may appear in lifecycle output without a corresponding health-check result.
5. An IAM role without `DescribeInstances` fails with a clear access-denied message after error handling is added.
6. The continuous-check implementation waits for the configured interval rather than calling the API continuously.

For a safe demonstration, use a dedicated development account or instances tagged specifically for this project. Do not intentionally impair production EC2 instances to test alerts.

## Production Hardening Checklist

- [ ] Configure Region, interval, and tag filters through CLI arguments or environment variables.
- [ ] Use paginators and support multiple instances per reservation.
- [ ] Add structured logging, error handling, retry/backoff, and an appropriate exit code.
- [ ] Filter by explicit project/environment tags in shared AWS accounts.
- [ ] Use IAM roles or short-lived credentials; never hard-code AWS keys.
- [ ] Add unit tests with Boto3 Stubber or mocked EC2 API responses.
- [ ] Add dependency pinning and vulnerability scanning.
- [ ] Run periodic checks through a managed scheduler/service or use CloudWatch alarms for operational monitoring.
- [ ] Send alerts only for defined unhealthy conditions and include a runbook link.

## Resources

- [Boto3 EC2 client documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2.html)
- [EC2 `describe_instances` API reference](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_DescribeInstances.html)
- [EC2 status checks](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html)
- [AWS IAM best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Terraform AWS Provider documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)