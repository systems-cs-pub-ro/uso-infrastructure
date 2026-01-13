# Google Sheets Downloader

This script downloads data from all sheets from the Catalogue Google Spreadsheet, filters rows with a valid email address, and merges them into a single CSV file.

## Setup

Create and activate a virtual environment:

```bash
source .venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Place your Google Service Account key file in the project root:

```bash
google-service-account.json
```

Share the Google Spreadsheet with the service account email.

## Configuration

Edit the following variables in the script if needed:

```python
SERVICE_ACCOUNT_FILE = 'google-service-account.json'
FOLDER_ID = '<your-folder-id'
SPREADSHEET_ID = '<your-spreadsheet-id>'
```

The script will output `catalog.csv` in the current directory.

## Usage

Run the script:

```bash
source .venv/bin/activate
python3 download_spreadsheet.py
```

Preview the output:

```bash
cat catalog.csv | head
```

## Notes

The first row of the first sheet is used as the CSV header

- Rows without an email address (column B) are ignored
- Empty cells are preserved
- Maximum rows per sheet: 150
