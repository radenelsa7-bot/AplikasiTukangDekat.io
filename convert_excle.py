import json
import os
import pandas as pd

# Nama file input dan output
json_file = "data_sprint.json"
excel_file = "GitHub_Sprint_Board_TukangDekat.xlsx"

# Pastikan file JSON hasil ekspor gh CLI ada
if not os.path.exists(json_file):
    print(f"✗ Gagal: File {json_file} tidak ditemukan di folder ini.")
    exit(1)

# 1. Baca data dari file JSON
with open(json_file, "r", encoding="utf-8") as f:
    data = json.load(f)

parsed_items = []

# 2. Ambil data items (menangani format objek atau list dari gh CLI)
items_list = data if isinstance(data, list) else data.get("items", [])

# 3. Ekstrak kolom yang rapi
for item in items_list:
    content = item.get("content", {})

    cleaned_item = {
        "Title": item.get("title") or content.get("title", "No Title"),
        "Status": item.get("status", "No Status"),
        "Assignees": ", ".join(item.get("assignees", []))
        if item.get("assignees")
        else "-",
        "Type": content.get("type", "Issue"),
        "Repository": content.get("repository", "-"),
        "Priority": item.get("priority", "-"),
        "Start Date": item.get("start date", "-"),
        "Target Date": item.get("target date", "-"),
        "URL": content.get("url", "-"),
    }
    parsed_items.append(cleaned_item)

# 4. Konversi ke DataFrame dan Ekspor ke Excel
df = pd.DataFrame(parsed_items)
df.to_excel(excel_file, index=False)

print(f"✓ Berhasil! File Excel telah dibuat: {excel_file}")
