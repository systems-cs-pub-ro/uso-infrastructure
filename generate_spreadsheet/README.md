# Spreadsheet Gradebook Generator

This Python script automates the creation of a Google Spreadsheet gradebook for labs.

It reads participants from a `.csv` and generates the gradebook as a spreadsheet in Google Drive.

## Features

- Creates a Google Spreadsheet inside a specific Google Drive folder.
- Adds one sheet per serie/group (by default: CA, CB, CC, CD, and Altii).
- Sorts students alphabetically by Grupa, Last Name, and First Name.

## Run it

To use this script:
- you must generate a Google Service Account key named `google-service-account.json`.
- Fetch the `FOLDER_ID` of the Google Drive folder where you want to create the spreadsheet (`https://drive.google.com/drive/folders/<FOLDER_ID>`).
- you must add the Google Service Account as an editor for `FOLDER_ID` in Google Drive's UI.

To install prerequisites, run the following commands:
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

To create the spreadsheet, run the following command:
```bash
FOLDER_ID=<google-drive-folder-id> python3 generate.py \
    --file participants.csv \
    --title "USO 2026-2027 - Catalog - Laboratoare" \
    --series CA CB CC CD AC Altii
```

`FOLDER_ID` is required and is the ID of the Google Drive folder where the spreadsheet is created - the last part of the folder URL: `https://drive.google.com/drive/folders/<FOLDER_ID>`.

With no arguments, the script uses the defaults below.

| Argument | Default | Description |
|---|---|---|
| `--file` | `participants.csv` | Path to the participants CSV file |
| `--title` | `USO 2025-2026 - Catalog - Laboratoare` | Title of the spreadsheet to create |
| `--series` | `CA CB CC CD Altii` | Series to sort and create sheets for (space separated) |

Each student is placed in the first sheet whose name appears in their `Grupa` column.
The **last** sheet name is the catch-all for students that don't match any other sheet.

Run `python3 generate.py --help` to see all options.
