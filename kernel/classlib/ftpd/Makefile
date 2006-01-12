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
    ftpacc.cpp \
    ftpcdup.cpp \
    ftpcmd.cpp \
    ftpcwd.cpp \
    ftpdele.cpp \
    ftpfact.cpp \
    ftplist.cpp \
    ftpmdtm.cpp \
    ftpmkd.cpp \
    ftpparse.cpp \
    ftppass.cpp \
    ftppasv.cpp \
    ftpport.cpp \
    ftppwd.cpp \
    ftpquit.cpp \
    ftpretr.cpp \
    ftprmd.cpp \
    ftpserv.cpp \
    ftpstor.cpp \
    ftpsyst.cpp \
    ftptype.cpp \
    ftpuser.cpp

EXOBJS	=\
	$(oDir)/ftpacc.o \
    $(oDir)/ftpcdup.o \
    $(oDir)/ftpcmd.o \
    $(oDir)/ftpcwd.o \
    $(oDir)/ftpdele.o \
    $(oDir)/ftpfact.o \
    $(oDir)/ftplist.o \
    $(oDir)/ftpmdtm.o \
    $(oDir)/ftpmkd.o \
    $(oDir)/ftpparse.o \
    $(oDir)/ftppass.o \
    $(oDir)/ftppasv.o \
    $(oDir)/ftpport.o \
    $(oDir)/ftppwd.o \
    $(oDir)/ftpquit.o \
    $(oDir)/ftpretr.o \
    $(oDir)/ftprmd.o \
    $(oDir)/ftpserv.o \
    $(oDir)/ftpstor.o \
    $(oDir)/ftpsyst.o \
    $(oDir)/ftptype.o \
    $(oDir)/ftpuser.o

ALLOBJS	=	$(EXOBJS)
ALLBIN	=	$(Bin)/ftpd.a
ALLTGT	=	$(Bin)/ftpd.a

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

$(Bin)/ftpd.a: $(EXOBJS)
	rm -f $(Bin)/ftpd.a
	rdos-ar cr $(Bin)/ftpd.a $(EXOBJS)
	rdos-ranlib $(Bin)/ftpd.a
