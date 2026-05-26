"""
Generates 4 App Store screenshots (iPhone 6.5" — 1284x2778 px).
"""
from PIL import Image, ImageDraw, ImageFont
import math, os, sys

W, H = 1284, 2778

# Brand colours
GD   = (27, 94, 32)      # green dark
GM   = (46, 125, 50)     # green mid
GL   = (200, 230, 201)   # green light
GOLD = (255, 193, 7)
WHITE = (255, 255, 255)
BG   = (245, 245, 245)
TP   = (33, 33, 33)
TS   = (117, 117, 117)

OUT = os.path.join(os.path.dirname(__file__), "screenshots")
os.makedirs(OUT, exist_ok=True)

# ── font helpers ───────────────────────────────────────────────────────────────
def font(size, bold=False):
    candidates = [
        "/Library/Fonts/SF-Pro-Display-Bold.otf" if bold else "/Library/Fonts/SF-Pro-Display-Regular.otf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/segoeui.ttf",
    ]
    for p in candidates:
        try:
            return ImageFont.truetype(p, size)
        except Exception:
            pass
    return ImageFont.load_default()

def text_center(draw, txt, y, fnt, color=WHITE):
    bb = draw.textbbox((0, 0), txt, font=fnt)
    x = (W - (bb[2] - bb[0])) // 2
    draw.text((x, y), txt, font=fnt, fill=color)

def gradient_bg(img, top, bot):
    d = ImageDraw.Draw(img)
    for y in range(H):
        t = y / H
        r = int(top[0] + (bot[0]-top[0])*t)
        g = int(top[1] + (bot[1]-top[1])*t)
        b = int(top[2] + (bot[2]-top[2])*t)
        d.line([(0, y), (W, y)], fill=(r, g, b))

def rounded_rect(draw, xy, r, fill):
    x0, y0, x1, y1 = xy
    draw.rectangle([x0+r, y0, x1-r, y1], fill=fill)
    draw.rectangle([x0, y0+r, x1, y1-r], fill=fill)
    for cx, cy in [(x0+r, y0+r), (x1-r, y0+r), (x0+r, y1-r), (x1-r, y1-r)]:
        draw.ellipse([cx-r, cy-r, cx+r, cy+r], fill=fill)

# ── 1. Main screen ─────────────────────────────────────────────────────────────
def make_main():
    img = Image.new("RGB", (W, H))
    gradient_bg(img, GD, (21, 71, 25))
    d = ImageDraw.Draw(img)

    # Title
    text_center(d, "Vocal Tasbeeh", 220, font(86, bold=True), GOLD)
    text_center(d, "Voice-Activated Dhikr Counter", 335, font(42), (200,230,201))

    # Dhikr grid (3 x 4)
    dhikrs = [
        "Subhanallah", "Alhamdulillah", "Allahu Akbar",
        "La ilahe illallah", "Astağfirullah", "Bismillah",
        "Sübhanallahi'l-Azim", "Hasbiyallah", "La havle...",
        "Salli ala...", "Custom Dhikr", "+ Add New",
    ]
    cols, rows = 3, 4
    pad = 40
    cw = (W - pad*2 - (cols-1)*24) // cols
    ch = 220
    start_y = 460
    for i, name in enumerate(dhikrs):
        col = i % cols
        row = i // cols
        x0 = pad + col*(cw+24)
        y0 = start_y + row*(ch+20)
        is_add = name.startswith("+")
        fill = (46, 125, 50) if not is_add else (33, 80, 36)
        rounded_rect(d, [x0, y0, x0+cw, y0+ch], 22, fill)
        # bead icon (simple circle chain)
        cx, cy = x0+cw//2, y0+56
        for a in range(8):
            ang = a * math.pi / 4
            bx = int(cx + 32*math.sin(ang))
            by = int(cy - 32*math.cos(ang))
            d.ellipse([bx-9, by-9, bx+9, by+9], fill=GOLD)
        # name
        fn = font(28, bold=True)
        lines = [name[:12], name[12:]] if len(name) > 12 else [name, ""]
        for li, ln in enumerate(lines):
            if ln:
                bb = d.textbbox((0,0), ln, font=fn)
                tx = x0 + (cw - (bb[2]-bb[0]))//2
                d.text((tx, y0+ch-70+li*34), ln, font=fn, fill=WHITE)

    # Bottom tagline
    text_center(d, "Say it — it counts!", H-220, font(58, bold=True), GOLD)
    text_center(d, "21 built-in dhikrs  ·  Custom dhikrs", H-140, font(38), (200,230,201))

    img.save(os.path.join(OUT, "01_main_screen.png"))
    print("01_main_screen.png done")

