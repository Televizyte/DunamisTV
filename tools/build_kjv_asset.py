#!/usr/bin/env python3
"""
Build FULL KJV Bible:
- Full file (kjv_bible.json)
- Chunk files (per book)
- index.json

Run:
    python tools/build_kjv_asset.py
"""

from __future__ import annotations
import json
import re
import urllib.request
from pathlib import Path

BASE_URL = "https://raw.githubusercontent.com/aruljohn/Bible-kjv/master"

ROOT = Path(__file__).resolve().parents[1]
BIBLE_DIR = ROOT / "assets" / "bible"
BOOKS_DIR = BIBLE_DIR / "books"

KJV_OUTPUT = BIBLE_DIR / "kjv_bible.json"
INDEX_OUTPUT = BIBLE_DIR / "index.json"

BOOK_SPECS = [
    ("Genesis", "Genesis.json", "Gen", "old"),
    ("Exodus", "Exodus.json", "Exo", "old"),
    ("Leviticus", "Leviticus.json", "Lev", "old"),
    ("Numbers", "Numbers.json", "Num", "old"),
    ("Deuteronomy", "Deuteronomy.json", "Deut", "old"),
    ("Joshua", "Joshua.json", "Josh", "old"),
    ("Judges", "Judges.json", "Judg", "old"),
    ("Ruth", "Ruth.json", "Ruth", "old"),
    ("1 Samuel", "1Samuel.json", "1Sam", "old"),
    ("2 Samuel", "2Samuel.json", "2Sam", "old"),
    ("1 Kings", "1Kings.json", "1Kgs", "old"),
    ("2 Kings", "2Kings.json", "2Kgs", "old"),
    ("1 Chronicles", "1Chronicles.json", "1Chr", "old"),
    ("2 Chronicles", "2Chronicles.json", "2Chr", "old"),
    ("Ezra", "Ezra.json", "Ezra", "old"),
    ("Nehemiah", "Nehemiah.json", "Neh", "old"),
    ("Esther", "Esther.json", "Est", "old"),
    ("Job", "Job.json", "Job", "old"),
    ("Psalms", "Psalms.json", "Ps", "old"),
    ("Proverbs", "Proverbs.json", "Prov", "old"),
    ("Ecclesiastes", "Ecclesiastes.json", "Eccl", "old"),
    ("Song of Solomon", "SongofSolomon.json", "Song", "old"),
    ("Isaiah", "Isaiah.json", "Isa", "old"),
    ("Jeremiah", "Jeremiah.json", "Jer", "old"),
    ("Lamentations", "Lamentations.json", "Lam", "old"),
    ("Ezekiel", "Ezekiel.json", "Ezek", "old"),
    ("Daniel", "Daniel.json", "Dan", "old"),
    ("Hosea", "Hosea.json", "Hos", "old"),
    ("Joel", "Joel.json", "Joel", "old"),
    ("Amos", "Amos.json", "Amos", "old"),
    ("Obadiah", "Obadiah.json", "Obad", "old"),
    ("Jonah", "Jonah.json", "Jon", "old"),
    ("Micah", "Micah.json", "Mic", "old"),
    ("Nahum", "Nahum.json", "Nah", "old"),
    ("Habakkuk", "Habakkuk.json", "Hab", "old"),
    ("Zephaniah", "Zephaniah.json", "Zeph", "old"),
    ("Haggai", "Haggai.json", "Hag", "old"),
    ("Zechariah", "Zechariah.json", "Zech", "old"),
    ("Malachi", "Malachi.json", "Mal", "old"),
    ("Matthew", "Matthew.json", "Matt", "new"),
    ("Mark", "Mark.json", "Mark", "new"),
    ("Luke", "Luke.json", "Luke", "new"),
    ("John", "John.json", "Jn", "new"),
    ("Acts", "Acts.json", "Acts", "new"),
    ("Romans", "Romans.json", "Rom", "new"),
    ("1 Corinthians", "1Corinthians.json", "1Cor", "new"),
    ("2 Corinthians", "2Corinthians.json", "2Cor", "new"),
    ("Galatians", "Galatians.json", "Gal", "new"),
    ("Ephesians", "Ephesians.json", "Eph", "new"),
    ("Philippians", "Philippians.json", "Phil", "new"),
    ("Colossians", "Colossians.json", "Col", "new"),
    ("1 Thessalonians", "1Thessalonians.json", "1Thess", "new"),
    ("2 Thessalonians", "2Thessalonians.json", "2Thess", "new"),
    ("1 Timothy", "1Timothy.json", "1Tim", "new"),
    ("2 Timothy", "2Timothy.json", "2Tim", "new"),
    ("Titus", "Titus.json", "Titus", "new"),
    ("Philemon", "Philemon.json", "Phlm", "new"),
    ("Hebrews", "Hebrews.json", "Heb", "new"),
    ("James", "James.json", "Jas", "new"),
    ("1 Peter", "1Peter.json", "1Pet", "new"),
    ("2 Peter", "2Peter.json", "2Pet", "new"),
    ("1 John", "1John.json", "1Jn", "new"),
    ("2 John", "2John.json", "2Jn", "new"),
    ("3 John", "3John.json", "3Jn", "new"),
    ("Jude", "Jude.json", "Jude", "new"),
    ("Revelation", "Revelation.json", "Rev", "new"),
]

def fetch_json(url: str):
    with urllib.request.urlopen(url) as res:
        return json.loads(res.read().decode())

def clean(text: str):
    text = text.replace("\n", " ")
    return re.sub(r"\s+", " ", text).strip()

def transform(name, file, abbr, test):
    data = fetch_json(f"{BASE_URL}/{file}")
    chapters = []
    for ch in data["chapters"]:
        verses = [clean(v["text"]) for v in ch["verses"]]
        chapters.append(verses)
    return {
        "name": name,
        "abbreviation": abbr,
        "testament": test,
        "chapters": chapters
    }

def main():
    BOOKS_DIR.mkdir(parents=True, exist_ok=True)

    full_books = []
    index_books = []

    print("Building FULL Bible + chunks...")

    for name, file, abbr, test in BOOK_SPECS:
        print("→", name)
        book = transform(name, file, abbr, test)

        # Save chunk
        filename = name.lower().replace(" ", "_") + ".json"
        with open(BOOKS_DIR / filename, "w", encoding="utf-8") as f:
            json.dump(book, f, ensure_ascii=False)

        # Index entry
        index_books.append({
            "name": name,
            "abbreviation": abbr,
            "testament": test,
            "file": filename
        })

        full_books.append(book)

    # Save full file
    with open(KJV_OUTPUT, "w", encoding="utf-8") as f:
        json.dump({"translation": "KJV", "books": full_books}, f)

    # Save index
    with open(INDEX_OUTPUT, "w", encoding="utf-8") as f:
        json.dump({"translation": "KJV", "books": index_books}, f, indent=2)

    print("\nDONE — FULL BIBLE READY")

if __name__ == "__main__":
    main()
