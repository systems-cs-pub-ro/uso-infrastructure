from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from google.oauth2 import service_account
import os

# Define the credentials file and scope
SCOPES = ['https://www.googleapis.com/auth/drive', 'https://www.googleapis.com/auth/spreadsheets']
SERVICE_ACCOUNT_FILE = 'google-service-account.json'

# Authenticate and create the Drive API client
credentials = service_account.Credentials.from_service_account_file(SERVICE_ACCOUNT_FILE, scopes=SCOPES)
sheets_service = build('sheets', 'v4', credentials=credentials)
drive_service = build('drive', 'v3', credentials=credentials)

def get_sheet_id(spreadsheet_id):
    """Retrieve the sheet ID of the first sheet in the spreadsheet."""
    spreadsheet = sheets_service.spreadsheets().get(spreadsheetId=spreadsheet_id).execute()
    sheet_id = spreadsheet['sheets'][0]['properties']['sheetId']  # Get the first sheet ID
    print(f"Sheet ID for spreadsheet {spreadsheet_id}: {sheet_id}")
    return sheet_id

def format_sheet(spreadsheet_id):
    """Apply formatting to the spreadsheet."""

    sheet_id = get_sheet_id(spreadsheet_id)

    requests = [
        # Freeze the first 3 rows
        {
            "updateSheetProperties": {
                "properties": {
                    "sheetId": sheet_id,  # Default sheet ID, adjust if necessary
                    "gridProperties": {
                        "frozenRowCount": 3
                    }
                },
                "fields": "gridProperties.frozenRowCount"
            }
        },
        # Bold the first 3 rows
        {
            "repeatCell": {
                "range": {
                    "sheetId": sheet_id,
                    "startRowIndex": 0,
                    "endRowIndex": 3
                },
                "cell": {
                    "userEnteredFormat": {
                        "textFormat": {
                            "bold": True
                        }
                    }
                },
                "fields": "userEnteredFormat.textFormat.bold"
            }
        },
        # Make Column E light green
        {
            "repeatCell": {
                "range": {
                    "sheetId": sheet_id,
                    "startColumnIndex": 4,
                    "endColumnIndex": 5
                },
                "cell": {
                    "userEnteredFormat": {
                        "backgroundColor": {
                            "red": 0.88,
                            "green": 0.96,
                            "blue": 0.88
                        }
                    }
                },
                "fields": "userEnteredFormat.backgroundColor"
            }
        },
        # Make Columns F-Q light blue
        {
            "repeatCell": {
                "range": {
                    "sheetId": sheet_id ,
                    "startColumnIndex": 5,
                    "endColumnIndex": 17
                },
                "cell": {
                    "userEnteredFormat": {
                        "backgroundColor": {
                            "red": 0.88,
                            "green": 0.92,
                            "blue": 0.96
                        }
                    }
                },
                "fields": "userEnteredFormat.backgroundColor"
            }
        }
    ]

    # Execute the batchUpdate request
    body = {"requests": requests}
    sheets_service.spreadsheets().batchUpdate(
        spreadsheetId=spreadsheet_id, body=body).execute()

    # Apply formula to all cells in Column E (starting from row 3)
    starting_cell = "E3"  # Adjust range as needed for your data size
    formulas = [
        [f"=MIN(SUM(F{row}:Q{row}),120)/12"] for row in range(3, 100)
    ]

    formula_body = {
        "range": starting_cell,
        "majorDimension": "ROWS",
        "values": formulas
    }

    sheets_service.spreadsheets().values().update(
        spreadsheetId=spreadsheet_id,
        range=starting_cell,
        valueInputOption="USER_ENTERED",
        body=formula_body
    ).execute()

    print(f"Formatting and formulas applied to spreadsheet: {spreadsheet_id}")

def upload_csv_as_sheet(file_path, folder_id):
    """Upload a CSV file to a specific folder in Google Drive and convert it to Google Sheets."""
    file_name = os.path.basename(file_path).replace('.csv', '')

    # Metadata for the file
    file_metadata = {
        'name': file_name,
        'mimeType': 'application/vnd.google-apps.spreadsheet',  # Convert to Google Sheets format
        'parents': [folder_id]  # Specify the target folder
    }

    # Media upload for the CSV
    media = MediaFileUpload(file_path, mimetype='text/csv', resumable=True)

    # Upload the file
    file = drive_service.files().create(
        body=file_metadata,
        media_body=media,
        fields='id'
    ).execute()

    file_id = file.get('id')
    print(f"Uploaded {file_path} as Google Sheets to folder {folder_id}. File ID: {file_id}")

    return file_id

# Define the directory containing your CSV files
csv_directory = './output'  # Replace with your output directory path

# TODO Replace this with the ID of your shared folder
shared_folder_id = '1X3bwHUTWSWSUee-2cB_wP7eNQDDkd0-y'

# Process each CSV file in the directory
for csv_file in os.listdir(csv_directory):
    if csv_file.endswith('.csv'):
        # Upload the file and get its spreadsheet ID
        spreadsheet_id = upload_csv_as_sheet(os.path.join(csv_directory, csv_file), shared_folder_id)

        # Apply formatting to the uploaded spreadsheet
        format_sheet(spreadsheet_id)
