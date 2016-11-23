#
# Makefile for building test benches with GHDL (the free VHDL compiler).
#

GHDL = ghdl
GHDLFLAGS =

.PHONY: all
all: tb_xoroshiro128plus tb_mt19937 tb_trivium

tb_xoroshiro128plus: tb_xoroshiro128plus.o rng_xoroshiro128plus.o
tb_xoroshiro128plus.o: tb_xoroshiro128plus.vhdl rng_xoroshiro128plus.o
rng_xoroshiro128plus.o: ../rtl/rng_xoroshiro128plus.vhdl

tb_mt19937:	tb_mt19937.o rng_mt19937.o
tb_mt19937.o:	tb_mt19937.vhdl rng_mt19937.o
rng_mt19937.o:	../rtl/rng_mt19937.vhdl

tb_trivium:	tb_trivium.o rng_trivium.o
tb_trivium.o:	tb_trivium.vhdl rng_trivium.o
rng_trivium.o:	../rtl/rng_trivium.vhdl

tb_%: tb_%.o
	$(GHDL) $(GHDLFLAGS) -e $@

%.o: %.vhdl
	$(GHDL) $(GHDLFLAGS) -a $<

%.o: ../rtl/%.vhdl
	$(GHDL) $(GHDLFLAGS) -a $<

.PHONY: clean
clean:
	$(GHDL) --remove

