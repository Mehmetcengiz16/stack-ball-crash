"""Efekt sprite'ları (şeffaf PNG): leke, alev, kıvılcım. Çalıştır: python tools/gen_fx_sprites.py"""
import numpy as np
from PIL import Image
import os

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures", "fx")
os.makedirs(OUT, exist_ok=True)


def grid(n):
    c = (np.arange(n) + 0.5) / n * 2 - 1
    return np.meshgrid(c, c)


def save(name, rgba):
    Image.fromarray((np.clip(rgba, 0, 1) * 255).astype(np.uint8)).save(os.path.join(OUT, name + ".png"))


# Leke: düzensiz kenarlı yuvarlak + sıçrama damlaları (beyaz, kodda renklenir)
n = 256
X, Y = grid(n)
r = np.hypot(X, Y)
a = np.arctan2(Y, X)
rng = np.random.default_rng(3)
edge = 0.55 + 0.06 * np.sin(a * 7 + 1) + 0.04 * np.sin(a * 13 + 2)
alpha = np.clip((edge - r) * 30, 0, 1)
for _ in range(9):
    ang = rng.uniform(0, 6.28)
    d = rng.uniform(0.68, 0.9)
    cx, cy, rad = np.cos(ang) * d, np.sin(ang) * d, rng.uniform(0.04, 0.09)
    alpha = np.maximum(alpha, np.clip((rad - np.hypot(X - cx, Y - cy)) * 60, 0, 1))
save("splat", np.dstack([np.ones_like(X)] * 3 + [alpha]))

# Alev: aşağıdan yukarı sivrilen damla, sıcak renk gradyanı
X, Y = grid(256)
yy = (Y + 1) / 2  # 0 üst, 1 alt
width = 0.15 + 0.55 * np.clip(yy, 0, 1) ** 0.7
shape = np.clip(1 - np.abs(X) / np.maximum(width, 1e-3), 0, 1) * np.clip((1 - yy) * 1.2 + 0.2, 0, 1) * np.clip((0.95 - yy) * 8, 0, 1)
core = shape ** 0.6
col = np.dstack([np.ones_like(X), 0.25 + 0.75 * core, 0.05 + 0.6 * core ** 3])
save("flame", np.dstack([col, shape ** 0.8]))

# Kıvılcım: 4 kollu parıltı + yumuşak hale
X, Y = grid(128)
r = np.hypot(X, Y)
glow = np.exp(-r * r * 12)
rays = np.exp(-np.abs(X) * 40) * np.exp(-np.abs(Y) * 3) + np.exp(-np.abs(Y) * 40) * np.exp(-np.abs(X) * 3)
alpha = np.clip(glow + rays, 0, 1)
save("spark", np.dstack([np.ones_like(X), np.ones_like(X), 0.85 + 0.15 * glow, alpha]))
print("ok", os.listdir(OUT))
