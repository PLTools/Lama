.PHONY: clean

GTD = tool.exe

LAMA_CMXES = ../src/Language.cmx
OCAMLC = ocamlfind c
OCAMLOPT = ocamlfind opt
BFLAGS += -package GT,ostap,re,str -I ../src -rectypes -g

all: $(GTD) $(OUT2)



$(GTD): tool.cmx
	$(OCAMLOPT) $(BFLAGS) $(LAMA_CMXES) -linkpkg $^ -o $@


clean:
	$(RM) *.cmi *.cmo *.cmx *.annot *.o *.opt *.byte *~ .depend $(OUT) $(GENERATED)

%.cmi: %.ml
	$(OCAMLC) -c $(BFLAGS)  $<

%.cmx: %.ml
	$(OCAMLOPT) -c $(BFLAGS) $<
