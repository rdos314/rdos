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
# discpart.h
# Dispart base class
#
########################################################################*/

#ifndef _DISCPART_H
#define _DISCPART_H

#include "parttype.h"
#include "discint.h"

class TDisc;

class TPartition
{
public:
    TPartition(long long StartSector, long long SectorCount);
    virtual ~TPartition();

    void SetType(int PartType);
    int GetType();

    char GetDrive();

    long long GetStartSector();
    long long GetSectorCount();

    bool CheckInside(long long sector, int count);

    int Handle;

protected:
    int FPartType;

    long long FStartSector;
    long long FSectorCount;
};

class TDisc
{
public:
    TDisc(TDiscServer *server);
    virtual ~TDisc();

    virtual long long GetSectorCount();
    virtual const char *FsTypeToName(int type);
    virtual int FsNameToType(const char *FsName);

    virtual bool InitPart() = 0;
    virtual bool LoadPart();
    virtual void Stop();
    virtual bool AddPart(const char *FsName, long long Sectors) = 0;

    TDiscServer *GetServer();
    int GetDiscNr();

    long long GetCached();
    long long GetLocked();

    void Add(TPartition *part);
    void Remove(TPartition *part);

    virtual bool IsGpt() = 0;

    int ReadSector(long long, char *buf, int size);
    int WriteSector(long long, char *buf, int size);

    int FBytesPerSector;
    long long FSectorCount;

    TPartition **FPartArr;
    int FCurrPartCount;
    int FMaxPartCount;

protected:
    void Sort();
    long long AllocateSectors(long long Start, long long Count);
    int FormatPart(const char *FsName, long long *Start, long long *Count, int *Type);

    virtual bool CreatePart(int Handle, int Type, long long Start, long long Sectors) = 0;

    void GrowPart();
    virtual void DeletePart(TPartition *part);
  
    int SizeToCount(int size);
    bool IsInsidePartition(long long sector, int count);

    bool FStopped;
    TDiscServer *FServer;
};

#endif

