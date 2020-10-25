.PHONY: clean

OUT = bench.exe
OUT2 = demo_infix.exe
LAMA_CMXES = ../src/Language.cmx
OCAMLC = ocamlfind c
OCAMLOPT = ocamlfind opt
BFLAGS += -package GT,ostap,re,benchmark,str -I ../src -rectypes -g
GENERATED = Pprint_gt.ml Pprint_default.ml

all: $(OUT) $(OUT2)

demo_infix.cmx bench_main.cmx: Pprint_gt.cmx Pprint_default.cmx

$(OUT): Pprint_gt.cmx Pprint_default.cmx bench_main.cmx
	$(OCAMLOPT) $(BFLAGS) $(LAMA_CMXES) -linkpkg $^ -o $@

$(OUT2): Pprint_gt.cmx Pprint_default.cmx demo_infix.cmx
	$(OCAMLOPT) $(BFLAGS) $(LAMA_CMXES) -linkpkg $^ -o $@

clean:
	$(RM) *.cmi *.cmo *.cmx *.annot *.o *.opt *.byte *~ .depend $(OUT) $(GENERATED)

%.cmi: %.ml
	$(OCAMLC) -c $(BFLAGS)  $<

%.cmx: %.ml
	$(OCAMLOPT) -c $(BFLAGS) $<


###############
Pprint_gt.ml: pp_gt.m4 p.ml
	m4 $< p.ml > $@

###############
Pprint_default.ml: pp_default.m4 p.ml
	m4 $< p.ml > $@
