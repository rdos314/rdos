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
CC  	=	rdos-gcc
oDir	=	.
Bin	=	.
libDirs	=
INCLUDES=	-I. -I../ -I../../ -I../rdos

LD_FLAGS =	-s
LIBS	=	
CFLAGS	=	-O

.cpp.o:
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

SRCS	=\
    jcapimin.cpp \
    jcapistd.cpp \
    jccoefct.cpp \
    jccolor.cpp \
    jcdctmgr.cpp \
    jchuff.cpp \
    jcinit.cpp \
    jcmainct.cpp \
    jcmarker.cpp \
    jcmaster.cpp \
    jcomapi.cpp \
    jcparam.cpp \
    jcphuff.cpp \
    jcprepct.cpp \
    jcsample.cpp \
    jctrans.cpp \
    jdapimin.cpp \
    jdapistd.cpp \
    jdatadst.cpp \
    jdatasrc.cpp \
    jdcoefct.cpp \
    jdcolor.cpp \
    jddctmgr.cpp \
    jdhuff.cpp \
    jdinput.cpp \
    jdmainct.cpp \
    jdmarker.cpp \
    jdmaster.cpp \
    jdmerge.cpp \
    jdphuff.cpp \
    jdpostct.cpp \
    jdsample.cpp \
    jdtrans.cpp \
    jerror.cpp \
    jfdctflt.cpp \
    jfdctfst.cpp \
    jfdctint.cpp \
    jidctflt.cpp \
    jidctfst.cpp \
    jidctint.cpp \
    jidctred.cpp \
    jmemmgr.cpp \
    jmemnobs.cpp \
    jquant1.cpp \
    jquant2.cpp \
    jutils.cpp

EXOBJS	=\
	$(oDir)/jcapimin.o \
	$(oDir)/jcapistd.o \
	$(oDir)/jccoefct.o \
	$(oDir)/jccolor.o \
	$(oDir)/jcdctmgr.o \
	$(oDir)/jchuff.o \
	$(oDir)/jcinit.o \
	$(oDir)/jcmainct.o \
	$(oDir)/jcmarker.o \
	$(oDir)/jcmaster.o \
	$(oDir)/jcomapi.o \
	$(oDir)/jcparam.o \
    $(oDir)/jcphuff.o \
    $(oDir)/jcprepct.o \
    $(oDir)/jcsample.o \
    $(oDir)/jctrans.o \
    $(oDir)/jdapimin.o \
    $(oDir)/jdapistd.o \
    $(oDir)/jdatadst.o \
    $(oDir)/jdatasrc.o \
    $(oDir)/jdcoefct.o \
    $(oDir)/jdcolor.o \
    $(oDir)/jddctmgr.o \
    $(oDir)/jdhuff.o \
    $(oDir)/jdinput.o \
    $(oDir)/jdmainct.o \
    $(oDir)/jdmarker.o \
    $(oDir)/jdmaster.o \
    $(oDir)/jdmerge.o \
    $(oDir)/jdphuff.o \
    $(oDir)/jdpostct.o \
    $(oDir)/jdsample.o \
    $(oDir)/jdtrans.o \
    $(oDir)/jerror.o \
    $(oDir)/jfdctflt.o \
    $(oDir)/jfdctfst.o \
    $(oDir)/jfdctint.o \
    $(oDir)/jidctflt.o \
    $(oDir)/jidctfst.o \
    $(oDir)/jidctint.o \
    $(oDir)/jidctred.o \
    $(oDir)/jmemmgr.o \
    $(oDir)/jmemnobs.o \
    $(oDir)/jquant1.o \
    $(oDir)/jquant2.o \
    $(oDir)/jutils.o

ALLOBJS	=	$(EXOBJS)
ALLBIN	=	$(Bin)/jpeg.a
ALLTGT	=	$(Bin)/jpeg.a

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

$(Bin)/jpeg.a: $(EXOBJS)
	rm -f $(Bin)/jpeg.a
	rdos-ar cr $(Bin)/jpeg.a $(EXOBJS)
	rdos-ranlib $(Bin)/jpeg.a
