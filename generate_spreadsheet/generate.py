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
drive_service = build('drive', 'v3', credentials=credentials)

# ========================
# Utility Functions
# ========================
def get_sheet_id_by_title(spreadsheet_id, sheet_title):
    """Get the sheetId for a given sheet title."""
    spreadsheet = sheets_service.spreadsheets().get(spreadsheetId=spreadsheet_id).execute()
    for s in spreadsheet['sheets']:
        if s['properties']['title'] == sheet_title:
            return s['properties']['sheetId']
    raise ValueError(f"Sheet with title {sheet_title} not found")


def format_sheet(spreadsheet_id, sheet_title):
    """Apply formatting to a specific sheet in the spreadsheet."""
    sheet_id = get_sheet_id_by_title(spreadsheet_id, sheet_title)

    requests = [
        # Freeze the first 3 rows
        {
            "updateSheetProperties": {
                "properties": {
                    "sheetId": sheet_id,
                    "gridProperties": {"frozenRowCount": 3}
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
                    "userEnteredFormat": {"textFormat": {"bold": True}}
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
                        "backgroundColor": {"red": 0.88, "green": 0.96, "blue": 0.88}
                    }
                },
                "fields": "userEnteredFormat.backgroundColor"
            }
        },
        # Make Columns F-Q light blue
        {
            "repeatCell": {
                "range": {
                    "sheetId": sheet_id,
                    "startColumnIndex": 5,
                    "endColumnIndex": 17
                },
                "cell": {
                    "userEnteredFormat": {
                        "backgroundColor": {"red": 0.88, "green": 0.92, "blue": 0.96}
                    }
                },
                "fields": "userEnteredFormat.backgroundColor"
            }
        }
    ]

    sheets_service.spreadsheets().batchUpdate(
        spreadsheetId=spreadsheet_id, body={"requests": requests}
    ).execute()

    # Apply formulas to Total laborator (E column) starting row 3
    formulas = [[f"=MIN(SUM(F{row}:Q{row}),120)/12"] for row in range(3, 150)]
    sheets_service.spreadsheets().values().update(
        spreadsheetId=spreadsheet_id,
        range=f"{sheet_title}!E3",
        valueInputOption="USER_ENTERED",
        body={"range": f"{sheet_title}!E3", "majorDimension": "ROWS", "values": formulas}
    ).execute()

    print(f"Formatting and formulas applied to sheet: {sheet_title}")


def create_spreadsheet_in_folder(title, folder_id):
    """Create a new Google Spreadsheet inside a specific Drive folder."""
    file_metadata = {
        'name': title,
        'mimeType': 'application/vnd.google-apps.spreadsheet',
        'parents': [folder_id]
    }

    file = drive_service.files().create(body=file_metadata, fields='id').execute()
    spreadsheet_id = file['id']
    print(f"Created spreadsheet '{title}' in folder {folder_id}: {spreadsheet_id}")
    return spreadsheet_id

def create_sheets(spreadsheet_id, sheet_names):
    """Create multiple sheets in the spreadsheet."""
    requests = [
        {
            "addSheet": {
                "properties": {"title": name}
            }
        } for name in sheet_names
    ]

    body = {"requests": requests}
    sheets_service.spreadsheets().batchUpdate(
        spreadsheetId=spreadsheet_id,
        body=body
    ).execute()

    print(f"Sheets {', '.join(sheet_names)} created in spreadsheet {spreadsheet_id}")


def write_header_and_students(spreadsheet_id, header, sheet_name, students_rows):
    """
    Write header in row 1, leave rows 2 & 3 empty, then start student data at row 4
    """
    # Combine everything into a single list of rows
    all_rows = [header, [], []] + students_rows  # row1=header, row2 & row3 empty, then data

    sheets_service.spreadsheets().values().update(
        spreadsheetId=spreadsheet_id,
        range=f"{sheet_name}!A1",  # start at row 1
        valueInputOption="USER_ENTERED",
        body={"values": all_rows}
    ).execute()

    print(f"Header and student data written to sheet: {sheet_name}")

# ========================
# CSV Parsing and Data Grouping
# ========================
def load_participants(csv_path):
    groups = {'CA': [], 'CB': [], 'CC': [], 'CD': [], 'AC': [], 'Altii': []}
    with open(csv_path, encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            full_name = f"{row['First name']} {row['Last name']}".strip()
            email = row['Email address']
            grupa = row['Grupa']

            # Determine which sheet they belong to
            if 'CA' in grupa:
                group = 'CA'
            elif 'CB' in grupa:
                group = 'CB'
            elif 'CC' in grupa:
                group = 'CC'
            elif 'CD' in grupa:
                group = 'CD'
            elif 'AC' in grupa:
                group = 'AC'
            else:
                group = 'Altii'

            groups[group].append([full_name, email, grupa] + [""] * 14)  # total 17 columns
    for group in groups:
        groups[group].sort(
            key=lambda x: (
                x[2],
                x[0].split()[-1],
                x[0].split()[0]
            )
        )

    return groups


# ========================
# Main
# ========================
if __name__ == "__main__":
    csv_file = "participants.csv"
    spreadsheet_title = "USO 2025-2026 - Catalog - Laboratoare"

    spreadsheet_id = create_spreadsheet_in_folder(spreadsheet_title, FOLDER_ID)

    sheet_names = ["CA", "CB", "CC", "CD", "AC", "Altii"]
    create_sheets(spreadsheet_id, sheet_names)

    header = [
        "Student", "Email", "Grupa", "Asistent", "Total laborator",
        "Laborator 01", "Laborator 02", "Laborator 03", "Laborator 04",
        "Laborator 05", "Laborator 06", "Laborator 07", "Laborator 08",
        "Laborator 09", "Laborator 10", "Laborator 11", "Laborator 12"
    ]

    grouped_students = load_participants(csv_file)

    for sheet_name in sheet_names:
        students_rows = grouped_students.get(sheet_name, [])
        write_header_and_students(spreadsheet_id, header, sheet_name, students_rows)
        format_sheet(spreadsheet_id, sheet_name)

    print(f"All data uploaded and formatted for spreadsheet ID: {spreadsheet_id}")
