"""Top desen dokularını (equirectangular, Godot SphereMesh UV'sine uygun) üretir.
Çalıştır: python tools/gen_ball_textures.py"""
import numpy as np
from PIL import Image
import os

W, H = 1024, 512
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "textures", "balls")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)

u = (np.arange(W) + 0.5) / W
v = (np.arange(H) + 0.5) / H
U, V = np.meshgrid(u, v)
lon = U * 2 * np.pi
lat = (0.5 - V) * np.pi
D = np.stack([np.cos(lat) * np.sin(lon), np.sin(lat), np.cos(lat) * np.cos(lon)], -1)  # birim yön


def save(name, rgb):
    Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8), "RGB").save(os.path.join(OUT, name + ".png"))


def col(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)])


def mix(a, b, t):
    return a * (1 - t[..., None]) + b * t[..., None]


def noise(scale, octaves=4, seed=0):
    """Küre üzerinde dikişsiz değer gürültüsü (rastgele dalgaların toplamı)."""
    r = np.random.default_rng(seed)
    out = np.zeros((H, W))
    amp = 1.0
    for o in range(octaves):
        for _ in range(6):
            k = r.normal(size=3)
            k /= np.linalg.norm(k)
            out += amp * np.sin((D @ k) * scale * (2 ** o) + r.uniform(0, 6.28))
        amp *= 0.5
    out -= out.min()
    return out / out.max()


def voronoi(points):
    """Her piksel için en yakın ve ikinci en yakın noktaya açısal mesafe."""
    dots = np.einsum("hwc,nc->hwn", D, points)
    s = np.sort(dots, -1)
    d1 = np.arccos(np.clip(s[..., -1], -1, 1))
    d2 = np.arccos(np.clip(s[..., -2], -1, 1))
    return d1, d2, np.argmax(dots, -1)


def rand_points(n, seed):
    p = np.random.default_rng(seed).normal(size=(n, 3))
    return p / np.linalg.norm(p, axis=1, keepdims=True)


shade = 0.88 + 0.12 * noise(3, 2, 99)

# 1) Kırmızı
save("red", col("e8213a") * shade[..., None])

# 2) Futbol: 12 siyah beşgen (ikosahedron köşeleri) + 20 beyaz altıgen
g = (1 + 5 ** 0.5) / 2
ico = np.array([[-1, g, 0], [1, g, 0], [-1, -g, 0], [1, -g, 0], [0, -1, g], [0, 1, g], [0, -1, -g], [0, 1, -g], [g, 0, -1], [g, 0, 1], [-g, 0, -1], [-g, 0, 1]], float)
ico /= np.linalg.norm(ico, axis=1, keepdims=True)
faces = []
for i in range(12):
    for j in range(i + 1, 12):
        for k in range(j + 1, 12):
            if all(np.dot(ico[a], ico[b]) > 0.4 for a, b in [(i, j), (j, k), (i, k)]):
                c = ico[i] + ico[j] + ico[k]
                faces.append(c / np.linalg.norm(c))
allp = np.vstack([ico, np.array(faces)])
d1, d2, idx = voronoi(allp)
rgb = np.ones((H, W, 3)) * 0.96
rgb[idx < 12] = col("1e1e1e")
seam = (d2 - d1) < 0.025
rgb[seam] = col("8a8a8a")
save("soccer", rgb * shade[..., None])

# 3) Çizgili mavi
y = D[..., 1]
rgb = np.tile(col("1f8bff"), (H, W, 1))
rgb[np.abs(y - 0.05) < 0.16] = col("8fd0ff")
rgb[np.abs(y + 0.45) < 0.07] = col("0b4fb8")
rgb[np.abs(y - 0.55) < 0.06] = col("0b4fb8")
save("blue_stripe", rgb * shade[..., None])

# 4) Lav: koyu kaya + parlayan çatlaklar
d1, d2, _ = voronoi(rand_points(60, 3))
edge = np.clip(1 - (d2 - d1) / 0.06, 0, 1) ** 2
n = noise(6, 3, 4)
rock = mix(col("1a0703"), col("4a1408"), n)
glow = mix(col("ff3d00"), col("ffd23f"), edge)
rgb = mix(rock, glow, np.clip(edge * 1.4, 0, 1))
save("lava", rgb)
save("lava_emission", glow * np.clip(edge * 1.4, 0, 1)[..., None])

# 5) Galaksi
n1, n2 = noise(4, 4, 11), noise(5, 4, 12)
rgb = mix(col("140838"), col("6a1fd0"), n1 ** 1.5)
rgb = mix(rgb, col("ff4fd8"), np.clip((n2 - 0.6) * 2.5, 0, 1))
rgb = mix(rgb, col("5fd0ff"), np.clip((n1 - 0.75) * 3, 0, 1))
stars = np.zeros((H, W))
sx, sy = rng.integers(0, W, 500), rng.integers(10, H - 10, 500)
stars[sy, sx] = 1
stars[sy, (sx + 1) % W] = 0.6
rgb = np.maximum(rgb, stars[..., None])
save("galaxy", rgb)
save("galaxy_emission", rgb * 0.6)

# 6) Altın: ayna karolar
tiles_u, tiles_v = (U * 32) % 1, (V * 16) % 1
line = (np.minimum(tiles_u, 1 - tiles_u) < 0.06) | (np.minimum(tiles_v, 1 - tiles_v) < 0.06)
tile_shade = np.random.default_rng(5).uniform(0.75, 1.1, (16, 32))[(V * 16).astype(int) % 16, (U * 32).astype(int) % 32]
rgb = col("ffc21f") * tile_shade[..., None]
rgb[line] = col("b8790a")
save("gold", rgb)

# 7) Neon: koyu zemin + camgöbeği altıgen ağı
d1, d2, _ = voronoi(rand_points(80, 21))
edge = np.clip(1 - (d2 - d1) / 0.035, 0, 1)
rgb = mix(col("062a33"), col("3ff3ff"), edge)
save("neon", rgb)
save("neon_emission", col("3ff3ff") * edge[..., None])

# 8) Gökkuşağı
bands = [col(c) for c in ["ff3b3b", "ff9a1f", "ffe03f", "5fd61f", "2fb7ff", "9b4dff"]]
bi = np.clip(((y + 1) / 2 * 6).astype(int), 0, 5)
rgb = np.array(bands)[5 - bi]
save("rainbow", rgb * shade[..., None])

# 9) Kristal
n = noise(7, 3, 31)
d1, d2, _ = voronoi(rand_points(50, 8))
facet = np.clip(1 - (d2 - d1) / 0.03, 0, 1)
rgb = mix(col("6fb4ff"), col("e6f4ff"), n * 0.7 + facet * 0.5)
save("crystal", rgb)

print("ok:", sorted(os.listdir(OUT)))
