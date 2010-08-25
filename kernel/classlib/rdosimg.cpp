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

#include <memory.h>

#include "rdosimg.h"

#define RDOS_SIGN   0x5A1E75D4

#define     FALSE   0
#define     TRUE    !FALSE

struct TExeHeader
{
    short int Signature;
    short int LsbSize;
    short int MsbSize;
    short int RelocCount;
    short int HeaderSize;
    short int MinAlloc;
    short int MaxAlloc;
    short int Ss;
    short int Sp;
    short int Checksum;
    short int Ip;
    short int Cs;    
    short int RelocOffs;
    short int OvNo;
};

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
void TRdosObject::LoadFile(TFile *File)
{
    if (FData)
        delete FData;
    FData = 0;
    FSize = 0;

    if (File && File->IsOpen())
    {
        FSize = File->GetSize();
        FData = new char[FSize];
        File->Read(FData, FSize);
    }
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

    LoadFile(&File);
}

/*##########################################################################
#
#   Name       : TRdosDeviceBaseObject::TRdosDeviceBaseObject
#
#   Purpose....: Constructor for TRdosDeviceBaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDeviceBaseObject::TRdosDeviceBaseObject()
{
}

/*##########################################################################
#
#   Name       : TRdosDeviceBaseObject::~TRdosDeviceBaseObject
#
#   Purpose....: Destructor for TRdosDeviceBaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDeviceBaseObject::~TRdosDeviceBaseObject()
{
}

/*##########################################################################
#
#   Name       : TRdosDeviceBaseObject::LoadDeviceFile
#
#   Purpose....: Load device file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosDeviceBaseObject::LoadDeviceFile(const char *FileName)
{
    TExeHeader ExeHeader;
    TFile File(FileName);
    int HeaderSize;
    int Size;

    if (FData)
        delete FData;
    FData = 0;
    FSize = 0;

    if (File.IsOpen())
    {
        File.Read(&ExeHeader, sizeof(TExeHeader));
        FDeviceHeader.StartIp = ExeHeader.Ip;

        HeaderSize = ExeHeader.HeaderSize << 4;        
        File.SetPos(HeaderSize);
        
        Size = ExeHeader.MsbSize << 5;
        Size += (ExeHeader.LsbSize >> 4) + 1;
        Size -= ExeHeader.HeaderSize;
        Size += ExeHeader.MinAlloc;

        FSize = Size >> 4;
        FData = new char[FSize];
        File.Read(FData, FSize);
    }
}

/*##########################################################################
#
#   Name       : TRdosKernelObject::TRdosKernelObject
#
#   Purpose....: Constructor for TRdosKernelObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosKernelObject::TRdosKernelObject(const char *KernelFileName)
{
    FType = RDOS_OBJECT_KERNEL;
    LoadDeviceFile(KernelFileName);
}

/*##########################################################################
#
#   Name       : TRdosKernelObject::~TRdosKernelObject
#
#   Purpose....: Destructor for TRdosKernelObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosKernelObject::~TRdosKernelObject()
{
}

/*##########################################################################
#
#   Name       : TRdosFontObject::TRdosFontObject
#
#   Purpose....: Constructor for TRdosFontObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosFontObject::TRdosFontObject(const char *FontFileName)
{
    FType = RDOS_OBJECT_FONT;
    LoadFile(FontFileName);
}

/*##########################################################################
#
#   Name       : TRdosFontObject::~TRdosFontObject
#
#   Purpose....: Destructor for TRdosFontObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosFontObject::~TRdosFontObject()
{
}

/*##########################################################################
#
#   Name       : TRdosDeviceObject::TRdosDeviceObject
#
#   Purpose....: Constructor for TRdosDeviceObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDeviceObject::TRdosDeviceObject(const char *DeviceFileName)
{
    FType = RDOS_OBJECT_DEVICE;
    LoadDeviceFile(DeviceFileName);
}

/*##########################################################################
#
#   Name       : TRdosDeviceObject::~TRdosDeviceObject
#
#   Purpose....: Destructor for TRdosDeviceObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDeviceObject::~TRdosDeviceObject()
{
}

/*##########################################################################
#
#   Name       : TRdosShutdownObject::TRdosShutdownObject
#
#   Purpose....: Constructor for TRdosShutdownObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosShutdownObject::TRdosShutdownObject(const char *ShutdownFileName)
{
    FType = RDOS_OBJECT_SHUTDOWN;
    LoadDeviceFile(ShutdownFileName);
}

/*##########################################################################
#
#   Name       : TRdosShutdownObject::~TRdosShutdownObject
#
#   Purpose....: Destructor for TRdosShutdownObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosShutdownObject::~TRdosShutdownObject()
{
}

/*##########################################################################
#
#   Name       : TRdosFileObject::TRdosFileObject
#
#   Purpose....: Constructor for TRdosFileObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosFileObject::TRdosFileObject(const char *FileName)
{
    TFile *File;

    FType = RDOS_OBJECT_FILE;

    File = CreateFileHeader(FileName);

    if (File)
        LoadFile(File);
}

/*##########################################################################
#
#   Name       : TRdosFileObject::~TRdosFileObject
#
#   Purpose....: Destructor for TRdosFileObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosFileObject::~TRdosFileObject()
{
}

/*##########################################################################
#
#   Name       : TRdosFileObject::CreateFileHeader
#
#   Purpose....: Create file header
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TRdosFileObject::CreateFileHeader(const char *FileName)
{
    TFile *File;
    int i;
    const char *ptr;

    File = new TFile(FileName);

    if (File->IsOpen())
    {
        ptr = FileName;

        for (i = 0; i < 8; i++)
            FFileHeader.Base[i] = ' ';
            
        for (i = 0; i < 8; i++)
        {
            if (*ptr == '.')
            {
                ptr++;
                break;
            }

            if (*ptr)
            {
                FFileHeader.Base[i] = *ptr;
                ptr++;
            }
            else
                break;            
        }


        for (i = 0; i < 3; i++)
            FFileHeader.Ext[i] = ' ';
            
        for (i = 0; i < 3; i++)
        {
            if (*ptr)
            {
                FFileHeader.Base[i] = *ptr;
                ptr++;
            }
            else
                break;            
        }

        FFileHeader.Attrib = 0;
        FFileHeader.Time = 0;
        FFileHeader.Date = 0;
        FFileHeader.Size = File->GetSize();
    }

    return File;
    
}

/*##########################################################################
#
#   Name       : TRdosCommandObject::TRdosCommandObject
#
#   Purpose....: Constructor for TRdosCommandObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosCommandObject::TRdosCommandObject(const char *Cmd)
{
    FType = RDOS_OBJECT_COMMAND;

    FSize = strlen(Cmd) + 1;
    FData = new char[FSize];
    memcpy(FData, Cmd, FSize);
}

/*##########################################################################
#
#   Name       : TRdosCommandObject::~TRdosCommandObject
#
#   Purpose....: Destructor for TRdosCommandObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosCommandObject::~TRdosCommandObject()
{
}

/*##########################################################################
#
#   Name       : TRdosSetObject::TRdosSetObject
#
#   Purpose....: Constructor for TRdosSetObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosSetObject::TRdosSetObject(const char *Param)
{
    FType = RDOS_OBJECT_SET;

    FSize = strlen(Param) + 1;
    FData = new char[FSize];
    memcpy(FData, Param, FSize);
}

/*##########################################################################
#
#   Name       : TRdosSetObject::~TRdosSetObject
#
#   Purpose....: Destructor for TRdosSetObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosSetObject::~TRdosSetObject()
{
}

/*##########################################################################
#
#   Name       : TRdosPathObject::TRdosPathObject
#
#   Purpose....: Constructor for TRdosPathObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosPathObject::TRdosPathObject(const char *Path)
{
    FType = RDOS_OBJECT_PATH;

    FSize = strlen(Path) + 1;
    FData = new char[FSize];
    memcpy(FData, Path, FSize);
}

/*##########################################################################
#
#   Name       : TRdosPathObject::~TRdosPathObject
#
#   Purpose....: Destructor for TRdosPathObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosPathObject::~TRdosPathObject()
{
}
