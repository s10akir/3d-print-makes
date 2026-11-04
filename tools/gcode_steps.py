#!/usr/bin/env python3
"""G-code の高さごとにファン速度やノズル温度を段階的に変える (ファンタワー / 温度タワー用)。

    tools/gcode_steps.py <in.gcode> <out.gcode> [--fan Z:% ...] [--temp Z:℃ ...]

例: 8mm ごとにファンを 80 → 60 → 40 → 20%
    tools/gcode_steps.py in.gcode out.gcode --fan 0.6:80 8:60 16:40 24:20

Z 以上の最初の層 (OrcaSlicer の ;LAYER_CHANGE の後の ;Z:) で切り替える。
ファンは段の中でスライサーが出す M106 (層の冷却やブリッジ用) もその段の値に書き換える。
M106 S0 (最初の層や終了時の停止) はそのまま残す。
"""
import re
import sys


def parse_steps(args, name):
    steps = []
    for a in args:
        z, sep, v = a.partition(":")
        if not sep:
            sys.exit(f"--{name} は Z:値 で指定: {a}")
        steps.append((float(z), float(v)))
    return sorted(steps)


def main():
    argv = sys.argv[1:]
    if len(argv) < 3:
        sys.exit(__doc__)
    src, dst, rest = argv[0], argv[1], argv[2:]
    groups, cur = {"fan": [], "temp": []}, None
    for a in rest:
        if a in ("--fan", "--temp"):
            cur = a[2:]
        elif cur:
            groups[cur].append(a)
        else:
            sys.exit(__doc__)
    fan = parse_steps(groups["fan"], "fan")
    temp = parse_steps(groups["temp"], "temp")
    if not fan and not temp:
        sys.exit("--fan か --temp を指定")

    out, fan_s, fi, ti, applied = [], None, 0, 0, []
    after_layer_change = False
    for line in open(src, encoding="utf-8"):
        if line.startswith(";LAYER_CHANGE"):
            after_layer_change = True
        elif after_layer_change and line.startswith(";Z:"):
            after_layer_change = False
            z = float(line[3:])
            out.append(line)
            while fi < len(fan) and z >= fan[fi][0] - 1e-6:
                fan_s = round(fan[fi][1] / 100 * 255)
                out.append(f"M106 S{fan_s} ; gcode_steps: fan {fan[fi][1]:g}% from Z{z:g}\n")
                applied.append(f"Z{z:g} fan {fan[fi][1]:g}%")
                fi += 1
            while ti < len(temp) and z >= temp[ti][0] - 1e-6:
                out.append(f"M104 S{temp[ti][1]:g} ; gcode_steps: nozzle {temp[ti][1]:g}C from Z{z:g}\n")
                applied.append(f"Z{z:g} nozzle {temp[ti][1]:g}C")
                ti += 1
            continue
        m = re.match(r"M106 S(\d+(?:\.\d+)?)", line)
        if fan_s is not None and m and float(m.group(1)) > 0:
            line = f"M106 S{fan_s} ; gcode_steps: was S{m.group(1)}\n"
        out.append(line)

    if fi < len(fan) or ti < len(temp):
        sys.exit("指定した高さに届かない段がある (モデルの高さを確認)")
    open(dst, "w", encoding="utf-8").writelines(out)
    print("\n".join(applied))


if __name__ == "__main__":
    main()
