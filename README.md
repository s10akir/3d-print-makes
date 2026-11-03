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

## スライスと印刷

プリンター: Elegoo Neptune 4 (0.6mm ノズル, Klipper)。Fluidd/Moonraker のホストは環境変数 `PRINTER_HOST`
で指定する (git 管理外の `mise.local.toml` の `[env]` に書いておく)。スライサーは OrcaSlicer 2.4.2 の CLI (`~/.local/bin/orca-slicer`、
Fedora では `mesa-libGLU` が必要)。

```sh
make out/foo.gcode   # STL を profiles/orca のプリセットでスライス
make upload-foo      # スライスしてアップロードのみ
make print-foo       # スライスしてアップロードし、印刷開始 (印刷中なら中止)
make status          # プリンターの状態
```

### プリセットの更新

`profiles/orca/*.json` は GUI の OrcaSlicer でスライスした G-code に埋め込まれた設定から作っている。
フィラメントを変えたり再キャリブレーションしたら、その設定で 1 回 GUI でスライスした
G-code を使って作り直す。

```sh
tools/orca_profile.py path/to/sliced.gcode profiles/orca
```
