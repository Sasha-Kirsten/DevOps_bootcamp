# Demo Project: Automate Configuring EC2 Server Instances

## Overview

This project demonstrates two EC2 automation tasks using Python and Boto3:

1. Adding or updating environment tags on EC2 server instances.
2. Displaying EC2 instance and system health checks on a schedule.

Consistent tags make AWS resources easier to identify, secure, operate, and allocate costs for. The primary goal of this project is to automate environment tagging—such as `Environment = development`, `staging`, or `production`—rather than applying tags manually in the AWS Console.

> **Current repository status:** The project contains two learning scripts. `ec_add_tags.py` demonstrates listing specific instances, calling `create_tags()`, and printing tags afterwards, but it contains placeholder instance IDs, resource IDs, and tag values. `main.py` performs a separate, read-only EC2 status check every 10 seconds. Neither script is ready to run safely against a shared or production AWS account without the corrections described below.

## Technologies Used

| Technology | Purpose |
| --- | --- |
| Python | Runs the automation scripts. |
| Boto3 | AWS SDK for Python used to call the EC2 API. |
| AWS EC2 | Provides the instances, tags, and health-status data. |
| `schedule` | Runs the status-check function in `main.py` at a fixed local interval. |

## Project Files

| File | Current purpose |
| --- | --- |
| `ec_add_tags.py` | Intended EC2 environment-tagging workflow. It describes listed instances, calls `create_tags()`, and prints tags afterwards. |
| `main.py` | Read-only instance/system status reporting loop using `describe_instance_status(IncludeAllInstances=True)`. |
| `ReadMe.md` | Project guide, safety requirements, and planned improvements. |

## How `ec_add_tags.py` Works

The tagging script currently follows this sequence:

1. Creates EC2 client and resource objects for the hard-coded `us-east-1` Region.
2. Defines `instance_ids_frankfurt`, a list of example EC2 instance IDs.
3. Calls `describe_instances(InstanceIds=...)` and prints each instance's lifecycle state.
4. Calls `create_tags()` to apply tags to resources.
5. Calls `describe_instances()` again and prints the tags returned for each listed instance.

The intended `create_tags()` request should target the same selected instance IDs and apply a real environment tag, for example:

```text
Resource: i-0123456789abcdef0
Tag: Environment = development
```

AWS tag keys and values are case-sensitive by convention. Define a shared tag standard before automation so `Environment`, `environment`, and `Env` do not fragment resource reporting.

## How `main.py` Works

`main.py` is a separate status-reporting proof of concept. It:

1. Creates an EC2 client for `us-east-1`.
2. Calls `describe_instance_status(IncludeAllInstances=True)`.
3. Prints the EC2 instance status and system status for each result.
4. Schedules this check every 10 seconds in an infinite loop.

Example intended output:

```text
Instance ID: i-0123456789abcdef0, Instance Status: ok, System Status: ok
Instance status check completed.
```

This script does not configure instances or add tags. It reports AWS health-check information. The 10-second schedule is suitable only for a short learning demonstration, not a production monitoring interval.

## Prerequisites

Before running either script, ensure you have:

- Python 3 installed.
- Boto3 installed; `main.py` also requires the `schedule` package.
- AWS credentials supplied through an AWS profile, AWS IAM Identity Center, environment variables, or an IAM role.
- Permission to list, inspect, tag, and—if using `main.py`—read the status of EC2 instances in the target Region.
- A dedicated development account or instances explicitly tagged for this exercise.

Install the dependencies in a virtual environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install boto3 schedule
```

Use short-lived credentials or an IAM role whenever possible. Never commit AWS access keys, secret keys, session tokens, production instance IDs, or real environment files to Git.

### Minimum IAM Permissions

For the current tagging and status workflows, the executing identity needs permissions equivalent to:

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"ec2:DescribeInstances",
				"ec2:DescribeInstanceStatus",
				"ec2:CreateTags"
			],
			"Resource": "*"
		}
	]
}
```

Use a dedicated role and constrain it to the intended AWS account, Region, and tag-governed resources wherever IAM supports the condition. Separate read-only status access from tag-mutation access if the reporting script is operated independently.

## Required Corrections Before Tagging

Do **not** execute `ec_add_tags.py` unchanged. Complete these corrections first:

