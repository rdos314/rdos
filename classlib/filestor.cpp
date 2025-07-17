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
