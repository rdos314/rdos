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
version = V1_0

dll_opt = -ap -s -Tpd 

# DEFINE GROUPS OF MODULES

kernel32_srcs = KERNEL32.ASM CONSOLE.ASM K32FILE.ASM K32MEM.ASM K32LFUNS.ASM \
				K32LOAD.ASM K32MISC.ASM K32TASK.ASM K32DEBUG.ASM K32EXC.ASM
kernel32_objs = $(kernel32_srcs:.ASM=.OBJ)
kernel32_dlls = KERNEL32.DLL

user32_srcs = USER32.ASM
user32_objs = $(user32_srcs:.ASM=.OBJ)
user32_dlls = USER32.DLL

oleaut32_srcs = OLEAUT32.ASM
oleaut32_objs = $(oleaut32_srcs:.ASM=.OBJ)
oleaut32_dlls = OLEAUT32.DLL

advapi32_srcs = ADVAPI32.ASM
advapi32_objs = $(advapi32_srcs:.ASM=.OBJ)
advapi32_dlls = ADVAPI32.DLL

rdos_srcs = RDOS.ASM
rdos_objs = $(rdos_srcs:.ASM=.OBJ)

bins =      $(cfgs:.CFG=.BIN)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# DEFAULT RULES
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.asm.obj:
     tasm32 -mx -M9 -Zi -w+ICG -w+PRO $<,$@,$*

dlls =		$(kernel32_dlls) $(user32_dlls) $(oleaut32_dlls) $(advapi32_dlls)

MAIN:	$(dlls) rdos.obj

KERNEL32.DLL : $(kernel32_objs)
    tlink32 @&&!
    -B:0x5E000000 $(dll_opt) $(kernel32_objs)
	KERNEL32.DLL
	KERNEL32.MAP,,KERNEL32.DEF
!

USER32.DLL : $(user32_objs)
    tlink32 @&&!
	-B:0x5E100000 $(dll_opt) $(user32_objs)
	USER32.DLL
	USER32.MAP,,USER32.DEF
!

OLEAUT32.DLL : $(oleaut32_objs)
    tlink32 @&&!
	-B:0x5E200000 $(dll_opt) $(oleaut32_objs)
	OLEAUT32.DLL
	OLEAUT32.MAP,,OLEAUT32.DEF
!

ADVAPI32.DLL : $(advapi32_objs)
    tlink32 @&&!
	-B:0x5E300000 $(dll_opt) $(advapi32_objs)
	ADVAPI32.DLL
	ADVAPI32.MAP,,ADVAPI32.DEF
!

