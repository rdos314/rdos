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
INCLUDES=	-I. -I../ -I../../ -I../jpeg -I../zlib

LD_FLAGS =	-s
LIBS	=	
CFLAGS	=	-O

.cpp.o:
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

SRCS	=\
	../bmp.cpp \
	../device.cpp \
	../gif.cpp \
	../jpeg.cpp \
	../png.cpp \
	../sample.cpp \
	../secsamp.cpp \
	../minsamp.cpp \
	../hoursamp.cpp \
	../daysamp.cpp \
	../montsamp.cpp \
	../yearsamp.cpp \
	../tempdev.cpp \
	../lightdev.cpp \
	../str.cpp \
	../ymodem.cpp \
	../axis.cpp \
	../xaxis.cpp \
	../yaxis.cpp \
	../linxaxis.cpp \
	../linyaxis.cpp \
	../chart.cpp \
	../list.cpp \
	../shareobj.cpp \
	../listbase.cpp \
	../strlist.cpp \
	../filestor.cpp \
	../discstor.cpp \
	../storlist.cpp \
	../redustor.cpp \
	../spltstor.cpp \
	../part.cpp \
	bitdev.cpp \
	datetime.cpp \
    file.cpp \
    font.cpp \
    graphdev.cpp \
    keyboard.cpp \
    mouse.cpp \
    section.cpp \
    serial.cpp \
    sprite.cpp \
    waitdev.cpp \
    videodev.cpp \
    adcdev.cpp \
    env.cpp \
    path.cpp \
    direntry.cpp \
    socket.cpp \
    thread.cpp \
    sigdev.cpp \
    rdfspart.cpp \
    fatpart.cpp \
    ffspart.cpp \
    disc.cpp \
    drive.cpp \
    fddisc.cpp \
    idedisc.cpp \
    serdist.cpp

EXOBJS	=\
	$(oDir)/bitdev.o \
	$(oDir)/bmp.o \
	$(oDir)/datetime.o \
	$(oDir)/device.o \
	$(oDir)/file.o \
	$(oDir)/font.o \
	$(oDir)/gif.o \
	$(oDir)/graphdev.o \
	$(oDir)/jpeg.o \
	$(oDir)/keyboard.o \
	$(oDir)/mouse.o \
	$(oDir)/png.o \
	$(oDir)/section.o \
	$(oDir)/serial.o \
	$(oDir)/sprite.o \
	$(oDir)/waitdev.o \
	$(oDir)/videodev.o \
	$(oDir)/adcdev.o \
	$(oDir)/sample.o \
	$(oDir)/secsamp.o \
	$(oDir)/minsamp.o \
	$(oDir)/hoursamp.o \
	$(oDir)/daysamp.o \
	$(oDir)/montsamp.o \
	$(oDir)/yearsamp.o \
	$(oDir)/tempdev.o \
	$(oDir)/lightdev.o \
	$(oDir)/env.o \
	$(oDir)/str.o \
	$(oDir)/path.o \
	$(oDir)/ymodem.o \
	$(oDir)/axis.o \
	$(oDir)/xaxis.o \
	$(oDir)/yaxis.o \
	$(oDir)/linxaxis.o \
	$(oDir)/linyaxis.o \
	$(oDir)/chart.o \
	$(oDir)/list.o \
	$(oDir)/shareobj.o \
	$(oDir)/listbase.o \
	$(oDir)/strlist.o \
	$(oDir)/direntry.o \
	$(oDir)/filestor.o \
	$(oDir)/discstor.o \
	$(oDir)/storlist.o \
	$(oDir)/redustor.o \
	$(oDir)/spltstor.o \
    $(oDir)/socket.o \
    $(oDir)/thread.o \
    $(oDir)/sigdev.o \
    $(oDir)/part.o \
    $(oDir)/rdfspart.o \
    $(oDir)/fatpart.o \
    $(oDir)/ffspart.o \
    $(oDir)/disc.o \
    $(oDir)/drive.o \
    $(oDir)/fddisc.o \
    $(oDir)/idedisc.o \
    $(oDir)/serdist.o	

ALLOBJS	=	$(EXOBJS)
ALLBIN	=	$(Bin)/rdos.a
ALLTGT	=	$(Bin)/rdos.a

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

device.o: ../device.cpp 
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

gif.o: ../gif.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

jpeg.o:  ../jpeg.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

png.o: ../png.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

list.o: ../list.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

shareobj.o: ../shareobj.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

listbase.o: ../listbase.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

strlist.o: ../strlist.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

discstor.o: ../discstor.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

storlist.o: ../storlist.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

redustor.o: ../redustor.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

spltstor.o: ../spltstor.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

part.o: ../part.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

bmp.o: ../bmp.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

sample.o: ../sample.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

secsamp.o: ../secsamp.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

minsamp.o: ../minsamp.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

hoursamp.o: ../hoursamp.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

daysamp.o: ../daysamp.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

montsamp.o: ../montsamp.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

yearsamp.o: ../yearsamp.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

tempdev.o: ../tempdev.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

lightdev.o: ../lightdev.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

str.o: ../str.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

ymodem.o: ../ymodem.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

axis.o: ../axis.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

xaxis.o: ../xaxis.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

yaxis.o: ../yaxis.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

linxaxis.o: ../linxaxis.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

linyaxis.o: ../linyaxis.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

chart.o: ../chart.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

filestor.o: ../filestor.cpp
	$(CC) $(CFLAGS) -O2 $(INCLUDES) -c $<

include Makefile.dep

#@# Dependency rules follow -----------------------------

$(Bin)/rdos.a: $(EXOBJS)
	rm -f $(Bin)/rdos.a
	rdos-ar cr $(Bin)/rdos.a $(EXOBJS)
	rdos-ranlib $(Bin)/rdos.a
