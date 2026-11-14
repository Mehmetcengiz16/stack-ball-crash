# Blender 3D Model Listesi

Genel kurallar (hepsi için geçerli):
- Birim: metre, ölçek 1.0. Blender'da **Apply All Transforms** (Ctrl+A) yap.
- Yukarı yön: Blender'da Z yukarı. glTF dışa aktarımı Godot için otomatik Y yukarı yapar.
- Dışa aktarma: **File > Export > glTF 2.0 (.glb)**. "Apply Modifiers" açık olsun.
- Low-poly ama yumuşak köşeli: **Bevel modifier** (genişlik 0.03–0.05, 2–3 segment) + **Shade Smooth / Auto Smooth**.
- Renkleri kodla değiştirebilmem için halka modellerini beyaz/gri materyalle bırak.
- Dosya adları aşağıdaki gibi olsun; dosyaları `assets/models/` klasörüne koy.

---

## 1. Kule (en önemli)

| # | Dosya | Açıklama | Ölçü |
|---|-------|----------|------|
| 1 | `ring_slice.glb` | Tek halka dilimi (30°'lik pasta dilimi, yuvarlatılmış köşeli blok) | İç yarıçap 0.55, dış yarıçap 2.05, kalınlık 0.46. 0° ile 30° arası (iki yanda ~2° boşluk, yani 2°–28°). Origin = kulenin merkezi (0,0,0), dilimin dikey ortası. |
| 2 | `ring_slice_shard_a.glb` / `_b` / `_c` | Kırılınca savrulan 3 farklı kırık parça (dilimin düzensiz kesilmiş halleri) | Dilimin ~1/3'ü kadar. Origin = parçanın merkezi. |
| 3 | `pole.glb` | Merkez kolon (silindir, üstü yuvarlatılmış) | Yarıçap 0.54, yükseklik 1.0 (kodda boyuna uzatılacak). Origin = merkez. |
| 4 | `finish_platform.glb` | Kulenin dibindeki bitiş diski (kenarı bevel'li, isteğe bağlı üstünde hedef halkası) | Yarıçap 2.2, kalınlık 0.46. |

## 2. Top

| # | Dosya | Açıklama |
|---|-------|----------|
| 5 | `ball.glb` | Pürüzsüz UV küre, yarıçap 0.3, düzgün UV açılımı (desen dokuları için). Tüm top görünümleri bu modeli kullanır. |
| 6 | `ball_crystal.glb` | Kristal top: dikenli/kristal kaplı küre (koleksiyondaki kilitli top). Yarıçap ~0.3. |

Top dokuları (1024×1024 PNG, `assets/textures/balls/`):
`red.png`, `soccer.png`, `blue_stripe.png`, `lava.png`, `galaxy.png`, `gold.png`, `neon.png`, `rainbow.png`, `crystal.png`
(İstersen lav, galaksi ve neon için ayrıca `*_emission.png` parlama dokusu.)

## 3. Efektler

| # | Dosya | Açıklama |
|---|-------|----------|
| 7 | `debris_cube.glb` | Küçük kırık parça (düzensiz küçük taş/blok), ~0.12 boyut. Parçacık efekti için. |
| 8 | `splat_decal.png` | Topun zıpladığı yerde kalan leke (2D doku, şeffaf PNG). |
| 9 | `flame_sprite.png` | Ateş topu alev parçacığı (şeffaf PNG, 256×256). |
| 10 | `spark_sprite.png` | Parlak kıvılcım/yıldız parçacığı (şeffaf PNG, 128×128). |

## 4. Menü / sahne dekorları (isteğe bağlı)

| # | Dosya | Açıklama |
|---|-------|----------|
| 11 | `menu_swirl.glb` | Logo arkasındaki enerji halkası (ince torus/şerit). |
| 12 | `cloud.glb` | Arka plan için yumuşak bulut kümesi (2–3 farklı şekil). |

## 5. Seviye Haritası (isteğe bağlı, şu an 2D çiziliyor)

| # | Dosya | Açıklama |
|---|-------|----------|
| 13 | `island_a.glb` / `island_b.glb` / `island_c.glb` | Yüzen ada: üstü çimen, altı kayalık uçurum. |
| 14 | `tree_pine.glb` | Çam ağacı (low-poly). |
| 15 | `waterfall.glb` | Adadan akan şelale. |
| 16 | `level_node.glb` | Seviye düğümü (yuvarlak, kenarı kalın jeton). |
| 17 | `lock.glb` | Kilitli seviye için küçük kilit. |

---

## Öncelik sırası
1. `ring_slice.glb` → oyunun görünümünü en çok değiştiren model
2. `ball.glb` + top dokuları
3. Kırık parçalar (`ring_slice_shard_*`, `debris_cube`)
4. `pole.glb`, `finish_platform.glb`
5. Efekt sprite'ları
6. Harita ve dekorlar
