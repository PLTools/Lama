.PHONY: all

all:
	@echo "build Lama in Lama"
	@make -C src
	@make -C runtime
	@echo "regression Lama in Lama"
	@make -C regression

clean:
	make clean -C src
	make clean -C runtime
	make clean -C regression


