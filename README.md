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
