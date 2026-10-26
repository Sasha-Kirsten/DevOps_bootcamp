# Demo Project: Data Backup & Restore

## Overview

This project demonstrates the first building block of automated Amazon EBS data protection with Python and Boto3. The current script discovers EBS volumes in an AWS Region and creates an EBS snapshot for each volume on a schedule.

The intended complete workflow is:

1. Identify the EBS volumes that belong to the application or environment.
2. Create tagged, encrypted EBS snapshots on a defined backup schedule.
3. Remove snapshots that exceed an agreed retention policy.
4. Restore data by creating a new EBS volume from a selected snapshot and attaching it safely to an EC2 instance.
5. Test the restoration process regularly against a non-production workload.

> **Current repository status:** `main.py` implements snapshot creation only. It uses `us-east-1`, calls `describe_volumes()` without filters, creates a snapshot for every returned volume, and schedules this action every 10 seconds. Snapshot cleanup, tagging, filtering, snapshot-completion checks, error handling, restoration, and Terraform infrastructure are not implemented yet.

## Technologies Used

| Technology | Purpose |
| --- | --- |
| Python | Runs the backup automation. |
| Boto3 | AWS SDK for Python used to call EC2 and EBS APIs. |
| AWS EC2 / EBS | Provides volumes and the snapshots used for backup and restore. |
| `schedule` | Runs the current snapshot function on a fixed local interval. |

## What `main.py` Currently Does

The script:

1. Creates a Boto3 EC2 client for the hard-coded `us-east-1` Region.
2. Defines `create_snapshot()`.
3. Calls `describe_volumes()` with no filter, returning every EBS volume the AWS identity can see in that Region.
4. Calls `create_snapshot()` once for each returned volume.
5. Prints the created snapshot ID and the full API response.
6. Schedules `create_snapshot()` to run every 10 seconds.
7. Runs `schedule.run_pending()` inside an infinite loop.

Example intended output:

```text
Created snapshot snap-0123456789abcdef0 for volume vol-0123456789abcdef0
```

Creating a snapshot only starts an asynchronous AWS operation. A successful `create_snapshot()` response does **not** mean the snapshot is complete and ready to restore. A production workflow must wait for and verify the `completed` state before reporting backup success.

## Project Structure

```text
Data_Backup_Restore/
├── main.py       # Current EBS snapshot creation proof of concept
└── ReadMe.md     # Project instructions and next steps
```

A completed implementation can add a package structure, tests, and configuration:

```text
Data_Backup_Restore/
├── main.py
├── requirements.txt
├── .env.example
├── tests/
│   ├── test_backup.py
│   ├── test_retention.py
│   └── test_restore.py
└── ReadMe.md
```

## Prerequisites

Before running the current script, ensure you have:

- Python 3 installed.
- The `boto3` and `schedule` packages installed in an isolated virtual environment.
- AWS credentials provided through an AWS profile, environment variables, or an IAM role.
- EC2/EBS permissions in `us-east-1`, or an updated Region configuration matching your volumes.
- A dedicated development account or explicitly tagged test volumes. Do **not** run the current script against a shared or production account.

Install the dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install boto3 schedule
```

Use IAM roles or short-lived credentials whenever possible. Never commit AWS access keys, secret keys, real `.env` files, or backup metadata containing sensitive details.

### Minimum IAM permissions

The current script needs permissions equivalent to:

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"ec2:DescribeVolumes",
				"ec2:CreateSnapshot"
			],
			"Resource": "*"
		}
	]
}
```

Retention and restore features will require additional actions, such as `ec2:DescribeSnapshots`, `ec2:DeleteSnapshot`, `ec2:CreateVolume`, `ec2:AttachVolume`, and potentially `ec2:DescribeInstances`. Review AWS IAM documentation and restrict access by account, environment, tags, and role where supported.

## Run the Current Script Safely

The script has no volume filtering and schedules a new snapshot of every visible EBS volume every 10 seconds. Snapshot storage has a cost, so use only deliberately tagged disposable volumes in a sandbox account.

Run the proof of concept:

```bash
python3 main.py
```

Stop it with `Ctrl+C` after observing one controlled run. Do not leave it running: it will continue to initiate snapshots every 10 seconds and never deletes them.

## Current Limitations and Next Steps

### 1. Filter target volumes before taking backups

The current `describe_volumes()` request has no filters, so it can select every discoverable volume in `us-east-1`. Add explicit filters such as a project, environment, and backup-opt-in tag.

For example, only volumes tagged conceptually as `Backup = true`, `Environment = development`, and `Project = backup-demo` should be considered. Validate tags and log selected volume IDs before creating a snapshot.

### 2. Replace the 10-second learning schedule

`schedule.every(10).seconds` is appropriate only for a short demonstration. It is unsafe and expensive for real snapshots.

