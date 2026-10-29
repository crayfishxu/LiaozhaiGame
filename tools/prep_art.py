#!/usr/bin/env python3
"""把 ImageGen 出的原图处理成游戏用的美术资源。

两种产物：

  敌人立绘  art/enemies/{key}.png     528x688 RGBA，背景透明
  卡面      art/cards/{key}_{xian,ben}.png  240x179 RGBA，四边羽化

原图放 art/_gen/raw/（敌人用 art/_gen/raw/enemy_{key}.png，
卡面用 art/_gen/raw/{key}.png）。

背景去除用「从边界泛洪」而不是全局阈值：现有 4 张敌人立绘只有 1 块透明区域、
内部空洞为 0，说明当初就是这么做的——墨画里衣袍缝隙的白要留着，
否则人像会变成碎块。

用法：
    python tools/prep_art.py enemy kugu
    python tools/prep_art.py card yichu
    python tools/prep_art.py all
"""

from __future__ import annotations

import glob
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW = os.path.join(ROOT, "art", "_gen", "raw")
OUT_ENEMY = os.path.join(ROOT, "art", "enemies")
OUT_CARD = os.path.join(ROOT, "art", "cards")

ENEMY_SIZE = (528, 688)
CARD_SIZE = (240, 179)

# 本相 = 显相同一张图调色，系数从现有 17 张反推（R 0.947/-6.4  G 0.712/-4.3  B 0.685/-3.1）
BEN_GRADE = [(0.947, -6.4), (0.712, -4.3), (0.685, -3.1)]


def _paper_color(a: np.ndarray) -> np.ndarray:
    b = np.concatenate([
        a[0:6].reshape(-1, 3), a[-6:].reshape(-1, 3),
        a[:, 0:6].reshape(-1, 3), a[:, -6:].reshape(-1, 3),
    ])
    return np.median(b, axis=0)


def _erase_watermark(a: np.ndarray, paper: np.ndarray) -> np.ndarray:
    """右下角的水印：把那一横条用上方的像素覆写掉。

    水印是白色描边字，压在纸面和墨晕上，直接涂纸色会在阴影里留一块白斑，
    所以整条上移复制——上面那一带同样只有纸和墨晕，接得上。
    """
    h, w, _ = a.shape
    x0, y0 = int(w * 0.78), int(h * 0.935)
    shift = max(24, int(h * 0.035))
    a[y0:, x0:] = a[y0 - shift:h - shift, x0:]
    return a


def _feather(alpha: np.ndarray, radius: float) -> np.ndarray:
    img = Image.fromarray(alpha)
    img = img.filter(ImageFilter.GaussianBlur(radius))
    return np.array(img)


