"""Print the remaining time until a user-defined goal deadline."""

from __future__ import annotations

import argparse
import sys
from datetime import datetime, timedelta


def parse_deadline(value: str) -> datetime:
    """Parse an ISO-8601 date or date-time in the local time zone when unspecified."""
    try:
        deadline = datetime.fromisoformat(value)
    except ValueError as error:
        raise ValueError(
            "Deadline must use ISO-8601 format, for example "
            "2026-12-31 or 2026-12-31T18:00:00."
        ) from error

    if len(value) == 10:
        deadline = deadline.replace(hour=23, minute=59, second=59)

    if deadline.tzinfo is None:
        deadline = deadline.astimezone()

    return deadline


def format_remaining_time(remaining: timedelta) -> str:
    """Return a friendly days, hours, minutes, and seconds representation."""
    total_seconds = int(remaining.total_seconds())
    days, remainder = divmod(total_seconds, 86_400)
    hours, remainder = divmod(remainder, 3_600)
    minutes, seconds = divmod(remainder, 60)
    return f"{days} days, {hours} hours, {minutes} minutes, and {seconds} seconds"


def parse_arguments() -> argparse.Namespace:
    """Parse optional non-interactive countdown inputs."""
    parser = argparse.ArgumentParser(
        description="Print the remaining time until a goal deadline."
    )
    parser.add_argument("--goal", help="Name of the goal")
    parser.add_argument(
        "--deadline",
        help="ISO-8601 date or date-time, for example 2026-12-31T18:00:00",
    )
    return parser.parse_args()


def main() -> int:
    """Collect countdown details and print the time remaining until the deadline."""
    args = parse_arguments()
    goal = args.goal or input("What is your goal? ").strip()
    deadline_input = args.deadline or input(
        "Enter the deadline (YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS): "
    ).strip()

    if not goal:
        print("A goal is required.", file=sys.stderr)
        return 1

    try:
        deadline = parse_deadline(deadline_input)
    except ValueError as error:
        print(error, file=sys.stderr)
        return 1

    remaining = deadline - datetime.now(deadline.tzinfo)
    if remaining.total_seconds() <= 0:
        print(f"The deadline for '{goal}' has already passed.")
        return 0

    print(f"Time remaining for '{goal}': {format_remaining_time(remaining)}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())