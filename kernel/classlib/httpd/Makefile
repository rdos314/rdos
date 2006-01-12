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
    httpcmd.cpp \
    httpcust.cpp \
    httpdata.cpp \
    httpfact.cpp \
    httpopt.cpp \
    httppars.cpp \
    httpserv.cpp

EXOBJS	=\
	$(oDir)/httpcmd.o \
	$(oDir)/httpcust.o \
	$(oDir)/httpdata.o \
	$(oDir)/httpfact.o \
	$(oDir)/httpopt.o \
	$(oDir)/httppars.o \
	$(oDir)/httpserv.o

ALLOBJS	=	$(EXOBJS)
ALLBIN	=	$(Bin)/httpd.a
ALLTGT	=	$(Bin)/httpd.a

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

$(Bin)/httpd.a: $(EXOBJS)
	rm -f $(Bin)/httpd.a
	rdos-ar cr $(Bin)/httpd.a $(EXOBJS)
	rdos-ranlib $(Bin)/httpd.a
