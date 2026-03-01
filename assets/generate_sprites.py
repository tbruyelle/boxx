#!/usr/bin/env python3
"""Generate pixel art sprites for Boxx game using Pillow."""

from PIL import Image
import os

ASSETS_DIR = os.path.dirname(os.path.abspath(__file__))
T = (0, 0, 0, 0)  # transparent


def save(img: Image.Image, name: str, scale: int = 1) -> None:
    if scale > 1:
        img = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    path = os.path.join(ASSETS_DIR, name)
    img.save(path)
    print(f"  saved {path} ({img.width}x{img.height})")


def make_player() -> None:
    """16x24 pixel art character - small robot/soldier."""
    print("Generating player sprite...")
    W = 16
    H = 24
    img = Image.new("RGBA", (W, H), T)
    px = img.load()

    # Color palette
    CYAN = (0, 200, 220, 255)
    DARK_CYAN = (0, 140, 160, 255)
    WHITE = (240, 240, 240, 255)
    VISOR = (200, 50, 50, 255)
    SKIN = (220, 180, 140, 255)
    DARK = (40, 40, 50, 255)
    GRAY = (120, 120, 130, 255)
    BOOT = (60, 60, 70, 255)
    GUN = (180, 160, 50, 255)

    # Pixel map rows (y=0 is top)
    rows = [
        # Head (helmet) rows 0-7
        ".....DDDD.......",
        "....DCCCCD......",
        "....DCCCCCD.....",
        "....DCVVVCD.....",
        "....DCVVVCD.....",
        "....DCSSSCD.....",
        ".....DCCCD......",
        "......DDD.......",
        # Body rows 8-15
        ".....CCCCC......",
        "....CCCCCCC.....",
        "...GCCCCCCG.....",
        "...GCCCCCCG.....",
        "...GCCCCCGG.....",
        "....CCCCC.......",
        "....CCCCC.......",
        "....DCCCD.......",
        # Legs rows 16-21
        "....DD.DD.......",
        "....DD.DD.......",
        "...DD...DD......",
        "...DD...DD......",
        "..BBB..BBB......",
        "..BBB..BBB......",
        # padding
        "................",
        "................",
    ]

    palette = {
        '.': T, 'D': DARK, 'C': CYAN, 'V': VISOR,
        'S': SKIN, 'G': GUN, 'B': BOOT, 'W': WHITE,
    }

    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in palette and palette[ch] != T:
                px[x, y] = palette[ch]

    # Add gun on right side
    for y in range(9, 14):
        px[11, y] = GUN
    px[11, 14] = GUN
    px[12, 11] = GUN
    px[12, 12] = GUN
    px[12, 13] = GUN
    px[13, 12] = GUN  # barrel tip

    # Eye shine
    px[7, 3] = WHITE
    px[7, 4] = (255, 100, 100, 255)

    save(img, "player.png", scale=4)


