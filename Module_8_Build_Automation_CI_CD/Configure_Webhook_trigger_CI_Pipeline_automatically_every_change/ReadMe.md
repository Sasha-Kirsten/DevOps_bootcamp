
# Configure Webhook Trigger CI Pipeline Automatically Every Change

## Overview
This guide walks through setting up a webhook trigger to automatically initiate your CI pipeline whenever code changes are pushed to your repository.

## Prerequisites
- Git repository (GitHub, GitLab, Bitbucket, etc.)
- CI/CD platform (Jenkins, GitHub Actions, GitLab CI, etc.)
- Repository admin access
- Webhook configuration capability

## Steps

### 1. Generate Webhook URL
Obtain the webhook URL from your CI/CD platform:
- **GitHub Actions**: Automatic (no manual setup needed)
- **Jenkins**: `http://your-jenkins-server/github-webhook/`
- **GitLab CI**: `http://your-gitlab-server/api/v4/projects/PROJECT_ID/push_events`

### 2. Configure Repository Webhook
Navigate to repository settings and add a new webhook:
- **Payload URL**: Your CI/CD webhook endpoint
- **Content type**: `application/json`
- **Events**: Select `Push events` or `All events`
- **Active**: Enable the webhook

### 3. Verify Configuration
Test the webhook by pushing a commit and monitoring:
```bash
git push origin main
```
Check CI/CD platform logs for pipeline execution.

## Troubleshooting
- Verify webhook URL accessibility
- Check firewall/network rules
- Review CI/CD platform logs for errors
- Ensure repository permissions are correct

## Resources
- [GitHub Webhooks Documentation](https://docs.github.com/en/developers/webhooks-and-events/webhooks)
- [Jenkins GitHub Integration](https://plugins.jenkins.io/github/)
- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
