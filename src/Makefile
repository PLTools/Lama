TOPFILE = rc
OCAMLC = ocamlc
OCAMLOPT = ocamlopt
OCAMLDEP = ocamldep
SOURCES = Language.ml SM.ml Driver.ml
LIBS = GT.cma unix.cma re.cma re_emacs.cma re_str.cma
CAMLP5 = -pp "camlp5o -I `ocamlfind -query GT.syntax` -I `ocamlfind -query ostap.syntax` pa_ostap.cmo pa_gt.cmo -L `ocamlfind -query GT.syntax`"
PXFLAGS = $(CAMLP5)
BFLAGS = -rectypes -I `ocamlfind -query GT` -I `ocamlfind -query re`  -I `ocamlfind -query ostap` 
OFLAGS = $(BFLAGS)

all: .depend $(TOPFILE).opt

.depend: $(SOURCES)
	$(OCAMLDEP) $(PXFLAGS) *.ml > .depend

$(TOPFILE).opt: $(SOURCES:.ml=.cmx)
	$(OCAMLOPT) -o $(TOPFILE).opt $(OFLAGS) $(LIBS:.cma=.cmxa) ostap.cmx $(SOURCES:.ml=.cmx)

$(TOPFILE).byte: $(SOURCES:.ml=.cmo)
	$(OCAMLC) -o $(TOPFILE).byte $(BFLAGS) $(LIBS) ostap.cma $(SOURCES:.ml=.cmo) 

clean:
	rm -Rf *.cmi *.cmo *.cmx *.annot *.o *.opt *.byte *~ .depend

-include .depend
# generic rules

###############
%.cmi: %.mli
	$(OCAMLC) -c $(BFLAGS) $(PXFLAGS) $<

# Note: cmi <- mli should go first
%.cmi: %.ml
	$(OCAMLC) -c $(BFLAGS) $(PXFLAGS) $<

%.cmo: %.ml
	$(OCAMLC) -c $(BFLAGS) $(PXFLAGS) $<

%.o: %.ml
	$(OCAMLOPT) -c $(OFLAGS) $(STATIC) $(PXFLAGS) $<

%.cmx: %.ml
	$(OCAMLOPT) -c $(OFLAGS) $(STATIC) $(PXFLAGS) $<

