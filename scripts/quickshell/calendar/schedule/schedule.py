import json
import datetime
import os

DIR = os.path.dirname(__file__)
JSON_PATH = os.path.join(DIR, "jadwal.json")

def generate_default():
    return {
        "header": "To-Do List",
        "link": "",
        "lessons": [
            {
                "subject": "Belum ada tugas",
                "time": "-",
                "room": "",
                "desc": "Tambahkan tugas dari menu To-Do",
                "is_compact": False
            }
        ]
    }

def process_schedule(todos):
    now = datetime.datetime.now()
    date_str = now.strftime("%d %b")
    
    data = {
        "header": f"To-Do List ({date_str})",
        "link": "",
        "lessons": []
    }
    
    for todo in todos:
        text = todo.get("text", "")
        done = todo.get("done", False)
        
        data["lessons"].append({
            "subject": text,
            "time": "Selesai" if done else "Belum",
            "room": "Tugas",
            "desc": "",
            "is_compact": False,
            "type": "class",
            "start": 0,
            "end": 0
        })
        
    if not data["lessons"]:
        return generate_default()
        
    return data

def main():
    todo_path = os.path.expanduser("~/.cache/quickshell/todo.json")
    
    try:
        if os.path.exists(todo_path):
            with open(todo_path, 'r') as f:
                todos = json.load(f)
                processed = process_schedule(todos)
                print(json.dumps(processed))
        else:
            print(json.dumps(generate_default()))
    except Exception as e:
        print(json.dumps(generate_default()))

if __name__ == "__main__":
    main()
