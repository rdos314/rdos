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
# filestor.cpp
# File storage class
#
########################################################################*/

#include "filestor.h"

#define FALSE   0
#define TRUE    !FALSE

/*##########################################################################
#
#   Name       : TFileStorage::TFileStorage
#
#   Purpose....: Constructor for file storage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileStorage::TFileStorage(TFile &File)
 : FFile(File)
{
}

/*##########################################################################
#
#   Name       : TFileStorage::TFileStorage
#
#   Purpose....: Constructor for file storage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileStorage::TFileStorage(TFile &File, int Size)
 : FFile(File)
{
    FFile.SetSize(Size);
}

/*##########################################################################
#
#   Name       : TFileStorage::TFileStorage
#
#   Purpose....: Constructor for file storage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileStorage::TFileStorage(const char *FileName)
 : FFile(FileName)
{
}

/*##########################################################################
#
#   Name       : TFileStorage::TFileStorage
#
#   Purpose....: Constructor for file storage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileStorage::TFileStorage(const char *FileName, int Size)
 : FFile(FileName)
{
    FFile.SetSize(Size);
}

/*##########################################################################
#
#   Name       : TFileStorage::~TFileStorage
#
#   Purpose....: Destructor for file storage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFileStorage::~TFileStorage()
{
}

/*##########################################################################
#
#   Name       : TFileStorage::Size
#
#   Purpose....: Get size
#
#
##########################################################################*/
long TFileStorage::Size()
{
	return (long)FFile.GetSize();
}

/*##########################################################################
#
#   Name       : TFileStorage::Read
#
#   Purpose....: Read data block
#
#
##########################################################################*/
int TFileStorage::Read(long offset, char *buf, int size)
{
    if (offset + size <= FFile.GetSize())
    {
        FFile.SetPos(offset);
        if (FFile.Read(buf, size) == size)
            return TRUE;
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TFileStorage::Write
#
#   Purpose....: Write data block
#
#
##########################################################################*/
int TFileStorage::Write(long offset, const char *buf, int size)
{
    if (offset + size <= FFile.GetSize())
    {
        FFile.SetPos(offset);
        if (FFile.Write(buf, size) == size)
            return TRUE;
    }
    return FALSE;
}
