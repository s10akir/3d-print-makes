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

// 高さを積層ピッチの倍数に切り上げる。スライス時に Z が層単位に丸められるので、
// 穴の深さや部品の高さはこれで揃えておくと設計値どおりになる
function layers_up(h) = ceil(h / layer_height - 1e-6) * layer_height;

// --- 圧入穴 (2026-11-03 φ6×2mm マグネットで実測, Rapid PLA+) ---
// 穴径 6.0: 入らない / 6.1: 強く押せば入り脱落しない / 6.2: 脱落する
press_fit_d = 0.1;  // 圧入穴の直径の上乗せ量
loose_fit_d = 0.2;  // この上乗せだと保持しない (すき間ばめ)

// 円柱マグネット用の圧入穴の [直径, 深さ]。
// 深さ = 公称高さ + 0.3 を層単位に切り上げ。公称どおり (+0.1) では
// 穴底の荒れでマグネットがわずかに浮いたため余裕を持たせている。
// 部品の上面も層の境目に揃えること (layers_up を使う)。
function magnet_pocket(d, h) = [d + press_fit_d, layers_up(h + 0.3)];
