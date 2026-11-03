// GABAN 瓶スパイス (φ35 寸胴) 用の位置決めプレート
// 底面にマグネットを埋めて鉄板のスパイスラックに貼り付ける。
//
// 1 マス = pitch 角のグリッド規格。cols × rows マスのユニットを並べて使う
// (例: 1×1 を必要数、1×3 で短手 120mm に 3 本、など)。
// 別サイズの瓶用を作るときも pitch の倍数で外形を揃えれば混ぜて並べられる。
//
// 印刷: 天面 (くぼみ側) を上にしてそのまま。マグネット穴は底面から開いているので
// サポート不要。印刷後にマグネットを圧入する (極性を全ユニットで揃えること)。
include <BOSL2/std.scad>
include <printer.scad>

/* [Layout] */
cols = 1;  // X 方向のマス数
rows = 1;  // Y 方向のマス数

/* [Grid standard] */
pitch = 40;   // 1 マスの寸法 [mm]。ユニット共通の規格
gap   = 0.4;  // 隣のユニットとの隙間 (外形 = マス数 × pitch - gap)

/* [Bottle] */
bottle_d    = 35;
bottle_fit  = 0.5;  // 瓶とくぼみの隙間 (片側)。瓶の個体差が大きければ増やす
pocket_h    = 10;   // くぼみの深さ (倒れ止めの高さ)
pocket_lead = 0.5;  // くぼみ入口の面取り。外周との壁が細くなるので小さめ

/* [Magnet] */
magnet_d     = 6;
magnet_h     = 2;
magnet_n     = 3;    // 1 マスあたりの個数 (くぼみの真下に円周配置。1 なら中心)
magnet_r     = 11;   // 配置円の半径
// マグネットを押し出すための貫通穴 (0 で無し)。穴の天井はブリッジで印刷されるので、
// 穴を開けるとブリッジが崩れてくぼみの底まで荒れる (2026-11-03 試作で確認)
eject_d      = 0;

/* [Rack] */
base_chamfer = 2;    // 底の外周の面取り。ラック隅の溶接の盛り上がりに乗り上げないように

/* [Hidden] */
$fn      = 128;
pocket_d = bottle_d + 2 * bottle_fit;
pocket   = magnet_pocket(magnet_d, magnet_h);  // 圧入穴 [直径, 深さ] (printer.scad)
magnet_hole = pocket[0];
hole_t   = pocket[1];
skin_t   = 4 * layer_height;               // マグネット穴とくぼみの間の床 (1 層目はブリッジ)
floor_t  = layers_up(hole_t + skin_t);
size     = [cols * pitch - gap, rows * pitch - gap, layers_up(floor_t + pocket_h)];
edge_r   = 3;   // 外形の縦の角の丸み (ラック隅の溶接盛りを避ける)
foot     = 0.4; // 穴入口の面取り (象の足対策)

function magnet_pos(i) =
    magnet_n == 1 ? [0, 0]
                  : magnet_r * [cos(90 + 360 * i / magnet_n), sin(90 + 360 * i / magnet_n)];

assert(pocket_d + 2 * pocket_lead + 2 * walls(2) <= pitch - gap,
       "くぼみ入口と外周の間の壁が 2 ライン分ない (pitch か pocket_lead を見直す)");
assert(magnet_n == 1 || magnet_r + magnet_hole / 2 < pocket_d / 2 - 1,
       "マグネットがくぼみの外に出ている");

diff()
    cuboid(size, rounding = edge_r, edges = "Z", anchor = BOTTOM) {
        // 底の外周を面取り (ラック隅の溶接の逃げ。1 層目のはみ出し対策も兼ねる)
        edge_profile(BOTTOM, excess = 1) mask2d_chamfer(base_chamfer);
        position(BOTTOM)
            grid_copies(spacing = pitch, n = [cols, rows]) {
                // 瓶のくぼみ (入口に面取り)
                tag("remove") up(floor_t)
                    cyl(d = pocket_d, h = size.z - floor_t + 0.01, anchor = BOTTOM,
                        chamfer2 = -pocket_lead);
                for (i = [0 : magnet_n - 1]) move(magnet_pos(i)) {
                    // マグネット穴 (底面から)
                    tag("remove") down(0.01)
                        cyl(d = magnet_hole, h = hole_t + 0.01, anchor = BOTTOM,
                            chamfer1 = -foot);
                    // 押し出し穴
                    if (eject_d > 0)
                        tag("remove") down(0.01)
                            cyl(d = eject_d, h = floor_t + 0.02, anchor = BOTTOM, $fn = 24);
                }
            }
    }

echo(size = size, floor_t = floor_t, magnet_pocket = pocket, pocket_d = pocket_d, magnets = cols * rows * magnet_n);
