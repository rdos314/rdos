######################################################################
# RDOS operating system
# Copyright (C) 1988-2000, Leif Ekblad
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
version = V8_0

prot_opt = /l/s/3/Twe
link_opt = /l/s/3

units = G:\BP\UNITS

# DEFINE GROUPS OF MODULES

wd_srcs = WD.ASM
wd_objs = $(wd_srcs:.ASM=.OBJ)
wd_rdvs = $(wd_srcs:.ASM=.RDV)

key_srcs = KEY.ASM KEYSW.ASM KEYUS.ASM KEYUK.ASM KEYFR.ASM SERKEY.ASM
key_objs = $(key_srcs:.ASM=.OBJ)
key_rdvs = KEYSW.RDV KEYUS.RDV KEYUK.RDV KEYFR.RDV SERKEY.RDV

keym_srcs = KEYMOUSE.ASM KEYSW.ASM KEYUS.ASM KEYUK.ASM KEYFR.ASM
keym_objs = $(keym_srcs:.ASM=.OBJ)
keym_rdvs = KEYMSW.RDV KEYMUS.RDV KEYMUK.RDV KEYMFR.RDV

ir_srcs = IR.ASM 
ir_objs = $(ir_srcs:.ASM=.OBJ)
ir_rdvs = IR.RDV

pcshut_srcs = PCSHUT.ASM
pcshut_objs = $(pcshut_srcs:.ASM=.OBJ)
pcshut_exes = PCSHUT.EXE

srcs =      $(key_srcs) \
			$(keym_srcs) \
			$(pcshut_srcs)   \
			$(prot_srcs) $(file_srcs) \
			$(ir_srcs) $(wd_srcs)

objs =      $(srcs:.ASM=.OBJ)

incs =      SYSTEM.DEF              PROTSEG.DEF             SYSTEM.INC      \
			DISC.DEF                BIOSDATA.DEF    \
			PROTSEG.INC            \
			INT.DEF			       \
			FAT.INC                 DOS.INC

exes =      $(prot_exes) $(pcshut_exes)

rdvs =      $(keym_rdvs)  \
			$(key_rdvs)   \
			$(ir_rdvs) $(wd_rdvs)

maps =      $(exes:.EXE=.MAP) $(rdvs:.RDV=.MAP)

bats =      RDOS.BAT

# DEFINE MODULES FOR CMS
vaxset_modules = $(srcs) $(incs) $(bats)

# DEFINE MODULES FOR SYSTEM VERSION
kit_modules =   $(maps) $(bats) $(bins)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# DEFAULT RULES
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.asm.obj:
     tasm /M4 /Zi /w+ICG /w+PRO $<,$@;
#     wasm -dt=dos -d1 -fpi87 $<

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# TARGET
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# +++++++++
# PROJ
# +++++++++

!IFDEF VER

VSMS:
	sort >vsm <<!
$(vaxset_modules)
!
	sort >kit <<!
$(kit_modules)
!
	sort >ver <<!
$(version)
!

!ENDIF


MAIN:   $(rdvs) $(exes)

userint.obj:    userint.asm

OS.OBJ :        ..\os.def

USER.OBJ :      ..\user.def

PCSHUT.EXE : $(pcshut_objs)
    tlink @&&!
	$(link_opt) +
	$(pcshut_objs)
	PCSHUT
	PCSHUT;       
!

IR.RDV : $(ir_objs)
    tlink @&&!
	$(link_opt) +
	$(ir_objs)
	IR.RDV
	IR;
!

KEYSW.RDV : $(key_objs)
    tlink @&&!
	$(link_opt) +
	KEY+KEYSW
	KEYSW.RDV
	KEYSW;
!

KEYUS.RDV : $(key_objs)
    tlink @&&!
	$(link_opt) +
	KEY+KEYUS
	KEYUS.RDV
	KEYUS;
!

KEYUK.RDV : $(key_objs)
    tlink @&&!
	$(link_opt) +
	KEY+KEYUK
	KEYUK.RDV
	KEYUK;
!

KEYFR.RDV : $(key_objs)
    tlink @&&!
	$(link_opt) +
	KEY+KEYFR
	KEYFR.RDV
	KEYFR;
!

KEYMSW.RDV : $(keym_objs)
    tlink @&&!
	$(link_opt) +
	KEYMOUSE+KEYSW
	KEYMSW.RDV
	KEYMSW;
!

KEYMUS.RDV : $(keym_objs)
    tlink @&&!
	$(link_opt) +
	KEYMOUSE+KEYUS
	KEYMUS.RDV
	KEYMUS;
!

KEYMUK.RDV : $(keym_objs)
    tlink @&&!
	$(link_opt) +
	KEYMOUSE+KEYUK
	KEYMUK.RDV
	KEYMUK;
!

KEYMFR.RDV : $(keym_objs)
    tlink @&&!
	$(link_opt) +
	KEYMOUSE+KEYFR
	KEYMFR.RDV
	KEYMFR;
!

SERKEY.RDV : $(key_objs)
    tlink @&&!
	$(link_opt) +
	SERKEY+KEYSW
	SERKEY.RDV
	SERKEY;
!

WD.RDV : $(wd_objs)
    tlink @&&!
	$(link_opt) +
	$(wd_objs)
	WD.RDV
	WD;
!
