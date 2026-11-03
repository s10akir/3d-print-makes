// grid40 シリーズ: 小物入れ。上が開いただけの中空の箱。規格は lib/grid40.scad。
//
// 印刷: 開口部を上にしてそのまま。サポート不要。印刷後にマグネットを圧入する
// (極性はシリーズ全体で揃えること)。
include <grid40.scad>

/* [Layout] */
cols = 3;  // X 方向のマス数
rows = 1;  // Y 方向のマス数

/* [Bin] */
height = 50;        // 全高 [mm]
wall   = walls(2);  // 側壁の厚さ (ちょうど 2 ライン)
in_r   = 2;         // 内側の角と底の丸み (取り出しやすいように)

/* [Magnet] */
magnet_n = 1;  // 1 マスあたりの個数 (1 なら中心、2 以上は円周配置)

/* [Hidden] */
$fn     = 64;
floor_t = grid40_floor_t;
size    = grid40_size(cols, rows, height);
inner   = [size.x - 2 * wall, size.y - 2 * wall, size.z - floor_t];

assert(wall >= walls(2), "壁は 2 ライン以上");
assert(size.x <= build_volume.x && size.y <= build_volume.y, "ベッドに載らない");

diff()
    grid40_body(cols, rows, size.z, magnets = magnet_n)
        // 中空部 (底と縦の角を丸める。上は抜く)
        tag("remove") position(BOTTOM) up(floor_t)
            cuboid(inner + [0, 0, 0.01], rounding = in_r, except = TOP, anchor = BOTTOM);

echo(size = size, inner = inner, floor_t = floor_t, magnet_pocket = grid40_pocket,
     magnets = cols * rows * magnet_n);
