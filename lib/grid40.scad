// grid40: 鉄板のスパイスラックに並べるユニットシリーズの共通規格。
// 1 マス 40mm 角のグリッドで外形を揃え、底面にマグネットを埋めて貼り付ける。
// シリーズのモデルは models/grid40_*.scad。
//
// 使い方: `include <grid40.scad>` (BOSL2/std.scad と printer.scad も読み込む)
include <BOSL2/std.scad>
include <printer.scad>

grid40_pitch  = 40;   // 1 マスの寸法 [mm]
grid40_gap    = 0.4;  // 隣のユニットとの隙間 (外形 = マス数 × pitch - gap)
grid40_edge_r = 3;    // 外形の縦の角の丸み (ラック隅の溶接盛りを避ける)
grid40_chamfer = 2;   // 底の外周の面取り (同上。1 層目のはみ出し対策も兼ねる)

// マグネット (φ6×2mm)
grid40_magnet_d = 6;
grid40_magnet_h = 2;
grid40_magnet_r = 11;  // 1 マスに複数置くときの配置円の半径
grid40_pocket   = magnet_pocket(grid40_magnet_d, grid40_magnet_h);  // 圧入穴 [直径, 深さ]
// 底の厚さ: マグネット穴の天井 (ブリッジ) の上に 4 層載せる
grid40_floor_t  = layers_up(grid40_pocket[1] + 4 * layer_height);

// cols × rows マスのユニットの外形 (高さは層単位に切り上げ)
function grid40_size(cols, rows, h) =
    [cols * grid40_pitch - grid40_gap, rows * grid40_pitch - grid40_gap, layers_up(h)];

// 1 マス内の i 番目のマグネット位置 (n == 1 なら中心、それ以外は円周配置)
function grid40_magnet_pos(i, n) =
    n == 1 ? [0, 0]
           : grid40_magnet_r * [cos(90 + 360 * i / n), sin(90 + 360 * i / n)];

// ユニット本体: 角丸の箱 + 底の面取り + 各マスのマグネット穴。
// diff() の中で使うこと。子要素は本体にアタッチされる (tag("remove") で削る)。
module grid40_body(cols, rows, h, magnets = 1) {
    foot = 0.4;  // 穴入口の面取り (象の足対策)
    cuboid(grid40_size(cols, rows, h), rounding = grid40_edge_r, edges = "Z", anchor = BOTTOM) {
        edge_profile(BOTTOM, excess = 1) mask2d_chamfer(grid40_chamfer);
        position(BOTTOM)
            grid_copies(spacing = grid40_pitch, n = [cols, rows])
                for (i = [0 : magnets - 1]) move(grid40_magnet_pos(i, magnets))
                    tag("remove") down(0.01)
                        cyl(d = grid40_pocket[0], h = grid40_pocket[1] + 0.01, anchor = BOTTOM,
                            chamfer1 = -foot);
        children();
    }
}
