# This Makefile is used under Linux

MATLABDIR ?= /usr/local/MATLAB/R2011a
CXX ?= g++
#CXX = g++-3.3
CC ?= gcc
CFLAGS = -Wall -Wconversion -O3 -fPIC -I$(MATLABDIR)/extern/include -I..

MEX = $(MATLABDIR)/bin/mex
MEX_OPTION = CC="$(CXX)" CXX="$(CXX)" CFLAGS="$(CFLAGS)" CXXFLAGS="$(CFLAGS)"
# comment the following line if you use MATLAB on a 32-bit computer
MEX_OPTION += -largeArrayDims
MEX_EXT = $(shell $(MATLABDIR)/bin/mexext)

all:	matlab

matlab:	binary

octave:
	@echo "please type make under Octave"
binary:mex_feature.$(MEX_EXT)

mex_feature.$(MEX_EXT): mex_feature.cpp ../linear.h ../tron.o ../linear.o linear_model_matlab.o ../blas/blas.a
	$(MEX) $(MEX_OPTION) mex_feature.cpp ../tron.o ../linear.o linear_model_matlab.o ../blas/blas.a

../linear.o: ../linear.cpp ../linear.h
	make -C .. linear.o

../tron.o: ../tron.cpp ../tron.h 
	make -C .. tron.o

linear_model_matlab.o: linear_model_matlab.c ../linear.h
	$(CXX) $(CFLAGS) -c linear_model_matlab.c

../blas/blas.a: ../blas/*.c ../blas/*.h
	make -C ../blas OPTFLAGS='$(CFLAGS)' CC='$(CC)';

clean:
	make -C ../blas clean
	rm -f *~ *.o *.mex* *.obj ../linear.o ../tron.o
