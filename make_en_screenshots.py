"""
App Store screenshots replicating the Android app design — English text.
Target: 1284x2778 (iPhone 6.5")
"""
from PIL import Image, ImageDraw, ImageFont
import os, math

W, H = 1284, 2778

BG       = (237, 232, 227)   # warm beige
WHITE    = (255, 255, 255)
GD       = (27,  94,  32)    # dark green
GM       = (46, 125,  50)    # mid green
GL       = (200, 230, 201)   # light green
GOLD     = (180, 130,  20)   # golden accent
TP       = (30,  30,  30)    # text primary
TS       = (120, 120, 120)   # text secondary
BORDER   = (220, 215, 210)

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "screenshots")
os.makedirs(OUT, exist_ok=True)

# ── fonts ──────────────────────────────────────────────────────────────────────
def fnt(size, bold=False):
    for p in [
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/segoeui.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf" if bold else
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]:
        try: return ImageFont.truetype(p, size)
        except: pass
    return ImageFont.load_default()

def cx_text(draw, text, y, f, color=TP):
    bb = draw.textbbox((0, 0), text, font=f)
    x = (W - (bb[2] - bb[0])) // 2
    draw.text((x, y), text, font=f, fill=color)

def rrect(draw, xy, r, fill, outline=None, width=2):
    x0, y0, x1, y1 = xy
    draw.rounded_rectangle([x0, y0, x1, y1], radius=r, fill=fill,
                           outline=outline, width=width)

def status_bar(draw):
    """Minimal iOS-style status bar."""
    draw.text((80, 55), "9:41", font=fnt(52, bold=True), fill=TP)
    # battery + wifi placeholder
    for i, bx in enumerate([1160, 1110, 1060]):
        draw.rounded_rectangle([bx, 62, bx+28, 82], radius=4,
                                fill=TP if i == 0 else TS)

