import json
import datetime
import os

DIR = os.path.dirname(__file__)
JSON_PATH = os.path.join(DIR, "jadwal.json")

def generate_default():
    return {
        "header": "Jadwal Harian",
        "link": "https://calendar.google.com",
        "lessons": [
            {
                "subject": "Belajar Linux",
                "time": "08:30-10:00",
                "room": "Kamar",
                "desc": "Ngoprek sistem",
                "is_compact": False
            },
            {
                "subject": "Istirahat",
                "time": "12:00-13:00",
                "room": "Ruang Makan",
                "desc": "Makan siang",
                "is_compact": True
            },
            {
                "subject": "Kuliah / Kerja",
                "time": "13:00-15:00",
                "room": "Kampus / Kantor",
                "desc": "",
                "is_compact": False
            }
        ]
    }

def process_schedule(data):
    now = datetime.datetime.now()
    # Add date to header
    date_str = now.strftime("%d %b")
    header = data.get("header", "Jadwal")
    data["header"] = f"{header} ({date_str})"
    
    lessons = data.get("lessons", [])
    
    for lesson in lessons:
        lesson["type"] = "class"
        if "is_compact" not in lesson:
            lesson["is_compact"] = False
            
        time_str = lesson.get("time", "")
        # Parse time like "08:30-10:00"
        try:
            if "-" in time_str:
                start_s, end_s = time_str.split("-")
                sh, sm = map(int, start_s.strip().split(":"))
                eh, em = map(int, end_s.strip().split(":"))
                
                start_ts = int(now.replace(hour=sh, minute=sm, second=0, microsecond=0).timestamp())
                end_ts = int(now.replace(hour=eh, minute=em, second=0, microsecond=0).timestamp())
                
                lesson["start"] = start_ts
                lesson["end"] = end_ts
        except Exception:
            lesson["start"] = 0
            lesson["end"] = 0
            
    return data

def main():
    if not os.path.exists(JSON_PATH):
        with open(JSON_PATH, 'w') as f:
            json.dump(generate_default(), f, indent=4)
            
    try:
        with open(JSON_PATH, 'r') as f:
            data = json.load(f)
            processed = process_schedule(data)
            print(json.dumps(processed))
    except Exception as e:
        print(json.dumps(process_schedule(generate_default())))

if __name__ == "__main__":
    main()
