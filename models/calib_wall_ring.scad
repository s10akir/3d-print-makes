// 壁の融着を比べるための筒 (ファンタワー / 温度タワー用)。
//
// 2 ラインの壁は、内側の線を引いてから 1 周して外側の線が来るので、1 周が長いほど
// 先の線が冷えて融着が弱くなる。本番 (tissue_box の一辺 75mm の六角形) と同じ 1 周の長さにしている。
// 高さごとの設定の切り替えは G-code の後処理 (tools/gcode_steps.py) で行う。
// 刷ったら段ごとに爪で 2 本の線を剥がしてみて比べる。
//
// 印刷: そのまま。サポートなし。
include <BOSL2/std.scad>
include <printer.scad>

side   = 75;        // 正六角形の一辺 (内側)
wall   = walls(2);  // 壁 (ちょうど 2 ライン)
steps  = 4;         // 段の数
step_h = 8;         // 1 段の高さ

h = layers_up(steps * step_h);

linear_extrude(h)
    difference() {
        circle(r = side + wall / cos(30), $fn = 6);
        circle(r = side, $fn = 6);
    }

echo(height = h, steps_at = [for (i = [0 : steps - 1]) i * step_h]);
