# Demo Project: API Request to GitLab

## Overview

This project is a small Python command-line application that talks to the GitLab REST API and lists all **public repositories** owned by a specified GitLab user. It demonstrates a safe, read-only external API integration using HTTP requests, JSON responses, pagination, timeouts, and error handling.

The application does not require a GitLab personal access token because it requests only public project information. It supports both GitLab.com and a self-managed GitLab instance.

## Technologies Used

| Technology | Purpose |
| --- | --- |
| Python | Implements the command-line client. |
| Requests | Sends HTTP requests to the GitLab REST API. |
| GitLab | External platform that provides the public project API. |
| Git | Tracks this project and its source code. |
| IntelliJ IDEA | Optional IDE for editing the project; the code also works in any Python-capable editor. |

## What `main.py` Does

`main.py`:

1. Accepts a required GitLab username as a command-line argument.
2. Uses `https://gitlab.com` by default, or accepts `--gitlab-url` for a self-managed GitLab instance.
3. Calls GitLab's user-project endpoint:

	 ```text
	 GET /api/v4/users/<username>/projects
	 ```

4. Requests only projects with `visibility=public`.
5. Requests up to 100 projects per page and follows GitLab's `x-next-page` header until all pages are retrieved.
6. Prints each project name, web URL, and description when available.
7. Returns a non-zero exit code for missing users, HTTP failures, timeouts, connection problems, or unexpected API responses.

Example output:

```text
Public GitLab projects for 'example-user' (2):
- sample-api
	https://gitlab.com/example-user/sample-api
	Example API project
- infrastructure
	https://gitlab.com/example-user/infrastructure
```

## Project Structure

```text
API_Request_Gitlab/
├── main.py           # GitLab public-project client
├── requirements.txt  # Python dependency constraints
└── ReadMe.md         # Project documentation
```

## Prerequisites

Before running the application, ensure you have:

- Python 3.9 or later installed.
- Network access to GitLab.com or the chosen self-managed GitLab instance.
- A GitLab username with public projects, or a username expected to have no public projects.

Create a virtual environment and install dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Run the Application

List public projects on GitLab.com:

```bash
python3 main.py <gitlab-username>
```

List public projects on a self-managed GitLab instance:

```bash
python3 main.py <gitlab-username> --gitlab-url https://gitlab.example.com
```

Replace the placeholders with a real username and GitLab base URL. Do not add a trailing API path: the script constructs `/api/v4/users/<username>/projects` itself.

## Verification

Verify the application with these cases:

1. A GitLab user with public projects prints their project names and URLs.
2. A user with no public projects prints `No public GitLab projects found...` and exits successfully.
3. A nonexistent username prints a clear error and exits with status `1`.
4. An unreachable GitLab host or invalid URL prints a request error rather than a Python traceback.
5. A user with more than one page of projects is fully listed, not limited to the first API page.

## Security and Operations Notes

- The current application uses unauthenticated, public GitLab API requests only. Do not add a personal access token unless the project must access private data.
- If authentication is later required, store tokens in environment variables or a secret manager—never in source code, command history, or the repository.
- The request timeout is 10 seconds. Keep timeouts to prevent a stalled network call from blocking automation indefinitely.
- GitLab applies API rate limits. Use the tool responsibly, avoid tight polling loops, and add retry/backoff only for retryable failures if the script evolves into scheduled automation.
- Treat project descriptions and URLs as untrusted external data when passing output to another system.

## Production Hardening Checklist

- [ ] Pin dependencies more strictly with a lock file or a fully resolved requirements file.
- [ ] Add unit tests using mocked HTTP responses for pagination, empty results, 404 errors, and malformed JSON.
- [ ] Add structured JSON output for CI/CD or downstream automation.
- [ ] Add logging with timestamps and avoid logging authentication tokens.
- [ ] Add bounded retries with exponential backoff for transient failures and rate limits.
- [ ] Validate the configured GitLab URL against an approved allowlist when used in an enterprise environment.
- [ ] Use a least-privilege, short-lived token only when private GitLab resources are required.

## Resources

- [GitLab Projects API](https://docs.gitlab.com/api/projects/)
- [GitLab Users API](https://docs.gitlab.com/api/users/)
- [Requests documentation](https://requests.readthedocs.io/)