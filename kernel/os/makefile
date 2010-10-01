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

debug_srcs =  DISNEW.ASM  DISASM.ASM    MATH.ASM                                        
kdebug_srcs = DEBUGIO.ASM   KDEBUG.ASM    $(debug_srcs)
kdeb40_srcs = DEBUG40.ASM   KDEB40.ASM    $(debug_srcs)
kdebug_objs = $(kdebug_srcs:.ASM=.OBJ)
kdeb40_objs = $(kdeb40_srcs:.ASM=.OBJ)
kdebug_rdvs = DEBUGIO.RDV
kdeb40_rdvs = DEBUG40.RDV

ipcdebug_srcs = IPCDEBUG.ASM  $(debug_srcs)
ipcdebug_objs = $(ipcdebug_srcs:.ASM=.OBJ)
ipcdebug_rdvs = IPCDEBUG.RDV

video_srcs = VIDEO.ASM BITMAP.ASM BIT1.ASM BIT16.ASM BIT24.ASM BIT32.ASM \
             SPRITE.ASM
video_objs = $(video_srcs:.ASM=.OBJ)
video_rdvs = VIDEO.RDV

wait_srcs = WAIT.ASM
wait_objs = $(wait_srcs:.ASM=.OBJ)
wait_rdvs = $(wait_srcs:.ASM=.RDV)

wd_srcs = WD.ASM
wd_objs = $(wd_srcs:.ASM=.OBJ)
wd_rdvs = $(wd_srcs:.ASM=.RDV)

timer_srcs = TIMER.ASM
timer_objs = $(timer_srcs:.ASM=.OBJ)
timer_rdvs = $(timer_srcs:.ASM=.RDV)

exec_srcs = EXEC.ASM
exec_objs = $(exec_srcs:.ASM=.OBJ)
exec_rdvs = $(exec_srcs:.ASM=.RDV)

pic_srcs = PIC.ASM
pic_objs = $(pic_srcs:.ASM=.OBJ)
pic_rdvs = $(pic_srcs:.ASM=.RDV)

rtc_srcs = RTC.ASM
rtc_objs = $(rtc_srcs:.ASM=.OBJ)
rtc_rdvs = RTC.RDV

dpmi_srcs = DPMI.ASM    DPMI16.ASM      DPMI32.ASM
dpmi_objs = $(dpmi_srcs:.ASM=.OBJ)
dpmi_rdvs = DPMI.RDV

pci_srcs = PCI.ASM
pci_objs = $(pci_srcs:.ASM=.OBJ)
pci_rdvs = PCI.RDV

com_srcs = COM.ASM
com_objs = $(com_srcs:.ASM=.OBJ)
com_rdvs = COM.RDV

usb_srcs = USB.ASM
usb_objs = $(usb_srcs:.ASM=.OBJ)
usb_rdvs = USB.RDV

keyboard_srcs = KEYBOARD.ASM 
keyboard_objs = $(keyboard_srcs:.ASM=.OBJ)
keyboard_rdvs = KEYBOARD.RDV

key_srcs = KEY.ASM KEYSW.ASM KEYUS.ASM KEYUK.ASM KEYFR.ASM SERKEY.ASM
key_objs = $(key_srcs:.ASM=.OBJ)
key_rdvs = KEYSW.RDV KEYUS.RDV KEYUK.RDV KEYFR.RDV SERKEY.RDV

keym_srcs = KEYMOUSE.ASM KEYSW.ASM KEYUS.ASM KEYUK.ASM KEYFR.ASM
keym_objs = $(keym_srcs:.ASM=.OBJ)
keym_rdvs = KEYMSW.RDV KEYMUS.RDV KEYMUK.RDV KEYMFR.RDV

mouse_srcs = MOUSE.ASM 
mouse_objs = $(mouse_srcs:.ASM=.OBJ)
mouse_rdvs = MOUSE.RDV

ir_srcs = IR.ASM 
ir_objs = $(ir_srcs:.ASM=.OBJ)
ir_rdvs = IR.RDV

inifile_srcs = INIFILE.ASM
inifile_objs = $(inifile_srcs:.ASM=.OBJ)
inifile_rdvs = INIFILE.RDV

