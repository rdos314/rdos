/*###########################################################################
* RDOS operating system
* Copyright (C) 1998-2000, Leif Ekblad
*
* This program is free software; you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation; either version 2 of the License, or
* (at your option) any later version. The only exception to this rule
* is for commercial usage. For information on commercial usage,
* contact em486@rdos.net.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*
* The author of this program may be contacted at leif@rdos.net
*
* BUS.H
* Bus emulation
*
*##########################################################################*/

#ifndef _BUS_H
#define _BUS_H

class TBus;

class TBusAreaData
{
public:
    unsigned long Base;
    unsigned long Size;
    char *Data;
};

class TBusFunction
{
public:
    TBusFunction(TBus *Bus);

    virtual int GetSize() = 0;

    virtual void Out(int Num, int Offset, char Value);

    virtual char ReadMemoryByte(int Num, unsigned long Offset);
    virtual short int ReadMemoryWord(int Num, unsigned long Offset);
    virtual long ReadMemoryDword(int Num, unsigned long Offset);
    virtual long long ReadMemoryQword(int Num, unsigned long Offset);

    virtual void WriteMemoryByte(int Num, unsigned long Offset, char val);
    virtual void WriteMemoryWord(int Num, unsigned long Offset, short int val);
    virtual void WriteMemoryDword(int Num, unsigned long Offset, long val);
    virtual void WriteMemoryQword(int Num, unsigned long Offset, long long val);

    virtual char InByte(int Num, int Offset);
    virtual short int InWord(int Num, int Offset);
    virtual long InDword(int Num, int Offset);

protected:
    void DefineIo(int Num, int Base, int Size, char *Data);
    void UndefineIo(int Num);
    void DefineMem(int Num, unsigned long long Base, unsigned long Size, char *Data);
    void UndefineMem(int Num);

    TBus *FBus;
    TBusAreaData *FIoArr[256];
    TBusAreaData *FMemArr[256];
    
};

class TBusArea
{
public:
    unsigned long long Base;
    unsigned long Size;
    TBusFunction *func;
    int Num;
};

class TBus
{
public:
    TBus();
    ~TBus();

    void Out(int Port, char Value);

    char ReadMemoryByte(unsigned long long Address);
    short int ReadMemoryWord(unsigned long long Address);
    long ReadMemoryDword(unsigned long long Address);
    long long ReadMemoryQword(unsigned long long Address);

    void WriteMemoryByte(unsigned long long Address, char val);
    void WriteMemoryWord(unsigned long long Address, short int val);
    void WriteMemoryDword(unsigned long long Address, long val);
    void WriteMemoryQword(unsigned long long Address, long long val);

    char InByte(int Port);
    short int InWord(int Port);
    long InDword(int Port);

    void DefineIo(TBusFunction *func, int Num, int Base, int Size);
    void UndefineIo(TBusFunction *func, int Num);
    void DefineMem(TBusFunction *func, int Num, unsigned long long Base, unsigned long Size);
    void UndefineMem(TBusFunction *func, int Num);
                
private:
    int FHookIoMax;
    int FHookMemMax;
    TBusArea *FHookIoArr[256];
    TBusArea *FHookMemArr[256];
            
};

#endif
