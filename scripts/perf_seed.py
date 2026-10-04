#!/usr/bin/env python3
"""Seeds a backend with enough content for integration_test/perf to scroll.

Creates 30 free dongeng (10 pages each) and 30 AR cards through the admin API,
all using real hosted images so image loading and decoding are part of what
gets measured. Titles start with "Perf " so the test can find them.

Point it at a disposable backend (e.g. arunika-backend's `make e2e-hold`,
API on :8090), never at one holding real content.

Usage: python3 scripts/perf_seed.py [api_base_url]
"""

import json
import sys
import time
import urllib.request

API = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8090"
DONGENG_IMAGES = [
    "https://pub-7df2f3d5530044f69bc987606173687a.r2.dev/hare-and-tortoise/Gemini_Generated_Image_.png",
    "https://pub-7df2f3d5530044f69bc987606173687a.r2.dev/prophet-yunus/Gemini_Generated_Image_%20(4).png",
]
CARD_IMAGE = "https://pub-b4af6051071f45a79611d6c062f749da.r2.dev/animals/main-image/frog.png"
CARD_MODEL = "https://pub-b4af6051071f45a79611d6c062f749da.r2.dev/animals/ar-object/frog.glb"


def call(method, path, body=None, token=None):
    req = urllib.request.Request(API + path, method=method,
                                 data=json.dumps(body).encode() if body is not None else None)
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", "Bearer " + token)
    with urllib.request.urlopen(req) as res:
        return json.loads(res.read() or b"{}")


# Seeded by db/seeds/R__seed_admin_user.sql on every environment.
token = call("POST", "/admin/auth/login", {"email": "admin@arunika.id", "password": "admin123"})["access_token"]
run = str(int(time.time()))

for i in range(30):
    image = DONGENG_IMAGES[i % 2]
    tale = call("POST", "/admin/content/fairy-tales", {
        "title": f"Perf Dongeng {i:02d} {run}", "image_url": image,
        "audio_url": "", "is_free": True, "duration": 300,
    }, token)["data"]
    for page in range(1, 11):
        call("POST", "/admin/content/dongen-pages", {
            "dongeng_id": tale["id"], "page_number": page,
            "image_url": DONGENG_IMAGES[(i + page) % 2],
            "text": f"Halaman {page}. Si kancil berjalan di hutan bersama teman-temannya.",
        }, token)

for i in range(30):
    call("POST", "/admin/content/ar-cards", {
        "title": f"Perf Kartu {i:02d} {run}", "type": "animal",
        "file_url": CARD_MODEL, "image_url": CARD_IMAGE,
        "short_code": f"PERF{run}{i:02d}",
    }, token)

tales = call("GET", "/fairy-tales")
cards = call("GET", "/ar/cards")
print(f"seeded: /fairy-tales first page {len(tales['data'])} of {tales.get('total')}, /ar/cards {len(cards['data'])}")