net_srcs = NET.ASM
net_objs = $(net_srcs:.ASM=.OBJ)
net_rdvs = NET.RDV

ip_srcs = IP.ASM DNS.ASM ICMP.ASM IPCACHE.ASM DHCP.ASM UDP.ASM NTP.ASM \
		  TCP.ASM
ip_objs = $(ip_srcs:.ASM=.OBJ)
ip_rdvs = IP.RDV

ipc_srcs = IPC.ASM IPCREC.ASM IPCSEND.ASM	\
		   SMP.ASM SMPREC.ASM SMPSEND.ASM SMPRESP.ASM
ipc_objs = $(ipc_srcs:.ASM=.OBJ)
ipc_rdvs = IPC.RDV

dos_srcs = DOS.ASM	DOSMEM.ASM	DOSCOM.ASM	DOSEXEC.ASM	\
		   DOSVM.ASM	DOS16.ASM	DOS32.ASM
dos_objs = $(dos_srcs:.ASM=.OBJ)
dos_rdvs = DOS.RDV

focus_srcs =     FOCUS.ASM
focus_objs = $(focus_srcs:.ASM=.OBJ)
focus_rdvs = FOCUS.RDV

drive_srcs = drive.ASM
drive_objs = $(drive_srcs:.ASM=.OBJ)
drive_rdvs = drive.RDV

ramdrive_srcs = RAMDRIVE.ASM
ramdrive_objs = $(ramdrive_srcs:.ASM=.OBJ)
ramdrive_rdvs = RAMDRIVE.RDV

rdfs_srcs = RDFS.ASM RDFSDIR.ASM RDFSFILE.ASM RDFSCRYP.ASM RDFSMISC.ASM \
			RDFSTAB.ASM RDFSCONT.ASM
rdfs_objs = $(rdfs_srcs:.ASM=.OBJ)
rdfs_rdvs = RDFS.RDV

flashfs_srcs = FLASHFS.ASM FLDIR.ASM FLTAB.ASM FLMISC.ASM
flashfs_objs = $(flashfs_srcs:.ASM=.OBJ)
flashfs_rdvs = FLASHFS.RDV

filedisc_srcs = FILEDISC.ASM
filedisc_objs = $(filedisc_srcs:.ASM=.OBJ)
filedisc_rdvs = FILEDISC.RDV

fs_srcs = FS.ASM DIR.ASM FILE.ASM MEMMAP.ASM
fs_objs = $(fs_srcs:.ASM=.OBJ)
fs_rdvs = FS.RDV

ne_srcs = NE.ASM
ne_objs = $(ne_srcs:.ASM=.OBJ)
ne_rdvs = NE.RDV

pe_srcs = PE.ASM
pe_objs = $(pe_srcs:.ASM=.OBJ)
pe_rdvs = PE.RDV

elf_srcs = ELF.ASM
elf_objs = $(elf_srcs:.ASM=.OBJ)
elf_rdvs = ELF.RDV

ac97_srcs = AC97.ASM
ac97_objs = $(ac97_srcs:.ASM=.OBJ)
ac97_rdvs = AC97.RDV

audio_srcs = AUDIO.ASM
audio_objs = $(audio_srcs:.ASM=.OBJ)
audio_rdvs = AUDIO.RDV

fm_srcs = FM.ASM FMSIN.ASM FMEXP.ASM
fm_objs = $(fm_srcs:.ASM=.OBJ)
fm_rdvs = FM.RDV

pcshut_srcs = PCSHUT.ASM
pcshut_objs = $(pcshut_srcs:.ASM=.OBJ)
pcshut_exes = PCSHUT.EXE

