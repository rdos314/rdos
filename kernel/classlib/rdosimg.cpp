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
#include <stdio.h>
#include <ctype.h>

#include "rdosimg.h"

#ifdef __RDOS__
#include "rdos.h"
#endif

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

struct TRdvHeader16
{
    short int Signature;
    unsigned short int Ip;
    unsigned short int CodeSize;
    short int CodeSel;
    unsigned short int DataSize;
    short int DataSel;
};

struct TRdvHeader32
{
    short int Signature;
    long Eip;
    long CodeSize;
    short int CodeSel;
    long DataSize;
    short int DataSel;
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
#   Name       : TRdosObject::TRdosObject
#
#   Purpose....: Constructor for TRdosObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosObject::TRdosObject(TFile *File, int Size)
{
    FSize = Size;
    FType = 0;
    FData = new char[FSize];
    File->Read(FData, FSize);
}

#ifdef __RDOS__

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
TRdosObject::TRdosObject(int adapter, int entry, int size)
{
    FSize = size;
    FType = 0;
    FData = new char[FSize];
    RdosGetImageData(adapter, entry, FData);
}

#endif

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
#   Name       : TRdosObject::WriteObject
#
#   Purpose....: Write object to config-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosObject::WriteObject(TFile *File)
{
    File->Write(FData, FSize);
}

/*##########################################################################
#
#   Name       : TRdosObject::GetSize
#
#   Purpose....: Get size of object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRdosObject::GetSize()
{
    return FSize;
}

/*##########################################################################
#
#   Name       : TRdosObject::GetType
#
#   Purpose....: Get type of object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
short int TRdosObject::GetType()
{
    return FType;
}

/*##########################################################################
#
#   Name       : TRdosObject::CalcCrc
#
#   Purpose....: Calculate object CRC
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
unsigned short int TRdosObject::CalcCrc(TCrc *Crc)
{
    if (FSize)
        return Crc->CalcCrc(0, FData, FSize);
    else
        return 0;
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
#   Name       : TRdosSimpleDeviceBaseObject::TRdosSimpleDeviceBaseObject
#
#   Purpose....: Constructor for TRdosSimpleDeviceBaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosSimpleDeviceBaseObject::TRdosSimpleDeviceBaseObject()
{
}

/*##########################################################################
#
#   Name       : TRdosSimpleDeviceBaseObject::TRdosSimpleDeviceBaseObject
#
#   Purpose....: Constructor for TRdosSimpleDeviceBaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosSimpleDeviceBaseObject::TRdosSimpleDeviceBaseObject(TFile *File, int Size)
 : TRdosObject(File, Size)
{
    FDeviceSize = FSize - sizeof(TRdosSimpleDeviceHeader);
    FDeviceHeader = (TRdosSimpleDeviceHeader *)FData;
    FDeviceData = FData + sizeof(TRdosSimpleDeviceHeader);    
}

#ifdef __RDOS__

/*##########################################################################
#
#   Name       : TRdosSimpleDeviceBaseObject::TRdosSimpleDeviceBaseObject
#
#   Purpose....: Constructor for TRdosSimpleDeviceBaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosSimpleDeviceBaseObject::TRdosSimpleDeviceBaseObject(int adapter, int entry, int size)
  : TRdosObject(adapter, entry, size)
{
    FDeviceSize = FSize - sizeof(TRdosSimpleDeviceHeader);
    FDeviceHeader = (TRdosSimpleDeviceHeader *)FData;
    FDeviceData = FData + sizeof(TRdosSimpleDeviceHeader);    
}

#endif

/*##########################################################################
#
#   Name       : TRdosSimpleDeviceBaseObject::~TRdosSimpleDeviceBaseObject
#
#   Purpose....: Destructor for TRdosDeviceBaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosSimpleDeviceBaseObject::~TRdosSimpleDeviceBaseObject()
{
}

/*##########################################################################
#
#   Name       : TRdosSimpleDeviceBaseObject::LoadDeviceFile
#
#   Purpose....: Load device file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRdosSimpleDeviceBaseObject::LoadDeviceFile(const char *FileName)
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
        ExeHeader.Signature = 0;
        File.Read(&ExeHeader, sizeof(TExeHeader));

        if (ExeHeader.Signature != 0x5A4D)
            return FALSE;

        HeaderSize = ExeHeader.HeaderSize << 4;        
        File.SetPos(HeaderSize);
        
        Size = ExeHeader.MsbSize << 5;
        Size += (ExeHeader.LsbSize >> 4) + 1;
        Size -= ExeHeader.HeaderSize;
        Size += ExeHeader.MinAlloc;

        FDeviceSize = Size << 4;
        FSize = FDeviceSize + sizeof(TRdosSimpleDeviceHeader);
        FData = new char[FSize];
        FDeviceHeader = (TRdosSimpleDeviceHeader *)FData;
        FDeviceData = FData + sizeof(TRdosSimpleDeviceHeader);

        FDeviceHeader->StartIp = ExeHeader.Ip;

        File.Read(FDeviceData, FDeviceSize);

        return TRUE;
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TRdosDosDeviceBaseObject::TRdosDosDeviceBaseObject
#
#   Purpose....: Constructor for TRdosDosDeviceBaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDosDeviceBaseObject::TRdosDosDeviceBaseObject()
{
}

/*##########################################################################
#
#   Name       : TRdosDeviceDosBaseObject::TRdosDeviceDosBaseObject
#
#   Purpose....: Constructor for TRdosDosDeviceBaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDosDeviceBaseObject::TRdosDosDeviceBaseObject(TFile *File, int Size)
 : TRdosObject(File, Size)
{
    FDeviceHeader = (TRdosDosDeviceHeader *)FData; 
    FDeviceSize = FSize - FDeviceHeader->Size;
    FDeviceData = FData + FDeviceHeader->Size;    
}

#ifdef __RDOS__

/*##########################################################################
#
#   Name       : TRdosDosDeviceBaseObject::TRdosDosDeviceBaseObject
#
#   Purpose....: Constructor for TRdosDosDeviceBaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDosDeviceBaseObject::TRdosDosDeviceBaseObject(int adapter, int entry, int size)
  : TRdosObject(adapter, entry, size)
{
    FDeviceHeader = (TRdosDosDeviceHeader *)FData; 
    FDeviceSize = FSize - FDeviceHeader->Size;
    FDeviceData = FData + FDeviceHeader->Size;    
}

#endif

/*##########################################################################
#
#   Name       : TRdosDosDeviceBaseObject::~TRdosDosDeviceBaseObject
#
#   Purpose....: Destructor for TRdosDosDeviceBaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDosDeviceBaseObject::~TRdosDosDeviceBaseObject()
{
}

/*##########################################################################
#
#   Name       : TRdosDosDeviceBaseObject::LoadDeviceFile
#
#   Purpose....: Load device file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRdosDosDeviceBaseObject::LoadDeviceFile(const char *FileName, const char *Param)
{
    TExeHeader ExeHeader;
    TFile File(FileName);
    int HeaderSize;
    int Size;
    char *ptr;

    if (FData)
        delete FData;
    FData = 0;
    FSize = 0;

    if (File.IsOpen())
    {
        ExeHeader.Signature = 0;
        File.Read(&ExeHeader, sizeof(TExeHeader));

        if (ExeHeader.Signature != 0x5A4D)
            return FALSE;

        HeaderSize = ExeHeader.HeaderSize << 4;        
        File.SetPos(HeaderSize);
        
        Size = ExeHeader.MsbSize << 5;
        Size += (ExeHeader.LsbSize >> 4) + 1;
        Size -= ExeHeader.HeaderSize;
        Size += ExeHeader.MinAlloc;

        HeaderSize = sizeof(TRdosDosDeviceHeader);
        HeaderSize += strlen(FileName);
        HeaderSize += strlen(Param);
        HeaderSize++;

        FDeviceSize = Size << 4;
        FSize = FDeviceSize + HeaderSize;
        FData = new char[FSize];
        FDeviceHeader = (TRdosDosDeviceHeader *)FData;
        FDeviceData = FData + HeaderSize;

        FDeviceHeader->Size = HeaderSize;
        FDeviceHeader->Sel = 0;
        FDeviceHeader->StartIp = ExeHeader.Ip;

        ptr = &FDeviceHeader->NameParam;
        strcpy(ptr, FileName);
        ptr += strlen(FileName);
        ptr++;        
        strcpy(ptr, Param);

        File.Read(FDeviceData, FDeviceSize);

        return TRUE;
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TRdosDevice16BaseObject::TRdosDevice16BaseObject
#
#   Purpose....: Constructor for TRdosDevice16BaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDevice16BaseObject::TRdosDevice16BaseObject()
{
}

/*##########################################################################
#
#   Name       : TRdosDevice16BaseObject::TRdosDevice16BaseObject
#
#   Purpose....: Constructor for TRdosDevice16BaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDevice16BaseObject::TRdosDevice16BaseObject(TFile *File, int Size)
 : TRdosObject(File, Size)
{
    FDeviceHeader = (TRdosDevice16Header *)FData; 
    FDeviceSize = FSize - FDeviceHeader->Size;
    FDeviceData = FData + FDeviceHeader->Size;    
}

#ifdef __RDOS__

/*##########################################################################
#
#   Name       : TRdosDevice16BaseObject::TRdosDevice16BaseObject
#
#   Purpose....: Constructor for TRdosDevice16BaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDevice16BaseObject::TRdosDevice16BaseObject(int adapter, int entry, int size)
  : TRdosObject(adapter, entry, size)
{
    FDeviceHeader = (TRdosDevice16Header *)FData; 
    FDeviceSize = FSize - FDeviceHeader->Size;
    FDeviceData = FData + FDeviceHeader->Size;    
}

#endif

/*##########################################################################
#
#   Name       : TRdosDevice16BaseObject::~TRdosDevice16BaseObject
#
#   Purpose....: Destructor for TRdosDevice16BaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDevice16BaseObject::~TRdosDevice16BaseObject()
{
}

/*##########################################################################
#
#   Name       : TRdosDevice16BaseObject::LoadDeviceFile
#
#   Purpose....: Load device file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRdosDevice16BaseObject::LoadDeviceFile(const char *FileName, const char *Param)
{
    TRdvHeader16 ExeHeader;
    TFile File(FileName);
    int HeaderSize;
    int Size;
    char *ptr;

    if (FData)
        delete FData;
    FData = 0;
    FSize = 0;

    if (File.IsOpen())
    {
        ExeHeader.Signature = 0;
        File.Read(&ExeHeader, sizeof(TRdvHeader16));

        if (ExeHeader.Signature != 0x3652)
            return FALSE;

        HeaderSize = sizeof(TRdosDevice16Header);
        HeaderSize += strlen(FileName);
        HeaderSize += strlen(Param);
        HeaderSize++;

        FDeviceSize = ExeHeader.CodeSize + ExeHeader.DataSize;
        FSize = FDeviceSize + HeaderSize;
        FData = new char[FSize];
        FDeviceHeader = (TRdosDevice16Header *)FData;
        FDeviceData = FData + HeaderSize;

        FDeviceHeader->Size = HeaderSize;
        FDeviceHeader->StartIp = ExeHeader.Ip;
        FDeviceHeader->CodeSize = ExeHeader.CodeSize;
        FDeviceHeader->CodeSel = ExeHeader.CodeSel;
        FDeviceHeader->DataSize = ExeHeader.DataSize;
        FDeviceHeader->DataSel = ExeHeader.DataSel;

        ptr = &FDeviceHeader->NameParam;
        strcpy(ptr, FileName);
        ptr += strlen(FileName);
        ptr++;        
        strcpy(ptr, Param);

        File.Read(FDeviceData, FDeviceSize);

        return TRUE;
    }
    return FALSE;
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
    if (LoadDeviceFile(KernelFileName))
        FType = RDOS_OBJECT_KERNEL;
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
TRdosKernelObject::TRdosKernelObject(TFile *File, int Size)
 : TRdosSimpleDeviceBaseObject(File, Size)
{
    FType = RDOS_OBJECT_KERNEL;
}

#ifdef __RDOS__

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
TRdosKernelObject::TRdosKernelObject(int adapter, int entry, int size)
  : TRdosSimpleDeviceBaseObject(adapter, entry, size)
{
    FType = RDOS_OBJECT_KERNEL;
}

#endif

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
#   Name       : TRdosKernelObject::GetInfo
#
#   Purpose....: Get printable object info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TRdosKernelObject::GetInfo()
{
    return TString("Kernel");
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
#   Name       : TRdosFontObject::TRdosFontObject
#
#   Purpose....: Constructor for TRdosFontObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosFontObject::TRdosFontObject(TFile *File, int Size)
 : TRdosObject(File, Size)
{
    FType = RDOS_OBJECT_FONT;
}

#ifdef __RDOS__

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
TRdosFontObject::TRdosFontObject(int adapter, int entry, int size)
  : TRdosObject(adapter, entry, size)
{
    FType = RDOS_OBJECT_FONT;
}

#endif

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
#   Name       : TRdosFontObject::GetInfo
#
#   Purpose....: Get printable object info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TRdosFontObject::GetInfo()
{
    return TString("Font");
}

/*##########################################################################
#
#   Name       : TRdosSimpleDeviceObject::TRdosSimpleDeviceObject
#
#   Purpose....: Constructor for TRdosSimpleDeviceObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosSimpleDeviceObject::TRdosSimpleDeviceObject(const char *DeviceFileName)
{
    if (LoadDeviceFile(DeviceFileName))
        FType = RDOS_OBJECT_SIMPLE_DEVICE;
}

/*##########################################################################
#
#   Name       : TRdosSimpleDeviceObject::TRdosSimpleDeviceObject
#
#   Purpose....: Constructor for TRdosSimpleDeviceObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosSimpleDeviceObject::TRdosSimpleDeviceObject(TFile *File, int Size)
 : TRdosSimpleDeviceBaseObject(File, Size)
{
    FType = RDOS_OBJECT_SIMPLE_DEVICE;
}

#ifdef __RDOS__

/*##########################################################################
#
#   Name       : TRdosSimpleDeviceObject::TRdosSimpleDeviceObject
#
#   Purpose....: Constructor for TRdosSimpleDeviceObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosSimpleDeviceObject::TRdosSimpleDeviceObject(int adapter, int entry, int size)
  : TRdosSimpleDeviceBaseObject(adapter, entry, size)
{
    FType = RDOS_OBJECT_SIMPLE_DEVICE;
}

#endif

/*##########################################################################
#
#   Name       : TRdosSimpleDeviceObject::~TRdosSimpleDeviceObject
#
#   Purpose....: Destructor for TRdosSimpleDeviceObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosSimpleDeviceObject::~TRdosSimpleDeviceObject()
{
}

/*##########################################################################
#
#   Name       : TRdosSimpleDeviceObject::GetInfo
#
#   Purpose....: Get printable object info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TRdosSimpleDeviceObject::GetInfo()
{
    return TString("DosDevice");
}

/*##########################################################################
#
#   Name       : TRdosDosDeviceObject::TRdosDosDeviceObject
#
#   Purpose....: Constructor for TRdosDosDeviceObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDosDeviceObject::TRdosDosDeviceObject(const char *DeviceFileName, const char *Param)
{
    if (LoadDeviceFile(DeviceFileName, Param))
        FType = RDOS_OBJECT_DOS_DEVICE;
}

/*##########################################################################
#
#   Name       : TRdosDosDeviceObject::TRdosDosDeviceObject
#
#   Purpose....: Constructor for TRdosDosDeviceObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDosDeviceObject::TRdosDosDeviceObject(TFile *File, int Size)
 : TRdosDosDeviceBaseObject(File, Size)
{
    FType = RDOS_OBJECT_DOS_DEVICE;
}

#ifdef __RDOS__

/*##########################################################################
#
#   Name       : TRdosDosDeviceObject::TRdosDosDeviceObject
#
#   Purpose....: Constructor for TRdosDosDeviceObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDosDeviceObject::TRdosDosDeviceObject(int adapter, int entry, int size)
  : TRdosDosDeviceBaseObject(adapter, entry, size)
{
    FType = RDOS_OBJECT_DOS_DEVICE;
}

#endif

/*##########################################################################
#
#   Name       : TRdosDosDeviceObject::~TRdosDosDeviceObject
#
#   Purpose....: Destructor for TRdosDosDeviceObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDosDeviceObject::~TRdosDosDeviceObject()
{
}

/*##########################################################################
#
#   Name       : TRdosDosDeviceObject::GetInfo
#
#   Purpose....: Get printable object info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TRdosDosDeviceObject::GetInfo()
{
    char str[256];
    char *ptr;

    strcpy(str, "Device ");

    ptr = &FDeviceHeader->NameParam;
    strcat(str, ptr);
    strcat(str, " ");

    ptr += strlen(ptr);
    ptr++;
    strcat(str, ptr);
    
    return TString(str);
}

/*##########################################################################
#
#   Name       : TRdosDevice16Object::TRdosDevice16Object
#
#   Purpose....: Constructor for TRdosDevice16Object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDevice16Object::TRdosDevice16Object(const char *DeviceFileName, const char *Param)
{
    if (LoadDeviceFile(DeviceFileName, Param))
        FType = RDOS_OBJECT_DEVICE16;
}

/*##########################################################################
#
#   Name       : TRdosDevice16Object::TRdosDevice16Object
#
#   Purpose....: Constructor for TRdosDevice16Object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDevice16Object::TRdosDevice16Object(TFile *File, int Size)
 : TRdosDevice16BaseObject(File, Size)
{
    FType = RDOS_OBJECT_DEVICE16;
}

#ifdef __RDOS__

/*##########################################################################
#
#   Name       : TRdosDevice16Object::TRdosDevice16Object
#
#   Purpose....: Constructor for TRdosDevice16Object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDevice16Object::TRdosDevice16Object(int adapter, int entry, int size)
  : TRdosDevice16BaseObject(adapter, entry, size)
{
    FType = RDOS_OBJECT_DEVICE16;
}

#endif

/*##########################################################################
#
#   Name       : TRdosDevice16Object::~TRdosDevice16Object
#
#   Purpose....: Destructor for TRdosDevice16Object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDevice16Object::~TRdosDevice16Object()
{
}

/*##########################################################################
#
#   Name       : TRdosDevice16Object::GetInfo
#
#   Purpose....: Get printable object info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TRdosDevice16Object::GetInfo()
{
    char str[256];
    char *ptr;

    strcpy(str, "Device16 ");

    ptr = &FDeviceHeader->NameParam;
    strcat(str, ptr);
    strcat(str, " ");

    ptr += strlen(ptr);
    ptr++;
    strcat(str, ptr);
    
    return TString(str);
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
    if (LoadDeviceFile(ShutdownFileName))
        FType = RDOS_OBJECT_SHUTDOWN;
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
TRdosShutdownObject::TRdosShutdownObject(TFile *File, int Size)
 : TRdosSimpleDeviceBaseObject(File, Size)
{
    FType = RDOS_OBJECT_SHUTDOWN;
}

#ifdef __RDOS__

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
TRdosShutdownObject::TRdosShutdownObject(int adapter, int entry, int size)
  : TRdosSimpleDeviceBaseObject(adapter, entry, size)
{
    FType = RDOS_OBJECT_SHUTDOWN;
}

#endif

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
#   Name       : TRdosShutdownObject::GetInfo
#
#   Purpose....: Get printable object info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TRdosShutdownObject::GetInfo()
{
    return TString("Shutdown");
}

/*##########################################################################
#
#   Name       : TRdosOldFileObject::TRdosOldFileObject
#
#   Purpose....: Constructor for TRdosOldFileObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosOldFileObject::TRdosOldFileObject(const char *FileName)
{
    FType = RDOS_OBJECT_OLD_FILE;

    LoadFileAndHeader(FileName);
}

/*##########################################################################
#
#   Name       : TRdosOldFileObject::TRdosOldFileObject
#
#   Purpose....: Constructor for TRdosOldFileObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosOldFileObject::TRdosOldFileObject(TFile *File, int Size)
 : TRdosObject(File, Size)
{
    FFileSize = FSize - sizeof(TRdosOldFileHeader);
    FFileHeader = (TRdosOldFileHeader *)FData;
    FFileData = FData + sizeof(TRdosOldFileHeader);    
    FType = RDOS_OBJECT_OLD_FILE;
}

#ifdef __RDOS__

/*##########################################################################
#
#   Name       : TRdosOldFileObject::TRdosOldFileObject
#
#   Purpose....: Constructor for TRdosOldFileObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosOldFileObject::TRdosOldFileObject(int adapter, int entry, int size)
  : TRdosObject(adapter, entry, size)
{
    FFileSize = FSize - sizeof(TRdosOldFileHeader);
    FFileHeader = (TRdosOldFileHeader *)FData;
    FFileData = FData + sizeof(TRdosOldFileHeader);    
    FType = RDOS_OBJECT_OLD_FILE;
}

#endif

/*##########################################################################
#
#   Name       : TRdosOldFileObject::~TRdosOldFileObject
#
#   Purpose....: Destructor for TRdosOldFileObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosOldFileObject::~TRdosOldFileObject()
{
}

/*##########################################################################
#
#   Name       : TRdosOldFileObject::GetInfo
#
#   Purpose....: Get printable object info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TRdosOldFileObject::GetInfo()
{
    int i;
    char str[255];
    char name[64];
    char *ptr;

    strcpy(str, "File ");

    ptr = name;

    for (i = 0; i < 8; i++)
        if (FFileHeader->Base[i] != ' ')
        {
            *ptr = FFileHeader->Base[i];
            ptr++;
        }
        else
            break;

    *ptr = '.';
    ptr++;
    
    for (i = 0; i < 3; i++)
        if (FFileHeader->Ext[i] != ' ')
        {
            *ptr = FFileHeader->Ext[i];
            ptr++;
        }
        else
            break;

    *ptr = 0;            
    strcat(str, name);
        
    return TString(str);
}

/*##########################################################################
#
#   Name       : TRdosOldFileObject::LoadFileAndHeader
#
#   Purpose....: Load header and file contents
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosOldFileObject::LoadFileAndHeader(const char *FileName)
{
    TFile File(FileName);
    int i;
    const char *ptr;

    if (File.IsOpen())
    {
        FFileSize = File.GetSize();
        FSize = FFileSize + sizeof(TRdosOldFileHeader);
        FData = new char[FSize];
        FFileHeader = (TRdosOldFileHeader *)FData;
        FFileData = FData + sizeof(TRdosOldFileHeader);
                    
        ptr = FileName + strlen(FileName) - 1;

        while (ptr != FileName && *ptr != '\\' && *ptr != '/')
            ptr--;

        if (*ptr == '\\' || *ptr == '/')
            ptr++;

        for (i = 0; i < 8; i++)
            FFileHeader->Base[i] = ' ';
            
        for (i = 0; i < 8; i++)
        {
            if (*ptr == '.')
            {
                ptr++;
                break;
            }

            if (*ptr)
            {
                FFileHeader->Base[i] = *ptr;
                ptr++;
            }
            else
                break;            
        }


        for (i = 0; i < 3; i++)
            FFileHeader->Ext[i] = ' ';
            
        for (i = 0; i < 3; i++)
        {
            if (*ptr)
            {
                FFileHeader->Ext[i] = *ptr;
                ptr++;
            }
            else
                break;            
        }

        FFileHeader->Attrib = 0;
        FFileHeader->Time = 0;
        FFileHeader->Date = 0;
        FFileHeader->Size = File.GetSize();

        File.Read(FFileData, FFileSize);
    }
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
    FType = RDOS_OBJECT_FILE;

    LoadFileAndHeader(FileName);
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
TRdosFileObject::TRdosFileObject(TFile *File, int Size)
 : TRdosObject(File, Size)
{
    FFileHeader = (TRdosFileHeader *)FData;
    FFileSize = FSize - FFileHeader->Size;
    FFileData = FData + FFileHeader->Size;    
    FType = RDOS_OBJECT_FILE;
}

#ifdef __RDOS__

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
TRdosFileObject::TRdosFileObject(int adapter, int entry, int size)
  : TRdosObject(adapter, entry, size)
{
    FFileHeader = (TRdosFileHeader *)FData;
    FFileSize = FSize - FFileHeader->Size;
    FFileData = FData + FFileHeader->Size;    
    FType = RDOS_OBJECT_FILE;
}

#endif

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
#   Name       : TRdosFileObject::GetInfo
#
#   Purpose....: Get printable object info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TRdosFileObject::GetInfo()
{
    char str[256];
    char *ptr;

    strcpy(str, "File ");

    ptr = &FFileHeader->FileName;
    strcat(str, ptr);
    
    return TString(str);
}

/*##########################################################################
#
#   Name       : TRdosFileObject::LoadFileAndHeader
#
#   Purpose....: Load header and file contents
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosFileObject::LoadFileAndHeader(const char *FileName)
{
    TFile File(FileName);
    const char *ptr;
    int HeaderSize;
    TDateTime time;

    if (File.IsOpen())
    {
         ptr = FileName + strlen(FileName) - 1;

        while (ptr != FileName && *ptr != '\\' && *ptr != '/')
            ptr--;

        if (*ptr == '\\' || *ptr == '/')
            ptr++;
    
        HeaderSize = sizeof(TRdosFileHeader);
        HeaderSize += strlen(ptr);
    
        FFileSize = File.GetSize();
        FSize = FFileSize + HeaderSize;
        FData = new char[FSize];
        FFileHeader = (TRdosFileHeader *)FData;
        FFileData = FData + HeaderSize;

        strcpy(&FFileHeader->FileName, ptr);

        FFileHeader->Size = HeaderSize;
        FFileHeader->Attrib = 0;
        FFileHeader->FileSize = File.GetSize();

        time = File.GetTime();        
        FFileHeader->LsbTime = time.GetLsb();
        FFileHeader->MsbTime = time.GetMsb();

        File.Read(FFileData, FFileSize);
    }
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
#   Name       : TRdosCommandObject::TRdosCommandObject
#
#   Purpose....: Constructor for TRdosCommandObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosCommandObject::TRdosCommandObject(TFile *File, int Size)
 : TRdosObject(File, Size)
{
    FType = RDOS_OBJECT_COMMAND;
}

#ifdef __RDOS__

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
TRdosCommandObject::TRdosCommandObject(int adapter, int entry, int size)
  : TRdosObject(adapter, entry, size)
{
    FType = RDOS_OBJECT_COMMAND;
}

#endif

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
#   Name       : TRdosCommandObject::GetInfo
#
#   Purpose....: Get printable object info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TRdosCommandObject::GetInfo()
{
    char str[256];

    strcpy(str, "Run ");
    strcat(str, FData);

    return TString(str);
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
#   Name       : TRdosSetObject::TRdosSetObject
#
#   Purpose....: Constructor for TRdosSetObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosSetObject::TRdosSetObject(TFile *File, int Size)
 : TRdosObject(File, Size)
{
    FType = RDOS_OBJECT_SET;
}

#ifdef __RDOS__

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
TRdosSetObject::TRdosSetObject(int adapter, int entry, int size)
  : TRdosObject(adapter, entry, size)
{
    FType = RDOS_OBJECT_SET;
}

#endif

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
#   Name       : TRdosSetObject::GetInfo
#
#   Purpose....: Get printable object info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TRdosSetObject::GetInfo()
{
    char str[256];

    strcpy(str, "Set ");
    strcat(str, FData);

    return TString(str);
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
#   Name       : TRdosPathObject::TRdosPathObject
#
#   Purpose....: Constructor for TRdosPathObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosPathObject::TRdosPathObject(TFile *File, int Size)
 : TRdosObject(File, Size)
{
    FType = RDOS_OBJECT_PATH;
}

#ifdef __RDOS__

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
TRdosPathObject::TRdosPathObject(int adapter, int entry, int size)
  : TRdosObject(adapter, entry, size)
{
    FType = RDOS_OBJECT_PATH;
}

#endif

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

/*##########################################################################
#
#   Name       : TRdosPathObject::GetInfo
#
#   Purpose....: Get printable object info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TRdosPathObject::GetInfo()
{
    char str[256];

    strcpy(str, "Path ");
    strcat(str, FData);

    return TString(str);
}

/*##########################################################################
#
#   Name       : TRdosImage::TRdosImage
#
#   Purpose....: Constructor for TRdosImage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosImage::TRdosImage()
 : FCrc(0x1021)
{
    FObjectList = 0;
}

/*##########################################################################
#
#   Name       : TRdosImage::~TRdosImage
#
#   Purpose....: Destructor for TRdosImage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosImage::~TRdosImage()
{
    Clear();
}

/*##########################################################################
#
#   Name       : TRdosImage::Clear
#
#   Purpose....: Clear image
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosImage::Clear()
{
    TRdosObject *obj;
    
    while (FObjectList)
    {
        obj = FObjectList->FLink;
        delete FObjectList;
        FObjectList = obj;
    }
}

/*##########################################################################
#
#   Name       : TRdosImage::Add
#
#   Purpose....: Add object to image
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosImage::Add(TRdosObject *obj)
{
    TRdosObject *p;

    obj->FLink = 0;

    if (FObjectList)
    {
        p = FObjectList;

        while (p->FLink)
            p = p->FLink;

        p->FLink = obj;
    }
    else
        FObjectList = obj;
}

/*##########################################################################
#
#   Name       : TRdosImage::Remove
#
#   Purpose....: Remove object to image
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosImage::Remove(TRdosObject *obj)
{
    TRdosObject *p;
    TRdosObject *h;

    h = 0;
    p = FObjectList;

    while (p)
    {
        if (p == obj)
        {
            if (h)
                h->FLink = p->FLink;
            else
                FObjectList = p->FLink;
            break;
        }
        else
        {
            h = p;
            p = p->FLink;
        }
    }
}

/*##########################################################################
#
#   Name       : TRdosImage::AddImage
#
#   Purpose....: Add image file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosImage::AddImage(const char *ImageFile)
{
    unsigned short int crc;
    int size;
    TFile File(ImageFile);
    TRdosObjectHeader Header;
    TRdosObject *obj;

    if (File.IsOpen())
    {
        size = File.Read(&Header, sizeof(Header));        
        while (size == sizeof(Header) && Header.sign == RDOS_SIGN)
        {
            size = Header.len - sizeof(Header);
            if (size >= 0)
            {
                obj = 0;

                switch (Header.type)
                {
                    case RDOS_OBJECT_KERNEL:
                        obj = new TRdosKernelObject(&File, size);
                        break;

                    case RDOS_OBJECT_FONT:
                        obj = new TRdosFontObject(&File, size);
                        break;

                    case RDOS_OBJECT_DEVICE16:
                        obj = new TRdosDevice16Object(&File, size);
                        break;

                    case RDOS_OBJECT_DOS_DEVICE:
                        obj = new TRdosDosDeviceObject(&File, size);
                        break;

                    case RDOS_OBJECT_SIMPLE_DEVICE:
                        obj = new TRdosSimpleDeviceObject(&File, size);
                        break;

                    case RDOS_OBJECT_SHUTDOWN:
                        obj = new TRdosShutdownObject(&File, size);
                        break;

                    case RDOS_OBJECT_FILE:
                        obj = new TRdosFileObject(&File, size);
                        break;

                    case RDOS_OBJECT_OLD_FILE:
                        obj = new TRdosOldFileObject(&File, size);
                        break;

                    case RDOS_OBJECT_COMMAND:
                        obj = new TRdosCommandObject(&File, size);
                        break;

                    case RDOS_OBJECT_SET:
                        obj = new TRdosSetObject(&File, size);
                        break;

                    case RDOS_OBJECT_PATH:
                        obj = new TRdosPathObject(&File, size);
                        break;

                }                

                if (obj)
                {
                    crc = obj->CalcCrc(&FCrc);
                    if (crc == Header.crc)   
                        Add(obj);
                    else
                    {
                        delete obj;
                        obj = 0;
                    }
                }
            }
            size = File.Read(&Header, sizeof(Header));        
        }
    }
}

#ifdef __RDOS__

/*##########################################################################
#
#   Name       : TRdosImage::AddRunning
#
#   Purpose....: Add running image
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosImage::AddRunning()
{
    int adapter;
    int entry;
    int size;
    TRdosObjectHeader Header;
    TRdosObject *obj;

    for (adapter = 0; adapter < 16; adapter++)
    {
        for (entry = 0; entry < 256; entry++)
        {
            if (RdosGetImageHeader(adapter, entry, &Header))
            {
                size = Header.len - sizeof(Header);
                if (size >= 0)
                {
                    obj = 0;

                    switch (Header.type)
                    {
                        case RDOS_OBJECT_KERNEL:
                            obj = new TRdosKernelObject(adapter, entry, size);
                            break;

                        case RDOS_OBJECT_FONT:
                            obj = new TRdosFontObject(adapter, entry, size);
                            break;

                        case RDOS_OBJECT_DEVICE16:
                            obj = new TRdosDevice16Object(adapter, entry, size);
                            break;

                        case RDOS_OBJECT_DOS_DEVICE:
                            obj = new TRdosDosDeviceObject(adapter, entry, size);
                            break;

                        case RDOS_OBJECT_SIMPLE_DEVICE:
                            obj = new TRdosSimpleDeviceObject(adapter, entry, size);
                            break;

                        case RDOS_OBJECT_SHUTDOWN:
                            obj = new TRdosShutdownObject(adapter, entry, size);
                            break;

                        case RDOS_OBJECT_FILE:
                            obj = new TRdosFileObject(adapter, entry, size);
                            break;

                        case RDOS_OBJECT_OLD_FILE:
                            obj = new TRdosOldFileObject(adapter, entry, size);
                            break;

                        case RDOS_OBJECT_COMMAND:
                            obj = new TRdosCommandObject(adapter, entry, size);
                            break;

                        case RDOS_OBJECT_SET:
                            obj = new TRdosSetObject(adapter, entry, size);
                            break;

                        case RDOS_OBJECT_PATH:
                            obj = new TRdosPathObject(adapter, entry, size);
                            break;

                    }                

                    if (obj)
                        Add(obj);
                }
            }
            else
                break;
        }
    }
}

#endif

/*##########################################################################
#
#   Name       : TRdosImage::AddConfigCmd
#
#   Purpose....: Add config row
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosImage::AddConfigCmd(const char *cmd, const char *param)
{
    const char *ptr;
    char file[64];
    char ch;
    int i;
    TRdosObject *obj = 0;

    ptr = param;
    for (i = 0; i < 63 && *ptr; i++)
    {
        ch = tolower(*ptr);
    
        if (ch == ' ' || ch == 0x8 || ch == '=')
            break;
        else
        {
            file[i] = ch;
            ptr++;
        }
    }

    file[i] = 0;    

    while (*ptr == ' ' || *ptr == 0x8 || *ptr == '=')
        ptr++;

    if (!strcmp(cmd, "kernel"))
        obj = new TRdosKernelObject(file);
    
    if (!strcmp(cmd, "font"))
        obj = new TRdosFontObject(file);
    
    if (!strcmp(cmd, "device"))
    {
        obj = new TRdosDosDeviceObject(file, ptr);
        if (obj->GetType() != RDOS_OBJECT_DOS_DEVICE)
        {
            delete obj;
            obj = new TRdosDevice16Object(file, ptr);
        } 
    }
    
    if (!strcmp(cmd, "shutdown"))
        obj = new TRdosShutdownObject(file);
    
    if (!strcmp(cmd, "file"))
        obj = new TRdosFileObject(file);
    
    if (!strcmp(cmd, "run"))
        obj = new TRdosCommandObject(param);
    
    if (!strcmp(cmd, "set"))
        obj = new TRdosSetObject(param);
    
    if (!strcmp(cmd, "path"))
        obj = new TRdosPathObject(param);

    if (obj)
    {
        if (obj->GetSize() > 0)
            Add(obj);        
        else
        {
            printf("Cannot find <");
            printf(file);
            printf(">\r\n");
            delete obj;
        }
    }
    else
    {
        printf("Unknown command <");
        printf(cmd);
        printf(">\r\n");
    }
}

/*##########################################################################
#
#   Name       : TRdosImage::AddConfigRow
#
#   Purpose....: Add config row
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosImage::AddConfigRow(const char *Row)
{
    int i;
    const char *ptr;
    char cmd[64];
    char ch;

    ptr = Row;

    for (i = 0; i < 63 && *ptr; i++)
    {
        ch = tolower(*ptr);
    
        if (ch == ' ' || ch == 0x8 || ch == '=')
            break;
        else
        {
            cmd[i] = ch;
            ptr++;
        }
    }

    cmd[i] = 0;    

    while (*ptr == ' ' || *ptr == 0x8 || *ptr == '=')
        ptr++;

    AddConfigCmd(cmd, ptr);        
}

/*##########################################################################
#
#   Name       : TRdosImage::AddConfig
#
#   Purpose....: Add config file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosImage::AddConfig(const char *ConfigFile)
{
    int pos;
    int size;
    char CurrentRow[1024];
    char *ptr;
    TFile File(ConfigFile);

    if (File.IsOpen())
    {
        pos = 0;

        for (;;)
        {
            size = File.Read(CurrentRow, 1023);

            if (size)
            {
                CurrentRow[size] = 0;
    
                ptr = CurrentRow;
                size = 0;
                while (*ptr == 0xd || *ptr == 0xa || *ptr == ' ' || *ptr == 0x8)
                {
                    ptr++;
                    size++;
                }

                pos += size;
                File.SetPos(pos);
            }

            size = File.Read(CurrentRow, 1023);
            if (size)
            {
                CurrentRow[size] = 0;

                ptr = CurrentRow;
                size = 0;
                while (*ptr && *ptr != 0xd && *ptr != 0xa)
                {
                    size++;
                    ptr++;
                }

                pos += size;
                pos++;

                File.SetPos(pos);

                *ptr = 0;

                AddConfigRow(CurrentRow);
            }
            else
                break;
                
        }                   
    }
}

/*##########################################################################
#
#   Name       : TRdosImage::WriteImage
#
#   Purpose....: Write image file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosImage::WriteImage(const char *ImageFile)
{
    TFile File(ImageFile, 0);
    TRdosObjectHeader Header;
    TRdosObject *obj;

    Header.sign = RDOS_SIGN;

    if (File.IsOpen())
    {
        obj = FObjectList;

        while (obj)
        {
            Header.len = obj->GetSize() + sizeof(Header);
            Header.type = obj->GetType();
            Header.crc = obj->CalcCrc(&FCrc);
            File.Write(&Header, sizeof(Header));
            obj->WriteObject(&File);

            obj = obj->FLink;
        }

        Header.len = 0;
        Header.type = 0xE5E5;
        Header.crc = 0;
        File.Write(&Header, sizeof(Header));
    }
}
