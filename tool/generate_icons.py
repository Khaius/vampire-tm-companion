#!/usr/bin/env python3
"""Genera le icone dell'app (Android + iOS) partendo dalla geometria del d10.

Serve solo se si vuole rigenerare la grafica: i PNG prodotti sono gia'
versionati nel repository.

    pip install pillow
    python3 tool/generate_icons.py
"""

import os
from PIL import Image, ImageDraw

SS = 4  # supersampling: si disegna in grande e si riduce con LANCZOS

NIGHT = (13, 10, 11)
BLOOD_GLOW = (196, 46, 40)

# Geometria del dado in coordinate 0..48 (la stessa degli asset SVG).
FACES = [
    ([(13.9, 23.2), (24, 30.6), (24, 44.4), (9.8, 33.4)], (52, 14, 17), (26, 7, 9)),
    ([(34.1, 23.2), (24, 30.6), (24, 44.4), (38.2, 33.4)], (46, 12, 15), (22, 6, 8)),
    ([(5.6, 18.8), (13.9, 23.2), (9.8, 33.4)], (38, 11, 14), (20, 5, 7)),
    ([(42.4, 18.8), (34.1, 23.2), (38.2, 33.4)], (34, 10, 13), (18, 5, 6)),
    ([(24, 3.6), (13.9, 23.2), (5.6, 18.8)], (94, 26, 29), (52, 14, 17)),
    ([(24, 3.6), (34.1, 23.2), (42.4, 18.8)], (104, 27, 30), (58, 15, 18)),
    ([(24, 3.6), (13.9, 23.2), (24, 30.6), (34.1, 23.2)], (134, 36, 36), (58, 15, 18)),
]

INNER_EDGES = [
    [(24, 3.6), (13.9, 23.2)],
    [(24, 3.6), (34.1, 23.2)],
    [(13.9, 23.2), (24, 30.6)],
    [(34.1, 23.2), (24, 30.6)],
    [(5.6, 18.8), (13.9, 23.2)],
    [(42.4, 18.8), (34.1, 23.2)],
    [(13.9, 23.2), (9.8, 33.4)],
    [(34.1, 23.2), (38.2, 33.4)],
    [(24, 30.6), (24, 44.4)],
]

OUTLINE = [(24, 3.6), (42.4, 18.8), (38.2, 33.4), (24, 44.4), (9.8, 33.4), (5.6, 18.8)]


def _lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3))


def _glow_layer(size, strength=0.30):
    """Alone di sangue dietro al dado, su livello separato e poi composito."""
    layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer)
    c = size / 2
    rmax = size * 0.54
    steps = 120
    # dal cerchio piu' grande al piu' piccolo: ogni passo sovrascrive
    # l'interno con un'opacita' maggiore, ottenendo la sfumatura radiale.
    for i in range(steps, 0, -1):
        t = i / steps
        r = rmax * t
        alpha = int(255 * strength * (1 - t) ** 1.6)
        if alpha <= 0:
            continue
        draw.ellipse([c - r, c - r, c + r, c + r], fill=BLOOD_GLOW + (alpha,))
    return layer


def make_icon(size, background=True, inset=0.80):
    """Disegna l'icona. `inset` regola quanto il dado riempie la tela:
    le icone adattive Android vogliono il soggetto nel 66% centrale."""
    w = size * SS
    if background:
        img = Image.new("RGBA", (w, w), NIGHT + (255,))
        img = Image.alpha_composite(img, _glow_layer(w))
    else:
        img = Image.new("RGBA", (w, w), (0, 0, 0, 0))
        img = Image.alpha_composite(img, _glow_layer(w, strength=0.22))

    draw = ImageDraw.Draw(img)
    scale = (w / 48) * inset
    ox = w / 2 - 24 * scale
    oy = w / 2 - 24 * scale

    def project(points):
        return [(ox + x * scale, oy + y * scale) for x, y in points]

    for points, top, bottom in FACES:
        poly = project(points)
        ys = [p[1] for p in poly]
        y0, y1 = min(ys), max(ys)
        band = Image.new("RGBA", (w, w), (0, 0, 0, 0))
        band_draw = ImageDraw.Draw(band)
        height = max(1, int(y1 - y0))
        for row in range(height):
            band_draw.line(
                [(0, y0 + row), (w, y0 + row)],
                fill=_lerp(top, bottom, row / height) + (255,),
            )
        mask = Image.new("L", (w, w), 0)
        ImageDraw.Draw(mask).polygon(poly, fill=255)
        img.paste(band, (0, 0), mask)

    edge = max(1, int(w * 0.0042))
    for segment in INNER_EDGES:
        draw.line(project(segment), fill=(228, 216, 196, 150), width=edge)
    draw.line(
        project(OUTLINE + [OUTLINE[0]]),
        fill=(239, 228, 210, 235),
        width=int(edge * 1.7),
    )

    return img.resize((size, size), Image.LANCZOS)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(root)

    android = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
    for name, px in android.items():
        path = f"android/app/src/main/res/mipmap-{name}/ic_launcher.png"
        os.makedirs(os.path.dirname(path), exist_ok=True)
        make_icon(px).save(path)
        print("android", name, px)

    adaptive = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324, "xxxhdpi": 432}
    for name, px in adaptive.items():
        path = f"android/app/src/main/res/mipmap-{name}/ic_launcher_foreground.png"
        make_icon(px, background=False, inset=0.52).save(path)
        print("adaptive", name, px)

    ios_icons = {
        "Icon-App-20x20@1x.png": 20,
        "Icon-App-20x20@2x.png": 40,
        "Icon-App-20x20@3x.png": 60,
        "Icon-App-29x29@1x.png": 29,
        "Icon-App-29x29@2x.png": 58,
        "Icon-App-29x29@3x.png": 87,
        "Icon-App-40x40@1x.png": 40,
        "Icon-App-40x40@2x.png": 80,
        "Icon-App-40x40@3x.png": 120,
        "Icon-App-60x60@2x.png": 120,
        "Icon-App-60x60@3x.png": 180,
        "Icon-App-76x76@1x.png": 76,
        "Icon-App-76x76@2x.png": 152,
        "Icon-App-83.5x83.5@2x.png": 167,
        "Icon-App-1024x1024@1x.png": 1024,
    }
    for name, px in ios_icons.items():
        path = f"ios/Runner/Assets.xcassets/AppIcon.appiconset/{name}"
        if os.path.isdir(os.path.dirname(path)):
            make_icon(px).convert("RGB").save(path)
    print("ios", len(ios_icons))

    make_icon(512).save("assets/icons/app_icon.png")
    print("ok")


if __name__ == "__main__":
    main()
