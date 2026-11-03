#!/usr/bin/env python3
"""OrcaSlicer が出力した G-code の CONFIG_BLOCK から CLI 用プリセット JSON を作る。

    tools/orca_profile.py <file.gcode> <outdir>

GUI でスライスした G-code にはスライス設定が全項目埋め込まれているので、
それを machine / process / filament の 3 ファイルに分けて書き出す。
OrcaSlicer 2.4.2 の CLI に合わせた調整:
  - process / filament の compatible_printers に machine の inherits を入れる
    (CLI は継承元の名前で互換性を判定する)
  - filament にはフィラメント項目だけを入れる (余計な項目があると CLI が落ちる)
"""
import json
import re
import sys
from pathlib import Path

# OrcaSlicer v2.4.2 src/libslic3r/Preset.cpp の s_Preset_filament_options
FILAMENT_KEYS = [
    'filament_colour', 'default_filament_colour', 'required_nozzle_HRC',
    'filament_diameter', 'pellet_flow_coefficient', 'volumetric_speed_coefficients',
    'filament_type', 'filament_soluble', 'filament_is_support', 'filament_printable',
    'filament_max_volumetric_speed', 'filament_adaptive_volumetric_speed',
    'filament_flow_ratio', 'filament_density', 'filament_adhesiveness_category',
    'filament_cost', 'filament_minimal_purge_on_wipe_tower',
    'filament_tower_interface_pre_extrusion_dist',
    'filament_tower_interface_pre_extrusion_length', 'filament_tower_ironing_area',
    'filament_tower_interface_purge_volume', 'filament_tower_interface_print_temp',
    'nozzle_temperature', 'nozzle_temperature_initial_layer', 'cool_plate_temp',
    'textured_cool_plate_temp', 'eng_plate_temp', 'hot_plate_temp',
    'textured_plate_temp', 'cool_plate_temp_initial_layer',
    'textured_cool_plate_temp_initial_layer', 'eng_plate_temp_initial_layer',
    'hot_plate_temp_initial_layer', 'textured_plate_temp_initial_layer',
    'supertack_plate_temp_initial_layer', 'supertack_plate_temp', 'bed_type',
    'temperature_vitrification', 'reduce_fan_stop_start_freq',
    'dont_slow_down_outer_wall', 'slow_down_for_layer_cooling', 'fan_min_speed',
    'fan_max_speed', 'enable_overhang_bridge_fan', 'overhang_fan_speed',
    'overhang_fan_threshold', 'close_fan_the_first_x_layers',
    'close_additional_fan_first_x_layers', 'first_x_layer_fan_speed',
    'full_fan_speed_layer', 'additional_fan_full_speed_layer', 'fan_cooling_layer_time',
    'slow_down_layer_time', 'slow_down_min_speed', 'filament_start_gcode',
    'filament_end_gcode', 'filament_change_extrusion_role_gcode',
    'activate_air_filtration', 'activate_air_filtration_during_print',
    'activate_air_filtration_on_completion', 'during_print_exhaust_fan_speed',
    'complete_print_exhaust_fan_speed', 'filament_retraction_length', 'filament_z_hop',
    'filament_z_hop_types', 'filament_retract_lift_above',
    'filament_retract_lift_below', 'filament_retract_lift_enforce',
    'filament_retraction_speed', 'filament_deretraction_speed',
    'filament_retract_restart_extra', 'filament_retraction_minimum_travel',
    'filament_retract_when_changing_layer', 'filament_wipe',
    'filament_retract_before_wipe', 'filament_vendor', 'compatible_prints',
    'compatible_prints_condition', 'compatible_printers',
    'compatible_printers_condition', 'inherits', 'filament_wipe_distance',
    'additional_cooling_fan_speed', 'nozzle_temperature_range_low',
    'nozzle_temperature_range_high', 'filament_extruder_variant',
    'enable_pressure_advance', 'pressure_advance', 'adaptive_pressure_advance',
    'adaptive_pressure_advance_model', 'adaptive_pressure_advance_overhangs',
    'adaptive_pressure_advance_bridges', 'chamber_temperature', 'filament_shrink',
    'filament_shrinkage_compensation_z', 'support_material_interface_fan_speed',
    'internal_bridge_fan_speed', 'filament_notes', 'filament_seam_gap',
    'ironing_fan_speed', 'filament_ironing_flow', 'filament_ironing_spacing',
    'filament_ironing_inset', 'filament_ironing_speed', 'filament_loading_speed',
    'filament_loading_speed_start', 'filament_unloading_speed',
    'filament_unloading_speed_start', 'filament_toolchange_delay',
    'filament_cooling_moves', 'filament_stamping_loading_speed',
    'filament_stamping_distance', 'filament_cooling_initial_speed',
    'filament_cooling_final_speed', 'filament_ramming_parameters',
    'filament_multitool_ramming', 'filament_multitool_ramming_volume',
    'filament_multitool_ramming_flow', 'activate_chamber_temp_control',
    'chamber_minimal_temperature', 'filament_long_retractions_when_cut',
    'filament_retraction_distances_when_cut', 'idle_temperature',
    'filament_change_length', 'filament_flush_volumetric_speed', 'filament_flush_temp',
    'filament_cooling_before_tower', 'long_retractions_when_ec',
    'retraction_distances_when_ec'
]

