.PHONY: all obj bytecode

SHELL := /bin/bash
SRCDIR ?= .
$(info SRCDIR = $(SRCDIR))
FILES ?= $(wildcard $(SRCDIR)/*.lama)
$(info FILES = $(FILES))
OFILES = $(FILES:$(SRCDIR)/%=%)
OFILES := $(OFILES:.lama=.o)
$(info OFILES = $(OFILES))
BCFILES = $(OFILES:.o=.bc)
ALL := $(sort $(OFILES))
LAMAC ?= ../src/lamac
BDIR ?= .

all: obj

obj: $(addprefix $(BDIR)/,$(ALL))
$(info ALL = $(ALL), SRCDIR = $(SRCDIR))

bytecode: obj $(addprefix $(BDIR)/,$(BCFILES))
$(BDIR)/Fun.o: $(BDIR)/Ref.o

$(BDIR)/Data.o: $(BDIR)/Ref.o $(BDIR)/Collection.o

$(BDIR)/Queue.o: $(BDIR)/List.o

$(BDIR)/Collection.o: $(BDIR)/List.o $(BDIR)/Ref.o

$(BDIR)/Array.o: $(BDIR)/List.o
$(BDIR)/Random.o $(BDIR)/Collection.o: $(BDIR)/Array.o
$(BDIR)/Ostap.o: $(BDIR)/List.o $(BDIR)/Collection.o $(BDIR)/Ref.o $(BDIR)/Fun.o $(BDIR)/Matcher.o $(BDIR)/Data.o

$(BDIR)/Buffer.o: $(BDIR)/List.o

$(BDIR)/STM.o: $(BDIR)/List.o $(BDIR)/Fun.o

$(BDIR)/%.o: $(SRCDIR)/%.lama
	$(LAMAC) -g -I . -c $< #-o $@

$(BDIR)/%.bc: $(SRCDIR)/%.lama obj
	$(LAMAC) -I . -b $<

clean:
	$(RM) -r *.s *.o *.i *.bc *~
	pushd regression && make clean && popd

