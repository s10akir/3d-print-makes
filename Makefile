OPENSCAD ?= openscad
BACKEND  ?= manifold
FORMAT   ?= stl
OUT      ?= out
PROFILE_DIR ?= profiles/orca
PROFILES := $(wildcard $(PROFILE_DIR)/*.json)
export PROFILE_DIR

export OPENSCADPATH := $(CURDIR)/lib

SRCS   := $(wildcard models/*.scad)
MODELS := $(patsubst models/%.scad,$(OUT)/%.$(FORMAT),$(SRCS))
PNGS   := $(patsubst models/%.scad,$(OUT)/%.png,$(SRCS))

SCAD_FLAGS := --backend=$(BACKEND)
PNG_FLAGS  := --autocenter --viewall --imgsize=1024,768 --colorscheme=Tomorrow

.PHONY: all png clean status
all: $(MODELS)
png: $(PNGS)

$(OUT)/%.stl: models/%.scad | $(OUT)
	$(OPENSCAD) $(SCAD_FLAGS) -d $@.d -o $@ $<

$(OUT)/%.3mf: models/%.scad | $(OUT)
	$(OPENSCAD) $(SCAD_FLAGS) -d $@.d -o $@ $<

$(OUT)/%.png: models/%.scad | $(OUT)
	$(OPENSCAD) $(SCAD_FLAGS) $(PNG_FLAGS) -d $@.d -o $@ $<

# スライス (profiles/orca のプリセットを使用)
# out/foo@9.gcode のように @N を付けると foo を N 個並べてスライスする
.SECONDEXPANSION:
$(OUT)/%.gcode: $$(OUT)/$$(firstword $$(subst @, ,$$*)).stl $(PROFILES) tools/slice.sh
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
