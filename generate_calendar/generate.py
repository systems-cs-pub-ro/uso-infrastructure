import csv
from datetime import datetime, timedelta, time

# ==============================
# CONFIGURATION
# ==============================

SERIES_INFO = {
    "CD": {"weekday": "Luni", "time": "16:00 - 18:00", "location": "PR001", "teacher": "Alexandru Radovici"},
    "CA": {"weekday": "Marți", "time": "10:00 - 12:00", "location": "EC105", "teacher": "Răzvan Rughiniș"},
    "CB": {"weekday": "Marți", "time": "10:00 - 12:00", "location": "PR001", "teacher": "Mihai Carabaș"},
    "CC-par": {"weekday": "Miercuri", "time": "16:00 - 18:00", "location": "AN030", "teacher": "Sergiu Weisz"},
    "CC-impar": {"weekday": "Miercuri", "time": "18:00 - 20:00", "location": "AN030", "teacher": "Sergiu Weisz"},
}

WEEKDAY_MAP = {
    "Luni": 0,
    "Marți": 1,
    "Miercuri": 2,
    "Joi": 3,
    "Vineri": 4,
    "Sâmbătă": 5,
    "Duminică": 6,
}

SEMESTER_START = datetime(2025, 9, 29)  # Week 1 start

LUCRARI_WEEKDAY = {
    "CA": "Marți",
    "CB": "Marți",
    "CC-par": "Miercuri",
    "CC-impar": "Miercuri",
    "CD": "Luni",
}

LUCRARI_DE_CURS_INFO = [
    ("Test de curs 1", "20-Oct-2025"),
    ("Test de curs 2", "3-Nov-2025"),
    ("Test de curs 3", "17-Nov-2025"),
    ("Test de curs 4", "8-Dec-2025"),
    ("Test de curs 5", "12-Jan-2026"),
]

MIDTERM_INFO = {
    "name": "Test practic mid-term",
    "date": "13-Dec-2025",
    "start_time": "09:00",
    "end_time": "17:00",
    "location": "Săli din facultate",
    "description": "https://ocw.cs.pub.ro/courses/uso/regulament#mijloc_de_semestru"
}

# ==============================
# HELPERS
# ==============================

def safe_parse_date(s):
    if not s or s.strip() in ["", "-"]:
        return None
    try:
        return datetime.strptime(s.strip(), "%d-%b-%Y")
    except Exception:
        return None


def parse_time_range(time_str):
    start_str, end_str = time_str.split("-")
    start = datetime.strptime(start_str.strip(), "%H:%M").time()
    end = datetime.strptime(end_str.strip(), "%H:%M").time()
    return start, end


def format_google_date(dt):
    return dt.strftime("%m/%d/%Y")


def format_google_time(dt):
    return dt.strftime("%-I:%M:%S %p")


def write_event(events, subject, start_dt, end_dt, all_day=False, description="", location=""):
    events.append({
        "Subject": subject,
        "Start Date": format_google_date(start_dt),
        "Start Time": "" if all_day else format_google_time(start_dt),
        "End Date": format_google_date(end_dt),
        "End Time": "" if all_day else format_google_time(end_dt),
        "All Day Event": "True" if all_day else "False",
        "Description": description,
        "Location": location,
        "Private": "False"
    })


def week_number_from_date(date):
    delta_days = (date - SEMESTER_START).days
    return 1 + delta_days // 7


def is_series_applicable_for_week(serie, week_number):
    if not serie.startswith("CC"):
        return True
    if serie.endswith("par"):
        return week_number % 2 == 0
    if serie.endswith("impar"):
        return week_number % 2 == 1
    return True

# ==============================
# EVENT GENERATORS
# ==============================

def generate_curs_events(events, input_csv):
    with open(input_csv, newline='', encoding='utf-8') as csvfile:
        reader = csv.reader(csvfile)
        next(reader)
        next(reader)

        course_counter = 1  # global counter

        for row in reader:
            if not row or not row[0].strip().isdigit():
                continue

            week_number = int(row[0])
            week_start = safe_parse_date(row[1])
            course_date = safe_parse_date(row[3])
            course_name = row[4].strip()

            if week_start and course_date and course_name:
                for serie_key, info in SERIES_INFO.items():
                    # Handle CC parity: skip series not for this week
                    if serie_key.startswith("CC"):
                        if (week_number % 2 == 1 and serie_key != "CC-impar") or \
                           (week_number % 2 == 0 and serie_key != "CC-par"):
                            continue

                    # Skip series not applicable for this week (other than CC)
                    if not serie_key.startswith("CC") and not is_series_applicable_for_week(serie_key, week_number):
                        continue

                    weekday_num = WEEKDAY_MAP[info["weekday"]]
                    course_real_date = week_start + timedelta(days=(weekday_num - week_start.weekday()) % 7)
                    start_t, end_t = parse_time_range(info["time"])
                    start_dt = datetime.combine(course_real_date, start_t)
                    end_dt = datetime.combine(course_real_date, end_t)

                    subject = f"Curs {course_counter:02d} USO (seria {serie_key}): {course_name}"
                    description = f"http://ocw.cs.pub.ro/courses/uso/cursuri/curs-{week_number:02d}"

                    write_event(events, subject, start_dt, end_dt, description=description, location=info["location"])

                course_counter += 1

