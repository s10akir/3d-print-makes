// 動作確認用サンプル: 角を丸めた箱
include <BOSL2/std.scad>

/* [Size] */
width  = 40;
depth  = 30;
height = 15;
wall   = 2;
radius = 3;

$fn = $preview ? 32 : 96;

diff()
    cuboid([width, depth, height], rounding = radius, except = TOP, anchor = BOTTOM)
        // 上面と同一平面にならないよう 1mm はみ出させて切り抜く
        tag("remove") position(TOP) up(1)
            cuboid([width - wall * 2, depth - wall * 2, height - wall + 1],
                   rounding = radius - wall, except = TOP, anchor = TOP);
