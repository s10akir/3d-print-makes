// ティッシュケース (ソフトパックの詰め替え用) の共通部分。断面が正六角形の横倒しの角柱。
//
// 束 (半折り 190×100×55mm, 200 組) を床の尾根に山形にかぶせ、天面の口から取り出す。
// 尾根が束を下から支えるので、残りが減っても頂点が取り出し口の近くに残る。
// かぶせた束は外側のシートほど脚が短くなり、断面は下すぼまりの扇形になる。
// 下すぼまりの六角形にちょうど収まるので、この形にしている。
// 尾根は最も内側のシートの脚 (約 80mm) より少し低くし、余りを床に寝かせて全高を抑える。
// 2026-11-04 テストピースで確認: 一辺 75 で、手を離すと束が内部いっぱいに広がり、押さえると少し余裕がある。
//
// 部品: 本体 (背面の壁・筒・尾根・取り出し口が一体) と前面の蓋。蓋を外して前から束を差し込む。
// 本体は背面を下にして刷る。積層の線が断面の六角形に沿うので、壁を滑り上がるシートが
// 線を横切らない (破れにくい)。前後の六角形の面はどちらもベッド面の仕上がりになる。
//
// 座標 (組み立てた状態): X = 幅, Y = 奥行き (前が -Y), Z = 高さ。内側の床が Z = 0、
// 本体の前の端 (蓋が当たる面) が Y = box_front。
include <BOSL2/std.scad>
include <printer.scad>

/* [Box] */
side    = 75;        // 内側の正六角形の一辺 (内幅 = 2 × side, 内高 = √3 × side)
inner_d = 108;       // 内寸 奥行き (シート幅 100 + 余裕)
wall    = walls(2);  // 側面の壁 (2026-11-04 Matte PLA で 2 ラインの融着を確認)
end_t   = layers_up(2.4);  // 背面と蓋の板の厚さ (ベッド面)

/* [Ridge] */
ridge_w = 20;  // 尾根の幅 (頂点は半円)
ridge_h = 71;  // 尾根の高さ (床から)

/* [Opening] */
open_shape = "hex";  // [hex, point, round] 両端の形 (下の opening_2d を参照)
open_l  = 80;   // 取り出し口の長さ (奥行き方向)
open_w  = 30;   // 取り出し口の幅
rim_in  = 2.4;  // 取り出し口のまわりを内側へ厚くする量 (縁を面取りするため)
rim_w   = 4;    // 厚くする範囲 (口の縁から)
rim_ch  = 2;    // 内側の縁の面取り (シートが引っかからないように)
open_ch = 0.6;  // 外側の縁の面取り

/* [Magnets] */
// φ6×2 を上の 2 つの角と左右の角に 4 組。下の 2 つの角は束の脚の端が来るので避ける。
magnet_d   = 6;
magnet_h   = 2;
mag_recess = 1.2;  // 本体の台座を前の端からこれだけ奥に下げ、蓋の出っ張りをはめる (位置合わせ)
mag_c      = 4.9;  // 角から穴の中心まで (角の二等分線上)
mag_reach  = 9.5;  // 角から台座の端まで

/* [Lid] */
notch_w = 24;   // 蓋を外すための指かけ (下の辺の中央、蓋の内側の面)
notch_d = 1.2;  // 深さ
notch_l = 4;    // 縁からの長さ

/* [Hidden] */
$fn = 96;
inner_h   = sqrt(3) * side;
box_front = -inner_d / 2;
box_back  = inner_d / 2;
pocket    = magnet_pocket(magnet_d, magnet_h);
boss_t    = pocket[1] + 1.2;  // 台座の厚さ (穴の深さ + 底)

// 内側の正六角形の頂点 (反時計回り、底の左から)
function hex_pts(a = side) =
    let (h = sqrt(3) * a)
    [[-a / 2, 0], [a / 2, 0], [a, h / 2], [a / 2, h], [-a / 2, h], [-a, h / 2]];

// マグネットを置く角 (hex_pts の番号)
mag_corners = [2, 3, 4, 5];

// 内側の正六角形 (2D: X = 幅, Y = 高さ。床が 0)
module hex_2d(a = side) {
    polygon(hex_pts(a));
}

// 内側の六角形を各辺から t だけ外へ広げた六角形 (床の高さは -t)
module hex_out_2d(t) {
    fwd(t) hex_2d(side + 2 * t / sqrt(3));
}

module ridge_2d() {
    rect([ridge_w, ridge_h - ridge_w / 2], anchor = FRONT);
    back(ridge_h - ridge_w / 2) circle(d = ridge_w);
}

// 断面 (2D) を奥行き方向に押し出す。Y = y0 から長さ l
module extrude_y(l, y0 = 0) {
    translate([0, y0 + l, 0]) rotate([90, 0, 0]) linear_extrude(l) children();
}

// 角 i の内側の二等分線方向の単位ベクトル
function corner_dir(i) =
    let (p = hex_pts(), v = p[i], a = p[(i + 5) % 6], b = p[(i + 1) % 6],
         e1 = unit(a - v), e2 = unit(b - v))
    unit(e1 + e2);