def generate_lab_and_teme_events(events, input_csv):
    with open(input_csv, newline='', encoding='utf-8') as csvfile:
        reader = csv.reader(csvfile)
        next(reader)
        next(reader)

        lab_counter = 1
        for row in reader:
            if not row or not row[0].strip().isdigit():
                continue

            week_number = int(row[0])

            # LAB
            lab_start_date = safe_parse_date(row[5])
            lab_end_date = safe_parse_date(row[6])
            lab_name = row[7].strip()
            if lab_start_date and lab_end_date and lab_name:
                lab_start = datetime.combine(lab_start_date, time(8, 0))
                lab_end = datetime.combine(lab_end_date, time(20, 0))
                subject = f"Laborator {lab_counter:02d} USO: {lab_name}"
                description = f"http://ocw.cs.pub.ro/courses/uso/laboratoare/laborator-{week_number:02d}"
                write_event(events, subject, lab_start, lab_end, description=description, location="EG106/EG306")
                lab_counter += 1

            # TEMA
            tema_start = safe_parse_date(row[8])
            tema_end = safe_parse_date(row[9])
            tema_name = row[11].strip() if len(row) > 11 else ""
            if tema_start and tema_end and tema_name:
                subject = tema_name
                write_event(events, subject, tema_start, tema_end, description="Lucru individual", location="Online")


def generate_lucrari_de_curs_events(events):
    for test_name, date_str in LUCRARI_DE_CURS_INFO:
        test_date = safe_parse_date(date_str)
        if not test_date:
            continue

        week_number = week_number_from_date(test_date)

        for serie, info in SERIES_INFO.items():
            # --- Handle CC parity logic ---
            if serie.startswith("CC"):
                # Odd week → only CC-impar; Even week → only CC-par
                if (week_number % 2 == 1 and serie != "CC-impar") or \
                   (week_number % 2 == 0 and serie != "CC-par"):
                    continue
            else:
                # Non-CC series use the standard applicability
                if not is_series_applicable_for_week(serie, week_number):
                    continue

            weekday_num = WEEKDAY_MAP[LUCRARI_WEEKDAY[serie]]
            event_date = test_date + timedelta(days=(weekday_num - test_date.weekday()) % 7)
            start_t, _ = parse_time_range(info["time"])
            start_dt = datetime.combine(event_date, start_t)
            end_dt = start_dt + timedelta(minutes=15)

            subject = f"{test_name} (seria {serie})"
            description = "https://ocw.cs.pub.ro/courses/uso/regulament#lucrari_de_curs"
            write_event(events, subject, start_dt, end_dt, description=description, location=info["location"])

def generate_midterm_event(events):
    date = safe_parse_date(MIDTERM_INFO["date"])
    if not date:
        return
    start_time = datetime.strptime(MIDTERM_INFO["start_time"], "%H:%M").time()
    end_time = datetime.strptime(MIDTERM_INFO["end_time"], "%H:%M").time()
    start_dt = datetime.combine(date, start_time)
    end_dt = datetime.combine(date, end_time)

    write_event(
        events,
        MIDTERM_INFO["name"],
        start_dt,
        end_dt,
        description=MIDTERM_INFO["description"],
        location=MIDTERM_INFO["location"]
    )

# ==============================
# MAIN
# ==============================

def convert_schedule(input_csv, output_csv):
    events = []
    generate_curs_events(events, input_csv)
    generate_lab_and_teme_events(events, input_csv)
    generate_lucrari_de_curs_events(events)
    generate_midterm_event(events)

    with open(output_csv, "w", newline='', encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=[
            "Subject", "Start Date", "Start Time", "End Date", "End Time",
            "All Day Event", "Description", "Location", "Private"
        ])
        writer.writeheader()
        writer.writerows(events)

    print(f"✅ Generated {len(events)} events into {output_csv}")


if __name__ == "__main__":
    convert_schedule("input.csv", "calendar_events.csv")
