// grid40 シリーズ: φ35 寸胴瓶 (GABAN のスパイス瓶など) の位置決めプレート。
// 天面のくぼみに瓶を置いて倒れ・ずれを止める。規格は lib/grid40.scad。
//
// cols × rows マスのユニットを並べて使う (例: 1×1 を必要数、1×3 で短手 120mm に 3 本、など)。
//
// 印刷: 天面 (くぼみ側) を上にしてそのまま。マグネット穴は底面から開いているので
// サポート不要。印刷後にマグネットを圧入する (極性はシリーズ全体で揃えること)。
// マグネットを押し出す貫通穴は開けない (穴の天井のブリッジが崩れてくぼみの底まで荒れる。
// 2026-11-03 試作で確認)。
include <grid40.scad>

/* [Layout] */
cols = 1;  // X 方向のマス数
rows = 1;  // Y 方向のマス数

/* [Bottle] */
bottle_d    = 35;
bottle_fit  = 0.5;  // 瓶とくぼみの隙間 (片側)。瓶の個体差が大きければ増やす
pocket_h    = 10;   // くぼみの深さ (倒れ止めの高さ)
pocket_lead = 0.5;  // くぼみ入口の面取り。外周との壁が細くなるので小さめ

/* [Magnet] */
magnet_n = 3;  // 1 マスあたりの個数 (くぼみの真下に円周配置。1 なら中心)

/* [Hidden] */
$fn      = 128;
pocket_d = bottle_d + 2 * bottle_fit;
floor_t  = grid40_floor_t;
size     = grid40_size(cols, rows, floor_t + pocket_h);

assert(pocket_d + 2 * pocket_lead + 2 * walls(2) <= grid40_pitch - grid40_gap,
       "くぼみ入口と外周の間の壁が 2 ライン分ない (pocket_lead を見直す)");
assert(magnet_n == 1 || grid40_magnet_r + grid40_pocket[0] / 2 < pocket_d / 2 - 1,
       "マグネットがくぼみの外に出ている");

diff()
    grid40_body(cols, rows, size.z, magnets = magnet_n)
        position(BOTTOM)
            grid_copies(spacing = grid40_pitch, n = [cols, rows])
                // 瓶のくぼみ (入口に面取り)
                tag("remove") up(floor_t)
                    cyl(d = pocket_d, h = size.z - floor_t + 0.01, anchor = BOTTOM,
                        chamfer2 = -pocket_lead);

echo(size = size, floor_t = floor_t, magnet_pocket = grid40_pocket, pocket_d = pocket_d,
     magnets = cols * rows * magnet_n);
