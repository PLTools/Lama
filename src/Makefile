TOPFILE = lamac
OCAMLC = ocamlfind c
OCAMLOPT = ocamlfind opt
OCAMLDEP = ocamlfind dep
PRE_SOURCES = Language.ml SM.ml X86.ml Driver.ml
SOURCES = version.ml stdpath.ml $(PRE_SOURCES) 
CAMLP5 = -syntax camlp5o -package ostap.syntax,GT.syntax.all
PXFLAGS = $(CAMLP5)
BFLAGS = -rectypes -g
OFLAGS = $(BFLAGS)

all: metagen .depend $(TOPFILE)

metagen:
	echo "let version = \"Version `git rev-parse --abbrev-ref HEAD`, `git rev-parse --short HEAD`, `git rev-parse --verify HEAD |git show --no-patch --no-notes --pretty='%cd'`\"" > version.ml
	echo "let path = \"`opam var share`/Lama\"" > stdpath.ml

.depend: $(PRE_SOURCES)
	$(OCAMLDEP) $(PXFLAGS) *.ml > .depend

$(TOPFILE): $(SOURCES:.ml=.cmx)
	$(OCAMLOPT) -o $(TOPFILE) $(OFLAGS) $(LIBS:.cma=.cmxa) -linkpkg -package ostap $(SOURCES:.ml=.cmx)

$(TOPFILE).byte: $(SOURCES:.ml=.cmo)
	$(OCAMLC) -o $(TOPFILE).byte $(BFLAGS) $(LIBS) -linkpkg -package ostap $(SOURCES:.ml=.cmo) 

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

