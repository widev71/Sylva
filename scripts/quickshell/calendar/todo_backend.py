#!/usr/bin/env python3
import json
import sys
import os

CACHE_DIR = os.path.expanduser("~/.cache/quickshell")
TODO_FILE = os.path.join(CACHE_DIR, "todo.json")

def load_todos():
    if not os.path.exists(TODO_FILE):
        return []
    try:
        with open(TODO_FILE, "r") as f:
            return json.load(f)
    except Exception:
        return []

def save_todos(todos):
    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(TODO_FILE, "w") as f:
        json.dump(todos, f, indent=4)

def print_json():
    todos = load_todos()
    print(json.dumps(todos))

def main():
    if len(sys.argv) < 2:
        print_json()
        return

    cmd = sys.argv[1]
    todos = load_todos()

    if cmd == "add" and len(sys.argv) > 2:
        text = " ".join(sys.argv[2:])
        todos.append({"text": text, "done": False})
        save_todos(todos)
        print_json()
    elif cmd == "toggle" and len(sys.argv) > 2:
        try:
            idx = int(sys.argv[2])
            if 0 <= idx < len(todos):
                todos[idx]["done"] = not todos[idx]["done"]
                save_todos(todos)
        except ValueError:
            pass
        print_json()
    elif cmd == "delete" and len(sys.argv) > 2:
        try:
            idx = int(sys.argv[2])
            if 0 <= idx < len(todos):
                todos.pop(idx)
                save_todos(todos)
        except ValueError:
            pass
        print_json()
    else:
        print_json()

if __name__ == "__main__":
    main()
