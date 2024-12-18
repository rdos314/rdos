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
#include <stdlib.h>
#include <ctype.h>

#include "rdosimg.h"

#ifdef __RDOS__
#include "rdos.h"

#define     FALSE   0
#define     TRUE    !FALSE

#endif

#define RDOS_SIGN   0x5A1E75D4

#pragma pack( push, 1 )

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

struct TBinLongModeHeader
{
    short int Signature;
    long Eip;
    long ImageBase;
    long ImageSize;
    long IdtBase;
};

struct TBinRealTimeHeader
{
    short int Signature;
};

#pragma pack( pop )

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
    memset(FData, 0xFF, FSize);
    FImageOffset = (int)File->GetPos();
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
    FImageOffset = 0;
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
#   Name       : TRdosObject::GetData
#
#   Purpose....: Get data of object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TRdosObject::GetData()
{
    return FData;
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
        FSize = (int)File->GetSize();
        FData = new char[FSize];
        memset(FData, 0xFF, FSize);
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
#   Name       : TRdosSimpleDeviceBaseObject::IsValid
#
#   Purpose....: Check for valid device file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRdosSimpleDeviceBaseObject::IsValid(const char *FileName)
{
    TExeHeader ExeHeader;
    TFile File(FileName);
    int ok = FALSE;

    if (File.IsOpen())
    {
        ExeHeader.Signature = 0;
        File.Read(&ExeHeader, sizeof(TExeHeader));

        if (ExeHeader.Signature == 0x5A4D)
            ok = TRUE;
    }
    return ok;
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
        memset(FData, 0xFF, FSize);
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
#   Name       : TRdosDosDeviceBaseObject::IsValid
#
#   Purpose....: Check for valid device file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRdosDosDeviceBaseObject::IsValid(const char *FileName)
{
    TExeHeader ExeHeader;
    TFile File(FileName);
    int ok = FALSE;

    if (File.IsOpen())
    {
        ExeHeader.Signature = 0;
        File.Read(&ExeHeader, sizeof(TExeHeader));

        if (ExeHeader.Signature == 0x5A4D)
            ok = TRUE;
    }

    return ok;
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
        memset(FData, 0xFF, FSize);
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
#   Name       : TRdosDevice16BaseObject::IsValid
#
#   Purpose....: Check for valid device file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRdosDevice16BaseObject::IsValid(const char *FileName)
{
    TRdvHeader16 ExeHeader;
    TFile File(FileName);
    int ok = FALSE;

    if (File.IsOpen())
    {
        ExeHeader.Signature = 0;
        File.Read(&ExeHeader, sizeof(TRdvHeader16));

        if (ExeHeader.Signature == 0x3652)
            ok = TRUE;
    }
    return ok;
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
        memset(FData, 0xFF, FSize);
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
#   Name       : TRdosDevice32BaseObject::TRdosDevice32BaseObject
#
#   Purpose....: Constructor for TRdosDevice32BaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDevice32BaseObject::TRdosDevice32BaseObject()
{
}

/*##########################################################################
#
#   Name       : TRdosDevice32BaseObject::TRdosDevice32BaseObject
#
#   Purpose....: Constructor for TRdosDevice32BaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDevice32BaseObject::TRdosDevice32BaseObject(TFile *File, int Size)
 : TRdosObject(File, Size)
{
    FDeviceHeader = (TRdosDevice32Header *)FData;
    FDeviceSize = FSize - FDeviceHeader->Size;
    FDeviceData = FData + FDeviceHeader->Size;
}

#ifdef __RDOS__

/*##########################################################################
#
#   Name       : TRdosDevice32BaseObject::TRdosDevice32BaseObject
#
#   Purpose....: Constructor for TRdosDevice32BaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDevice32BaseObject::TRdosDevice32BaseObject(int adapter, int entry, int size)
  : TRdosObject(adapter, entry, size)
{
    FDeviceHeader = (TRdosDevice32Header *)FData;
    FDeviceSize = FSize - FDeviceHeader->Size;
    FDeviceData = FData + FDeviceHeader->Size;
}

#endif

/*##########################################################################
#
#   Name       : TRdosDevice32BaseObject::~TRdosDevice32BaseObject
#
#   Purpose....: Destructor for TRdosDevice32BaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDevice32BaseObject::~TRdosDevice32BaseObject()
{
}

/*##########################################################################
#
#   Name       : TRdosDevice32BaseObject::IsValid
#
#   Purpose....: Check for valid device file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRdosDevice32BaseObject::IsValid(const char *FileName)
{
    TRdvHeader32 ExeHeader;
    TFile File(FileName);
    int ok = FALSE;

    if (File.IsOpen())
    {
        ExeHeader.Signature = 0;
        File.Read(&ExeHeader, sizeof(TRdvHeader32));

        if (ExeHeader.Signature == 0x3252)
            ok = TRUE;
    }
    return ok;
}

/*##########################################################################
#
#   Name       : TRdosDevice32BaseObject::LoadDeviceFile
#
#   Purpose....: Load device file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRdosDevice32BaseObject::LoadDeviceFile(const char *FileName, const char *Param)
{
    TRdvHeader32 ExeHeader;
    TFile File(FileName);
    int HeaderSize;
    char *ptr;

    if (FData)
        delete FData;
    FData = 0;
    FSize = 0;

    if (File.IsOpen())
    {
        ExeHeader.Signature = 0;
        File.Read(&ExeHeader, sizeof(TRdvHeader32));

        if (ExeHeader.Signature != 0x3252)
            return FALSE;

        HeaderSize = sizeof(TRdosDevice32Header);
        HeaderSize += strlen(FileName);
        HeaderSize += strlen(Param);
        HeaderSize++;

        FDeviceSize = ExeHeader.CodeSize + ExeHeader.DataSize;
        FSize = FDeviceSize + HeaderSize;
        FData = new char[FSize];
        memset(FData, 0xFF, FSize);
        FDeviceHeader = (TRdosDevice32Header *)FData;
        FDeviceData = FData + HeaderSize;

        FDeviceHeader->Size = HeaderSize;
        FDeviceHeader->StartIp = ExeHeader.Eip;
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
#   Name       : TRdosLongModeObject::TRdosLongModeObject
#
#   Purpose....: Constructor for TRdosLongModeObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosLongModeObject::TRdosLongModeObject(const char *FileName)
{
    if (LoadFile(FileName))
        FType = RDOS_OBJECT_LONG_MODE;
}

/*##########################################################################
#
#   Name       : TRdosLongModeObject::TRdosLongModeObject
#
#   Purpose....: Constructor for TRdosLongModeObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosLongModeObject::TRdosLongModeObject(TFile *File, int Size)
 : TRdosObject(File, Size)
{
    FDeviceHeader = (TRdosLongModeHeader *)FData;
    FDeviceSize = FSize - FDeviceHeader->Size;
    FDeviceData = FData + FDeviceHeader->Size;
    FType = RDOS_OBJECT_LONG_MODE;
}

#ifdef __RDOS__

/*##########################################################################
#
#   Name       : TRdosLongModeObject::TRdosLongModeObject
#
#   Purpose....: Constructor for TRdosLongModeObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosLongModeObject::TRdosLongModeObject(int adapter, int entry, int size)
  : TRdosObject(adapter, entry, size)
{
    FDeviceHeader = (TRdosLongModeHeader *)FData;
    FDeviceSize = FSize - FDeviceHeader->Size;
    FDeviceData = FData + FDeviceHeader->Size;
    FType = RDOS_OBJECT_LONG_MODE;
}

#endif

/*##########################################################################
#
#   Name       : TRdosLongModeObject::~TRdosLongModeObject
#
#   Purpose....: Destructor for TRdosLongModeObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosLongModeObject::~TRdosLongModeObject()
{
}

/*##########################################################################
#
#   Name       : TRdosLongModeObject::LoadFile
#
#   Purpose....: Load file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRdosLongModeObject::LoadFile(const char *FileName)
{
    TBinLongModeHeader ExeHeader;
    TFile File(FileName);
    int HeaderSize;
    char *ptr;
    long pos;

    if (FData)
        delete FData;
    FData = 0;
    FSize = 0;

    if (File.IsOpen())
    {
        ExeHeader.Signature = 0;
        File.Read(&ExeHeader, sizeof(TBinLongModeHeader));

        if (ExeHeader.Signature != 0x6452)
            return FALSE;

        HeaderSize = sizeof(TRdosLongModeHeader);
        HeaderSize += strlen(FileName);
        HeaderSize++;

        pos = ExeHeader.ImageBase;
        File.SetPos(pos);

        FDeviceSize = (int)File.GetSize() - pos;
        FSize = FDeviceSize + HeaderSize;
        FData = new char[FSize];
        memset(FData, 0xFF, FSize);
        FDeviceHeader = (TRdosLongModeHeader *)FData;
        FDeviceData = FData + HeaderSize;

        FDeviceHeader->Size = HeaderSize;
        FDeviceHeader->StartIp = ExeHeader.Eip;
        FDeviceHeader->ImageBase = ExeHeader.ImageBase;
        FDeviceHeader->ImageSize = ExeHeader.ImageSize;
        FDeviceHeader->IdtBase = ExeHeader.IdtBase;

        ptr = &FDeviceHeader->NameParam;
        strcpy(ptr, FileName);

        File.Read(FDeviceData, FDeviceSize);

        return TRUE;
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TRdosLongModeObject::GetInfo
#
#   Purpose....: Get printable object info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TRdosLongModeObject::GetInfo()
{
    char str[256];
    char *ptr;

    strcpy(str, "LongMode ");

    ptr = &FDeviceHeader->NameParam;
    strcat(str, ptr);

    return TString(str);
}

/*##########################################################################
#
#   Name       : TRdosRealTimeObject::TRdosRealTimeObject
#
#   Purpose....: Constructor for TRdosRealTimeObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosRealTimeObject::TRdosRealTimeObject(const char *FileName)
{
    if (LoadFile(FileName))
        FType = RDOS_OBJECT_REAL_TIME;
}

/*##########################################################################
#
#   Name       : TRdosRealTimeObject::TRdosRealTimeObject
#
#   Purpose....: Constructor for TRdosRealTimeObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosRealTimeObject::TRdosRealTimeObject(TFile *File, int Size)
 : TRdosObject(File, Size)
{
    FDeviceHeader = (TRdosRealTimeHeader *)FData;
    FDeviceSize = FSize - FDeviceHeader->Size;
    FDeviceData = FData + FDeviceHeader->Size;
    FType = RDOS_OBJECT_REAL_TIME;
}

#ifdef __RDOS__

/*##########################################################################
#
#   Name       : TRdosRealTimeObject::TRdosRealTimeObject
#
#   Purpose....: Constructor for TRdosRealTimeObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosRealTimeObject::TRdosRealTimeObject(int adapter, int entry, int size)
  : TRdosObject(adapter, entry, size)
{
    FDeviceHeader = (TRdosRealTimeHeader *)FData;
    FDeviceSize = FSize - FDeviceHeader->Size;
    FDeviceData = FData + FDeviceHeader->Size;
    FType = RDOS_OBJECT_REAL_TIME;
}

#endif

/*##########################################################################
#
#   Name       : TRdosRealTimeObject::~TRdosRealTimeObject
#
#   Purpose....: Destructor for TRdosRealTimeObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosRealTimeObject::~TRdosRealTimeObject()
{
}

/*##########################################################################
#
#   Name       : TRdosRealTimeObject::LoadFile
#
#   Purpose....: Load file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRdosRealTimeObject::LoadFile(const char *FileName)
{
    TBinRealTimeHeader ExeHeader;
    TFile File(FileName);
    int HeaderSize;

    if (FData)
        delete FData;
    FData = 0;
    FSize = 0;

    if (File.IsOpen())
    {
        ExeHeader.Signature = 0;
        File.Read(&ExeHeader, sizeof(TBinRealTimeHeader));

        if (ExeHeader.Signature != 0x657A)
            return FALSE;

        HeaderSize = sizeof(TRdosRealTimeHeader);

        FDeviceSize = (int)File.GetSize();
        FSize = FDeviceSize + HeaderSize;
        FData = new char[FSize];
        memset(FData, 0xFF, FSize);
        FDeviceHeader = (TRdosRealTimeHeader *)FData;
        FDeviceData = FData + HeaderSize;

        FDeviceHeader->Size = FDeviceSize;

        File.SetPos(0);
        File.Read(FDeviceData, FDeviceSize);

        return TRUE;
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TRdosRealTimeObject::GetInfo
#
#   Purpose....: Get printable object info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TRdosRealTimeObject::GetInfo()
{
    char str[256];

    strcpy(str, "RealTime");

    return TString(str);
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
#   Name       : TRdosDevice32Object::TRdosDevice32Object
#
#   Purpose....: Constructor for TRdosDevice32Object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDevice32Object::TRdosDevice32Object(const char *DeviceFileName, const char *Param)
{
    if (LoadDeviceFile(DeviceFileName, Param))
        FType = RDOS_OBJECT_DEVICE32;
}

/*##########################################################################
#
#   Name       : TRdosDevice32Object::TRdosDevice32Object
#
#   Purpose....: Constructor for TRdosDevice32Object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDevice32Object::TRdosDevice32Object(TFile *File, int Size)
 : TRdosDevice32BaseObject(File, Size)
{
    FType = RDOS_OBJECT_DEVICE32;
}

#ifdef __RDOS__

/*##########################################################################
#
#   Name       : TRdosDevice32Object::TRdosDevice32Object
#
#   Purpose....: Constructor for TRdosDevice32Object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDevice32Object::TRdosDevice32Object(int adapter, int entry, int size)
  : TRdosDevice32BaseObject(adapter, entry, size)
{
    FType = RDOS_OBJECT_DEVICE32;
}

#endif

/*##########################################################################
#
#   Name       : TRdosDevice32Object::~TRdosDevice32Object
#
#   Purpose....: Destructor for TRdosDevice32Object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDevice32Object::~TRdosDevice32Object()
{
}

/*##########################################################################
#
#   Name       : TRdosDevice32Object::GetInfo
#
#   Purpose....: Get printable object info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TRdosDevice32Object::GetInfo()
{
    char str[256];
    char *ptr;

    strcpy(str, "Device32 ");

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
        FFileSize = (int)File.GetSize();
        FSize = FFileSize + sizeof(TRdosOldFileHeader);
        FData = new char[FSize];
        memset(FData, 0xFF, FSize);
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
        FFileHeader->Size = (int)File.GetSize();

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

        FFileSize = (int)File.GetSize();
        FSize = FFileSize + HeaderSize;
        FData = new char[FSize];
        memset(FData, 0xFF, FSize);
        FFileHeader = (TRdosFileHeader *)FData;
        FFileData = FData + HeaderSize;

        strcpy(&FFileHeader->FileName, ptr);

        FFileHeader->Size = HeaderSize;
        FFileHeader->Attrib = 0;
        FFileHeader->FileSize = (int)File.GetSize();

        time = File.GetTime();
        FFileHeader->LsbTime = time.GetLsb();
        FFileHeader->MsbTime = time.GetMsb();

        File.Read(FFileData, FFileSize);
    }
}

/*##########################################################################
#
#   Name       : TRdosServerObject::TRdosServerObject
#
#   Purpose....: Constructor for TRdosServerObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosServerObject::TRdosServerObject(const char *FileName)
{
    FType = RDOS_OBJECT_SERVER;

    LoadFileAndHeader(FileName);
}

/*##########################################################################
#
#   Name       : TRdosServerObject::TRdosServerObject
#
#   Purpose....: Constructor for TRdosServerObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosServerObject::TRdosServerObject(TFile *File, int Size)
 : TRdosObject(File, Size)
{
    FServerHeader = (TRdosServerHeader *)FData;
    FFileSize = FSize - FServerHeader->Size;
    FFileData = FData + FServerHeader->Size;
    FType = RDOS_OBJECT_SERVER;
}

#ifdef __RDOS__

/*##########################################################################
#
#   Name       : TRdosServerObject::TRdosServerObject
#
#   Purpose....: Constructor for TRdosServerObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosServerObject::TRdosServerObject(int adapter, int entry, int size)
  : TRdosObject(adapter, entry, size)
{
    FServerHeader = (TRdosServerHeader *)FData;
    FFileSize = FSize - FServerHeader->Size;
    FFileData = FData + FServerHeader->Size;
    FType = RDOS_OBJECT_SERVER;
}

#endif

/*##########################################################################
#
#   Name       : TRdosServerObject::~TRdosServerObject
#
#   Purpose....: Destructor for TRdosServerObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosServerObject::~TRdosServerObject()
{
}

/*##########################################################################
#
#   Name       : TRdosServerObject::GetInfo
#
#   Purpose....: Get printable object info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TRdosServerObject::GetInfo()
{
    char str[256];
    char *ptr;

    strcpy(str, "Server ");

    ptr = &FServerHeader->FileName;
    strcat(str, ptr);

    return TString(str);
}

/*##########################################################################
#
#   Name       : TRdosServerObject::LoadFileAndHeader
#
#   Purpose....: Load header and file contents
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosServerObject::LoadFileAndHeader(const char *FileName)
{
    TFile File(FileName);
    const char *ptr;
    int HeaderSize;
    TDateTime time;
    char Name[128];
    char *exeptr;

    ptr = FileName + strlen(FileName) - 1;

    while (ptr != FileName && *ptr != '\\' && *ptr != '/')
        ptr--;

    if (*ptr == '\\' || *ptr == '/')
        ptr++;

    strcpy(Name, ptr);
    exeptr = strstr(Name, ".exe");
    if (exeptr)
        *exeptr = 0;

    if (File.IsOpen() && exeptr)
    {
        HeaderSize = sizeof(TRdosServerHeader);
        HeaderSize += strlen(Name);

        FFileSize = (int)File.GetSize();
        FSize = FFileSize + HeaderSize;
        FData = new char[FSize];
        memset(FData, 0xFF, FSize);
        FServerHeader = (TRdosServerHeader *)FData;
        FFileData = FData + HeaderSize;

        strcpy(&FServerHeader->FileName, Name);

        FServerHeader->Size = HeaderSize;
        FServerHeader->FileSize = (int)File.GetSize();

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
#   Name       : TRdosSetObject::IsSetting
#
#   Purpose....: Check for setting
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TRdosSetObject::IsSetting(const char *var)
{
    char str[256];
    char *ptr;

    strcpy(str, FData);
    ptr = strchr(str, '=');
    if (ptr)
    {
        *ptr = 0;
        if (!strcmp(str, var))
            return true;
        else
            return false;
    }
    else
        return false;
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
    bool check = false;
    bool skip = false;

    switch (obj->GetType())
    {
        case RDOS_OBJECT_KERNEL:
        case RDOS_OBJECT_SHUTDOWN:
        case RDOS_OBJECT_DEVICE16:
        case RDOS_OBJECT_DEVICE32:
        case RDOS_OBJECT_LONG_MODE:
        case RDOS_OBJECT_REAL_TIME:
            check = true;
            break;
    }

    if (check)
    {
        p = FObjectList;

        while (p && !skip)
        {
            if (p->GetType() == obj->GetType())
                if (p->GetInfo() == obj->GetInfo())
                    skip = true;

            p = p->FLink;
        }
    }

    if (skip)
        delete obj;
    else
    {
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

                    case RDOS_OBJECT_LONG_MODE:
                        obj = new TRdosLongModeObject(&File, size);
                        break;

                    case RDOS_OBJECT_REAL_TIME:
                        obj = new TRdosRealTimeObject(&File, size);
                        break;

                    case RDOS_OBJECT_FONT:
                        obj = new TRdosFontObject(&File, size);
                        break;

                    case RDOS_OBJECT_DEVICE16:
                        obj = new TRdosDevice16Object(&File, size);
                        break;

                    case RDOS_OBJECT_DEVICE32:
                        obj = new TRdosDevice32Object(&File, size);
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

                    case RDOS_OBJECT_SERVER:
                        obj = new TRdosServerObject(&File, size);
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

                        case RDOS_OBJECT_LONG_MODE:
                            obj = new TRdosLongModeObject(adapter, entry, size);
                            break;

                        case RDOS_OBJECT_REAL_TIME:
                            obj = new TRdosRealTimeObject(adapter, entry, size);
                            break;

                        case RDOS_OBJECT_FONT:
                            obj = new TRdosFontObject(adapter, entry, size);
                            break;

                        case RDOS_OBJECT_DEVICE16:
                            obj = new TRdosDevice16Object(adapter, entry, size);
                            break;

                        case RDOS_OBJECT_DEVICE32:
                            obj = new TRdosDevice32Object(adapter, entry, size);
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

                        case RDOS_OBJECT_SERVER:
                            obj = new TRdosServerObject(adapter, entry, size);
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
    char fullname[_MAX_PATH];
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

    if (!strcmp(cmd, "longmode"))
        obj = new TRdosLongModeObject(file);

    if (!strcmp(cmd, "realtime"))
        obj = new TRdosRealTimeObject(file);

    if (!strcmp(cmd, "font"))
        obj = new TRdosFontObject(file);

    if (!strcmp(cmd, "device"))
    {
        _fullpath(fullname, file, _MAX_PATH);

        if (TRdosDosDeviceBaseObject::IsValid(fullname))
            obj = new TRdosDosDeviceObject(fullname, ptr);
        else if (TRdosDevice16BaseObject::IsValid(fullname))
            obj = new TRdosDevice16Object(fullname, ptr);
        else if (TRdosDevice32BaseObject::IsValid(fullname))
            obj = new TRdosDevice32Object(fullname, ptr);
    }

    if (!strcmp(cmd, "shutdown"))
        obj = new TRdosShutdownObject(file);

    if (!strcmp(cmd, "file"))
        obj = new TRdosFileObject(file);

    if (!strcmp(cmd, "server"))
        obj = new TRdosServerObject(file);

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

/*##########################################################################
#
#   Name       : TRdosImage::IsIdentical
#
#   Purpose....: Check if another image is identical (by comparing CRCs)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRdosImage::IsIdentical(TRdosImage &img)
{
    TRdosObject *obj1;
    TRdosObject *obj2;
    unsigned short int crc1;
    unsigned short int crc2;

    obj1 = FObjectList;
    obj2 = img.FObjectList;

    while (obj1 && obj2)
    {
        crc1 = obj1->CalcCrc(&FCrc);
        crc2 = obj2->CalcCrc(&img.FCrc);

        if (crc1 != crc2)
            return FALSE;

        obj1 = obj1->FLink;
        obj2 = obj2->FLink;
    }

    if (obj1 == 0 && obj2 == 0)
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TRdosImage::HasKernel
#
#   Purpose....: Check if image has kernel
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRdosImage::HasKernel()
{
    TRdosObject *obj;

    obj = FObjectList;

    while (obj)
    {
        if (obj->GetType() == RDOS_OBJECT_KERNEL)
            return TRUE;

        obj = obj->FLink;
    }

    return FALSE;
}

/*##########################################################################
#
#   Name       : TRdosImage::HasShutdown
#
#   Purpose....: Check if image has shutdown
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRdosImage::HasShutdown()
{
    TRdosObject *obj;

    obj = FObjectList;

    while (obj)
    {
        if (obj->GetType() == RDOS_OBJECT_SHUTDOWN)
            return TRUE;

        obj = obj->FLink;
    }

    return FALSE;
}

/*##########################################################################
#
#   Name       : TRdosImage::HasDevice
#
#   Purpose....: Check if image has a specific device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TRdosImage::HasDevice(const char *name)
{
    int Type;
    const char *devname;
    TRdosObject *obj;
    const char *matchstr;

    obj = FObjectList;

    while (obj)
    {
        Type = obj->GetType();
        switch (Type)
        {
            case RDOS_OBJECT_DEVICE16:
            case RDOS_OBJECT_DEVICE32:
                devname = obj->GetInfo().GetData();
                matchstr = strstr(devname, name);
                if (matchstr)
                {
                    if (matchstr == devname)
                        return TRUE;

                    switch (*(matchstr - 1))
                    {
                        case ':':
                        case '\\':
                        case '/':
                        case ' ':
                            return TRUE;
                    }
                }
                break;
        }

        obj = obj->FLink;
    }

    return FALSE;
}

/*##########################################################################
#
#   Name       : TRdosImage::UpdateSetting
#
#   Purpose....: Update setting
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TRdosImage::UpdateSetting(const char *name, const char *value)
{
    int Type;
    TRdosObject *obj;
    TRdosSetObject *setting;
    bool remove = false;
    char str[80];

    obj = FObjectList;

    while (obj && !remove)
    {
        Type = obj->GetType();
        switch (Type)
        {
            case RDOS_OBJECT_SET:
                setting = (TRdosSetObject *)obj;
                if (setting->IsSetting(name))
                    remove = true;
        }

        if (remove)
            Remove(obj);
        else
            obj = obj->FLink;
    }

    strcpy(str, name);
    strcat(str, "=");
    strcat(str, value);

    obj = new TRdosSetObject(str);
    Add(obj);
}
