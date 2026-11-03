OPENSCAD ?= openscad
BACKEND  ?= manifold
FORMAT   ?= stl
OUT      ?= out

export OPENSCADPATH := $(CURDIR)/lib

SRCS   := $(wildcard models/*.scad)
MODELS := $(patsubst models/%.scad,$(OUT)/%.$(FORMAT),$(SRCS))
PNGS   := $(patsubst models/%.scad,$(OUT)/%.png,$(SRCS))

SCAD_FLAGS := --backend=$(BACKEND)
PNG_FLAGS  := --autocenter --viewall --imgsize=1024,768 --colorscheme=Tomorrow

.PHONY: all png clean
all: $(MODELS)
png: $(PNGS)

$(OUT)/%.$(FORMAT): models/%.scad | $(OUT)
	$(OPENSCAD) $(SCAD_FLAGS) -d $@.d -o $@ $<

$(OUT)/%.png: models/%.scad | $(OUT)
	$(OPENSCAD) $(SCAD_FLAGS) $(PNG_FLAGS) -d $@.d -o $@ $<

$(OUT):
	mkdir -p $@

clean:
	rm -rf $(OUT)

-include $(wildcard $(OUT)/*.d)
