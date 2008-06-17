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

pcvideo_srcs = PCVIDEO.ASM  TEXTMODE.ASM	BITMODE.ASM	VBE.ASM
pcvideo_objs = $(pcvideo_srcs:.ASM=.OBJ)
pcvideo_rdvs = PCVIDEO.RDV

novideo_srcs = NOVIDEO.ASM
novideo_objs = $(novideo_srcs:.ASM=.OBJ)
novideo_rdvs = NOVIDEO.RDV

pmouse_srcs = PMOUSE.ASM
pmouse_objs = $(pmouse_srcs:.ASM=.OBJ)
pmouse_rdvs = PMOUSE.RDV

s1mouse_srcs = S1MOUSE.ASM
s1mouse_objs = $(s1mouse_srcs:.ASM=.OBJ)
s1mouse_rdvs = S1MOUSE.RDV

s2mouse_srcs = S2MOUSE.ASM
s2mouse_objs = $(s2mouse_srcs:.ASM=.OBJ)
s2mouse_rdvs = S2MOUSE.RDV

ts2003_srcs = TS2003.ASM
ts2003_objs = $(ts2003_srcs:.ASM=.OBJ)
ts2003_rdvs = TS2003.RDV

egalax_srcs = EGALAX.ASM
egalax_objs = $(egalax_srcs:.ASM=.OBJ)
egalax_rdvs = EGALAX.RDV

pccom_srcs = PCCOM.ASM
pccom_objs = $(pccom_srcs:.ASM=.OBJ)
pccom_rdvs = PCCOM.RDV

usbcom_srcs = USBCOM.ASM
usbcom_objs = $(usbcom_srcs:.ASM=.OBJ)
usbcom_rdvs = USBCOM.RDV

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

dp83815_srcs = DP83815.ASM
dp83815_objs = $(dp83815_srcs:.ASM=.OBJ)
dp83815_rdvs = DP83815.RDV

rtl8139_srcs = RTL8139.ASM
rtl8139_objs = $(rtl8139_srcs:.ASM=.OBJ)
rtl8139_rdvs = RTL8139.RDV

8255x_srcs = 8255x.ASM
8255x_objs = $(8255x_srcs:.ASM=.OBJ)
8255x_rdvs = 8255x.RDV

uhci_srcs = UHCI.ASM
uhci_objs = $(uhci_srcs:.ASM=.OBJ)
uhci_rdvs = UHCI.RDV

ppp_srcs = PPP.ASM
ppp_objs = $(ppp_srcs:.ASM=.OBJ)
ppp_rdvs = PPP.RDV

sernet_srcs = SERNET.ASM
sernet_objs = $(sernet_srcs:.ASM=.OBJ)
sernet_rdvs = SERNET.RDV

fat_srcs = FAT.ASM FATMISC.ASM FATTAB.ASM FATDIR.ASM FATFILE.ASM FATVERI.ASM
fat_objs = $(fat_srcs:.ASM=.OBJ)
fat_rdvs = FAT.RDV

srcs =      $(ide_srcs) $(pcvideo_srcs) $(floppy_srcs) $(novideo_srcs)	\
			$(fat_srcs)	$(pmouse_srcs) $(s1mouse_srcs) $(s2mouse_srcs) \
			$(ne2000_srcs)	$(ppp_srcs) $(printer_srcs) $(sernet_srcs) \
			$(pccom_srcs) $(dp83815_srcs) $(rtl8139_srcs) $(8255x_srcs) \
			$(ts2003_srcs) $(egalax_srcs) $(uhci_srcs) $(usbcom_srcs)

objs =      $(srcs:.ASM=.OBJ)

rdvs =      $(ide_rdvs) $(floppy_rdvs) $(pcvideo_rdvs) $(novideo_rdvs) \
			$(fat_rdvs) $(pmouse_rdvs) $(s1mouse_rdvs) $(s2mouse_rdvs) \
			$(ne2000_rdvs) $(ppp_rdvs) $(sernet_rdvs) $(dp83815_rdvs) \
			$(printer_rdvs) $(pccom_rdvs) $(rtl8139_rdvs) $(8255x_rdvs) \
			$(ts2003_rdvs) $(egalax_rdvs) $(uhci_rdvs) $(usbcom_rdvs)

maps =      $(exes:.EXE=.MAP) $(rdvs:.RDV=.MAP)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# DEFAULT RULES
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.asm.obj:
     tasm /M4 /Zi /w+ICG /w+PRO $<,$@;

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

NOVIDEO.RDV : $(novideo_objs)
    tlink @&&!
	$(link_opt) +
	$(novideo_objs)
	NOVIDEO.RDV
	NOVIDEO;       
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

TS2003.RDV : $(ts2003_objs)
    tlink @&&!
	$(link_opt) +
	$(ts2003_objs)
	TS2003.RDV
	TS2003;       
!

EGALAX.RDV : $(egalax_objs)
    tlink @&&!
	$(link_opt) +
	$(egalax_objs)
	EGALAX.RDV
	EGALAX;       
!

PCCOM.RDV : $(pccom_objs)
    tlink @&&!
	$(link_opt) +
	$(pccom_objs)
	PCCOM.RDV
	PCCOM;       
!

USBCOM.RDV : $(usbcom_objs)
    tlink @&&!
	$(link_opt) +
	$(usbcom_objs)
	USBCOM.RDV
	USBCOM;       
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

DP83815.RDV : $(dp83815_objs)
    tlink @&&!
	$(link_opt) +
	$(dp83815_objs)
	DP83815.RDV
	DP83815;
!

RTL8139.RDV : $(rtl8139_objs)
    tlink @&&!
	$(link_opt) +
	$(rtl8139_objs)
	RTL8139.RDV
	RTL8139;
!

8255x.RDV : $(8255x_objs)
    tlink @&&!
	$(link_opt) +
	$(8255x_objs)
	8255x.RDV
	8255x;
!

UHCI.RDV : $(uhci_objs)
    tlink @&&!
	$(link_opt) +
	$(uhci_objs)
	UHCI.RDV
	UHCI;
!

FAT.RDV : $(fat_objs)
    tlink @&&!
	$(link_opt) +
	$(fat_objs)
	FAT.RDV
	FAT;
!
