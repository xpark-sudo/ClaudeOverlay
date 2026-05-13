#!/usr/bin/env python3
"""Generate AppIcon.icns for ClaudeOverlay from scratch using Pillow."""
import os, sys, struct, math
from PIL import Image, ImageDraw, ImageFont

OUT_DIR = sys.argv[1] if len(sys.argv) > 1 else "Sources/Resources"
ICONSET = os.path.join(OUT_DIR, "AppIcon.iconset")
ICNS = os.path.join(OUT_DIR, "AppIcon.icns")

PURPLE = (153, 51, 230)
BLUE = (51, 102, 255)
BG = (25, 25, 30)

SIZES = {
    "icon_16x16.png": 16,
    "icon_16x16@2x.png": 32,
    "icon_32x32.png": 32,
    "icon_32x32@2x.png": 64,
    "icon_128x128.png": 128,
    "icon_128x128@2x.png": 256,
    "icon_256x256.png": 256,
    "icon_256x256@2x.png": 512,
    "icon_512x512.png": 512,
    "icon_512x512@2x.png": 1024,
}


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def make_icon(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Rounded rect background with gradient
    radius = size / 5
    # Draw gradient by drawing thin rounded rectangles
    for y in range(size):
        t = y / size
        color = lerp(PURPLE, BLUE, t)
        # horizontal gradient within each row
        for x in range(size):
            tx = (x / size + t) / 2  # blend top-left to bottom-right
            c = lerp(PURPLE, BLUE, tx)
            d.point((x, y), fill=c + (255,))

    # Mask to rounded rect
    mask = Image.new("L", (size, size), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([0, 0, size - 1, size - 1], radius=int(radius), fill=255)
    img.putalpha(mask)

    # Text "CC"
    font_size = int(size * 0.42)
    try:
        font = ImageFont.truetype("/System/Library/Fonts/SFNSRounded.ttf", font_size)
    except (IOError, OSError):
        try:
            font = ImageFont.truetype("/System/Library/Fonts/SFNSText.ttf", font_size)
        except (IOError, OSError):
            font = ImageFont.load_default()

    bbox = d.textbbox((0, 0), "CC", font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    tx = (size - tw) / 2 - bbox[0]
    ty = (size - th) / 2 - bbox[1]

    # Draw text onto a new layer for alpha
    txt_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    td = ImageDraw.Draw(txt_layer)
    td.text((tx, ty), "CC", fill=(255, 255, 255, 255), font=font)
    img = Image.alpha_composite(img, txt_layer)

    return img


def build_icns(png_path, output_path):
    """Pack a single 1024x1024 PNG into a minimal .icns using ic07-ic13 entries."""
    from io import BytesIO
    img = Image.open(png_path)
    assert img.size == (1024, 1024)

    icons = []
    for code, size in [("ic07", 128), ("ic08", 256), ("ic09", 512), ("ic10", 1024), ("ic13", 1024)]:
        if size != img.size[0]:
            r = img.resize((size, size), Image.LANCZOS)
        else:
            r = img
        buf = BytesIO()
        r.save(buf, format="PNG")
        icons.append((code, buf.getvalue()))

    # Build icns
    out = bytearray()
    out.extend(b"icns")
    # Placeholder for total size
    total_size = 8
    entries = []
    for code, data in icons:
        entry_size = 8 + len(data)
        entries.append(struct.pack(">4sI", code.encode(), entry_size) + data)
        total_size += entry_size

    out[4:8] = struct.pack(">I", total_size)
    for e in entries:
        out.extend(e)

    with open(output_path, "wb") as f:
        f.write(bytes(out))


def main():
    os.makedirs(ICONSET, exist_ok=True)

    for fname, sz in SIZES.items():
        img = make_icon(sz)
        path = os.path.join(ICONSET, fname)
        img.save(path, "PNG")

    # Also generate icns directly from the 1024 px image
    build_icns(os.path.join(ICONSET, "icon_512x512@2x.png"), ICNS)

    # Set permissions
    for fname in SIZES:
        os.chmod(os.path.join(ICONSET, fname), 0o644)
    os.chmod(ICNS, 0o644)

    # Verify
    for fname in SIZES:
        p = os.path.join(ICONSET, fname)
        img = Image.open(p)
        assert img.size == (SIZES[fname], SIZES[fname]), f"{fname} size mismatch: {img.size}"
    print(f"Generated {len(SIZES)} icons + {ICNS}")


if __name__ == "__main__":
    main()
