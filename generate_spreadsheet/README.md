# USO - Catalog Laboratoare

This Python script automates the creation of a Google Spreadsheet gradebook for USO laboratory participants.
It reads participant information from a CSV file and generates a spreadsheet with multiple sheets, formatted headers, and sorted student data.

## Features

- Creates a Google Spreadsheet inside a specific Google Drive folder.
- Adds multiple sheets for groups: CA, CB, CC, CD, AC, and Altii.
- Sorts students alphabetically by Grupa, Last Name, and First Name.

## Run it

```bash
pip install -r requirements.txt
python3 generate.py
```

The script will read `participants.csv` and it will create the spreadsheet in `FOLDER_ID` on google drive.

To use this script you must generate a Google Service Account key named `google-service-account.json` and also add the Google Service Account as an editor for `FOLDER_ID`.