Make the schedule configurable and choose a retention-aware cadence based on recovery objectives:

- **RPO (Recovery Point Objective):** the maximum acceptable data loss measured in time.
- **RTO (Recovery Time Objective):** the maximum acceptable restoration time.

For production, use AWS Backup, Amazon Data Lifecycle Manager, EventBridge Scheduler/Lambda, or a supervised scheduled service instead of a local infinite loop on a workstation.

### 3. Avoid the busy loop

The `while True` loop calls `schedule.run_pending()` continuously without sleeping, consuming CPU while it waits for the next job. Add a bounded sleep interval and graceful shutdown handling in the next implementation.

### 4. Tag and verify snapshots

Give every created snapshot tags such as `Project`, `Environment`, `ManagedBy`, `SourceVolumeId`, `CreatedAt`, and a retention classification. Use `create_tags()` or snapshot tag specifications.

Wait for each snapshot to complete with an AWS waiter or controlled polling. Record the final snapshot ID, source volume, start/completion timestamps, encryption status, and outcome in structured logs.

### 5. Implement snapshot cleanup

Add a retention function that:

1. Lists only snapshots owned by the account and created by this project.
2. Filters by explicit management/project tags.
3. Sorts by start time and preserves the configured number or age of snapshots.
4. Protects snapshots required for legal hold, incident response, or restore testing.
5. Deletes only snapshots that exceed the policy, using a dry-run/report mode first.

Never delete snapshots based only on a description string. Apply a tag-based ownership policy and log every deletion for auditability.

### 6. Implement restoration safely

EBS restore is not an in-place overwrite operation. A restore workflow should:

1. Select and validate the expected completed snapshot.
2. Create a **new** volume from that snapshot in the same Availability Zone as the target EC2 instance.
3. Wait for the new volume to become `available`.
4. Attach it to a non-production test instance or a planned recovery target using the correct device name.
5. Mount the filesystem, validate the recovered data, and document the outcome.
6. Only then perform an approved production cutover following a tested runbook.

Do not detach or replace a production root/data volume automatically from a simple script. A wrong volume, Availability Zone, or device mapping can cause an outage or data loss.

### 7. Add errors, pagination, and observability

Use paginators for volume and snapshot listings. Handle missing credentials, authorization failures, invalid Region/configuration, throttling, unavailable services, and partial failures. Apply exponential backoff for retryable AWS errors.

Replace raw `print(snapshot)` output with structured logging that avoids sensitive data and includes timestamps, Region, source volume ID, snapshot ID, action, and result. Emit metrics/alerts for failed backups, overdue snapshots, and cleanup failures.

## Verification

Validate the completed workflow in a dedicated development environment:

1. Only the explicitly tagged test volumes are selected.
2. Each created snapshot has the expected tags and reaches `completed` status.
3. The retention job preserves required snapshots and deletes only tagged snapshots beyond policy.
4. A restore creates a new volume in the target instance's Availability Zone.
5. The restored volume can be attached, mounted, and checked for expected test data.
6. IAM denial, AWS API throttling, and an incomplete snapshot produce clear errors without causing unsafe deletion or restore actions.
7. Backup failures and missed schedules generate an actionable alert.

Regularly test restores. A snapshot that has never been restored is only an assumption of recoverability.

## Production Hardening Checklist

- [ ] Configure Region, tag filters, schedule, retention policy, and restore target outside source code.
- [ ] Snapshot only volumes explicitly opted in through mandatory tags.
- [ ] Use encrypted EBS volumes/snapshots and approved KMS keys; verify cross-account restore requirements separately.
- [ ] Tag snapshots for ownership, source, lifecycle, environment, and auditability.
- [ ] Wait for `completed` snapshots before marking a backup successful.
- [ ] Use pagination, structured logs, retries/backoff, and clear failure exit codes.
- [ ] Implement retention with report/dry-run mode and tag-based deletion safeguards.
- [ ] Test restore procedures routinely in a separate account or isolated environment.
- [ ] Use least-privilege IAM roles and short-lived credentials.
- [ ] Prefer AWS Backup or Data Lifecycle Manager for operational EBS backup policies.
- [ ] Add unit tests using Boto3 Stubber/mocks and pin/scan dependencies in CI/CD.

## Resources

- [Boto3 EC2 client documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/ec2.html)
- [Amazon EBS snapshots](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-creating-snapshot.html)
- [Restore an EBS volume from a snapshot](https://docs.aws.amazon.com/ebs/latest/userguide/ebs-restoring-volume.html)
- [Amazon Data Lifecycle Manager](https://docs.aws.amazon.com/ebs/latest/userguide/snapshot-lifecycle.html)
- [AWS Backup documentation](https://docs.aws.amazon.com/aws-backup/latest/devguide/whatisbackup.html)
- [AWS IAM best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)