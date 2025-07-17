/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# tempdev.cpp
# Temperature measurement class
#
########################################################################*/

#include <stdio.h>
#include <string.h>

#include "tempdev.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TTempDevice::TTempDevice
#
#   Purpose....: Constructor
#
#   In params..: Channel #
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTempDevice::TTempDevice(int channel)
 : TAdcDevice(channel)
{
}

/*##########################################################################
#
#   Name       : TTempDevice::TTempDevice
#
#   Purpose....: Constructor
#
#   In params..: Channel #
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTempDevice::TTempDevice(const char *IniSection, int channel)
  : TAdcDevice(IniSection, channel)
{
}

/*##########################################################################
#
#   Name       : TTempDevice::~TTempDevice
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTempDevice::~TTempDevice()
{
}

/*##########################################################################
#
#   Name       : TTempDevice::DeviceName
#
#   Purpose....: Get device-name
#
#   In params..: Name		Device name buffer
#			   : MaxLen		Max length of name
#   Out params.: *
#   Returns....: Real value
#
##########################################################################*/
void TTempDevice::DeviceName(char *Name, int MaxLen) const
{
	char str[80];

	sprintf(str, "Temperature channel #%d", FChannel);
	strncpy(Name, str, MaxLen);
}

/*##########################################################################
#
#   Name       : TTempDevice::GetUnit
#
#   Purpose....: Get unit
#
#   In params..: *
#   Out params.: *
#   Returns....: Measurement unit
#
##########################################################################*/
const char *TTempDevice::GetUnit()
{
	return "øC";
}

/*##########################################################################
#
#   Name       : TTempDevice::MvToReal
#
#   Purpose....: Convert from millivolt to real unit
#
#   In params..: Val	millivolt value
#   Out params.: *
#   Returns....: Real value
#
##########################################################################*/
long double TTempDevice::MvToReal(long double value)
{
	return TAdcDevice::MvToReal(value) / 100.0;
}