srcs =      $(dpmi_srcs) $(inifile_srcs)   \
			$(dos_srcs) $(key_srcs) $(kdebug_srcs) $(kdeb40_srcs) $(pci_srcs) \
			$(net_srcs) $(ip_srcs) $(keym_srcs) $(usb_srcs) $(com_srcs) \
			$(ipc_srcs) $(mouse_srcs) $(ipcdebug_srcs)  \
			$(fs_srcs) $(ne_srcs) $(pe_srcs) $(elf_srcs) \
			$(video_srcs) $(pcshut_srcs)   \
			$(prot_srcs) $(timer_srcs) $(file_srcs) $(exec_srcs) \
			$(keyboard_srcs) \
			$(drive_srcs) $(ramdrive_srcs) $(rdfs_srcs) $(flashfs_srcs)	\
			$(focus_srcs) $(rtc_srcs) $(wait_srcs) $(filedisc_srcs) \
			$(ac97_srcs) $(audio_srcs) $(ir_srcs) $(fm_srcs) $(wd_srcs) \
			$(pic_srcs)

objs =      $(srcs:.ASM=.OBJ)

incs =      SYSTEM.DEF              PROTSEG.DEF             SYSTEM.INC      \
			DISC.DEF                BIOSDATA.DEF    \
			PROTSEG.INC            \
			DPMI.INC                INT.DEF			       \
			FAT.INC                 DOS.INC

exes =      $(prot_exes) $(pcshut_exes)

rdvs =      $(dpmi_rdvs) $(keym_rdvs)  \
			$(dos_rdvs) $(key_rdvs) $(kdebug_rdvs) $(kdeb40_rdvs) $(pci_rdvs)     \
			$(fs_rdvs) $(ne_rdvs) $(pe_rdvs) $(elf_rdvs)   \
		    $(timer_rdvs) $(mouse_rdvs) $(file_rdvs) \
			$(ipc_rdvs) $(ipcdebug_rdvs) \
			$(net_rdvs) $(ip_rdvs) $(usb_rdvs) $(com_rdvs) $(exec_rdvs) \
			$(keyboard_rdvs) $(inifile_rdvs)  \
			$(drive_rdvs) $(ramdrive_rdvs) $(rdfs_rdvs) $(flashfs_rdvs) \
			$(focus_rdvs) $(wait_rdvs) $(filedisc_rdvs)	\
			$(rtc_rdvs) $(video_rdvs) $(ac97_rdvs) $(audio_rdvs) \
			$(ir_rdvs) $(fm_rdvs) $(wd_rdvs) $(pic_rdvs)

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

VIDEO.RDV : $(video_objs)
    tlink @&&!
	$(link_opt) +
	$(video_objs)
	VIDEO.RDV
	VIDEO;
!

AC97.RDV : $(ac97_objs)
    tlink @&&!
	$(link_opt) +
	$(ac97_objs)
	AC97.RDV
	AC97;
!

AUDIO.RDV : $(audio_objs)
    tlink @&&!
	$(link_opt) +
	$(audio_objs)
	AUDIO.RDV
	AUDIO;
!

FM.RDV : $(fm_objs)
    tlink @&&!
	$(link_opt) +
	$(fm_objs)
	FM.RDV
	FM;
!

IR.RDV : $(ir_objs)
    tlink @&&!
	$(link_opt) +
	$(ir_objs)
	IR.RDV
	IR;
!

DPMI.RDV : $(dpmi_objs)
    tlink @&&!
	$(link_opt) +
	$(dpmi_objs)
	DPMI.RDV
	DPMI;
!

PCI.RDV : $(pci_objs)
    tlink @&&!
	$(link_opt) +
	$(pci_objs)
	PCI.RDV
	PCI;
!

COM.RDV : $(com_objs)
    tlink @&&!
	$(link_opt) +
	$(com_objs)
	COM.RDV
	COM;
!

USB.RDV : $(usb_objs)
    tlink @&&!
	$(link_opt) +
	$(usb_objs)
	USB.RDV
	USB;
!

KEYBOARD.RDV : $(keyboard_objs)
    tlink @&&!
	$(link_opt) +
	$(keyboard_objs)
	KEYBOARD.RDV
	KEYBOARD;
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

MOUSE.RDV : $(mouse_objs)
    tlink @&&!
	$(link_opt) +
	$(mouse_objs)
	MOUSE.RDV
	MOUSE;
!

INIFILE.RDV : $(inifile_objs)
    tlink @&&!
	$(link_opt) +
	$(inifile_objs)
	INIFILE.RDV
	INIFILE;
