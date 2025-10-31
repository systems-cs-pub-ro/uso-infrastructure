import os
import csv
from googleapiclient.discovery import build
from google.oauth2 import service_account

# ========================
# Google API Setup
# ========================
SCOPES = ['https://www.googleapis.com/auth/drive', 'https://www.googleapis.com/auth/spreadsheets']
SERVICE_ACCOUNT_FILE = 'google-service-account.json'
FOLDER_ID = '15cTNJzHrw1l4mxxFj_1QK25GGT9EQoFV'

credentials = service_account.Credentials.from_service_account_file(
    SERVICE_ACCOUNT_FILE, scopes=SCOPES
)

sheets_service = build('sheets', 'v4', credentials=credentials)

# ========================
# Functions
# ========================
def get_sheet_names(spreadsheet_id):
    """Return a list of all sheet names in the spreadsheet."""
    spreadsheet = sheets_service.spreadsheets().get(spreadsheetId=spreadsheet_id).execute()
    return [s['properties']['title'] for s in spreadsheet['sheets']]

def download_sheet_data(spreadsheet_id, sheet_name, max_rows=150):
    """Download all values (including empty ones) from a given sheet."""
    range_str = f"{sheet_name}!A1:Q{max_rows}"
    result = sheets_service.spreadsheets().values().get(
        spreadsheetId=spreadsheet_id,
        range=range_str,
        valueRenderOption="UNFORMATTED_VALUE",
        dateTimeRenderOption="FORMATTED_STRING"
    ).execute()
    values = result.get('values', [])

    for i, row in enumerate(values):
        if len(row) < 17:
            values[i] = row + [""] * (17 - len(row))
    return values

def process(spreadsheet_id, output_csv):
    """Download all sheets and concatenate them into one CSV."""
    sheet_names = get_sheet_names(spreadsheet_id)
    print(f"Found sheets: {', '.join(sheet_names)}")

    all_rows = []
    header_written = False
    email_idx = 1
    for sheet_name in sheet_names:
        if sheet_name == "AC":
            continue
        print(f"Downloading sheet: {sheet_name}")
        rows = download_sheet_data(spreadsheet_id, sheet_name)

        header = rows[0]
        data_rows = rows[1:] if len(rows) > 1 else []

        if not header_written:
            all_rows.append(header)
            header_written = True

        for row in data_rows:
            if len(row) <= email_idx or not row[email_idx].strip():
                continue
            all_rows.append(row)

    with open(output_csv, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerows(all_rows)

    print(f"\n All sheets combined into {output_csv}")

# ========================
# Main
# ========================
if __name__ == "__main__":
    SPREADSHEET_ID = "1WXduOieXmje_rrPF7_UraE7_U1APiDbn8oI4xDeAT2o"
    OUTPUT_DIR = "./output"
    OUTPUT_CSV = "catalog.csv"

    process(SPREADSHEET_ID, OUTPUT_CSV)