1. **Use the correct Region.** The variable name `instance_ids_frankfurt` suggests `eu-central-1`, but the client is configured for `us-east-1`. An EC2 instance ID is valid only in its own Region. Make the Region a CLI argument or environment variable and ensure it matches the selected IDs.
2. **Replace example IDs.** The two IDs are placeholders. Discover intended targets through explicit filters or pass validated instance IDs at runtime; do not commit production IDs.
3. **Replace `Resources=['string']`.** Pass the actual selected instance IDs, normally `Resources=instance_ids`.
4. **Replace the placeholder tag.** Set a defined key/value pair, for example `{"Key": "Environment", "Value": "development"}`.
5. **Fix dry-run handling.** `DryRun=False|True` evaluates to `True` in Python. Use an explicit boolean such as `DryRun=True` for validation, then require an explicit `--apply` flag before using `DryRun=False`.
6. **Remove unused objects.** Both scripts create `ec2_resource` but only use `ec2_client`. Remove the unused resource or use it consistently.
7. **Add API error handling.** Catch missing credentials, access denied, invalid instance IDs, incorrect Region, throttling, and partial failure errors before reporting success.

## Safe Environment-Tagging Workflow

### 1. Define a tag policy

Agree on consistent mandatory tags before writing automation. A simple starting policy is:

| Tag | Example | Purpose |
| --- | --- | --- |
| `Environment` | `development` | Separates development, staging, and production resources. |
| `Project` | `ec2-tagging-demo` | Identifies the workload or learning project. |
| `Owner` | `platform-team` | Identifies the accountable owner. |
| `ManagedBy` | `python-boto3` | Records the automation responsible for the tag. |

Use AWS Tag Policies, Service Control Policies, IaC validation, or CI/CD checks where appropriate to enforce the schema. Do not allow this script to overwrite protected or centrally managed tags without a review process.

### 2. Select targets safely

Avoid a hard-coded list for bulk operations. Use `describe_instances` filters that require explicit opt-in tags, for example:

- `Project = ec2-tagging-demo`
- `TaggingOptIn = true`
- `instance-state-name = running`

Print the selected instance IDs and their current tags. Require an operator to review the planned changes before the script calls the mutating `create_tags()` API.

### 3. Use dry-run and apply modes

Provide a `--dry-run` mode that calls `create_tags(DryRun=True)`. AWS returns a `DryRunOperation` error when permissions are sufficient—this confirms authorization without applying the change.

Make the real mutation opt-in, for example through `--apply`. Log the intended and applied tag changes with a timestamp, Region, AWS account, automation identity, and resource IDs.

### 4. Verify tag results

After tagging, call `describe_instances` again and verify that every selected instance has the expected key/value. Treat missing or conflicting tags as failures and return a non-zero exit code for CI/CD or scheduled automation.

## Run and Verify

After completing the required corrections, use a development account and explicit test targets:

```bash
python3 ec_add_tags.py --region eu-central-1 --environment development --dry-run
python3 ec_add_tags.py --region eu-central-1 --environment development --apply
```

The command-line interface above is a recommended next implementation; the current script does not yet accept these arguments.

Verify that:

1. Only explicitly selected/filtered test instances are displayed and tagged.
2. Dry-run confirms permissions without changing any tags.
3. Apply mode writes the expected `Environment` tag and preserves unrelated tags.
4. The post-tag `describe_instances` output includes the expected tag values.
5. Incorrect Region, missing permissions, or invalid IDs produces clear errors and no partial silent success.
6. The status script reports instance/system checks without mutating resources.

## Production Hardening Checklist

- [ ] Configure Region, target filters, tag key/value, and output format outside source code.
- [ ] Use pagination for instance discovery and process all matching reservations/instances.
- [ ] Require explicit opt-in tags and a dry-run review before mutations.
- [ ] Use a separate `--apply` confirmation for real tag changes.
- [ ] Use least-privilege IAM roles and IAM tag conditions where supported.
- [ ] Protect centrally governed tags from unreviewed changes.
- [ ] Add structured logs, API retry/backoff, clear exit codes, and audit records.
- [ ] Replace the 10-second status loop with a configurable schedule or managed monitoring service.
- [ ] Add unit tests with Boto3 Stubber/mocks and dependency pinning/scanning in CI/CD.
- [ ] Prefer Terraform, CloudFormation, or provider tag policies for baseline resource tags created with infrastructure.

## Resources

- [Boto3 EC2 client documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2.html)
- [EC2 `create_tags` API reference](https://docs.aws.amazon.com/AWSEC2/latest/APIReference/API_CreateTags.html)
- [Tagging AWS resources](https://docs.aws.amazon.com/tag-editor/latest/userguide/tagging.html)
- [EC2 status checks](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/monitoring-system-instance-status-check.html)
- [AWS IAM best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)