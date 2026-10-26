# Demo Project: Write Countdown Application

## Overview

This project is a small Python countdown application. It accepts a user-defined goal and deadline, calculates the difference between the current time and that deadline, and prints the remaining days, hours, minutes, and seconds.

The application can be used interactively through terminal prompts or non-interactively with command-line arguments. It uses only the Python standard library, so no external package installation is required.

## Technologies Used

| Technology | Purpose |
| --- | --- |
| Python | Collects input, validates the deadline, and calculates remaining time. |
| Git | Tracks the source code and documentation. |
| IntelliJ IDEA | Optional IDE for editing the project; any Python-capable editor can be used. |

## What `main.py` Does

`main.py`:

1. Accepts a goal and deadline through interactive prompts, or through `--goal` and `--deadline` arguments.
2. Validates that the goal is not empty.
3. Parses the deadline as an ISO-8601 date or date-time.
4. Treats a date-only deadline such as `2026-12-31` as `23:59:59` in the local time zone.
5. Uses the current local time to calculate the remaining duration.
6. Prints the remaining days, hours, minutes, and seconds.
7. Clearly reports invalid date input or a deadline that has already passed.

Example output:

```text
Time remaining for 'Complete DevOps bootcamp': 72 days, 5 hours, 14 minutes, and 9 seconds.
```

## Project Structure

```text
Write_Countdown_Application/
├── main.py       # Countdown application
└── ReadMe.md     # Project documentation
```

## Prerequisites

Before running the application, ensure you have Python 3 installed:

```bash
python3 --version
```

No third-party dependencies are required.

## Run the Application

### Interactive mode

Run the script and answer the prompts:

```bash
python3 main.py
```

Example input:

```text
What is your goal? Complete DevOps bootcamp
Enter the deadline (YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS): 2026-12-31T18:00:00
```

### Command-line mode

Provide both values without prompts:

```bash
python3 main.py --goal "Complete DevOps bootcamp" --deadline 2026-12-31T18:00:00
```

Use `--help` to display supported options:

```bash
python3 main.py --help
```

## Supported Deadline Formats

The deadline must use an ISO-8601 format:

| Format | Example | Interpretation |
| --- | --- | --- |
| Date | `2026-12-31` | End of that date (`23:59:59`) in the local time zone. |
| Date and time | `2026-12-31T18:00:00` | Local date and time. |
| Date, time, and offset | `2026-12-31T18:00:00+01:00` | Time with an explicit UTC offset. |

For shared teams and CI/CD automation, prefer a deadline with an explicit offset or UTC to avoid ambiguity caused by local time zones and daylight-saving changes.

## Verification

Verify these cases:

1. A future date prints a positive remaining duration.
2. A future date-time prints the expected days, hours, minutes, and seconds.
3. An empty goal returns a clear validation error.
4. An invalid deadline such as `31-12-2026` returns a clear format error.
5. A past deadline reports that the deadline has already passed.
6. `python3 main.py --help` lists the goal and deadline arguments.

## Production Hardening and Next Steps

This project is intentionally a small command-line exercise. If it evolves into a production reminder service, consider:

- [ ] Use timezone-aware deadlines with a required IANA timezone or UTC input.
- [ ] Store goals and deadlines in a database or a durable file instead of accepting one-off input.
- [ ] Add scheduled notifications through email, chat, or a task-management API.
- [ ] Add unit tests for deadline parsing, daylight-saving boundaries, and duration formatting.
- [ ] Add structured logging and clear exit codes for scheduled automation.
- [ ] Validate user input limits and avoid passing untrusted values to shell commands.

## Resources

- [Python `datetime` documentation](https://docs.python.org/3/library/datetime.html)
- [Python `argparse` documentation](https://docs.python.org/3/library/argparse.html)