# ── 2. Voice counter ───────────────────────────────────────────────────────────
def make_counter():
    img = Image.new("RGB", (W, H))
    gradient_bg(img, (21, 71, 25), (30, 100, 35))
    d = ImageDraw.Draw(img)

    text_center(d, "Hands-Free Counting", 200, font(72, bold=True))
    text_center(d, "Just say the dhikr — no tapping needed", 310, font(40), (200,230,201))

    # Zikir name
    text_center(d, "Subhanallah", 520, font(80, bold=True), GOLD)

    # Big counter circle
    cx, cy, r = W//2, 1050, 340
    d.ellipse([cx-r, cy-r, cx+r, cy+r], outline=GOLD, width=12)
    d.ellipse([cx-r+20, cy-r+20, cx+r-20, cy+r-20], fill=(27, 94, 32))
    text_center(d, "33", cy-90, font(280, bold=True), WHITE)
    text_center(d, "of 33", cy+110, font(52), (200,230,201))

    # Mic visual
    mic_y = 1500
    # mic body
    d.rounded_rectangle([W//2-60, mic_y, W//2+60, mic_y+220], radius=50, fill=GOLD)
    # stand
    d.arc([W//2-120, mic_y+140, W//2+120, mic_y+340], start=0, end=180, fill=GOLD, width=14)
    d.line([W//2, mic_y+340, W//2, mic_y+400], fill=GOLD, width=14)
    d.line([W//2-70, mic_y+400, W//2+70, mic_y+400], fill=GOLD, width=14)

    # Sound waves
    for i, rad in enumerate([180, 240, 300]):
        alpha = 200 - i*50
        d.arc([W//2-rad, mic_y+40-rad+160, W//2+rad, mic_y+40+rad+160],
              start=200, end=340, fill=(*GOLD, alpha), width=8)

    text_center(d, "🎙 Listening...", 2100, font(54), (200,230,201))
    text_center(d, "Tap to start · Tap again to stop", 2220, font(38), TS)

    # Bottom
    text_center(d, "Voice recognition · Works offline", H-180, font(44, bold=True), GOLD)

    img.save(os.path.join(OUT, "02_counter_screen.png"))
    print("02_counter_screen.png done")

# ── 3. Prayer times ────────────────────────────────────────────────────────────
def make_prayer():
    img = Image.new("RGB", (W, H))
    gradient_bg(img, GD, (20, 68, 25))
    d = ImageDraw.Draw(img)

    text_center(d, "Accurate Prayer Times", 200, font(68, bold=True))
    text_center(d, "GPS-based · Updates automatically", 310, font(40), (200,230,201))

    # White card area
    card_x, card_y = 80, 430
    card_w, card_h = W - 160, 2050
    rounded_rect(d, [card_x, card_y, card_x+card_w, card_y+card_h], 40, WHITE)

    # City + date
    text_center(d, "Istanbul", card_y+70, font(70, bold=True), GD)
    text_center(d, "13 May 2026", card_y+160, font(44), TS)

    prayers = [
        ("Fajr",    "04:28", False),
        ("Sunrise", "06:13", False),
        ("Dhuhr",   "13:05", True),   # highlight = next
        ("Asr",     "17:01", False),
        ("Maghrib", "20:08", False),
        ("Isha",    "21:45", False),
    ]

    row_h = 270
    start_y = card_y + 280
    for i, (name, time, highlight) in enumerate(prayers):
        ry = start_y + i * row_h
        rx = card_x + 20
        rw = card_w - 40
        bg = GL if highlight else (250, 250, 250)
        outline = (105, 240, 174) if highlight else (240, 240, 240)
        rounded_rect(d, [rx, ry, rx+rw, ry+row_h-20], 20, bg)
        if highlight:
            d.rounded_rectangle([rx, ry, rx+rw, ry+row_h-20],
                                 radius=20, outline=outline, width=4)

        fn = font(52, bold=highlight)
        fc = GD if highlight else TP
        d.text((rx+60, ry+90), name, font=fn, fill=fc)
        # time right-aligned
        tbb = d.textbbox((0,0), time, font=font(64, bold=True))
        tx = rx + rw - 60 - (tbb[2]-tbb[0])
        d.text((tx, ry+76), time, font=font(64, bold=True), fill=fc)

    img.save(os.path.join(OUT, "03_prayer_times.png"))
    print("03_prayer_times.png done")

# ── 4. Qibla compass ──────────────────────────────────────────────────────────
def make_qibla():
    img = Image.new("RGB", (W, H))
    gradient_bg(img, GD, (20, 68, 25))
    d = ImageDraw.Draw(img)

    text_center(d, "Real-Time Qibla Compass", 200, font(64, bold=True))
    text_center(d, "Always know the direction of prayer", 310, font(40), (200,230,201))

    # Compass circle
    cx, cy, r = W//2, 1200, 480
    # Outer ring
    d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=WHITE, outline=GL, width=6)
    # Cardinal labels
    labels = [("N", 0), ("E", 90), ("S", 180), ("W", 270)]
    for lbl, ang in labels:
        rad = math.radians(ang - 90)
        lx = cx + int((r-80) * math.cos(rad))
        ly = cy + int((r-80) * math.sin(rad))
        fn = font(56, bold=True)
        bb = d.textbbox((0,0), lbl, font=fn)
        d.text((lx-(bb[2]-bb[0])//2, ly-(bb[3]-bb[1])//2), lbl, font=fn, fill=TS)

    # Tick marks
    for a in range(0, 360, 10):
        rad = math.radians(a)
        inner = r - (40 if a % 90 == 0 else 20)
        x1 = cx + int(inner * math.sin(rad))
        y1 = cy - int(inner * math.cos(rad))
        x2 = cx + int((r-8) * math.sin(rad))
        y2 = cy - int((r-8) * math.cos(rad))
        d.line([x1, y1, x2, y2], fill=(180,180,180), width=3 if a % 90 == 0 else 2)

    # Needle (pointing to qibla ~135° for Istanbul)
    needle_ang = math.radians(135)
    # Green tip (toward Qibla)
    tip_x = cx + int(320 * math.sin(needle_ang))
    tip_y = cy - int(320 * math.cos(needle_ang))
    # Grey tail
    tail_x = cx - int(240 * math.sin(needle_ang))
    tail_y = cy + int(240 * math.cos(needle_ang))

    perp = math.radians(135 + 90)
    pw, tw = 22, 14
    pts_green = [
        (cx + int(pw*math.sin(perp)), cy - int(pw*math.cos(perp))),
        (tip_x, tip_y),
        (cx - int(pw*math.sin(perp)), cy + int(pw*math.cos(perp))),
    ]
    pts_grey = [
        (cx + int(tw*math.sin(perp)), cy - int(tw*math.cos(perp))),
        (tail_x, tail_y),
        (cx - int(tw*math.sin(perp)), cy + int(tw*math.cos(perp))),
    ]
    d.polygon(pts_green, fill=GM)
    d.polygon(pts_grey, fill=(200,200,200))
    d.ellipse([cx-24, cy-24, cx+24, cy+24], fill=GD)

    # Kaaba emoji placeholder
    text_center(d, "🕋", cy-26, font(64))

    # Aligned badge
    badge_y = cy + r + 60
    rounded_rect(d, [W//2-260, badge_y, W//2+260, badge_y+100], 50, GM)
    text_center(d, "You're facing Qibla! ✓", badge_y+22, font(44, bold=True), WHITE)

    text_center(d, "Mecca direction: 135°", badge_y+160, font(44), (200,230,201))
    text_center(d, "Calculated from your GPS location", badge_y+240, font(38), TS)

    text_center(d, "Live compass · GPS accuracy", H-180, font(44, bold=True), GOLD)

    img.save(os.path.join(OUT, "04_qibla_compass.png"))
    print("04_qibla_compass.png done")

make_main()
make_counter()
make_prayer()
make_qibla()
print("\nAll 4 screenshots saved to:", OUT)
