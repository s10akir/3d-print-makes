// ティッシュケースの本体 (背面の壁・筒・尾根・取り出し口が一体)。設計は lib/tissue_box.scad。
//
// 印刷: 背面を下にして立てる。サポートなし。取り出し口は縦の壁の穴になり、上端は 45° に尖らせてある。
// 印刷後、前の端の台座 4 か所に φ6×2 のマグネットを圧入する (蓋と引き合う向きに揃える)。
include <tissue_box.scad>

up(box_back + end_t) xrot(-90) tissue_box_body();

echo(outer = [2 * side + 2 * wall / sqrt(3) * 2, inner_d + end_t, inner_h + 2 * wall],
     opening = [open_w, open_l], magnet_pocket = pocket);