!

NET.RDV : $(net_objs)
    tlink @&&!
	$(link_opt) +
	$(net_objs)
	NET.RDV
	NET;
!

IP.RDV : $(ip_objs)
    tlink @&&!
	$(link_opt) +
	$(ip_objs)
	IP.RDV
	IP;
!

IPC.RDV : $(ipc_objs)
    tlink @&&!
	$(link_opt) +
	$(ipc_objs)
	IPC.RDV
	IPC;
!

WAIT.RDV : $(wait_objs)
    tlink @&&!
	$(link_opt) +
	$(wait_objs)
	WAIT.RDV
	WAIT;
!

WD.RDV : $(wd_objs)
    tlink @&&!
	$(link_opt) +
	$(wd_objs)
	WD.RDV
	WD;
!

TIMER.RDV : $(timer_objs)
    tlink @&&!
	$(link_opt) +
	$(timer_objs)
	TIMER.RDV
	TIMER;
!

EXEC.RDV : $(exec_objs)
    tlink @&&!
	$(link_opt) +
	$(exec_objs)
	EXEC.RDV
	EXEC;
!

PIC.RDV : $(pic_objs)
    tlink @&&!
	$(link_opt) +
	$(pic_objs)
	PIC.RDV
	PIC;
!

RTC.RDV : $(rtc_objs)
    tlink @&&!
	$(link_opt) +
	$(rtc_objs)
	RTC.RDV
	RTC;
!

DOS.RDV : $(dos_objs)
    tlink @&&!
	$(link_opt) +
	$(dos_objs)
	DOS.RDV
	DOS;
!

FOCUS.RDV : $(focus_objs)
    tlink @&&!
	$(link_opt) +
	$(focus_objs)
	FOCUS.RDV
	FOCUS;
!

drive.RDV : $(drive_objs)
    tlink @&&!
	$(link_opt) +
	$(drive_objs)
	drive.RDV
	drive;
!

RAMDRIVE.RDV : $(ramdrive_objs)
    tlink @&&!
	$(link_opt) +
	$(ramdrive_objs)
	RAMDRIVE.RDV
	RAMDRIVE;
!

RDFS.RDV : $(rdfs_objs)
    tlink @&&!
	$(link_opt) +
	$(rdfs_objs)
	RDFS.RDV
	RDFS;
!

FLASHFS.RDV : $(flashfs_objs)
    tlink @&&!
	$(link_opt) +
	$(flashfs_objs)
	FLASHFS.RDV
	FLASHFS;
!

FILEDISC.RDV : $(filedisc_objs)
    tlink @&&!
	$(link_opt) +
	$(filedisc_objs)
	FILEDISC.RDV
	FILEDISC;
!

FILE.RDV : $(file_objs)
    tlink @&&!
	$(link_opt) +
	$(file_objs)
	FILE.RDV
	FILE;
!

FS.RDV : $(fs_objs)
    tlink @&&!
	$(link_opt) +
	$(fs_objs)
	FS.RDV
	FS;
!

NE.RDV : $(ne_objs)
    tlink @&&!
	$(link_opt) +
	$(ne_objs)
	NE.RDV
	NE;
!

PE.RDV : $(pe_objs)
    tlink @&&!
	$(link_opt) +
	$(pe_objs)
	PE.RDV
	PE;
!

ELF.RDV : $(elf_objs)
    tlink @&&!
	$(link_opt) +
	$(elf_objs)
	ELF.RDV
	ELF;
!

DEBUGIO.RDV : $(kdebug_objs)
    tlink @&&!
	$(link_opt) +
	$(kdebug_objs)
	DEBUGIO.RDV
	DEBUGIO;
!

DEBUG40.RDV : $(kdeb40_objs)
    tlink @&&!
	$(link_opt) +
	$(kdeb40_objs)
	DEBUG40.RDV
	DEBUG40;
!

IPCDEBUG.RDV : $(ipcdebug_objs)
    tlink @&&!
	$(link_opt) +
	$(ipcdebug_objs)
	IPCDEBUG.RDV
	IPCDEBUG;
!
