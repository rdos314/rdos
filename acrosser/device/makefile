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

# DEFINE GROUPS OF MODULES

ar-b1320_srcs = AR-B1320.ASM
ar-b1320_objs = $(ar-b1320_srcs:.ASM=.OBJ)
ar-b1320_rdvs = ar-b1320.RDV

srcs =      $(ar-b1320_srcs)

objs =      $(srcs:.ASM=.OBJ)

rdvs =      $(ar-b1320_rdvs)

maps =      $(exes:.EXE=.MAP)

# DEFINE MODULES FOR CMS
vaxset_modules = $(srcs) $(incs) $(fonts) $(bats)

# DEFINE MODULES FOR SYSTEM VERSION
kit_modules =   $(maps) $(bats) $(bins)  LOAD.EXE GRUBLOAD.EXE

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# DEFAULT RULES
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.asm.obj:
     tasm /M4 /Zi $<,$@;

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# TARGET
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

MAIN:   $(rdvs) $(exes)

ar-b1320.RDV : $(ar-b1320_objs)
    tlink @&&!
	$(link_opt) +
	$(ar-b1320_objs)
	ar-b1320.RDV
	ar-b1320;
!
