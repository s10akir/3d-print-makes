// 使用プリンター: Elegoo Neptune 4 (0.6mm ノズル)
// モデル側で `include <printer.scad>` して寸法の基準に使う

build_volume = [225, 225, 265];  // 造形可能範囲 [mm]
nozzle       = 0.6;
line_width   = 0.65;             // 押し出し幅の目安 (ノズル径 ×1.1 程度)
layer_height = 0.3;              // 0.6mm ノズルの標準的な積層ピッチ

// 押し出し n 本分の壁厚
function walls(n) = n * line_width;

// はめ合いのクリアランス (片側)。0.6mm ノズルは精度が落ちるので大きめ
fit_clearance = 0.3;
