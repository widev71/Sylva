#!/usr/bin/env python3
import urllib.request
import re
import json
import sys
import os

USERNAME = "widev71"

# We want 14 weeks * 7 days = 98 squares
WEEKS = 20
DAYS = WEEKS * 7

try:
    req = urllib.request.Request(f"https://github.com/users/{USERNAME}/contributions", headers={'User-Agent': 'Mozilla/5.0'})
    html = urllib.request.urlopen(req, timeout=10).read().decode('utf-8')
    
    # GitHub changed their DOM recently, so we extract by data-level
    pattern = r'data-date="(\d{4}-\d{2}-\d{2})".*?data-level="(\d)"'
    matches = re.findall(pattern, html)
    
    # Grab the last DAYS elements
    recent = matches[-DAYS:] if len(matches) > DAYS else matches
    
    output = [{"date": d, "level": int(l)} for d, l in recent]
    print(json.dumps(output))

except Exception as e:
    print(json.dumps([]))
