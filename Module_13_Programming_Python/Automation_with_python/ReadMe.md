# Demo Project: Automation with Python

## Overview

This project demonstrates spreadsheet automation with Python. The intended application reads an Excel inventory workbook, processes its rows, calculates the total inventory quantity for each supplier, and saves a workbook after processing.

This is a practical example of using Python to replace repetitive spreadsheet work with a repeatable script. Instead of manually filtering rows and adding stock values for each supplier, the script reads the worksheet data and builds a supplier-to-inventory-total mapping.

> **Current repository status:** `main.py` contains the aggregation logic, but it is a starter file and is not runnable yet. The import should be `openpyxl`, and the input workbook path and worksheet name are empty placeholders. The script also calculates `product_per_supplier` but does not currently write that summary back into the workbook. Complete the corrections in [Required corrections before running](#required-corrections-before-running) first.

## Technologies Used

| Technology | Purpose |
| --- | --- |
| Python | Reads, processes, and writes spreadsheet data. |
| openpyxl | Python library intended for working with `.xlsx` Excel workbooks. |
| Git | Tracks the project source code and documentation. |
| IntelliJ IDEA | Optional IDE for editing the project; any Python-capable editor can be used. |

## What `main.py` Is Designed to Do

The script is designed to:

1. Load an Excel workbook with `openpyxl.load_workbook()`.
2. Select an inventory worksheet.
3. Start at row `2`, treating row `1` as a header row.
4. Read each row's inventory quantity from **column B** (`2`).
5. Read each row's supplier name from **column D** (`4`).
6. Build the `product_per_supplier` dictionary, where each key is a supplier and each value is the sum of that supplier's inventory quantities.
7. Save the workbook as `updated_inv.xlsx`.
8. Close the workbook.

The core aggregation behaves conceptually like this:

```text
Supplier A: 4 + 6 = 10
Supplier B: 3 = 3
```

The script currently prints the worksheet's maximum row count. This helps confirm that rows were discovered, but it does not yet print or save the calculated supplier totals.

## Expected Spreadsheet Layout

The aggregation logic assumes an inventory worksheet with a header row and these columns:

| Column | Position | Expected value | Used by the script |
| --- | --- | --- | --- |
| A | 1 | Any product data, such as product name or ID | No |
| B | 2 | Inventory quantity as a number | Yes |
| C | 3 | Any additional product data | No |
| D | 4 | Supplier name | Yes |

Example source data:

| Product | Inventory | Category | Supplier |
| --- | ---: | --- | --- |
| Keyboard | 4 | Hardware | Supplier A |
| Mouse | 6 | Hardware | Supplier A |
| Monitor | 3 | Hardware | Supplier B |

Expected calculated result:

| Supplier | Total inventory |
| --- | ---: |
| Supplier A | 10 |
| Supplier B | 3 |

## Project Structure

```text
Automation_with_python/
├── main.py       # Spreadsheet processing and supplier aggregation script
└── ReadMe.md     # Project documentation
```

A completed version can add a sample workbook, dependency metadata, and tests:

```text
Automation_with_python/
├── main.py
├── requirements.txt
├── input_inventory.xlsx
├── tests/
│   └── test_inventory_processing.py
└── ReadMe.md
```

## Prerequisites

Before running the completed script, ensure you have:

- Python 3 installed.
- An `.xlsx` input workbook with the expected worksheet and columns.
- The `openpyxl` package installed in an isolated virtual environment.
- Write permission in the output directory.

Set up the environment:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install openpyxl
```

Do not use `openpyxl` for legacy `.xls` files. Convert those files to `.xlsx`, or use a library designed for the legacy Excel format.

## Required Corrections Before Running

Complete the following changes in `main.py` before executing it:

1. **Fix the import.** Change `import openxyl` to `import openpyxl`.
2. **Set the input path.** Replace the empty string in `load_workbook("")` with the path to the input `.xlsx` file.
3. **Set the worksheet name.** Replace `inv_file[""]` with the expected worksheet title, such as `inv_file["Inventory"]`.
4. **Validate the input columns.** Confirm that inventory quantities are in column B and supplier names are in column D, or update the column numbers to match the workbook.
5. **Handle missing/invalid data.** Skip or report blank suppliers, blank inventory values, and non-numeric quantities before adding values together.
6. **Write the result.** Add a summary worksheet or output table so `product_per_supplier` is visible in `updated_inv.xlsx`.
7. **Protect the source workbook.** Save to a new path, as the script currently intends, rather than overwriting the input file.

## Run the Script

After completing the required configuration, run:

```bash
python3 main.py
```

The current output name is `updated_inv.xlsx`. Verify the input workbook is not accidentally named the same as the output workbook before running the script.

## Verification

Use a small test workbook before processing real inventory data.

Verify that:

1. The script loads the expected workbook and worksheet.
2. The printed maximum row count matches the input data.
3. Quantities for repeated suppliers are summed correctly.
4. Every supplier appears once in the generated summary.
5. The output workbook is created at the expected location.
6. The original workbook remains unchanged.
7. Blank or invalid quantity cells produce a clear validation error or are handled according to a documented rule.

Open `updated_inv.xlsx` in Excel, LibreOffice Calc, or another spreadsheet application and compare the generated totals with a manually calculated test case.

## Production Hardening Checklist

- [ ] Accept the input path, output path, and worksheet name through command-line arguments instead of hard-coding them.
- [ ] Validate that required columns, headers, and data types are present before processing.
- [ ] Define explicit rules for empty rows, missing suppliers, negative quantities, decimals, and duplicate entries.
- [ ] Write the supplier summary to a dedicated worksheet with headers and formatting.
- [ ] Add structured logging and clear non-zero exit codes for file, worksheet, and validation errors.
- [ ] Make output paths configurable and avoid overwriting source workbooks.
- [ ] Add unit tests with temporary sample workbooks, including invalid data cases.
- [ ] Pin `openpyxl` in `requirements.txt` and scan dependencies in CI/CD.
- [ ] Avoid placing sensitive inventory, supplier, or pricing workbooks in Git; commit only anonymised sample data when needed.

## Resources

- [openpyxl documentation](https://openpyxl.readthedocs.io/)
- [openpyxl tutorial](https://openpyxl.readthedocs.io/en/stable/tutorial.html)
- [Python virtual environments](https://docs.python.org/3/library/venv.html)