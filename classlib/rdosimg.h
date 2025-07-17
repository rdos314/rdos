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
    const char *GetData();
    short int GetType();

    virtual TString GetInfo() = 0;
    virtual void WriteObject(TFile *File);

    TRdosObject *FLink;
    int FImageOffset;

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

    static int IsValid(const char *FileName);

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

    static int IsValid(const char *FileName);

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

    static int IsValid(const char *FileName);

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

    static int IsValid(const char *FileName);

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

class TRdosLongModeObject : public TRdosObject
{
public:
    TRdosLongModeObject(const char *FileName);
    TRdosLongModeObject(TFile *File, int Size);

#ifdef __RDOS__
    TRdosLongModeObject(int adapter, int entry, int size);
#endif

    virtual ~TRdosLongModeObject();

    virtual TString GetInfo();

protected:
    int LoadFile(const char *FileName);

    TRdosLongModeHeader *FDeviceHeader;
    char *FDeviceData;
    int FDeviceSize;
};

class TRdosRealTimeObject : public TRdosObject
{
public:
    TRdosRealTimeObject(const char *FileName);
    TRdosRealTimeObject(TFile *File, int Size);

#ifdef __RDOS__
    TRdosRealTimeObject(int adapter, int entry, int size);
#endif

    virtual ~TRdosRealTimeObject();

    virtual TString GetInfo();

protected:
    int LoadFile(const char *FileName);

    TRdosRealTimeHeader *FDeviceHeader;
    char *FDeviceData;
    int FDeviceSize;
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

class TRdosServerObject : public TRdosObject
{
public:
    TRdosServerObject(const char *FileName);
    TRdosServerObject(TFile *File, int Size);

#ifdef __RDOS__
    TRdosServerObject(int adapter, int entry, int size);
#endif

    virtual ~TRdosServerObject();

    virtual TString GetInfo();

protected:
    void LoadFileAndHeader(const char *FileName);

    TRdosServerHeader *FServerHeader;
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

    bool IsSetting(const char *var);

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

    int IsIdentical(TRdosImage &img);
    int HasKernel();
    int HasShutdown();
    int HasDevice(const char *name);

    void UpdateSetting(const char *name, const char *value);

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