def make_wall() -> None:
    """32x16 tileable brick wall pattern."""
    print("Generating wall sprite...")
    W, H = 32, 16
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    px = img.load()

    BRICK1 = (160, 80, 40, 255)
    BRICK2 = (140, 70, 35, 255)
    BRICK3 = (175, 90, 45, 255)
    MORTAR = (90, 85, 70, 255)

    bricks = [BRICK1, BRICK2, BRICK3]

    # Row pattern: alternating offset bricks
    def draw_brick_row(y_start: int, h: int, offset: int, seed: int) -> None:
        brick_w = 8
        for y in range(y_start, min(y_start + h, H)):
            for x in range(W):
                bx = (x + offset) % W
                in_mortar_v = (bx % brick_w == 0)
                in_mortar_h = (y == y_start)
                if in_mortar_v or in_mortar_h:
                    px[x, y] = MORTAR
                else:
                    brick_idx = ((bx // brick_w) + seed) % len(bricks)
                    c = bricks[brick_idx]
                    # Add slight variation
                    noise = ((x * 7 + y * 13) % 5) - 2
                    px[x, y] = (c[0] + noise, c[1] + noise, c[2] + noise, 255)

    draw_brick_row(0, 4, 0, 0)
    draw_brick_row(4, 4, 4, 1)
    draw_brick_row(8, 4, 0, 2)
    draw_brick_row(12, 4, 4, 0)

    save(img, "wall.png", scale=4)


def make_monster() -> None:
    """16x16 pixel art monster - angry slime/demon."""
    print("Generating monster sprite...")
    W, H = 16, 16
    img = Image.new("RGBA", (W, H), T)
    px = img.load()

    RED = (200, 40, 40, 255)
    DARK_RED = (140, 20, 20, 255)
    LIGHT_RED = (230, 80, 60, 255)
    WHITE = (240, 240, 240, 255)
    BLACK = (20, 20, 20, 255)
    YELLOW = (240, 220, 50, 255)
    MOUTH = (80, 10, 10, 255)

    rows = [
        ".....RRRRRR.....",  # 0 - top horns
        "...DRRRRRRRD....",  # 1
        "...DRRLRRRLRD...",  # 2 - horns
        "..DRRRRRRRRRD...",  # 3
        "..DRRRRRRRRRRD..",  # 4
        "..DRWBRRWBRRRD..",  # 5 - eyes
        "..DRWBRRWBRRRD..",  # 6
        "..DRRRRRRRRRD...",  # 7
        "..DRMRMRMRMRD...",  # 8 - teeth
        "...DRRRRRRRRD...",  # 9 - mouth
        "...DRRRRRRRD....",  # 10
        "....DRRRRRRD....",  # 11
        "....DRRRRRD.....",  # 12
        ".....DRRRD......",  # 13
        ".....DRRRD......",  # 14
        "......DDD.......",  # 15
    ]

    palette = {
        '.': T, 'R': RED, 'D': DARK_RED, 'L': LIGHT_RED,
        'W': WHITE, 'B': BLACK, 'Y': YELLOW, 'M': MOUTH,
    }

    for y, row in enumerate(rows):
        for x, ch in enumerate(row):
            if ch in palette and palette[ch] != T:
                px[x, y] = palette[ch]

    # Yellow eyes highlight
    px[5, 5] = YELLOW
    px[9, 5] = YELLOW

    save(img, "monster.png", scale=4)


def _make_cobblestone(tint: tuple = (0, 0, 0)) -> Image.Image:
    """Create a 16x16 cobblestone tile with mortar, cracks, and color tint."""
    W, H = 16, 16
    img = Image.new("RGBA", (W, H), (0, 0, 0, 255))
    px = img.load()

    # Stone map: each char = a different stone ID, '.' = mortar
    stones = [
        "AAA.BBB.CCCC.DDD",  # row 0 intentionally 17 chars, trimmed below
        "AAA.BBB.CCCC.DDD",
        "AAA.BBB.CCCC.DDD",
        "................",
        "EEE.FFFFF.GG.HHH",
        "EEE.FFFFF.GG.HHH",
        "EEE.FFFFF.GG.HHH",
        "EEE.FFFFF.GG.HHH",
        "................",
        "II.JJJJ.KKK.LLLL",
        "II.JJJJ.KKK.LLLL",
        "II.JJJJ.KKK.LLLL",
        "................",
        "MMMM.NNN.OO.PPPP",
        "MMMM.NNN.OO.PPPP",
        "MMMM.NNN.OO.PPPP",
    ]

    # Each stone gets a slightly different base brightness
    stone_brightness = {
        'A': 180, 'B': 170, 'C': 190, 'D': 175,
        'E': 185, 'F': 165, 'G': 195, 'H': 172,
        'I': 178, 'J': 188, 'K': 168, 'L': 182,
        'M': 174, 'N': 192, 'O': 186, 'P': 170,
    }
    mortar_base = 100

    for y in range(H):
        row = stones[y]
        for x in range(W):
            if x >= len(row):
                ch = row[-1]
            else:
                ch = row[x]

            if ch == '.':
                noise = ((x * 3 + y * 7) % 5) - 2
                v = mortar_base + noise
                r = max(0, min(255, v + tint[0] // 4))
                g = max(0, min(255, v + tint[1] // 4))
                b = max(0, min(255, v + tint[2] // 4))
                px[x, y] = (r, g, b, 255)
            else:
                base = stone_brightness.get(ch, 180)
                # Per-pixel noise for texture
                noise = ((x * 13 + y * 7 + x * y * 3) % 11) - 5
                v = base + noise
                r = max(0, min(255, v + tint[0]))
                g = max(0, min(255, v + tint[1]))
                b = max(0, min(255, v + tint[2]))
                px[x, y] = (r, g, b, 255)

    # Highlight top edge of each stone (light)
    for y in range(H):
        row = stones[y]
        for x in range(W):
            if x >= len(row):
                continue
            ch = row[x]
            if ch == '.':
                continue
            above_ch = stones[y - 1][x] if y > 0 and x < len(stones[y - 1]) else '.'
            if above_ch == '.':
                r, g, b, _ = px[x, y]
                px[x, y] = (min(255, r + 25), min(255, g + 25), min(255, b + 25), 255)

    # Shadow bottom edge of each stone (dark)
    for y in range(H):
        row = stones[y]
        for x in range(W):
            if x >= len(row):
                continue
            ch = row[x]
            if ch == '.':
                continue
            below_ch = stones[y + 1][x] if y < H - 1 and x < len(stones[y + 1]) else '.'
            if below_ch == '.':
                r, g, b, _ = px[x, y]
                px[x, y] = (max(0, r - 20), max(0, g - 20), max(0, b - 20), 255)

    return img


def _add_cracks(px, W: int, H: int) -> None:
    """Add subtle diagonal cracks to a tile."""
    crack = (60, 55, 50, 255)
    # Diagonal crack from top-left area
    px[3, 2] = crack
    px[4, 3] = crack
    px[5, 4] = crack
    px[5, 5] = crack
    px[6, 6] = crack
    # Small chip
    px[11, 10] = crack
    px[12, 11] = crack


def make_cells() -> None:
    """Generate cell tile textures for each bonus type."""
    print("Generating cell sprites...")

    # --- NONE (gray stone) ---
    img = _make_cobblestone(tint=(0, 0, 0))
    _add_cracks(img.load(), 16, 16)
    save(img, "cell_gray.png", scale=4)

    # --- FIRE_RATE_X2 (green) ---
    img = _make_cobblestone(tint=(-60, 50, -60))
    save(img, "cell_green.png", scale=4)

    # --- FIRE_RATE_HALF (red) ---
    img = _make_cobblestone(tint=(50, -60, -60))
    save(img, "cell_red.png", scale=4)

    # --- BULLETS_PLUS_10 (blue) ---
    img = _make_cobblestone(tint=(-60, -30, 60))
    save(img, "cell_blue.png", scale=4)


if __name__ == "__main__":
    make_player()
    make_wall()
    make_monster()
    make_cells()
    print("Done!")