# ══════════════════════════════════════════════════════════════════════════════
# 1. Main screen — dhikr list
# ══════════════════════════════════════════════════════════════════════════════
def make_main():
    img = Image.new("RGB", (W, H), BG)
    d   = ImageDraw.Draw(img)
    status_bar(d)

    # App icon + title
    icon_s = 140
    ix = (W - icon_s) // 2
    rrect(d, [ix, 160, ix+icon_s, 160+icon_s], 24, GD)
    # mic icon (simple)
    mx, my = ix + icon_s//2, 160 + icon_s//2
    d.rounded_rectangle([mx-18, my-36, mx+18, my+20], radius=14, fill=WHITE)
    d.arc([mx-28, my+8, mx+28, my+52], 0, 180, fill=WHITE, width=6)
    d.line([mx, my+52, mx, my+68], fill=WHITE, width=6)
    d.line([mx-20, my+68, mx+20, my+68], fill=WHITE, width=6)

    cx_text(d, "Sesli Tesbih", 320, fnt(72, bold=True), TP)
    cx_text(d, "Select a dhikr and start speaking", 415, fnt(40), TS)

    # + and i buttons
    d.text((W-180, 510), "+", font=fnt(72), fill=GD)
    d.ellipse([W-120, 518, W-76, 562], outline=TS, width=3)
    d.text((W-107, 520), "i", font=fnt(38), fill=TS)

    # separator
    d.line([(40, 585), (W-40, 585)], fill=BORDER, width=2)

    dhikrs = [
        ("Subhanallah",   "Glory be to Allah",               "× 33"),
        ("Alhamdulillah", "All praise is due to Allah",      "× 33"),
        ("Allahu Akbar",  "Allah is the Greatest",           "× 34"),
        ("La ilaha illallah","There is no god but Allah",    "× 100"),
        ("Astaghfirullah","I seek forgiveness from Allah",   "× 100"),
        ("Salawat",       "Blessings upon the Prophet",      "× 100"),
        ("Allah",         "Allah",                           "× 1000"),
        ("HasbunAllah",   "Allah is sufficient for us",      "× 450"),
    ]

    cols, pad = 2, 36
    cw = (W - pad*3) // 2
    ch = 220
    sy = 610
    gap = 18

    for i, (name, desc, count) in enumerate(dhikrs):
        col = i % 2
        row = i // 2
        x0 = pad + col * (cw + pad)
        y0 = sy + row * (ch + gap)
        rrect(d, [x0, y0, x0+cw, y0+ch], 28, WHITE)
        d.text((x0+30, y0+28), name, font=fnt(44, bold=True), fill=TP)
        # wrap desc
        words = desc.split()
        line1 = " ".join(words[:4])
        line2 = " ".join(words[4:]) if len(words) > 4 else ""
        d.text((x0+30, y0+88), line1, font=fnt(30), fill=TS)
        if line2:
            d.text((x0+30, y0+124), line2, font=fnt(30), fill=TS)
        d.text((x0+30, y0+ch-54), count, font=fnt(38, bold=True), fill=GD)

    # Bottom nav bar
    nav_y = H - 180
    d.line([(0, nav_y), (W, nav_y)], fill=BORDER, width=2)
    nav_items = [("Dhikr", True), ("Prayers", False), ("Prayer Times", False), ("Qibla", False)]
    nw = W // len(nav_items)
    for i, (label, active) in enumerate(nav_items):
        nx = i * nw + nw // 2
        color = GD if active else TS
        bb = d.textbbox((0,0), label, font=fnt(34))
        d.text((nx-(bb[2]-bb[0])//2, nav_y+80), label, font=fnt(34), fill=color)
        # icon dot
        d.ellipse([nx-16, nav_y+24, nx+16, nav_y+56],
                  fill=GD if active else None, outline=TS, width=2)

    img.save(os.path.join(OUT, "01_screenshot.png"))
    print("01 done")

# ══════════════════════════════════════════════════════════════════════════════
# 2. Prayer times
# ══════════════════════════════════════════════════════════════════════════════
def make_prayer():
    img = Image.new("RGB", (W, H), BG)
    d   = ImageDraw.Draw(img)
    status_bar(d)

    # Top bar
    d.text((60, 160), "←", font=fnt(64), fill=TP)
    cx_text(d, "Kırklareli", 162, fnt(56, bold=True), TP)
    cx_text(d, "13 May 2026", 232, fnt(40), TS)
    d.line([(40, 300), (W-40, 300)], fill=BORDER, width=2)

    prayers = [
        ("Fajr",    "05:35", True),
        ("Sunrise", "07:09", False),
        ("Dhuhr",   "13:19", False),
        ("Asr",     "16:47", False),
        ("Maghrib", "19:28", True),   # highlighted = next prayer
        ("Isha",    "20:56", False),
    ]

    py = 340
    ph = 240
    gap = 20
    for name, time, highlight in prayers:
        fill = GL if highlight else WHITE
        outline = GD if highlight else None
        rrect(d, [40, py, W-40, py+ph], 28, fill,
              outline=outline, width=4 if highlight else 2)

        fc = GD if highlight else TP
        d.text((90, py+80), name, font=fnt(52, bold=highlight), fill=fc)
        # time right-aligned
        tb = d.textbbox((0,0), time, font=fnt(64, bold=True))
        d.text((W - 90 - (tb[2]-tb[0]), py+72), time,
               font=fnt(64, bold=True), fill=GOLD)
        py += ph + gap

    img.save(os.path.join(OUT, "02_screenshot.png"))
    print("02 done")

# ══════════════════════════════════════════════════════════════════════════════
# 3. Counter screen
# ══════════════════════════════════════════════════════════════════════════════
def make_counter():
    img = Image.new("RGB", (W, H), BG)
    d   = ImageDraw.Draw(img)
    status_bar(d)

    # Top bar
    d.text((60, 160), "←", font=fnt(64), fill=TP)
    for label, tx in [("Count", W-360), ("Reset", W-160)]:
        rrect(d, [tx, 162, tx+160, 222], 30, GL)
        bb = d.textbbox((0,0), label, font=fnt(38))
        d.text((tx+(160-(bb[2]-bb[0]))//2, 175), label, font=fnt(38), fill=GD)

    cx_text(d, "Subhanallah", 340, fnt(72, bold=True), GD)
    cx_text(d, "Glory be to Allah", 440, fnt(42), TS)

    # Counter
    cx_text(d, "11", 820, fnt(340, bold=True), TP)
    cx_text(d, "/ 33", 1170, fnt(72, bold=True), GD)
    cx_text(d, "22 remaining", 1270, fnt(46), TS)

    # Big green button
    br = 260
    bx, by = W//2, 1780
    d.ellipse([bx-br, by-br, bx+br, by+br], fill=GD)
    cx_text(d, "Tap", by-60, fnt(68, bold=True), WHITE)
    cx_text(d, "Count", by+20, fnt(68, bold=True), WHITE)

    # Bottom mic bar
    d.line([(40, H-220), (W-40, H-220)], fill=GD, width=6)
    d.ellipse([60, H-190, 120, H-130], outline=GD, width=3)
    # mic icon small
    d.rounded_rectangle([82, H-184, 98, H-152], radius=6, fill=GD)
    d.text((140, H-188), "Voice detected", font=fnt(44), fill=TS)
    stop_w = 160
    rrect(d, [W-stop_w-40, H-196, W-40, H-136], 20, None)
    d.text((W-stop_w-10, H-192), "Stop", font=fnt(44), fill=GD)

    img.save(os.path.join(OUT, "03_screenshot.png"))
    print("03 done")

# ══════════════════════════════════════════════════════════════════════════════
# 4. Counter + dialog
# ══════════════════════════════════════════════════════════════════════════════
def make_dialog():
    img = Image.new("RGB", (W, H), BG)
    d   = ImageDraw.Draw(img)
    status_bar(d)

    # Same counter bg (dimmed)
    overlay = Image.new("RGBA", (W, H), (0, 0, 0, 120))

    # Redraw counter bg elements dimmed
    d.text((60, 160), "←", font=fnt(64), fill=TS)
    cx_text(d, "Subhanallah", 340, fnt(72, bold=True), TS)
    cx_text(d, "11", 820, fnt(340, bold=True), TS)
    cx_text(d, "/ 33", 1170, fnt(72, bold=True), TS)
    br = 260
    bx, by = W//2, 1780
    d.ellipse([bx-br, by-br, bx+br, by+br], fill=(80, 80, 80))
    cx_text(d, "Tap", by-60, fnt(68, bold=True), (160,160,160))
    cx_text(d, "Count", by+20, fnt(68, bold=True), (160,160,160))

    # dim overlay
    img = img.convert("RGBA")
    img.paste(overlay, (0,0), overlay)
    img = img.convert("RGB")
    d = ImageDraw.Draw(img)

    # Dialog card
    dw, dh = 960, 440
    dx = (W - dw) // 2
    dy = (H - dh) // 2 + 200
    rrect(d, [dx, dy, dx+dw, dy+dh], 28, WHITE)

    d.text((dx+50, dy+50), "Change Target Count", font=fnt(52, bold=True), fill=TP)

    # Input field
    d.text((dx+50, dy+160), "33", font=fnt(58), fill=TP)
    d.line([(dx+50, dy+230), (dx+dw-50, dy+230)], fill=GD, width=3)

    # Buttons
    for label, tx, active in [("CANCEL", dx+480, False), ("ADD", dx+720, True)]:
        bb = d.textbbox((0,0), label, font=fnt(46, bold=True))
        d.text((tx, dy+310), label, font=fnt(46, bold=True),
               fill=GD if active else TS)

    img.save(os.path.join(OUT, "04_screenshot.png"))
    print("04 done")

make_main()
make_prayer()
make_counter()
make_dialog()
print("\nAll done ->", OUT)
