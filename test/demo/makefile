######################################################################
# RDOS operating system
# Copyright (C) 2000, Leif Ekblad
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
# MAKEFILE
# Makefile for Borland MAKE.
#
######################################################################

# DEFINE SYSTEM VERSION  
version = V1_0

prot_opt = /l/s/3/Twe
link_opt = /l/s/3
dll_opt = /l/s/3/Twd

# DEFINE GROUPS OF MODULES

cfg2bin_srcs = CFG2BIN.ASM
cfg2bin_objs = $(cfg2bin_srcs:.ASM=.OBJ)
cfg2bin_exes = CFG2BIN.EXE

boot2bin_srcs = BOOT2BIN.ASM
boot2bin_objs = $(boot2bin_srcs:.ASM=.OBJ)
boot2bin_exes = BOOT2BIN.EXE

bootprom_srcs = BOOTPROM.ASM
bootprom_objs = $(bootprom_srcs:.ASM=.OBJ)
bootprom_exes = BOOTPROM.EXE

aliboot_srcs = ALIBOOT.ASM
aliboot_objs = $(aliboot_srcs:.ASM=.OBJ)
aliboot_exes = ALIBOOT.EXE

elanboot_srcs = ELANBOOT.ASM
elanboot_objs = $(elanboot_srcs:.ASM=.OBJ)
elanboot_exes = ELANBOOT.EXE

load_srcs = BOOTVECT.ASM LOAD.ASM BOOT.ASM
load_objs = $(load_srcs:.ASM=.OBJ)
load_exes = LOAD.EXE

grubload_srcs = GRUB32.ASM	GRUBLOAD.ASM
grubload_objs = $(grubload_srcs:.ASM=.OBJ)
grubload_exes = GRUBLOAD.EXE

acrprom_srcs = ACRPROM.ASM
acrprom_objs = $(acrprom_srcs:.ASM=.OBJ)
acrprom_exes = ACRPROM.EXE

acrloc_srcs = ACRLOC.ASM
acrloc_objs = $(acrloc_srcs:.ASM=.OBJ)
acrloc_exes = ACRLOC.EXE

rdfsboot_srcs = BOOTSEC.ASM BOOTLOAD.ASM BOOT.ASM RDFSBOOT.ASM
rdfsboot_objs = $(rdfsboot_srcs:.ASM=.OBJ)
rdfsboot_exes = RDFSBOOT.EXE

rdfsimg_srcs = BOOTSEC.ASM BOOTLOAD.ASM BOOT.ASM RDFSIMG.ASM
rdfsimg_objs = $(rdfsimg_srcs:.ASM=.OBJ)
rdfsimg_exes = RDFSIMG.EXE

hdimg_srcs = BOOTSEC.ASM HDIMG.ASM
hdimg_objs = $(hdimg_srcs:.ASM=.OBJ)
hdimg_exes = HDIMG.EXE

grubimg_srcs = GRUBIMG.ASM
grubimg_objs = $(grubimg_srcs:.ASM=.OBJ)
grubimg_exes = GRUBIMG.EXE

progfl_srcs = BOOTSEC.ASM BOOTLOAD.ASM BOOT.ASM PROGFL.ASM
progfl_objs = $(progfl_srcs:.ASM=.OBJ)
progfl_exes = PROGFL.EXE

run_srcs = RUN.ASM
run_objs = $(run_srcs:.ASM=.OBJ)
run_exes = RUN.EXE

state_srcs = STATEAPP.ASM
state_objs = $(state_srcs:.ASM=.OBJ)
state_exes = STATEAPP.EXE

remdebug_srcs = REMDEBUG.ASM
remdebug_objs = $(remdebug_srcs:.ASM=.OBJ)
remdebug_exes = REMDEBUG.EXE

test_srcs = TEST.ASM ..\OS\MATH.ASM
test_objs = $(test_srcs:.ASM=.OBJ)
test_exes = TEST.EXE

srcs =      $(cfg2bin_srcs) $(boot2bin_srcs) $(load_srcs) $(acrloc_srcs)    \
			$(bootprom_srcs) $(elanboot_srcs) $(acrprom_srcs) $(aliboot_srcs)	\
			$(rdfsboot_srcs) $(grubload_srcs) $(hdimg_srcs) \
			$(rdfsimg_srcs) $(progfl_srcs) $(grubimg_srcs) \
		    $(test_srcs) $(state_srcs) \
			$(run_srcs) $(remdebug_srcs)

objs =      $(srcs:.ASM=.OBJ)

exes =      $(cfg2bin_exes) $(boot2bin_exes) $(acrprom_exes)  \
			$(load_exes) $(bootprom_exes) $(elanboot_exes) $(aliboot_exes)	\
			$(rdfsboot_exes) $(grubload_exes) $(hdimg_exes) \
			$(rdfsimg_exes) $(progfl_exes) $(grubimg_exes) \
		    $(test_exes) $(state_exes) $(acrloc_exes)	\
			$(run_exes) $(remdebug_exes)

