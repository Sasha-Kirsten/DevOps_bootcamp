# Demo Project: Automate Displaying EKS Cluster Information

## Overview

This project demonstrates how to use Python and Boto3 to retrieve and display information about Amazon Elastic Kubernetes Service (EKS) clusters. The intended script uses the AWS EKS API to list clusters in a Region, retrieve details for each cluster, and print useful operational information to the console.

Typical cluster details include the cluster name, status, Kubernetes version, endpoint, created time, IAM role, VPC configuration, logging configuration, and enabled access settings.

> **Current repository status:** This directory currently contains documentation only. Add the Python script and dependency metadata described below before treating the project as executable.

## Technologies Used

| Technology | Purpose |
| --- | --- |
| Python | Runs the automation script. |
| Boto3 | AWS SDK for Python used to call the EKS API. |
| AWS EKS | Managed Kubernetes service whose cluster information is retrieved. |

## What the Script Should Do

The completed Python script should:

1. Create a Boto3 EKS client for a configured AWS Region.
2. Call `list_clusters()` to find accessible EKS clusters.
3. Call `describe_cluster(name=...)` for each cluster.
4. Print a readable summary for every cluster.
5. Handle the case where no clusters are available.
6. Report AWS credential, permission, Region, throttling, and API errors clearly.

Example console output:

```text
Cluster name: development-eks
Status: ACTIVE
Kubernetes version: 1.31
Endpoint: https://example.gr7.eu-central-1.eks.amazonaws.com
Created: 2026-10-20T10:15:00+00:00
Endpoint public access: false
```

The EKS API returns control-plane metadata. It does not automatically show Kubernetes workloads, pods, deployments, or in-cluster resources; those require Kubernetes API access through tools such as `kubectl` or the Kubernetes Python client.

## Suggested Project Structure

```text
Automate_display_EKS_Cluster_information/
├── ReadMe.md
├── main.py             # Planned Boto3 EKS information script
├── requirements.txt    # Pinned Python dependencies
└── tests/              # Mocked Boto3 API tests
```

## Prerequisites

Before implementing or running the script, ensure you have:

- Python 3 installed.
- Boto3 installed in an isolated virtual environment.
- AWS credentials supplied through an AWS profile, environment variables, AWS IAM Identity Center, or an IAM role.
- Permission to list and describe EKS clusters in the target AWS Region.
- One or more EKS clusters in that Region, or an expectation that the script returns an empty list.

Install Boto3:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install boto3
```

Do not commit AWS access keys, secret keys, session tokens, kubeconfig files, or real environment files to the repository. Prefer short-lived credentials and IAM roles.

### Minimum IAM Permissions

For a read-only cluster summary, the executing identity needs permissions equivalent to:

```json
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Effect": "Allow",
			"Action": [
				"eks:ListClusters",
				"eks:DescribeCluster"
			],
			"Resource": "*"
		}
	]
}
```

Use a dedicated read-only IAM role and limit access to the intended AWS account and environment. The script should not need permissions to create, update, delete, or access Kubernetes workloads.

## Implementation Steps

### 1. Configure Region and credentials safely

Do not hard-code the AWS Region or credentials in source code. Read the Region from an environment variable or command-line argument, and use the standard AWS credential provider chain.

For example, a completed script can accept an `--region` argument, then create its client with:

```python
eks_client = boto3.client("eks", region_name=region)
```

### 2. List and describe clusters

Use the `list_clusters` paginator so the script works in accounts with more clusters than one API response contains. For every returned name, call `describe_cluster` and select only useful fields for console output.

Avoid printing unnecessary sensitive metadata. In particular, treat cluster endpoint addresses, certificate data, security-group IDs, and subnet IDs according to your organisation's information-sharing policy.

### 3. Handle errors and empty results

Catch expected Boto3 and botocore errors, such as missing credentials, expired sessions, access denied, invalid Region, throttling, and connection failures. Return a clear non-zero exit status when the script cannot complete.

If `list_clusters` returns no results, print an informative message such as `No EKS clusters found in <region>.` This is not necessarily an error.

### 4. Make output useful for automation

Start with readable console output, then add an optional JSON output mode for CI/CD, inventory reports, or monitoring integrations. Include the AWS Region and a timestamp with each report.

## Run and Verify

After adding `main.py`, run the script with the configured AWS identity:

```bash
python3 main.py --region eu-central-1
```

Verify that:

1. The script lists only clusters visible to the configured AWS identity.
2. Each cluster includes its name, status, version, and endpoint-access information.
3. An account with no EKS clusters produces a clear empty-result message.
4. Insufficient permissions produce a clear access-denied error without exposing credentials.
5. An invalid Region or expired credential produces an actionable error message.

## Production Hardening Checklist

- [ ] Configure the AWS Region and output format through CLI arguments or environment variables.
- [ ] Use `list_clusters` pagination and handle all accessible clusters.
- [ ] Use a dedicated least-privilege IAM role with read-only EKS permissions.
- [ ] Add error handling, structured logging, retries/backoff, and clear exit codes.
- [ ] Keep sensitive cluster metadata out of logs and reports unless required.
- [ ] Add unit tests using Boto3 Stubber or mocked EKS responses.
- [ ] Pin and scan Python dependencies in CI/CD.
- [ ] Consider JSON output and scheduled reporting only when there is a clear operational use case.

## Resources

- [Boto3 EKS client documentation](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/eks.html)
- [EKS `list_clusters` API reference](https://docs.aws.amazon.com/eks/latest/APIReference/API_ListClusters.html)
- [EKS `describe_cluster` API reference](https://docs.aws.amazon.com/eks/latest/APIReference/API_DescribeCluster.html)
- [AWS IAM best practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)