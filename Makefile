OPENSCAD ?= openscad
BACKEND  ?= manifold
FORMAT   ?= stl
OUT      ?= out
PROFILE_DIR ?= profiles/orca
# プリンターに載せているフィラメント (profiles/orca/filaments/<FILAMENT>.json)
FILAMENT ?= rapid_pla_plus
PROFILES := $(PROFILE_DIR)/machine.json $(PROFILE_DIR)/process.json $(PROFILE_DIR)/filaments/$(FILAMENT).json
export PROFILE_DIR FILAMENT
ifeq ($(wildcard $(PROFILE_DIR)/filaments/$(FILAMENT).json),)
$(error フィラメントのプリセットがない: $(PROFILE_DIR)/filaments/$(FILAMENT).json)
endif

export OPENSCADPATH := $(CURDIR)/lib

SRCS   := $(wildcard models/*.scad)
MODELS := $(patsubst models/%.scad,$(OUT)/%.$(FORMAT),$(SRCS))
PNGS   := $(patsubst models/%.scad,$(OUT)/%.png,$(SRCS))

SCAD_FLAGS := --backend=$(BACKEND)
PNG_FLAGS  := --autocenter --viewall --imgsize=1024,768 --colorscheme=Tomorrow

.PHONY: all png clean status FORCE
all: $(MODELS)
png: $(PNGS)

$(OUT)/%.stl: models/%.scad | $(OUT)
	$(OPENSCAD) $(SCAD_FLAGS) -d $@.d -o $@ $<

$(OUT)/%.3mf: models/%.scad | $(OUT)
	$(OPENSCAD) $(SCAD_FLAGS) -d $@.d -o $@ $<

$(OUT)/%.png: models/%.scad | $(OUT)
	$(OPENSCAD) $(SCAD_FLAGS) $(PNG_FLAGS) -d $@.d -o $@ $<

# スライス (profiles/orca のプリセットと FILAMENT のフィラメントを使用)
# out/foo@9.gcode のように @N を付けると foo を N 個並べてスライスする
# FILAMENT を切り替えたら作り直すよう、使ったフィラメント名を out/.filament に残す
FILAMENT_STAMP := $(OUT)/.filament
$(FILAMENT_STAMP): FORCE | $(OUT)
	@[ "$$(cat $@ 2>/dev/null)" = "$(FILAMENT)" ] || echo "$(FILAMENT)" > $@

.SECONDEXPANSION:
$(OUT)/%.gcode: $$(OUT)/$$(firstword $$(subst @, ,$$*)).stl $(PROFILES) $(FILAMENT_STAMP) tools/slice.sh
	COPIES=$(or $(word 2,$(subst @, ,$*)),1) tools/slice.sh $< $@

# プリンター操作: make print-<model> / make upload-<model> / make status
print-%: $(OUT)/%.gcode
	tools/moonraker.sh print $<

upload-%: $(OUT)/%.gcode
	tools/moonraker.sh upload $<

status:
	@tools/moonraker.sh status

$(OUT):
	mkdir -p $@

clean:
	rm -rf $(OUT)

# 中間生成物 (STL) を自動削除しない
.SECONDARY:

-include $(wildcard $(OUT)/*.d)
