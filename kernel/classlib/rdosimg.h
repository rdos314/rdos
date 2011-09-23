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

#include "rdoshdr.h"
#include "file.h"
#include "crc.h"
#include "str.h"

class TRdosObject 
{
public:
    TRdosObject();
    TRdosObject(TFile *File, int Size);

#ifdef __RDOS__
    TRdosObject(int adapter, int entry, int size);
#endif
    
    virtual ~TRdosObject();

    unsigned short int CalcCrc(TCrc *Crc);
    int GetSize();
    short int GetType();

    virtual TString GetInfo() = 0;
    virtual void WriteObject(TFile *File);

    TRdosObject *FLink;

protected:
    void CreateObject(int size);
    void LoadFile(TFile *File);
    void LoadFile(const char *FileName);

    char *FData;
    int FSize;
    short int FType;
    
};

class TRdosSimpleDeviceBaseObject : public TRdosObject
{
public:
    TRdosSimpleDeviceBaseObject();
    TRdosSimpleDeviceBaseObject(TFile *File, int Size);

#ifdef __RDOS__
    TRdosSimpleDeviceBaseObject(int adapter, int entry, int size);
#endif
    
    virtual ~TRdosSimpleDeviceBaseObject();

protected:
    int LoadDeviceFile(const char *FileName);

    TRdosSimpleDeviceHeader *FDeviceHeader;    
    char *FDeviceData;
    int FDeviceSize;
};

class TRdosDosDeviceBaseObject : public TRdosObject
{
public:
    TRdosDosDeviceBaseObject();
    TRdosDosDeviceBaseObject(TFile *File, int Size);

#ifdef __RDOS__
    TRdosDosDeviceBaseObject(int adapter, int entry, int size);
#endif
    
    virtual ~TRdosDosDeviceBaseObject();

protected:
    int LoadDeviceFile(const char *FileName, const char *Param);

    TRdosDosDeviceHeader *FDeviceHeader;    
    char *FDeviceData;
    int FDeviceSize;
};

class TRdosDevice16BaseObject : public TRdosObject
{
public:
    TRdosDevice16BaseObject();
    TRdosDevice16BaseObject(TFile *File, int Size);

#ifdef __RDOS__
    TRdosDevice16BaseObject(int adapter, int entry, int size);
#endif
    
    virtual ~TRdosDevice16BaseObject();

protected:
    int LoadDeviceFile(const char *FileName, const char *Param);

    TRdosDevice16Header *FDeviceHeader;    
    char *FDeviceData;
    int FDeviceSize;
};

class TRdosDevice32BaseObject : public TRdosObject
{
public:
    TRdosDevice32BaseObject();
    TRdosDevice32BaseObject(TFile *File, int Size);

#ifdef __RDOS__
    TRdosDevice32BaseObject(int adapter, int entry, int size);
#endif
    
    virtual ~TRdosDevice32BaseObject();

protected:
    int LoadDeviceFile(const char *FileName, const char *Param);

    TRdosDevice32Header *FDeviceHeader;    
    char *FDeviceData;
    int FDeviceSize;
};
    
class TRdosKernelObject : public TRdosSimpleDeviceBaseObject
{
public:
    TRdosKernelObject(const char *KernelFileName);
    TRdosKernelObject(TFile *File, int Size);

#ifdef __RDOS__
    TRdosKernelObject(int adapter, int entry, int size);
#endif
    
    virtual ~TRdosKernelObject();

    virtual TString GetInfo();
};
    
class TRdosFontObject : public TRdosObject
{
public:
    TRdosFontObject(const char *FontFileName);
    TRdosFontObject(TFile *File, int Size);

#ifdef __RDOS__
    TRdosFontObject(int adapter, int entry, int size);
#endif
    
    virtual ~TRdosFontObject();

    virtual TString GetInfo();
};
    
class TRdosSimpleDeviceObject : public TRdosSimpleDeviceBaseObject
{
public:
    TRdosSimpleDeviceObject(const char *DeviceFileName);
    TRdosSimpleDeviceObject(TFile *File, int Size);

#ifdef __RDOS__
    TRdosSimpleDeviceObject(int adapter, int entry, int size);
#endif
    
