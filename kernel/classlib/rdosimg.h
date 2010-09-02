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
    virtual ~TRdosSimpleDeviceBaseObject();

protected:
    void LoadDeviceFile(const char *FileName);

    TRdosSimpleDeviceHeader *FDeviceHeader;    
    char *FDeviceData;
    int FDeviceSize;
};

class TRdosDeviceBaseObject : public TRdosObject
{
public:
    TRdosDeviceBaseObject();
    TRdosDeviceBaseObject(TFile *File, int Size);
    virtual ~TRdosDeviceBaseObject();

protected:
    void LoadDeviceFile(const char *FileName, const char *Param);

    TRdosDeviceHeader *FDeviceHeader;    
    char *FDeviceData;
    int FDeviceSize;
};
    
class TRdosKernelObject : public TRdosSimpleDeviceBaseObject
{
public:
    TRdosKernelObject(const char *KernelFileName);
    TRdosKernelObject(TFile *File, int Size);
    virtual ~TRdosKernelObject();

    virtual TString GetInfo();
};
    
class TRdosFontObject : public TRdosObject
{
public:
    TRdosFontObject(const char *FontFileName);
    TRdosFontObject(TFile *File, int Size);
    virtual ~TRdosFontObject();

    virtual TString GetInfo();
};
    
class TRdosSimpleDeviceObject : public TRdosSimpleDeviceBaseObject
{
public:
    TRdosSimpleDeviceObject(const char *DeviceFileName);
    TRdosSimpleDeviceObject(TFile *File, int Size);
    virtual ~TRdosSimpleDeviceObject();

    virtual TString GetInfo();
};
    
class TRdosDeviceObject : public TRdosDeviceBaseObject
{
public:
    TRdosDeviceObject(const char *DeviceFileName);
    TRdosDeviceObject(TFile *File, int Size);
    virtual ~TRdosDeviceObject();

    virtual TString GetInfo();
};
    
class TRdosShutdownObject : public TRdosSimpleDeviceBaseObject
{
public:
    TRdosShutdownObject(const char *ShutdownFileName);
    TRdosShutdownObject(TFile *File, int Size);
    virtual ~TRdosShutdownObject();

    virtual TString GetInfo();
};
    
class TRdosOldFileObject : public TRdosObject
{
public:
    TRdosOldFileObject(const char *FileName);
    TRdosOldFileObject(TFile *File, int Size);
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
    virtual ~TRdosCommandObject();

    virtual TString GetInfo();
};
    
class TRdosSetObject : public TRdosObject
{
public:
    TRdosSetObject(const char *Param);
    TRdosSetObject(TFile *File, int Size);
    virtual ~TRdosSetObject();

    virtual TString GetInfo();
};
    
class TRdosPathObject : public TRdosObject
{
public:
    TRdosPathObject(const char *Param);
    TRdosPathObject(TFile *File, int Size);
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

    void WriteImage(const char *ImageFile);

    TRdosObject *FObjectList;

protected:
    void Add(TRdosObject *obj);
    void Remove(TRdosObject *obj);
    void AddConfigRow(const char *Row);

    TCrc FCrc;
};

#endif
