#######################################################################
# RDOS operating system
# Copyright (C) 1988-2005, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# Makefile for GCC
#
########################################################################*/

# Standard defines:
CC  	=	rdos-g++
oDir	=	.
Bin	=	.
libDirs	=
INCLUDES=	-I. -I../ -I../../ -I../zlib

LD_FLAGS =	-s
LIBS	=	
CFLAGS	=	-O

.cpp.o:
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

SRCS	=\
    png.cpp \
    pngerror.cpp \
    pngget.cpp \
    pngmem.cpp \
    pngread.cpp \
    pngrio.cpp \
    pngrtran.cpp \
    pngrutil.cpp \
    pngset.cpp \
    pngtrans.cpp \
    pngwio.cpp \
    pngwrite.cpp \
    pngwtran.cpp \
    pngwutil.cpp

EXOBJS	=\
	$(oDir)/png.o \
	$(oDir)/pngerror.o \
	$(oDir)/pngget.o \
	$(oDir)/pngmem.o \
	$(oDir)/pngread.o \
	$(oDir)/pngrio.o \
	$(oDir)/pngrtran.o \
	$(oDir)/pngrutil.o \
	$(oDir)/pngset.o \
	$(oDir)/pngtrans.o \
	$(oDir)/pngwio.o \
	$(oDir)/pngwrite.o \
	$(oDir)/pngwtran.o \
	$(oDir)/pngwutil.o

ALLOBJS	=	$(EXOBJS)
ALLBIN	=	$(Bin)/png.a
ALLTGT	=	$(Bin)/png.a

# User defines:

#@# Targets follow ---------------------------------

all:	$(ALLTGT) Makefile.dep

objs:	$(ALLOBJS)

cleanobjs:
	rm -f $(ALLOBJS)
	rm -f Makefile.dep

cleanbin:
	rm -f $(ALLBIN)

clean:	cleanobjs cleanbin

cleanall:	cleanobjs cleanbin

Makefile.dep:   $(SRCS) Makefile
	$(CC) -M $(INCLUDES) $(SRCS) >Makefile.dep

#@# User Targets follow ---------------------------------

include Makefile.dep

#@# Dependency rules follow -----------------------------

$(Bin)/png.a: $(EXOBJS)
	rm -f $(Bin)/png.a
	rdos-ar cr $(Bin)/png.a $(EXOBJS)
	rdos-ranlib $(Bin)/png.a
