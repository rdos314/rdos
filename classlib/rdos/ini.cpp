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
# ini.cpp
# Ini file class
#
########################################################################*/

#include <string.h>
#include "rdos.h"
#include "ini.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TIniFile::TIniFile
#
#   Purpose....: Constructor for TIniFile, system ini
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIniFile::TIniFile()
{
	FHandle = RdosOpenSysIni();
}

/*##########################################################################
#
#   Name       : TIniFile::TIniFile
#
#   Purpose....: Constructor for TIniFile, private ini
#
#   In params..: filename
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIniFile::TIniFile(const char *IniName)
{
	FHandle = RdosOpenIni(IniName);
}

/*##########################################################################
#
#   Name       : TIniFile::~TIniFile
#
#   Purpose....: Destructor for TIniFile
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TIniFile::~TIniFile()
{
	if (FHandle)
		RdosCloseIni(FHandle);
}

/*##########################################################################
#
#   Name       : TIniFile::GotoSection
#
#   Purpose....: Goto section in ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIniFile::GotoSection(const char *name)
{
    return RdosGotoIniSection(FHandle, name);
}

/*##########################################################################
#
#   Name       : TIniFile::DeleteSection
#
#   Purpose....: Delete current section in ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIniFile::DeleteSection(const char *name)
{
    return RdosRemoveIniSection(FHandle, name);
}

/*##########################################################################
#
#   Name       : TIniFile::ReadVar
#
#   Purpose....: Read variable in current section
#
#   In params..: var, buffer, maxsize
#   Out params.: *
#   Returns....: size read
#
##########################################################################*/
int TIniFile::ReadVar(const char *var, char *str, int maxsize)
{
    return RdosReadIni(FHandle, var, str, maxsize);
}

/*##########################################################################
#
#   Name       : TIniFile::WriteVar
#
#   Purpose....: Write variable in current section
#
#   In params..: var, buffer, maxsize
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIniFile::WriteVar(const char *var, const char *str)
{
    return RdosWriteIni(FHandle, var, str);
}

/*##########################################################################
#
#   Name       : TIniFile::DeleteVar
#
#   Purpose....: Delete variable in current section
#
#   In params..: var
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TIniFile::DeleteVar(const char *var)
{
    return RdosDeleteIni(FHandle, var);
}