    virtual ~TRdosSimpleDeviceObject();

    virtual TString GetInfo();
};
    
class TRdosDosDeviceObject : public TRdosDosDeviceBaseObject
{
public:
    TRdosDosDeviceObject(const char *DeviceFileName, const char *Param);
    TRdosDosDeviceObject(TFile *File, int Size);

#ifdef __RDOS__
    TRdosDosDeviceObject(int adapter, int entry, int size);
#endif
    
    virtual ~TRdosDosDeviceObject();

    virtual TString GetInfo();
};
    
class TRdosDevice16Object : public TRdosDevice16BaseObject
{
public:
    TRdosDevice16Object(const char *DeviceFileName, const char *Param);
    TRdosDevice16Object(TFile *File, int Size);

#ifdef __RDOS__
    TRdosDevice16Object(int adapter, int entry, int size);
#endif
    
    virtual ~TRdosDevice16Object();

    virtual TString GetInfo();
};
    
class TRdosDevice32Object : public TRdosDevice32BaseObject
{
public:
    TRdosDevice32Object(const char *DeviceFileName, const char *Param);
    TRdosDevice32Object(TFile *File, int Size);

#ifdef __RDOS__
    TRdosDevice32Object(int adapter, int entry, int size);
#endif
    
    virtual ~TRdosDevice32Object();

    virtual TString GetInfo();
};
    
class TRdosShutdownObject : public TRdosSimpleDeviceBaseObject
{
public:
    TRdosShutdownObject(const char *ShutdownFileName);
    TRdosShutdownObject(TFile *File, int Size);

#ifdef __RDOS__
    TRdosShutdownObject(int adapter, int entry, int size);
#endif
    
    virtual ~TRdosShutdownObject();

    virtual TString GetInfo();
};
    
class TRdosOldFileObject : public TRdosObject
{
public:
    TRdosOldFileObject(const char *FileName);
    TRdosOldFileObject(TFile *File, int Size);

#ifdef __RDOS__
    TRdosOldFileObject(int adapter, int entry, int size);
#endif
    
    virtual ~TRdosOldFileObject();

    virtual TString GetInfo();

protected:
    void LoadFileAndHeader(const char *FileName);

    TRdosOldFileHeader *FFileHeader;
    char *FFileData;
    int FFileSize;    
};
    
class TRdosFileObject : public TRdosObject
{
public:
    TRdosFileObject(const char *FileName);
    TRdosFileObject(TFile *File, int Size);

#ifdef __RDOS__
    TRdosFileObject(int adapter, int entry, int size);
#endif
    
    virtual ~TRdosFileObject();

    virtual TString GetInfo();

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

#ifdef __RDOS__
    TRdosCommandObject(int adapter, int entry, int size);
#endif
    
    virtual ~TRdosCommandObject();

    virtual TString GetInfo();
};
    
class TRdosSetObject : public TRdosObject
{
public:
    TRdosSetObject(const char *Param);
    TRdosSetObject(TFile *File, int Size);

#ifdef __RDOS__
    TRdosSetObject(int adapter, int entry, int size);
#endif
    
    virtual ~TRdosSetObject();

    virtual TString GetInfo();
};
    
class TRdosPathObject : public TRdosObject
{
public:
    TRdosPathObject(const char *Param);
    TRdosPathObject(TFile *File, int Size);

#ifdef __RDOS__
    TRdosPathObject(int adapter, int entry, int size);
#endif
    
    virtual ~TRdosPathObject();

    virtual TString GetInfo();
};

class TRdosImage
{
public:
    TRdosImage();
    virtual ~TRdosImage();

    void Clear();
    void AddImage(const char *ImageFile);
    void AddConfig(const char *ConfigFile);
    void AddConfigCmd(const char *cmd, const char *param);

#ifdef __RDOS__
    void AddRunning();
#endif

    void WriteImage(const char *ImageFile);

    TRdosObject *FObjectList;

protected:
    void Add(TRdosObject *obj);
    void Remove(TRdosObject *obj);
    void AddConfigRow(const char *Row);

    TCrc FCrc;
};

#endif
