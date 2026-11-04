#!/usr/bin/env python3
"""OrcaSlicer 同梱のフィラメントプリセットから CLI 用のフィラメント JSON を作る。

    tools/orca_filament.py <システムプリセット名> <out.json> [key=value ...]

例:
    tools/orca_filament.py "Elegoo PLA Matte @EN4 Series" profiles/orca/filaments/matte_pla.json
    tools/orca_filament.py "Elegoo PLA Matte @EN4 Series" profiles/orca/filaments/matte_pla.json \\
        fan_max_speed=60 filament_flow_ratio=0.96

OrcaSlicer の CLI はユーザープリセットの inherits をたどらない (継承元の値が入らない) ので、
AppImage から resources/profiles を取り出して継承を自前で展開し、全項目を書き出す。
key=value で上書きした値は filament_notes にも記録する (作り直すときの控え)。
GUI で調整したフィラメントなら tools/orca_profile.py で G-code から作る方がよい。

環境変数 ORCA で OrcaSlicer の AppImage を指定できる (既定: PATH 上の orca-slicer)。
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

sys.dont_write_bytecode = True  # tools/__pycache__ を作らない
sys.path.insert(0, str(Path(__file__).resolve().parent))
from orca_profile import FILAMENT_KEYS  # noqa: E402

REPO = Path(__file__).resolve().parent.parent
MACHINE_JSON = REPO / "profiles/orca/machine.json"


def extract_profiles(workdir):
    orca = shutil.which(os.environ.get("ORCA", "orca-slicer"))
    if not orca:
        sys.exit("OrcaSlicer の AppImage が見つからない (ORCA で指定)")
    subprocess.run([orca, "--appimage-extract", "resources/profiles/*"], cwd=workdir,
                   check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    root = Path(workdir) / "squashfs-root/resources/profiles"
    if not root.is_dir():
        sys.exit(f"{orca}: resources/profiles を取り出せない (AppImage か確認)")
    return root


def index_filaments(root):
    """名前 → [(ベンダー, パス)]。fdm_filament_pla など同名がベンダーごとにある"""
    idx = {}
    for path in root.glob("*/filament/**/*.json"):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (json.JSONDecodeError, UnicodeDecodeError):
            continue
        if data.get("type") == "filament" and "name" in data:
            vendor = path.relative_to(root).parts[0]
            idx.setdefault(data["name"], []).append((vendor, path))
    return idx


def find(idx, name, vendor=None):
    cands = idx.get(name)
    if not cands:
        sys.exit(f"プリセットが見つからない: {name}")
    # 同じベンダー → OrcaFilamentLibrary → 最初のもの の順で選ぶ
    for want in (vendor, "OrcaFilamentLibrary"):
        for v, p in cands:
            if v == want:
                return v, p
    return cands[0]


def resolve(idx, name):
    """継承元から順に値を重ねた dict を返す"""
    chain, vendor = [], None
    while name:
        vendor, path = find(idx, name, vendor)
        data = json.loads(path.read_text(encoding="utf-8"))
        chain.append(data)
        name = data.get("inherits")
    merged = {}
    for data in reversed(chain):
        merged.update(data)
    return merged


def main():
    if len(sys.argv) < 3:
        sys.exit(__doc__)
    preset, out = sys.argv[1], Path(sys.argv[2])
    overrides = {}
    for arg in sys.argv[3:]:
        key, sep, value = arg.partition("=")
        if not sep or key not in FILAMENT_KEYS:
            sys.exit(f"上書きは key=value (フィラメントの項目) で指定: {arg}")
        overrides[key] = value

    machine_inherits = json.loads(MACHINE_JSON.read_text(encoding="utf-8"))["inherits"]
    with tempfile.TemporaryDirectory() as tmp:
        merged = resolve(index_filaments(extract_profiles(tmp)), preset)

    if machine_inherits not in merged.get("compatible_printers", [machine_inherits]):
        print(f"警告: {preset} は {machine_inherits} 向けではない", file=sys.stderr)

    note = f"{preset} を展開"
    if overrides:
        note += " / 上書き: " + " ".join(f"{k}={v}" for k, v in overrides.items())
    filament = {k: merged[k] for k in FILAMENT_KEYS if k in merged}
    filament.update(overrides)
    filament.update({
        "type": "filament", "from": "User", "instantiation": "true",
        "name": f"{preset} ({out.stem})", "inherits": preset,
        "filament_id": merged.get("filament_id", ""),
        "compatible_printers": [machine_inherits],
        "filament_notes": note,
    })
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(filament, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
                   encoding="utf-8")
    print(f"{out}: {filament['name']}")


if __name__ == "__main__":
    main()
