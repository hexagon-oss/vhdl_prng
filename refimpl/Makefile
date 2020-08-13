#
# Makefile for software reference implementations of PRNGs.
#
# This makefile works with GCC under Linux.
#

CC = gcc
CXX = g++
CFLAGS = -std=c11 -Wall -O2
CXXFLAGS = -std=c++11 -Wall -O2

.PHONY: all
all: ref_xoshiro128plusplus \
     ref_xoroshiro128plus \
     ref_mt19937 \
     ref_trivium

ref_xoshiro128plusplus: ref_xoshiro128plusplus.c
ref_xoroshiro128plus: ref_xoroshiro128plus.c

ref_mt19937: ref_mt19937.cpp

ref_trivium: ref_trivium.cpp

.PHONY: clean
clean:
	$(RM) ref_xoshiro128plusplus
	$(RM) ref_xoroshiro128plus
	$(RM) ref_mt19937
	$(RM) ref_trivium

