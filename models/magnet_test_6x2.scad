// φ6×2mm マグネット埋め込み穴のはめ合いテストピース
// 穴径を少しずつ変えて並べ、各穴の下に径を刻印する。
// 底の小穴はマグネットを裏から押し出すためのもの。
include <BOSL2/std.scad>
include <printer.scad>

/* [Magnet] */
magnet_d = 6;
magnet_h = 2;

/* [Test range] */
d_start = 6.0;   // 最小の穴径
d_step  = 0.1;
count   = 8;     // 6.0, 6.1, ... 6.7
depth   = magnet_h + 0.2;  // マグネットが面から少し沈む深さ

/* [Plate] */
cols     = 4;                 // 1 段あたりの穴数
cell     = [14, 16];          // 1 穴分 (穴 + 刻印) の区画
margin   = 3;
floor_t  = 3 * layer_height;  // 穴の底の厚み
label_h  = 5;                 // 刻印文字の大きさ (0.6mm ノズルで潰れない程度)
label_digits = 1;             // 刻印する小数桁数 (d_step に合わせる)
label_t  = 2 * layer_height;  // 刻印の深さ
eject_d  = 2;                 // 押し出し用の貫通穴

/* [Hidden] */
$fn   = 96;  // 多角形近似で穴が小さくならないよう細かめに
rows  = ceil(count / cols);
plate = [cols * cell.x + 2 * margin,
         rows * cell.y + 2 * margin,
         floor_t + depth];

function hole_d(i) = d_start + i * d_step;

// i 番目の区画の中心 (左上から右へ、上の段から順に)
function cell_pos(i) = [
    (i % cols - (cols - 1) / 2) * cell.x,
    ((rows - 1) / 2 - floor(i / cols)) * cell.y,
];

diff()
    cuboid(plate, rounding = 2, edges = "Z", anchor = BOTTOM) {
        for (i = [0 : count - 1]) {
            p = cell_pos(i);
            hole_xy  = p + [0, cell.y / 2 - 1 - 4];   // 区画の上寄り
            label_xy = p + [0, -cell.y / 2 + 1 + label_h / 2];
            // マグネット穴
            tag("remove") position(TOP) move([each hole_xy, 0.01])
                cyl(d = hole_d(i), h = depth + 0.01, anchor = TOP);
            // 押し出し穴
            tag("remove") move(hole_xy)
                cyl(d = eject_d, h = plate.z + 1, $fn = 24);
            // 径の刻印
            tag("remove") position(TOP) move([each label_xy, 0.01])
                text3d(format_fixed(hole_d(i), label_digits), h = label_t + 0.01,
                       size = label_h, font = "Liberation Sans:style=Bold",
                       anchor = TOP, atype = "ycenter");
        }
        // 向きの目印 (左上の角を面取り)
        tag("remove") position(LEFT + BACK)
            zrot(45) cuboid([4, 4, plate.z + 1]);
    }

echo(plate = plate);
