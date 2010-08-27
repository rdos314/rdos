/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# crc.cpp
# CRC class
#
########################################################################*/

#include "win32.h"
#include "crc.h"

/*##########################################################################
#
#   Name       : TCrc::TCrc
#
#   Purpose....: Constructor for TCrc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCrc::TCrc(unsigned short int CrcPoly)
{
    Win32InitCrc(FCrcArr, CrcPoly);
}

/*##########################################################################
#
#   Name       : TCrc::~TCrc
#
#   Purpose....: Destructor for TCrc
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCrc::~TCrc()
{
}

/*##########################################################################
#
#   Name       : TCrc::CalcCrc
#
#   Purpose....: Calculate CRC
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned short int TCrc::CalcCrc(unsigned short int CrcVal, const char *Buf, int Size)
{
    return Win32CalcCrc(FCrcArr, CrcVal, Buf, Size); 
}
