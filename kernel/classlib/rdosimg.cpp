/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2010, Leif Ekblad
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
# rdosimg.cpp
# RDOS image creator / manipulator
#
########################################################################*/

#include "rdosimg.h"
#include "file.h"

#define RDOS_SIGN   0x5A1E75D4

#define     FALSE   0
#define     TRUE    !FALSE

/*##########################################################################
#
#   Name       : TRdosObject::TRdosObject
#
#   Purpose....: Constructor for TRdosObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosObject::TRdosObject()
{
    FData = 0;
    FSize = 0;
    FType = 0;
}

/*##########################################################################
#
#   Name       : TRdosObject::~TRdosObject
#
#   Purpose....: Destructor for TRdosObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosObject::~TRdosObject()
{
    if (FData)
        delete FData;
}

/*##########################################################################
#
#   Name       : TRdosObject::CreateObject
#
#   Purpose....: Create a new object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosObject::CreateObject(int size)
{
    if (FData)
        delete FData;

    FData = new char[size];
    FSize = size;
}

/*##########################################################################
#
#   Name       : TRdosObject::LoadFile
#
#   Purpose....: Load object from file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosObject::LoadFile(const char *FileName)
{
    TFile File(FileName);

    if (FData)
        delete FData;
    FData = 0;
    FSize = 0;

    if (File.IsOpen())
    {
        FSize = File.GetSize();
        FData = new char[FSize];
        File.Read(FData, FSize);
    }
}

/*##########################################################################
#
#   Name       : TRdosFont::TRdosFont
#
#   Purpose....: Constructor for TRdosFont
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosFont::TRdosFont(const char *FontFileName)
{
    FType = RDOS_OBJECT_FONT;
    LoadFile(FontFileName);
}

/*##########################################################################
#
#   Name       : TRdosFont::~TRdosFont
#
#   Purpose....: Destructor for TRdosFont
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosFont::~TRdosFont()
{
}
