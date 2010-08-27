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

#define RDOS_OBJECT_KERNEL      0
#define RDOS_OBJECT_FONT        1
#define RDOS_OBJECT_DEVICE      2
#define RDOS_OBJECT_SHUTDOWN    3
#define RDOS_OBJECT_FILE        6
#define RDOS_OBJECT_COMMAND     7
#define RDOS_OBJECT_SET         8
#define RDOS_OBJECT_PATH        9

struct TRdosObjectHeader
{
    long sign;
    long len;
    short int type;
    short int crc;    
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
    virtual ~TRdosKernelObject();
};
    
class TRdosFontObject : public TRdosObject
{
public:
    TRdosFontObject(const char *FontFileName);
    virtual ~TRdosFontObject();
};
    
class TRdosDeviceObject : public TRdosDeviceBaseObject
{
public:
    TRdosDeviceObject(const char *DeviceFileName);
    virtual ~TRdosDeviceObject();
};
    
class TRdosShutdownObject : public TRdosDeviceBaseObject
{
public:
    TRdosShutdownObject(const char *ShutdownFileName);
    virtual ~TRdosShutdownObject();
};
    
class TRdosFileObject : public TRdosObject
{
public:
    TRdosFileObject(const char *FileName);
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
    virtual ~TRdosCommandObject();
};
    
class TRdosSetObject : public TRdosObject
{
public:
    TRdosSetObject(const char *Param);
    virtual ~TRdosSetObject();
};
    
class TRdosPathObject : public TRdosObject
{
public:
    TRdosPathObject(const char *Param);
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
};

#endif
