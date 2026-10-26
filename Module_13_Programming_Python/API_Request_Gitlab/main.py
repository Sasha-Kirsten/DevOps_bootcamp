"""List public GitLab projects for a specified GitLab user."""

from __future__ import annotations

import argparse
import sys
from typing import Any
from urllib.parse import quote

import requests

DEFAULT_GITLAB_URL = "https://gitlab.com"
REQUEST_TIMEOUT_SECONDS = 10
PROJECTS_PER_PAGE = 100


def list_public_projects(gitlab_url: str, username: str) -> list[dict[str, Any]]:
	"""Return every public project owned by ``username`` from a GitLab instance."""
	base_url = gitlab_url.rstrip("/")
	encoded_username = quote(username, safe="")
	api_url = f"{base_url}/api/v4/users/{encoded_username}/projects"
	projects: list[dict[str, Any]] = []
	page = 1

	with requests.Session() as session:
		while True:
			response = session.get(
				api_url,
				params={
					"visibility": "public",
					"order_by": "last_activity_at",
					"sort": "desc",
					"per_page": PROJECTS_PER_PAGE,
					"page": page,
				},
				timeout=REQUEST_TIMEOUT_SECONDS,
			)
			response.raise_for_status()

			page_projects = response.json()
			if not isinstance(page_projects, list):
				raise ValueError("GitLab returned an unexpected project-list response.")

			projects.extend(page_projects)
			next_page = response.headers.get("x-next-page")
			if not next_page:
				break
			page = int(next_page)

	return projects


def print_projects(username: str, projects: list[dict[str, Any]]) -> None:
	"""Print a concise, human-readable public-project summary."""
	if not projects:
		print(f"No public GitLab projects found for user '{username}'.")
		return

	print(f"Public GitLab projects for '{username}' ({len(projects)}):")
	for project in projects:
		print(f"- {project['name']}\n  {project['web_url']}")
		if description := project.get("description"):
			print(f"  {description}")


def parse_arguments() -> argparse.Namespace:
	"""Parse the username and optional self-managed GitLab base URL."""
	parser = argparse.ArgumentParser(
		description="List all public GitLab projects owned by a specified user."
	)
	parser.add_argument("username", help="GitLab username whose public projects are listed")
	parser.add_argument(
		"--gitlab-url",
		default=DEFAULT_GITLAB_URL,
		help=f"GitLab base URL (default: {DEFAULT_GITLAB_URL})",
	)
	return parser.parse_args()


def main() -> int:
	"""Run the public GitLab project lookup and return a process exit code."""
	args = parse_arguments()
	try:
		projects = list_public_projects(args.gitlab_url, args.username)
	except requests.HTTPError as error:
		if error.response is not None and error.response.status_code == 404:
			print(f"GitLab user '{args.username}' was not found.", file=sys.stderr)
		else:
			print(f"GitLab API request failed: {error}", file=sys.stderr)
		return 1
	except (requests.RequestException, ValueError) as error:
		print(f"Unable to retrieve GitLab projects: {error}", file=sys.stderr)
		return 1

	print_projects(args.username, projects)
	return 0


if __name__ == "__main__":
	raise SystemExit(main())



