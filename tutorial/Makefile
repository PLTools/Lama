FILES=$(wildcard *.lama)
ALL=$(sort $(FILES:.lama=))
EXTRA_TARGETS =

ifeq ($(LAMAC),)
	LAMAC := ../src/lamac
	EXTRA_TARGETS += $(LAMAC)
endif

all: $(EXTRA_TARGETS) $(ALL)

../src/lamac:
	$(MAKE) -C ../src

%: %.lama
	$(LAMAC) $<

clean:
	$(RM) -R *.s *.o *.i *~ $(ALL)
