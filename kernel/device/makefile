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

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# MACROS SYSTEM 
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


# DEFINE SYSTEM VERSION  
version = V1_0

link_opt = /l/s/3

# DEFINE GROUPS OF MODULES

pcvideo_srcs = PCVIDEO.ASM  TEXTMODE.ASM	BITMODE.ASM	VBE.ASM	TRUEMODE.ASM
pcvideo_objs = $(pcvideo_srcs:.ASM=.OBJ)
pcvideo_rdvs = PCVIDEO.RDV

pmouse_srcs = PMOUSE.ASM
pmouse_objs = $(pmouse_srcs:.ASM=.OBJ)
pmouse_rdvs = PMOUSE.RDV

s1mouse_srcs = S1MOUSE.ASM
s1mouse_objs = $(s1mouse_srcs:.ASM=.OBJ)
s1mouse_rdvs = S1MOUSE.RDV

s2mouse_srcs = S2MOUSE.ASM
s2mouse_objs = $(s2mouse_srcs:.ASM=.OBJ)
s2mouse_rdvs = S2MOUSE.RDV

pccom_srcs = PCCOM.ASM
pccom_objs = $(pccom_srcs:.ASM=.OBJ)
pccom_rdvs = PCCOM.RDV

printer_srcs = PRINTER.ASM
printer_objs = $(printer_srcs:.ASM=.OBJ)
printer_rdvs = PRINTER.RDV

ide_srcs = IDE.ASM
ide_objs = $(ide_srcs:.ASM=.OBJ)
ide_rdvs = IDE.RDV

floppy_srcs = FLOPPY.ASM
floppy_objs = $(floppy_srcs:.ASM=.OBJ)
floppy_rdvs = FLOPPY.RDV

ne2000_srcs = NE2000.ASM
ne2000_objs = $(ne2000_srcs:.ASM=.OBJ)
ne2000_rdvs = NE2000.RDV

ppp_srcs = PPP.ASM
ppp_objs = $(ppp_srcs:.ASM=.OBJ)
ppp_rdvs = PPP.RDV

sernet_srcs = SERNET.ASM
sernet_objs = $(sernet_srcs:.ASM=.OBJ)
sernet_rdvs = SERNET.RDV

fat_srcs = FAT.ASM FATMISC.ASM FATTAB.ASM FATDIR.ASM FATFILE.ASM
fat_objs = $(fat_srcs:.ASM=.OBJ)
fat_rdvs = FAT.RDV

srcs =      $(ide_srcs) $(pcvideo_srcs) \
			$(floppy_srcs)	\
			$(fat_srcs)	$(pmouse_srcs) $(s1mouse_srcs) $(s2mouse_srcs) \
			$(ne2000_srcs)	$(ppp_srcs) $(printer_srcs) $(sernet_srcs) \
			$(pccom_srcs)

objs =      $(srcs:.ASM=.OBJ)

rdvs =      $(ide_rdvs) $(floppy_rdvs) $(pcvideo_rdvs) \
			$(fat_rdvs) $(pmouse_rdvs) $(s1mouse_rdvs) $(s2mouse_rdvs) \
			$(ne2000_rdvs) $(ppp_rdvs) $(sernet_rdvs) \
			$(printer_rdvs) $(pccom_rdvs)

maps =      $(exes:.EXE=.MAP) $(rdvs:.RDV=.MAP)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# DEFAULT RULES
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.asm.obj:
     tasm /M2 /Zi /w+ICG /w+PRO $<,$@;

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# TARGET
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# +++++++++
# PROJ
# +++++++++

MAIN:   $(rdvs)

PCVIDEO.RDV : $(pcvideo_objs)
    tlink @&&!
	$(link_opt) +
	$(pcvideo_objs)
	PCVIDEO.RDV
	PCVIDEO;       
!

PMOUSE.RDV : $(pmouse_objs)
    tlink @&&!
	$(link_opt) +
	$(pmouse_objs)
	PMOUSE.RDV
	PMOUSE;  
!

S1MOUSE.RDV : $(s1mouse_objs)
    tlink @&&!
	$(link_opt) +
	$(s1mouse_objs)
	S1MOUSE.RDV
	S1MOUSE;  
!

S2MOUSE.RDV : $(s2mouse_objs)
    tlink @&&!
	$(link_opt) +
	$(s2mouse_objs)
	S2MOUSE.RDV
	S2MOUSE;  
!

PCCOM.RDV : $(pccom_objs)
    tlink @&&!
	$(link_opt) +
	$(pccom_objs)
	PCCOM.RDV
	PCCOM;       
!


PPP.RDV : $(ppp_objs)
    tlink @&&!
	$(link_opt) +
	$(ppp_objs)
	PPP.RDV
	PPP;       
!

SERNET.RDV : $(sernet_objs)
    tlink @&&!
	$(link_opt) +
	$(sernet_objs)
	SERNET.RDV
	SERNET;       
!

PRINTER.RDV : $(printer_objs)
    tlink @&&!
	$(link_opt) +
	$(printer_objs)
	PRINTER.RDV
	PRINTER;       
!

IDE.RDV : $(ide_objs)
    tlink @&&!
	$(link_opt) +
	$(ide_objs)
	IDE.RDV
	IDE;
!

FLOPPY.RDV : $(floppy_objs)
    tlink @&&!
	$(link_opt) +
	$(floppy_objs)
	FLOPPY.RDV
	FLOPPY;
!

NE2000.RDV : $(ne2000_objs)
    tlink @&&!
	$(link_opt) +
	$(ne2000_objs)
	NE2000.RDV
	NE2000;
!

FAT.RDV : $(fat_objs)
    tlink @&&!
	$(link_opt) +
	$(fat_objs)
	FAT.RDV
	FAT;
!
