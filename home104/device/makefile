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

ewlcd_srcs = EWLCD.ASM
ewlcd_objs = $(ewlcd_srcs:.ASM=.OBJ)
ewlcd_rdvs = EWLCD.RDV

keylcd_srcs = KEYLCD.ASM
keylcd_objs = $(keylcd_srcs:.ASM=.OBJ)
keylcd_rdvs = KEYLCD.RDV

anio_srcs = ANIO.ASM
anio_objs = $(anio_srcs:.ASM=.OBJ)
anio_rdvs = ANIO.RDV

digio_srcs = DIGIO.ASM
digio_objs = $(digio_srcs:.ASM=.OBJ)
digio_rdvs = DIGIO.RDV

dcf_srcs = DCF.ASM
dcf_objs = $(dcf_srcs:.ASM=.OBJ)
dcf_rdvs = DCF.RDV

srcs =      $(ewlcd_srcs) $(keylcd_srcs) \
			$(anio_srcs) $(digio_srcs) $(dcf_srcs)

objs =      $(srcs:.ASM=.OBJ)

rdvs =      $(ewlcd_rdvs) $(keylcd_rdvs)\
			$(anio_rdvs) $(digio_rdvs) $(dcf_rdvs)

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

EWLCD.RDV : $(ewlcd_objs)
    tlink @&&!
	$(link_opt) +
	$(ewlcd_objs)
	EWLCD.RDV
	EWLCD;       
!

KEYLCD.RDV : $(keylcd_objs)
    tlink @&&!
	$(link_opt) +
	$(keylcd_objs)
	KEYLCD.RDV
	KEYLCD;       
!

ANIO.RDV : $(anio_objs)
    tlink @&&!
	$(link_opt) +
	$(anio_objs)
	ANIO.RDV
	ANIO;
!

DIGIO.RDV : $(digio_objs)
    tlink @&&!
	$(link_opt) +
	$(digio_objs)
	DIGIO.RDV
	DIGIO;
!

DCF.RDV : $(dcf_objs)
    tlink @&&!
	$(link_opt) +
	$(dcf_objs)
	DCF.RDV
	DCF;
!
