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
# lightdev.cpp
# Light measurement class
#
########################################################################*/

#include <stdio.h>
#include <string.h>

#include "lightdev.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TLightDevice::TLightDevice
#
#   Purpose....: Constructor
#
#   In params..: Channel #
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLightDevice::TLightDevice(int channel)
 : TAdcDevice(channel)
{
}

/*##########################################################################
#
#   Name       : TLightDevice::TLightDevice
#
#   Purpose....: Constructor
#
#   In params..: Channel #
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLightDevice::TLightDevice(const char *IniSection, int channel)
  : TAdcDevice(IniSection, channel)
{
}

/*##########################################################################
#
#   Name       : TLightDevice::~TLightDevice
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLightDevice::~TLightDevice()
{
}

/*##########################################################################
#
#   Name       : TLightDevice::DeviceName
#
#   Purpose....: Get device-name
#
#   In params..: Name		Device name buffer
#			   : MaxLen		Max length of name
#   Out params.: *
#   Returns....: Real value
#
##########################################################################*/
void TLightDevice::DeviceName(char *Name, int MaxLen) const
{
	char str[80];

	sprintf(str, "Light channel #%d", FChannel);
	strncpy(Name, str, MaxLen);
}

/*##########################################################################
#
#   Name       : TLightDevice::GetUnit
#
#   Purpose....: Get unit
#
#   In params..: *
#   Out params.: *
#   Returns....: Measurement unit
#
##########################################################################*/
const char *TLightDevice::GetUnit()
{
	return "W/m2";
}

/*##########################################################################
#
#   Name       : TLightDevice::MvToReal
#
#   Purpose....: Convert from millivolt to real unit
#
#   In params..: Val	millivolt value
#   Out params.: *
#   Returns....: Real value
#
##########################################################################*/
long double TLightDevice::MvToReal(long double value)
{
	return TAdcDevice::MvToReal(value) / 100.0 / 50.0;
}
