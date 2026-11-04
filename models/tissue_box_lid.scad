// ティッシュケースの前面の蓋。設計は lib/tissue_box.scad。
//
// 印刷: 外側の面を下にしてそのまま。印刷後、角の出っ張り 4 か所に φ6×2 のマグネットを圧入する
// (本体と引き合う向きに揃える)。
include <tissue_box.scad>

up(end_t - box_front) xrot(90) tissue_box_lid();
