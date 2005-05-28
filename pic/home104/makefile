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

# DEFINE GROUPS OF MODULES

serda_srcs		= SERDA.ASM
serda_objs  	= SERDA.OBJ

siodrive_srcs	= SIODRIVE.ASM
siodrive_objs	= SIODRIVE.OBJ

siokeyb_srcs	= SIOKEYB.ASM
siokeyb_objs	= SIOKEYB.OBJ

radled_srcs		= RADLED.ASM
radled_objs		= RADLED.OBJ

radcom_srcs		= RADCOM.ASM
radcom_objs		= RADCOM.OBJ

radfuzzy_srcs	= RADFUZZY.ASM
radfuzzy_objs	= RADFUZZY.OBJ

pcbus_srcs		= PCBUS.ASM
pcbus_objs  	= PCBUS.OBJ

dcf_srcs		= DCF.ASM
dcf_objs  	    = DCF.OBJ
sernet_srcs		= SERNET.ASM
sernet_objs  	= SERNET.OBJ

srcs =      $(serda_srcs) $(siodrive_srcs) $(siokeyb_srcs)	\
			$(radled_srcs) $(radcom_srcs) $(radfuzzy_srcs)  \
			$(pcbus_srcs) $(dcf_srcs) $(sernet_srcs)

objs =      $(srcs:.ASM=.OBJ)

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# DEFAULT RULES
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

.asm.obj:
	pictasm -1684 -b $<

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# TARGET
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# +++++++++
# PROJ
# +++++++++

MAIN:   $(objs)
