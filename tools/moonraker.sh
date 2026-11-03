#!/usr/bin/env bash
# Moonraker (Fluidd) 経由でプリンターを操作する
#   tools/moonraker.sh status
#   tools/moonraker.sh upload <file.gcode>   アップロードのみ
#   tools/moonraker.sh print  <file.gcode>   アップロードして印刷開始
set -euo pipefail

HOST=${PRINTER_HOST:?PRINTER_HOST にプリンターのホストを設定してください (mise.local.toml の [env] など)}
api=http://$HOST

status() {
    curl -fsS -m 8 "$api/printer/objects/query?print_stats&extruder&heater_bed&display_status" |
        python3 -c '
import json, sys
d = json.load(sys.stdin)["result"]["status"]
p = d["print_stats"]
e, b = d["extruder"], d["heater_bed"]
print("%s  %.0f%%  %s" % (p["state"], d["display_status"]["progress"] * 100, p["filename"]))
print("nozzle %.0f/%.0f  bed %.0f/%.0f" % (e["temperature"], e["target"], b["temperature"], b["target"]))'
}

state() {
    curl -fsS -m 8 "$api/printer/objects/query?print_stats" |
        python3 -c 'import json,sys; print(json.load(sys.stdin)["result"]["status"]["print_stats"]["state"])'
}

upload() {
    local file=$1 start=$2
    curl -fsS -m 300 -F "file=@$file" -F "print=$start" "$api/server/files/upload" >/dev/null
    echo "uploaded: $(basename "$file") (print=$start)"
}

case ${1:-} in
    status) status ;;
    upload) upload "$2" false ;;
    print)
        s=$(state)
        if [[ $s != standby && $s != complete && $s != cancelled ]]; then
            echo "printer is busy ($s)" >&2
            exit 1
        fi
        upload "$2" true ;;
    *) sed -n '2,5p' "$0" >&2; exit 2 ;;
esac
