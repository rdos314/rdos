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

dll_opt = /l/s/3/Twd

# DEFINE GROUPS OF MODULES

rdos_srcs = RDOS.ASM
rdos_objs = $(rdos_srcs:.ASM=.OBJ)

winkrnl_srcs = WINKRNL.ASM
winkrnl_objs = $(winkrnl_srcs:.ASM=.OBJ)
winkrnl_dlls = KERNEL.DLL

winuser_srcs = WINUSER.ASM
winuser_objs = $(winuser_srcs:.ASM=.OBJ)
winuser_dlls = USER.DLL

wintool_srcs = WINTOOL.ASM
wintool_objs = $(wintool_srcs:.ASM=.OBJ)
wintool_dlls = TOOLHELP.DLL

win87em_srcs = WIN87EM.ASM
win87em_objs = $(win87em_srcs:.ASM=.OBJ)
win87em_dlls = WIN87EM.DLL

bins =      $(cfgs:.CFG=.BIN)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# DEFAULT RULES
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.asm.obj:
     tasm /M4 /Zi /w+ICG /w+PRO $<,$@;

dlls =		$(winkrnl_dlls) $(winuser_dlls) $(wintool_dlls)	\
			$(win87em_dlls) $(rdos_dlls)

MAIN:	$(dlls) $(bins) rdos.obj

KERNEL.DLL : $(winkrnl_objs) winkrnl.def
    link /l $(winkrnl_objs),KERNEL.DLL,WINKRNL.MAP,,WINKRNL.DEF

USER.DLL : $(winuser_objs)
    tlink $(dll_opt) $(winuser_objs),USER.DLL,WINUSER.MAP,,WINUSER.DEF

TOOLHELP.DLL : $(wintool_objs)
    tlink $(dll_opt) $(wintool_objs),TOOLHELP.DLL,WINTOOL.MAP,,WINTOOL.DEF

WIN87EM.DLL : $(win87em_objs)
    tlink $(dll_opt) $(win87em_objs),WIN87EM.DLL,WIN87EM.MAP,,WIN87EM.DEF