def prep_enemy(key: str) -> str:
    src = os.path.join(RAW, f"enemy_{key}.png")
    if not os.path.exists(src):
        cand = glob.glob(os.path.join(RAW, f"{key}*.png"))
        if not cand:
            raise FileNotFoundError(src)
        src = cand[0]

    im = Image.open(src).convert("RGB")
    a = np.array(im).astype(np.int16)
    paper = _paper_color(a)
    a = _erase_watermark(a, paper)

    # 与纸张的色差 → 透明度。
    # 不能用「从边界泛洪」：剑和袍子围出来的那块纸不与边界连通，
    # 泛洪会留下一大块白斑（第一版就是这么翻车的）。
    # 也不能一刀切硬阈值：骨头的亮部会被打穿。做成两段软过渡。
    dist = np.abs(a.astype(np.float32) - paper).max(axis=2)
    alpha = np.clip((dist - 8.0) / (24.0 - 8.0), 0.0, 1.0) * 255.0
    alpha = alpha.astype(np.uint8)

    # 主体包围盒之外的小块（右下角水印残渣）清掉
    solid = alpha > 40
    sl, sn = ndimage.label(solid)
    if sn > 1:
        sizes = ndimage.sum(solid, sl, range(1, sn + 1))
        main = int(np.argmax(sizes)) + 1
        ys, xs = np.where(sl == main)
        h, w = solid.shape
        mx0, mx1 = xs.min() - int(w * 0.03), xs.max() + int(w * 0.03)
        my0, my1 = ys.min() - int(h * 0.03), ys.max() + int(h * 0.03)
        boxes = ndimage.find_objects(sl)
        drop = []
        for i, s in enumerate(boxes, start=1):
            if i == main or s is None:
                continue
            cy = (s[0].start + s[0].stop) // 2
            cx = (s[1].start + s[1].stop) // 2
            if not (mx0 <= cx <= mx1 and my0 <= cy <= my1):
                drop.append(i)
        if drop:
            alpha[np.isin(sl, drop)] = 0

    alpha = _feather(alpha, 0.6)

    # 纸纹噪点：半透明的碎屑全清掉，否则深色背景上会看到一层灰雪
    alpha[alpha < 30] = 0
    tl, tn = ndimage.label(alpha > 0)
    if tn:
        ts = ndimage.sum(alpha > 0, tl, range(1, tn + 1))
        small = np.where(ts < 24)[0] + 1
        if small.size:
            alpha[np.isin(tl, small)] = 0

    rgba = np.dstack([np.array(im), alpha])
    out = Image.fromarray(rgba, "RGBA")

    # 裁到内容，再等比缩放进 528x688 画布
    bbox = out.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    if bbox:
        out = out.crop(bbox)
    ow, oh = out.size
    scale = min(ENEMY_SIZE[0] / ow, ENEMY_SIZE[1] / oh)
    nw, nh = max(1, int(ow * scale)), max(1, int(oh * scale))
    out = out.resize((nw, nh), Image.LANCZOS)

    canvas = Image.new("RGBA", ENEMY_SIZE, (0, 0, 0, 0))
    canvas.paste(out, ((ENEMY_SIZE[0] - nw) // 2, ENEMY_SIZE[1] - nh))
    dst = os.path.join(OUT_ENEMY, f"{key}.png")
    canvas.save(dst)
    return dst


def _card_mask(size: tuple[int, int], feather: int = 9, radius: int = 8) -> Image.Image:
    w, h = size
    big = Image.new("L", (w * 4, h * 4), 0)
    d = ImageDraw.Draw(big)
    d.rounded_rectangle([feather * 4, feather * 4, w * 4 - feather * 4, h * 4 - feather * 4],
                        radius=radius * 4, fill=255)
    big = big.resize((w, h), Image.LANCZOS).filter(ImageFilter.GaussianBlur(2.2))
    return big


def prep_card(key: str) -> list[str]:
    src = os.path.join(RAW, f"{key}.png")
    if not os.path.exists(src):
        cand = glob.glob(os.path.join(RAW, f"{key}*.png"))
        if not cand:
            raise FileNotFoundError(src)
        src = cand[0]

    im = Image.open(src).convert("RGB")
    w, h = im.size
    ar = CARD_SIZE[0] / CARD_SIZE[1]
    if w / h > ar:
        nw = int(h * ar)
        im = im.crop(((w - nw) // 2, 0, (w - nw) // 2 + nw, h))
    else:
        nh = int(w / ar)
        im = im.crop((0, (h - nh) // 2, w, (h - nh) // 2 + nh))
    im = im.resize(CARD_SIZE, Image.LANCZOS)

    # 统一压暗一点，和现有卡面的墨色对齐
    a = np.array(im).astype(np.float32) * 0.94
    a = np.clip(a, 0, 255).astype(np.uint8)
    base = Image.fromarray(a, "RGB").convert("RGBA")
    base.putalpha(_card_mask(CARD_SIZE))

    out = []
    xian = os.path.join(OUT_CARD, f"{key}_xian.png")
    base.save(xian)
    out.append(xian)

    ch = np.array(base).astype(np.float32)
    for c, (k, b) in enumerate(BEN_GRADE):
        ch[:, :, c] = np.clip(ch[:, :, c] * k + b, 0, 255)
    ben = os.path.join(OUT_CARD, f"{key}_ben.png")
    Image.fromarray(ch.astype(np.uint8), "RGBA").save(ben)
    out.append(ben)
    return out


def main() -> None:
    if len(sys.argv) < 2:
        print(__doc__)
        return
    mode = sys.argv[1]
    keys = sys.argv[2:]
    if mode == "all":
        for p in sorted(glob.glob(os.path.join(RAW, "enemy_*.png"))):
            k = os.path.basename(p)[6:-4]
            print("enemy", prep_enemy(k))
        for p in sorted(glob.glob(os.path.join(RAW, "*.png"))):
            k = os.path.basename(p)[:-4]
            if k.startswith("enemy_") or k.startswith("_"):
                continue
            print("card ", " ".join(prep_card(k)))
        return
    fn = prep_enemy if mode == "enemy" else prep_card
    for k in keys:
        print(mode, k, fn(k))


if __name__ == "__main__":
    main()
