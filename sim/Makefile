#
# Makefile for building test benches with GHDL (the free VHDL compiler).
#

GHDL = ghdl
GHDLFLAGS =

.PHONY: all
all: tb_xoroshiro128plus

tb_xoroshiro128plus: tb_xoroshiro128plus.o rng_xoroshiro128plus.o
tb_xoroshiro128plus.o: tb_xoroshiro128plus.vhdl rng_xoroshiro128plus.o
rng_xoroshiro128plus.o: ../rtl/rng_xoroshiro128plus.vhdl

tb_%: tb_%.o
	$(GHDL) $(GHDLFLAGS) -e $@

%.o: %.vhdl
	$(GHDL) $(GHDLFLAGS) -a $<

%.o: ../rtl/%.vhdl
	$(GHDL) $(GHDLFLAGS) -a $<

.PHONY: clean
clean:
	$(GHDL) --remove