# 印刷結果に関係しない / 環境依存の項目
DROP_KEYS = {"print_host", "print_host_webui", "printhost_apikey", "printhost_cafile",
             "printhost_password", "printhost_user", "printhost_port"}


def parse_config(path):
    cfg, inside = {}, False
    for line in path.open(encoding="utf-8"):
        line = line.rstrip("\n")
        if line.startswith("; CONFIG_BLOCK_START"):
            inside = True
        elif line.startswith("; CONFIG_BLOCK_END"):
            break
        elif inside:
            m = re.match(r"^; (\S+) = ?(.*)$", line)
            if m and m.group(1) not in DROP_KEYS:
                cfg[m.group(1)] = m.group(2)
    if not cfg:
        sys.exit(f"{path}: CONFIG_BLOCK が見つからない (OrcaSlicer の G-code か確認)")
    return cfg


def unquote(s):
    return s[1:-1] if len(s) >= 2 and s[0] == s[-1] == '"' else s


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    src, outdir = Path(sys.argv[1]), Path(sys.argv[2])
    cfg = parse_config(src)

    # inherits_group = "<process>";"<filament>";"<machine>"
    groups = [unquote(g) for g in cfg["inherits_group"].split(";")]
    inh_process, inh_filament, inh_machine = (groups + ["", "", ""])[:3]

    meta = {"from": "User", "instantiation": "true"}
    machine = {**cfg, **meta, "type": "machine",
               "name": unquote(cfg["printer_settings_id"]), "inherits": inh_machine}
    process = {**cfg, **meta, "type": "process",
               "name": unquote(cfg["print_settings_id"]), "inherits": inh_process,
               "compatible_printers": [inh_machine]}
    filament = {**{k: cfg[k] for k in FILAMENT_KEYS if k in cfg}, **meta, "type": "filament",
                "name": unquote(cfg["filament_settings_id"]), "inherits": inh_filament,
                "filament_id": unquote(cfg.get("filament_ids", "")),
                "compatible_printers": [inh_machine]}

    outdir.mkdir(parents=True, exist_ok=True)
    for kind, data in (("machine", machine), ("process", process), ("filament", filament)):
        out = outdir / f"{kind}.json"
        out.write_text(json.dumps(data, ensure_ascii=False, indent=2, sort_keys=True) + "\n",
                       encoding="utf-8")
        print(f"{out}: {data['name']}")


if __name__ == "__main__":
    main()
