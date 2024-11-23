from googleapiclient.discovery import build
from google.oauth2 import service_account
import os
import csv

# Path to your service account key file
SERVICE_ACCOUNT_FILE = 'google-service-account.json'

# Scopes for accessing Google Drive and Sheets
SCOPES = ['https://www.googleapis.com/auth/drive', 'https://www.googleapis.com/auth/spreadsheets.readonly']

# Authenticate with the service account
credentials = service_account.Credentials.from_service_account_file(SERVICE_ACCOUNT_FILE, scopes=SCOPES)
drive_service = build('drive', 'v3', credentials=credentials)
sheets_service = build('sheets', 'v4', credentials=credentials)

# Directory to save downloaded CSV files
output_dir = './output_moodle'
os.makedirs(output_dir, exist_ok=True)

# Consolidated file path
consolidated_file = os.path.join(output_dir, 'consolidated_catalog.csv')

def get_files_from_folder(folder_id):
    """Retrieve spreadsheet files from the specified folder that match the naming pattern."""
    results = drive_service.files().list(
        q=f"'{folder_id}' in parents and mimeType='application/vnd.google-apps.spreadsheet' and name contains 'USO - 2024 - 2025 - Catalog -'",
        fields='files(id, name)'
    ).execute()
    return results.get('files', [])

def download_and_filter_spreadsheet(file_id, file_name, writer, is_header_written):
    """Download the spreadsheet as CSV, filter specific columns, and append to the consolidated file."""
    # Export spreadsheet as CSV
    request = drive_service.files().export_media(fileId=file_id, mimeType='text/csv')
    file_path = os.path.join(output_dir, f"{file_name}.csv")

    with open(file_path, 'wb') as f:
        f.write(request.execute())
    print(f"Downloaded {file_name} as CSV.")

    # Filter columns: Email, Laborator 01 through Laborator 12
    with open(file_path, 'r') as infile:
        reader = csv.DictReader(infile)
        fieldnames = ['Email', 'Laborator 01', 'Laborator 02', 'Laborator 03',
                      'Laborator 04', 'Laborator 05', 'Laborator 06',
                      'Laborator 07', 'Laborator 08', 'Laborator 09',
                      'Laborator 10', 'Laborator 11', 'Laborator 12']

        # Write header only once
        if not is_header_written:
            writer.writeheader()
            is_header_written = True

        # Append filtered rows to the consolidated file, ignoring empty lines and rows without email
        for row in reader:
            if not any(row.values()):  # Skip completely empty rows
                continue
            if not row.get('Email'):  # Skip rows with empty 'Email'
                continue
            filtered_row = {key: row[key] for key in fieldnames if key in row}
            writer.writerow(filtered_row)

    return is_header_written

def process_folder(folder_id):
    """Process all matching spreadsheets in the specified folder."""
    files = get_files_from_folder(folder_id)
    if not files:
        print("No matching files found in the folder.")
        return

    is_header_written = False
    with open(consolidated_file, 'w', newline='') as outfile:
        writer = csv.DictWriter(outfile, fieldnames=[
            'Email', 'Laborator 01', 'Laborator 02', 'Laborator 03',
            'Laborator 04', 'Laborator 05', 'Laborator 06',
            'Laborator 07', 'Laborator 08', 'Laborator 09',
            'Laborator 10', 'Laborator 11', 'Laborator 12'
        ])
        for file in files:
            file_id = file['id']
            file_name = file['name']
            try:
                is_header_written = download_and_filter_spreadsheet(file_id, file_name, writer, is_header_written)
            except Exception as e:
                print(f"Error processing {file_name}: {e}")

    print(f"Consolidated file created: {consolidated_file}")

# TODO Replace with your target folder ID
shared_folder_id = '1X3bwHUTWSWSUee-2cB_wP7eNQDDkd0-y'
process_folder(shared_folder_id)
