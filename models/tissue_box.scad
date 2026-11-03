// ティッシュケース (ソフトパックの詰め替え用)。断面が正六角形の横倒しの角柱。
//
// 束 (半折り 190×100×55mm, 200 組) を底の尾根に山形にかぶせ、天面の口から取り出す。
// 尾根が束を下から支えるので、残りが減っても頂点が取り出し口の近くに残る。
// かぶせた束は外側のシートほど脚が短くなり、断面は下すぼまりの扇形になる。
// 下すぼまりの六角形にちょうど収まるので、この形にしている。
// 尾根は最も内側のシートの脚 (約 80mm) より少し低くし、余りを床に寝かせて全高を抑える。
//
// 部品 (予定): 上半分 (本体) / 下半分 (尾根付きの台座)。六角形の中央の角で分割する
// (束の最大幅 約 130mm が通り、継ぎ目が稜線に重なる)。
//
// part = "test": 寸法確認用のテストピース。両端が抜けた短い六角形の筒 + 尾根 (どちらも 2 ラインの殻)。
//   束の中ほどに通して、断面の収まりを見る。材料節約のため各面と尾根の側面は柱と上下の帯だけの窓枠
//   (尾根の頂点の半円は束の曲がりを決めるので残す)。
//   印刷: 断面を下にして奥行き方向に積む。壁はすべて垂直で、窓の上辺だけがブリッジ
//   (test_span 以下になるよう柱を足す)。
include <BOSL2/std.scad>
include <printer.scad>

/* [Part] */
part = "test";  // [test, section]

/* [Box] */
side    = 75;   // 内側の正六角形の一辺 (内幅 = 2 × side, 内高 = √3 × side)
inner_d = 108;  // 内寸 奥行き (シート幅 100 + 余裕)

/* [Ridge] */
ridge_w = 20;  // 尾根の幅 (頂点は半円)
ridge_h = 71;  // 尾根の高さ (床から)

/* [Test piece] */
test_wall    = walls(2);  // 筒と尾根の壁
test_d       = 40;        // 筒の長さ (奥行き)
test_post    = 6;         // 柱の幅
test_band    = 4;         // 筒の両端に残す帯の幅
test_span    = 20;        // 窓の幅 (= ブリッジの長さ) の上限 (ブリッジ性能の確認も兼ねる)

/* [Hidden] */
$fn = 96;
inner_h = sqrt(3) * side;

// 内側の正六角形 (X = 幅, Y = 高さ。床が 0)
module hex_2d(a = side) {
    h = sqrt(3) * a;
    polygon([[-a / 2, 0], [a / 2, 0], [a, h / 2], [a / 2, h], [-a / 2, h], [-a, h / 2]]);
}

// 内側の六角形を各辺から t だけ外へ広げた六角形 (床の高さは -t)
module hex_out_2d(t) {
    fwd(t) hex_2d(side + 2 * t / sqrt(3));
}

module ridge_2d() {
    rect([ridge_w, ridge_h - ridge_w / 2], anchor = FRONT);
    back(ridge_h - ridge_w / 2) circle(d = ridge_w);
}

// 断面を奥行き (Y) 方向に押し出す。y0 から長さ l
module extrude_y(l, y0 = 0) {
    translate([0, y0 + l, 0]) rotate([90, 0, 0]) linear_extrude(l) children();
}

// 断面を下にした向き (X = 幅, Y = 高さ, Z = 奥行き)
module test_piece() {
    difference() {
        linear_extrude(test_d) {
            difference() { hex_out_2d(test_wall); hex_2d(); }
            difference() { ridge_2d(); offset(delta = -test_wall) ridge_2d(); }
        }
        // 各面に窓を開ける (六角形の角には柱の半分ずつ、床の面は尾根の左右に分ける)
        h = sqrt(3) * side;
        v = [[-side / 2, 0], [side / 2, 0], [side, h / 2], [side / 2, h], [-side / 2, h], [-side, h / 2]];
        for (i = [0 : 5]) {
            a = v[i]; b = v[(i + 1) % 6];
            u0 = test_post / 2; u1 = side - test_post / 2;
            if (i == 0) {
                window_row(a, b, u0, side / 2 - ridge_w / 2);
                window_row(a, b, side / 2 + ridge_w / 2, u1);
            } else {
                window_row(a, b, u0, u1);
            }
        }
        // 尾根の両側面 (根元に柱の半分を残し、半円の手前まで)
        for (x = [-1, 1] * ridge_w / 2)
            window_row([x, 0], [x, ridge_h - ridge_w / 2], test_post / 2, ridge_h - ridge_w / 2);
    }
}

// a→b の線上の u0〜u1 に、間に柱を挟みながら幅 test_span 以下の窓を等間隔に開ける (壁を貫く角柱)
module window_row(a, b, u0, u1) {
    lw = u1 - u0;
    n = ceil((lw + test_post) / (test_span + test_post));
    w = (lw - (n - 1) * test_post) / n;
    ang = atan2(b.y - a.y, b.x - a.x);
    for (k = [0 : n - 1])
        translate([a.x, a.y, test_d / 2]) rotate([0, 0, ang]) rotate([90, 0, 0])
            linear_extrude(4 * test_wall, center = true)
                right(u0 + k * (w + test_post) + w / 2)
                    square([w, test_d - 2 * test_band], center = true);
}

if (part == "test") {
    test_piece();
} else if (part == "section") {
    // 断面の確認用。正面 (-Y) から見る
    color("ivory") extrude_y(1) difference() { hex_out_2d(walls(4)); hex_2d(); }
    color("tan") extrude_y(1) ridge_2d();
}

echo(side = side, inner = [2 * side, inner_d, inner_h], ridge_h = ridge_h);
