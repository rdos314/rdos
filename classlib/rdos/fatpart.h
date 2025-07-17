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
# fatpart.h
# FAT partition class
#
########################################################################*/

#ifndef _FATPART_H
#define _FATPART_H

#include "idepart.h"

class TIdeFatPartition : public TIdeFsPartition
{
public:
        TIdeFatPartition(TDisc *Disc, unsigned char Type, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        virtual ~TIdeFatPartition();        

protected:
    void WriteBootSector(const char *BootCode, int BootSize);
};

class TIdeFat12Partition : public TIdeFatPartition
{
public:
        TIdeFat12Partition(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        virtual ~TIdeFat12Partition();        
        virtual const char *GetPartName();
        virtual int Format(const char *BootCode, int BootSize);
};

class TIdeFat16Partition : public TIdeFatPartition
{
public:
        TIdeFat16Partition(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        virtual ~TIdeFat16Partition();        
        virtual const char *GetPartName();
        virtual int Format(const char *BootCode, int BootSize);
};

class TIdeFat32Partition : public TIdeFatPartition
{
public:
        TIdeFat32Partition(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        virtual ~TIdeFat32Partition();        
        virtual const char *GetPartName();
        virtual int Format(const char *BootCode, int BootSize);
};

class TIdeFat12PartitionFactory : public TIdeFsPartitionFactory
{
public:
        TIdeFat12PartitionFactory();
        virtual ~TIdeFat12PartitionFactory();

protected:
        virtual TIdeFsPartition *Open(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        virtual TIdeFsPartition *Create(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size, const char *BootCode, int BootSize);
};

class TIdeFat16PartitionFactory : public TIdeFsPartitionFactory
{
public:
        TIdeFat16PartitionFactory();
        virtual ~TIdeFat16PartitionFactory();

protected:
        virtual TIdeFsPartition *Open(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        virtual TIdeFsPartition *Create(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size, const char *BootCode, int BootSize);
};

class TIdeFat32PartitionFactory : public TIdeFsPartitionFactory
{
public:
        TIdeFat32PartitionFactory();
        virtual ~TIdeFat32PartitionFactory();

protected:
        virtual TIdeFsPartition *Open(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size);
        virtual TIdeFsPartition *Create(TDisc *Disc, TIdePartitionTable *Parent, int Entry, long Start, long Size, const char *BootCode, int BootSize);
};

#endif

