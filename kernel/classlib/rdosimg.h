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
# rdosimg.h
# Rdos image creator / manipulator
#
########################################################################*/

#ifndef _RDOSIMG_H
#define _RDOSIMG_H

#include "file.h"
#include "crc.h"

#define RDOS_OBJECT_KERNEL      0
#define RDOS_OBJECT_FONT        1
#define RDOS_OBJECT_DEVICE      2
#define RDOS_OBJECT_SHUTDOWN    3
#define RDOS_OBJECT_FILE        6
#define RDOS_OBJECT_COMMAND     7
#define RDOS_OBJECT_SET         8
#define RDOS_OBJECT_PATH        9

#define RDOS_SIGN    0x5A1E75D4

struct TRdosObjectHeader
{
    long sign;
    long len;
    short int type;
    unsigned short int crc;    
};

struct TRdosDeviceHeader
{
    short int StartIp;
};

struct TRdosFileHeader
{
    char Base[8];
    char Ext[3];
    char Attrib;
    char Resv[10];
    short int Time;
    short int Date;
    short int Cluster;
    int Size;
};

class TRdosObject 
{
public:
    TRdosObject();
    TRdosObject(TFile *File, int Size);
    virtual ~TRdosObject();

    TRdosObject *FLink;

protected:
    void CreateObject(int size);
    void LoadFile(TFile *File);
    void LoadFile(const char *FileName);

    char *FData;
    int FSize;
    short int FType;
    
};

class TRdosDeviceBaseObject : public TRdosObject
{
public:
    TRdosDeviceBaseObject();
    TRdosDeviceBaseObject(TFile *File, int Size);
    virtual ~TRdosDeviceBaseObject();

protected:
    void LoadDeviceFile(const char *FileName);

    TRdosDeviceHeader *FDeviceHeader;    
    char *FDeviceData;
    int FDeviceSize;
};

    
class TRdosKernelObject : public TRdosDeviceBaseObject
{
public:
    TRdosKernelObject(const char *KernelFileName);
    TRdosKernelObject(TFile *File, int Size);
    virtual ~TRdosKernelObject();
};
    
class TRdosFontObject : public TRdosObject
{
public:
    TRdosFontObject(const char *FontFileName);
    TRdosFontObject(TFile *File, int Size);
    virtual ~TRdosFontObject();
};
    
class TRdosDeviceObject : public TRdosDeviceBaseObject
{
public:
    TRdosDeviceObject(const char *DeviceFileName);
    TRdosDeviceObject(TFile *File, int Size);
    virtual ~TRdosDeviceObject();
};
    
class TRdosShutdownObject : public TRdosDeviceBaseObject
{
public:
    TRdosShutdownObject(const char *ShutdownFileName);
    TRdosShutdownObject(TFile *File, int Size);
    virtual ~TRdosShutdownObject();
};
    
class TRdosFileObject : public TRdosObject
{
public:
    TRdosFileObject(const char *FileName);
    TRdosFileObject(TFile *File, int Size);
    virtual ~TRdosFileObject();

protected:
    void LoadFileAndHeader(const char *FileName);

    TRdosFileHeader *FFileHeader;
    char *FFileData;
    int FFileSize;    
};
    
class TRdosCommandObject : public TRdosObject
{
public:
    TRdosCommandObject(const char *Cmd);
    TRdosCommandObject(TFile *File, int Size);
    virtual ~TRdosCommandObject();
};
    
class TRdosSetObject : public TRdosObject
{
public:
    TRdosSetObject(const char *Param);
    TRdosSetObject(TFile *File, int Size);
    virtual ~TRdosSetObject();
};
    
class TRdosPathObject : public TRdosObject
{
public:
    TRdosPathObject(const char *Param);
    TRdosPathObject(TFile *File, int Size);
    virtual ~TRdosPathObject();
};

class TRdosImage
{
public:
    TRdosImage();
    TRdosImage(const char *ImageFile);
    virtual ~TRdosImage();

    void Clear();
    void Add(const char *ImageFile);

    TRdosObject *FObjectList;

protected:
    void Add(TRdosObject *obj);
    void Remove(TRdosObject *obj);

    TCrc FCrc;
};

#endif
