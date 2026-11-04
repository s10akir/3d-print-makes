# 3d-print-makes

OpenSCAD で作る 3D プリント用モデル。

## 構成

```
models/   モデル本体 (1 ファイル = 1 出力)
lib/      ライブラリ (BOSL2 は git submodule)
out/      ビルド成果物 (git 管理外)
```

## セットアップ

```sh
git clone --recursive <repo>
# 既に clone 済みなら
git submodule update --init
```

OpenSCAD は開発版 AppImage (Manifold バックエンドが使えるもの) を想定。
`~/.local/bin/openscad` に配置している。

## 使い方

```sh
make                # models/*.scad をすべて out/*.stl に出力
make FORMAT=3mf     # 3MF で出力
make out/foo.stl    # 1 つだけ出力
make png            # プレビュー画像を out/*.png に出力
make clean
```

GUI で編集するときは、このディレクトリで `openscad models/foo.scad` を起動する
(mise が `OPENSCADPATH=lib` を設定するので `include <BOSL2/std.scad>` が解決できる)。

## grid40 シリーズ

鉄板のスパイスラックに並べるユニット群。1 マス 40mm 角のグリッドで外形を揃え
(外形 = マス数 × 40 - 0.4mm)、底面に φ6×2mm マグネットを圧入して貼り付ける。
共通の寸法と本体 (角丸・底の面取り・マグネット穴) は `lib/grid40.scad`。

| モデル | 内容 |
| --- | --- |
| `grid40_jar35` | φ35 寸胴瓶 (GABAN のスパイス瓶など) の位置決めプレート |
| `grid40_bin` | 上が開いただけの小物入れ (既定 3×1, 高さ 50mm) |

新しいユニットは `include <grid40.scad>` して `diff() grid40_body(cols, rows, h) ...` に
削る形を足して作る。マグネットの極性はシリーズ全体で揃えること。

## スライスと印刷

プリンター: Elegoo Neptune 4 (0.6mm ノズル, Klipper)。Fluidd/Moonraker のホストは環境変数 `PRINTER_HOST`
で指定する (git 管理外の `mise.local.toml` の `[env]` に書いておく)。スライサーは OrcaSlicer 2.4.2 の CLI (`~/.local/bin/orca-slicer`、
Fedora では `mesa-libGLU` が必要)。

```sh
make out/foo.gcode   # STL を profiles/orca のプリセットでスライス
make upload-foo      # スライスしてアップロードのみ
make print-foo       # スライスしてアップロードし、印刷開始 (印刷中なら中止)
make status          # プリンターの状態
make FILAMENT=rapid_pla_plus print-foo   # 別のフィラメントのプリセットでスライス
```

フィラメントのプリセットは `profiles/orca/filaments/<名前>.json` で、`FILAMENT` で選ぶ
(既定値は Makefile の `FILAMENT ?=`。プリンターに載せ替えたらここを変える)。
`FILAMENT` を変えると G-code は作り直される。

`@N` を付けると同じモデルを N 個ベッドに自動配置してスライスする (`make print-foo@9` など)。
小物は時間が個数にほぼ比例する (1×1 の grid40_jar35: 1 個 11 分 / 9 個 1h36m / 16 個 2h52m) ので、
まとめる利点は段取りが 1 回で済むことくらい。G-code は EXCLUDE_OBJECT 付きなので、
失敗した 1 個だけ Fluidd から除外して続行できる。

## 設計メモ (0.6mm ノズル / Rapid PLA+ での実測・試作から)

- 圧入穴やはめ合いの値は `lib/printer.scad` に実測値と経緯を残している (`magnet_pocket()` など)。
- 底面 (ベッド側) から開けた止まり穴の天井はブリッジになる。そこに貫通穴を開けるとブリッジが
  崩れるので開けない。天井の上には 4 層 (1.2mm) 以上載せる。3 層だと荒れが表に透ける。
  上面から開ける穴 (テストピースなど) にはこの問題はない。
- 上面に出る壁は最も細い所でも 2 ライン (`walls(2)` = 1.18mm) 以上残す。入口の面取りで
  壁が 0.3mm まで削れていたら上面の縁がガタガタになった。
- 置くだけの位置決め (φ35 のガラス瓶) はすき間片側 0.5mm で「少し緩くてちょうどいい」。
- 小物はインフィルの設定で印刷時間がほとんど変わらない (壁と上下面が大半)。

### プリセットの更新

`profiles/orca/machine.json` / `process.json` / `filaments/*.json` は GUI の OrcaSlicer でスライスした
G-code に埋め込まれた設定から作っている。再キャリブレーションしたら、その設定で 1 回 GUI でスライスした
G-code を使って作り直す。

```sh
tools/orca_profile.py path/to/sliced.gcode profiles/orca rapid_pla_plus                   # 3 つとも
tools/orca_profile.py --filament-only path/to/sliced.gcode profiles/orca matte_pla        # フィラメントだけ
```

新しいフィラメントは、まず OrcaSlicer 同梱のプリセットから作れる (CLI はプリセットの継承をたどらないので、
AppImage から同梱プリセットを取り出して展開した全項目を書き出す)。`key=value` で値を上書きでき、
上書きした値は `filament_notes` に残る。GUI で調整したら上の `--filament-only` で置き換える。

```sh
tools/orca_filament.py "Elegoo PLA Matte @EN4 Series" profiles/orca/filaments/matte_pla.json
tools/orca_filament.py "Elegoo PLA Matte @EN4 Series" profiles/orca/filaments/matte_pla.json fan_max_speed=60
```

| 名前 | 内容 |
| --- | --- |
| `rapid_pla_plus` | Elegoo Rapid PLA+ (GUI で流量など調整済み。`lib/printer.scad` の実測値はこれで測った) |
| `matte_pla` | Elegoo PLA Matte (同梱の `@EN4 Series` を展開しただけ。未調整) |

### フィラメントを替えたときの壁の確認

`models/calib_wall_ring.scad` は 2 ラインの壁の筒 (1 周の長さは tissue_box と同じ)。
`tools/gcode_steps.py` で高さごとにファンや温度を変えて刷り、段ごとに 2 本の線の融着を比べる。

```sh
make out/calib_wall_ring.gcode
tools/gcode_steps.py out/calib_wall_ring.gcode out/calib_wall_ring_fan.gcode --fan 0.6:80 8:60 16:40 24:20
tools/moonraker.sh print out/calib_wall_ring_fan.gcode
```
