// 使用プリンター: Elegoo Neptune 4 (0.6mm ノズル)
// モデル側で `include <printer.scad>` して寸法の基準に使う

build_volume = [225, 225, 265];  // 造形可能範囲 [mm]
nozzle       = 0.6;
line_width   = 0.62;             // 押し出し幅 (profiles/orca/process.json の line_width と合わせる)
layer_height = 0.3;              // 0.6mm ノズルの標準的な積層ピッチ

// 隣り合う線の中心間隔。スライサー (classic) は線を楕円断面とみなして
// layer_height × (1 - π/4) だけ重ねるので、線幅より少し狭い
line_spacing = line_width - layer_height * (1 - PI / 4);

// ちょうど n 本の線で埋まる壁厚 (= 線幅 + (n-1) × 間隔)。
// 2026-11-03 実測 (classic, wall_loops 2): 薄い壁は両側の輪郭から 1 周ずつ対称に作られるので、
// すき間埋め (Gap infill) なしで出せるのは偶数本だけ。
//   0.9〜1.24mm → 2 本 (walls(2) = 1.18)  /  1.3〜2.04mm → 2 本 + すき間埋め
//   2.08〜2.34mm → 4 本 (walls(4) = 2.29) / 2.38mm〜 → 4 本 + すき間埋め
// 奇数本は wall_generator を arachne にすれば出る (walls(3) = 1.73 で 3 本を確認) が、
// 圧入穴などの実測値が classic 前提なので今は切り替えていない。
function walls(n) = line_width + (n - 1) * line_spacing;

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