maps =      $(exes:.EXE=.MAP)

cfgs =      DEMO.CFG ALIBOOT.CFG

bins =      $(cfgs:.CFG=.BIN)

# DEFINE MODULES FOR CMS
vaxset_modules = $(srcs) $(incs) $(fonts) $(bats)

# DEFINE MODULES FOR SYSTEM VERSION
kit_modules =   $(maps) $(bats) $(bins)  LOAD.EXE GRUBLOAD.EXE

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# DEFAULT RULES
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.asm.obj:
     tasm /M2 /Zi /w+ICG /w+PRO $<,$@;

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# TARGET
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

MAIN:   BOOT2BIN.EXE CFG2BIN.EXE $(exes) $(bins) GRUBLOAD.BIN

CFG2BIN.EXE : $(cfg2bin_objs)
    tlink @&&!
	$(link_opt) +
	$(cfg2bin_objs)
	CFG2BIN
	CFG2BIN;
!

BOOT2BIN.EXE : $(boot2bin_objs)
    tlink @&&!
	$(link_opt) +
	$(boot2bin_objs)
	BOOT2BIN
	BOOT2BIN;
!

LOAD.EXE : $(load_objs)
    tlink @&&!
	$(link_opt) +
	$(load_objs)
	LOAD
	LOAD;
!

GRUBLOAD.EXE : $(grubload_objs)
    tlink @&&!
	$(link_opt) +
	$(grubload_objs)
	GRUBLOAD
	GRUBLOAD;
!

BOOTPROM.EXE : $(bootprom_objs)
    tlink @&&!
	$(link_opt) +
	$(bootprom_objs)
	BOOTPROM
	BOOTPROM;
!

ALIBOOT.EXE : $(aliboot_objs)
    tlink @&&!
	$(link_opt) +
	$(aliboot_objs)
	ALIBOOT
	ALIBOOT;
!

ELANBOOT.EXE : $(elanboot_objs)
    tlink @&&!
	$(link_opt) +
	$(elanboot_objs)
	ELANBOOT
	ELANBOOT;
!

ACRPROM.EXE : $(acrprom_objs)
    tlink @&&!
	$(link_opt) +
	$(acrprom_objs)
	ACRPROM
	ACRPROM;
!

ACRLOC.EXE : $(acrloc_objs)
    tlink @&&!
	$(link_opt) +
	$(acrloc_objs)
	ACRLOC
	ACRLOC;
!

RDFSBOOT.EXE : $(rdfsboot_objs)
    tlink @&&!
	$(link_opt) +
	$(rdfsboot_objs)
	RDFSBOOT
	RDFSBOOT;
!

RDFSIMG.EXE : $(rdfsimg_objs)
    tlink @&&!
	$(link_opt) +
	$(rdfsimg_objs)
	RDFSIMG
	RDFSIMG;
!

HDIMG.EXE : $(hdimg_objs)
    tlink @&&!
	$(link_opt) +
	$(hdimg_objs)
	HDIMG
	HDIMG;
!

GRUBIMG.EXE : $(grubimg_objs)
    tlink @&&!
	$(link_opt) +
	$(grubimg_objs)
	GRUBIMG
	GRUBIMG;
!

PROGFL.EXE : $(progfl_objs)
    tlink @&&!
	$(link_opt) +
	$(progfl_objs)
	PROGFL
	PROGFL;
!


STATEAPP.EXE : $(state_objs)
    tlink @&&!
	$(prot_opt) +
	$(state_objs)
	STATEAPP.EXE
	STATEAPP,,stateapp;
!

REMDEBUG.EXE : $(remdebug_objs)
    tlink @&&!
	$(prot_opt) +
	$(remdebug_objs)
	REMDEBUG.EXE
	REMDEBUG,,remdebug;
!

RUN.EXE : $(run_objs)
    tlink @&&!
	$(prot_opt) +
	$(run_objs)
	RUN.EXE
	RUN,,run;
!

TEST.EXE : $(test_objs)
    tlink @&&!
	$(prot_opt) +
	$(test_objs)
	TEST
	TEST,,test;
!

DEMO.BIN:   DEMO.CFG $(rdvs) $(exes) $(dlls)
	cfg2bin demo

ALIBOOT.BIN:   ALIBOOT.CFG $(rdvs) $(exes) $(dlls)
	boot2bin

GRUBLOAD.BIN:	GRUBLOAD.EXE $(grubload_srcs)
	grubimg

BOOTSEC.BIN:	HDIMG.EXE $(hdimg_objs)
	hdimg

