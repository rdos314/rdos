/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# discserv.c
# Disc server interface
#
########################################################################*/

void RunCmd(int handle, char *msg);
int ReadSector(long long sector, char *buf, int size);
int WriteSector(long long sector, char *buf, int size);

/*##########################################################################
#
#   Name       : LowCmd
#
##########################################################################*/
#pragma aux LowCmd "*" parm routine [ebx] [edi] value [eax]
void LowCmd(int handle, char *msg)
{
    RunCmd(handle, msg);
}

/*##########################################################################
#
#   Name       : LowReadSector
#
##########################################################################*/
#pragma aux LowReadSector "*" parm routine [edx eax] [ebx] [ecx] value [eax]
int LowReadSector(long long sector, char *buf, int size)
{
    return ReadSector(sector, buf, size);
}

/*##########################################################################
#
#   Name       : LowWriteSector
#
##########################################################################*/
#pragma aux LowWriteSector "*" parm routine [edx eax] [ebx] [ecx] value [eax]
int LowWriteSector(long long sector, char *buf, int size)
{
    return WriteSector(sector, buf, size);
}
