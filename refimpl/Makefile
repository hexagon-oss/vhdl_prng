#
# Makefile for software reference implementations of PRNGs.
#
# This makefile works with GCC under Linux.
#

.PHONY: all
all: ref_xoroshiro ref_mt19937

ref_xoroshiro: ref_xoroshiro.c
	$(CC) -std=c11 -Wall -O2 -o $@ $<

ref_mt19937: ref_mt19937.cpp
	$(CXX) -std=c++11 -Wall -O2 -o $@ $<

.PHONY: clean
clean:
	$(RM) ref_xoroshiro ref_mt19937