// 角 i を埋める三角形 (二等分線に垂直な線で reach の位置で切る)。off で内側へ縮める
module corner_2d(i, reach = mag_reach, off = 0) {
    p = hex_pts(); v = p[i];
    e1 = unit(p[(i + 5) % 6] - v); e2 = unit(p[(i + 1) % 6] - v);
    l = reach / cos(60);
    offset(delta = -off) polygon([v, v + e1 * l, v + e2 * l]);
}

// 取り出し口の形 (2D: X = 幅, Y = 奥行き)。両端は open_shape で選ぶ。本体は背面を下に刷るので、
// 前の端が縦の壁に開いた穴の上端になる (サポートなしで刷れるかはこの端で決まる)。
//   hex:   六角形の半分 (幅の半分の平らな辺 + 60° の斜辺)。平らな辺が open_w/2 のブリッジになる
//   point: 45° に尖らせる。張り出しもブリッジもない
//   round: 半円。上端の天辺がほぼ水平の張り出しになり、少し垂れる
// grow で外へ広げる (面取りや縁の厚みに使う。角の形を保つ)
module opening_2d(grow = 0) {
    w = open_w; l = open_l;
    if (open_shape == "hex") {
        e = w * sqrt(3) / 4;  // 端の斜辺の奥行き
        offset(delta = grow)
            polygon([[-w / 4, -l / 2], [w / 4, -l / 2], [w / 2, -l / 2 + e],
                     [w / 2, l / 2 - e], [w / 4, l / 2], [-w / 4, l / 2],
                     [-w / 2, l / 2 - e], [-w / 2, -l / 2 + e]]);
    } else {
        r = w / 2;
        c = l / 2 - r;
        tip = open_shape == "point" ? r * (sqrt(2) - 1) : 0;  // 尖らせても全長は open_l のまま
        offset(r = grow)
            hull() {
                back(c - tip) circle(r = r);
                fwd(c - tip) circle(r = r);
                if (open_shape == "point")
                    for (y = [-1, 1]) back(y * (c - tip + r * sqrt(2))) square(0.01, center = true);
            }
    }
}

// 本体 (組み立てた状態の座標)
module tissue_box_body() {
    difference() {
        union() {
            // 側面の筒と背面の板
            extrude_y(inner_d, box_front) difference() { hex_out_2d(wall); hex_2d(); }
            extrude_y(end_t, box_back) hex_out_2d(wall);
            // 尾根 (2 ラインの殻。前の端は開けたまま、背面の板でふさがる)
            extrude_y(box_back - box_front - 1, box_front + 1)
                difference() { ridge_2d(); offset(delta = -wall) ridge_2d(); }
            // 取り出し口のまわりを内側へ厚くする (前後の端の板からははみ出さない)
            up(inner_h - rim_in) linear_extrude(rim_in + 0.01)
                intersection() {
                    opening_2d(rim_ch + rim_w);
                    rect([2 * side, inner_d], anchor = CENTER);
                }
            // マグネットの台座 (奥側は 45° で角へすぼめ、背面を下に刷っても張り出しにならない)
            for (i = mag_corners)
                hull() {
                    extrude_y(boss_t, box_front + mag_recess) corner_2d(i);
                    extrude_y(0.01, box_front + mag_recess + boss_t + mag_reach) corner_2d(i, 0.05);
                }
        }
        // 取り出し口 (内側の縁は rim_ch、外側の縁は open_ch の面取り)
        up(inner_h - rim_in - 1) linear_extrude(rim_in + wall + 2) opening_2d();
        hull() {
            up(inner_h - rim_in - 0.01) linear_extrude(0.01) opening_2d(rim_ch);
            up(inner_h - rim_in + rim_ch) linear_extrude(0.01) opening_2d();
        }
        hull() {
            up(inner_h + wall - open_ch) linear_extrude(0.01) opening_2d();
            up(inner_h + wall) linear_extrude(0.01) opening_2d(open_ch);
        }
        // マグネットの穴 (前向き)
        for (i = mag_corners)
            magnet_hole(i, box_front + mag_recess - 0.01, 1);
    }
}

// 前面の蓋 (組み立てた状態の座標)。内側の面の角に、本体の台座のくぼみにはまる出っ張り
module tissue_box_lid() {
    pad_h = mag_recess - 0.2;  // 出っ張りは少し低くし、蓋が本体の端に確実に当たるようにする
    difference() {
        union() {
            extrude_y(end_t, box_front - end_t) hex_out_2d(wall);
            for (i = mag_corners)
                extrude_y(pad_h, box_front) corner_2d(i, off = fit_clearance);
        }
        for (i = mag_corners)
            magnet_hole(i, box_front + pad_h + 0.01, -1);
        // 指かけ (上の辺の中央。蓋の内側の面を削り、本体との間にすき間を作る)
        translate([0, box_front - notch_d / 2 + 0.01, inner_h + wall - notch_l / 2 + 0.5])
            cube([notch_w, notch_d + 0.02, notch_l + 1], center = true);
    }
}

// 角 i のマグネットの穴。y0 の面から dir (+1: 奥へ, -1: 手前へ) に掘る
module magnet_hole(i, y0, dir) {
    c = hex_pts()[i] + corner_dir(i) * mag_c;
    translate([c.x, y0 + (dir > 0 ? 0 : -pocket[1]), c.y])
        rotate([-90, 0, 0]) cylinder(d = pocket[0], h = pocket[1]);
}
