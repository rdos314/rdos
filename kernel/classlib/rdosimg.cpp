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
#   Name       : TRdosDeviceBaseObject::TRdosDeviceBaseObject
#
#   Purpose....: Constructor for TRdosDeviceBaseObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDeviceBaseObject::TRdosDeviceBaseObject(TFile *File, int Size)
 : TRdosObject(File, Size)
{
    FDeviceSize = FSize - sizeof(TRdosDeviceHeader);
    FDeviceHeader = (TRdosDeviceHeader *)FData;
    FDeviceData = FData + sizeof(TRdosDeviceHeader);    
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

        HeaderSize = ExeHeader.HeaderSize << 4;        
        File.SetPos(HeaderSize);
        
        Size = ExeHeader.MsbSize << 5;
        Size += (ExeHeader.LsbSize >> 4) + 1;
        Size -= ExeHeader.HeaderSize;
        Size += ExeHeader.MinAlloc;

        FDeviceSize = Size << 4;
        FSize = FDeviceSize + sizeof(TRdosDeviceHeader);
        FData = new char[FSize];
        FDeviceHeader = (TRdosDeviceHeader *)FData;
        FDeviceData = FData + sizeof(TRdosDeviceHeader);

        FDeviceHeader->StartIp = ExeHeader.Ip;

        File.Read(FDeviceData, FDeviceSize);
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
 : TRdosDeviceBaseObject(File, Size)
{
    FType = RDOS_OBJECT_KERNEL;
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
#   Name       : TRdosDeviceObject::TRdosDeviceObject
#
#   Purpose....: Constructor for TRdosDeviceObject
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TRdosDeviceObject::TRdosDeviceObject(TFile *File, int Size)
 : TRdosDeviceBaseObject(File, Size)
{
    FType = RDOS_OBJECT_DEVICE;
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
#   Name       : TRdosDeviceObject::GetInfo
#
#   Purpose....: Get printable object info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TRdosDeviceObject::GetInfo()
{
    return TString("Device");
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
 : TRdosDeviceBaseObject(File, Size)
{
    FType = RDOS_OBJECT_SHUTDOWN;
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
    FFileSize = FSize - sizeof(TRdosFileHeader);
    FFileHeader = (TRdosFileHeader *)FData;
    FFileData = FData + sizeof(TRdosFileHeader);    
    FType = RDOS_OBJECT_FILE;
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
    int i;
    const char *ptr;

    if (File.IsOpen())
    {
        FFileSize = File.GetSize();
        FSize = FFileSize + sizeof(TRdosFileHeader);
        FData = new char[FSize];
        FFileHeader = (TRdosFileHeader *)FData;
        FFileData = FData + sizeof(TRdosFileHeader);
                    
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

                    case RDOS_OBJECT_DEVICE:
                        obj = new TRdosDeviceObject(&File, size);
                        break;

                    case RDOS_OBJECT_SHUTDOWN:
                        obj = new TRdosShutdownObject(&File, size);
                        break;

                    case RDOS_OBJECT_FILE:
                        obj = new TRdosFileObject(&File, size);
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
    TRdosObject *obj = 0;
    
    if (!strcmp(cmd, "kernel"))
        obj = new TRdosKernelObject(param);
    
    if (!strcmp(cmd, "font"))
        obj = new TRdosFontObject(param);
    
    if (!strcmp(cmd, "device"))
        obj = new TRdosDeviceObject(param);
    
    if (!strcmp(cmd, "shutdown"))
        obj = new TRdosShutdownObject(param);
    
    if (!strcmp(cmd, "file"))
        obj = new TRdosFileObject(param);
    
    if (!strcmp(cmd, "run"))
        obj = new TRdosCommandObject(param);
    
    if (!strcmp(cmd, "set"))
        obj = new TRdosSetObject(param);
    
    if (!strcmp(cmd, "path"))
        obj = new TRdosPathObject(param);

    if (obj)
        Add(obj);        
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
    TRdosObject *obj;

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
