#!/usr/bin/env bash
# STL を profiles/orca のプリセットで G-code にスライスする
#   tools/slice.sh <model.stl> <out.gcode>
set -euo pipefail

ORCA=${ORCA:-orca-slicer}
PROFILE_DIR=${PROFILE_DIR:-profiles/orca}
in=$1 out=$2

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# --datadir を一時ディレクトリにして GUI 側の設定に影響されないようにする
if ! "$ORCA" --datadir "$work/data" \
        --load-settings "$PROFILE_DIR/machine.json;$PROFILE_DIR/process.json" \
        --load-filaments "$PROFILE_DIR/filament.json" \
        --arrange 1 --orient 0 --slice 0 --outputdir "$work/out" "$in" \
        >"$work/log.txt" 2>&1; then
    grep -v libexpat "$work/log.txt" >&2 || true
    [[ -f $work/out/result.json ]] && cat "$work/out/result.json" >&2
    echo "slice failed: $in" >&2
    exit 1
fi

mv "$work/out/plate_1.gcode" "$out"
grep -m1 '^; estimated printing time' "$out" || true
grep -m1 '^; total filament used \[g\]' "$out" || true
