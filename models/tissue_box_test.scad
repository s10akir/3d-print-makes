// ティッシュケースの寸法確認用のテストピース。設計は lib/tissue_box.scad。
//
// 両端が抜けた短い六角形の筒 + 尾根 (どちらも 2 ラインの殻)。束の中ほどに通して、断面の収まりを見る。
// 材料節約のため各面と尾根の側面は柱と上下の帯だけの窓枠 (尾根の頂点の半円は束の曲がりを決めるので残す)。
// 印刷: 断面を下にして奥行き方向に積む。壁はすべて垂直で、窓の上辺だけがブリッジ
// (test_span 以下になるよう柱を足す)。
include <tissue_box.scad>

/* [Test piece] */
test_wall    = walls(2);  // 筒と尾根の壁
test_d       = 40;        // 筒の長さ (奥行き)
test_post    = 6;         // 柱の幅
test_band    = 4;         // 筒の両端に残す帯の幅
test_span    = 20;        // 窓の幅 (= ブリッジの長さ) の上限 (ブリッジ性能の確認も兼ねる)

// 断面を下にした向き (X = 幅, Y = 高さ, Z = 奥行き)
module test_piece() {
    difference() {
        linear_extrude(test_d) {
            difference() { hex_out_2d(test_wall); hex_2d(); }
            difference() { ridge_2d(); offset(delta = -test_wall) ridge_2d(); }
        }
        // 各面に窓を開ける (六角形の角には柱の半分ずつ、床の面は尾根の左右に分ける)
        v = hex_pts();
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

test_piece();
