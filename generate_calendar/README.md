## USO Planificare to Google Calendar CSV

This Python script converts USO course and lab schedules from a CSV file into a Google Calendar-compatible CSV file with events for courses, labs, assignments, and mid-term exams.


## Run it

```bash
pip install -r requirements.txt
python3 generate.py
```

The script will read `input.csv` and it will create a `calendar_events.csv` that can be imported in the USO Google calendar
