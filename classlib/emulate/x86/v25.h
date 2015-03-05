/*###########################################################################
* Em486 CPU emulator
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
* V25.H
* V25 emulation class
*
*##########################################################################*/

#ifndef	_V25_H
#define _V25_H

#include "cpu.h"

class TV25Int : public TInterrupt
{
public:
    TV25Int(TBus *Bus);

    virtual int GetSize();

    virtual void Set(int Number);
    virtual void Reset(int Number);
    virtual void Edge(int Number);
    virtual char Ack();

    void Enable(int Number);
    void Disable(int Number);
    void Eoi();

    void DefineCpu(TCpu *Cpu);

protected:
    int GetIrr();
    int GetIsr();
    void Update();

    TCpu *FCpu;
    int FIrr;
    int FImr;
    int FIsr;
    int FEdge;

private:
};

class TV25Cpu : public TCpu
{
public:
	TV25Cpu();
	~TV25Cpu();

	virtual void Reset();
    virtual void DefineBus(TBus *Bus);

    virtual char ReadMemoryByte(unsigned long long Address);
    virtual short int ReadMemoryWord(unsigned long long Address);
    virtual long ReadMemoryDword(unsigned long long Address);
    virtual long long ReadMemoryQword(unsigned long long Address);

    virtual void WriteMemoryByte(unsigned long long Address, char val);
    virtual void WriteMemoryWord(unsigned long long Address, short int val);
    virtual void WriteMemoryDword(unsigned long long Address, long val);
    virtual void WriteMemoryQword(unsigned long long Address, long long val);

    virtual char ReadIoByte(unsigned short int Port);
    virtual short int ReadIoWord(unsigned short int Port);

    virtual void WriteIoByte(unsigned short int Port, char val);
    virtual void WriteIoWord(unsigned short int Port, short int val);

    virtual void Fint();

    virtual void UpdateTime(int ns);

    char (*OnReadP0)(TV25Cpu *Cpu);
    void (*OnWriteP0)(TV25Cpu *Cpu, char val, char mask);

    char (*OnReadP1)(TV25Cpu *Cpu);
    void (*OnWriteP1)(TV25Cpu *Cpu, char val, char mask);

    char (*OnReadP2)(TV25Cpu *Cpu);
    void (*OnWriteP2)(TV25Cpu *Cpu, char val, char mask);

    char (*OnReadPT)(TV25Cpu *Cpu);

protected:
    char ReadIdbByte(int offset);
    short int ReadIdbWord(int offset);

    void SetTmc1(char val);
    void SetTmic0(char val);
    void SetTmic1(char val);
    void SetTmic2(char val);
    void NotifyTm1();
    void DecTm1();

    void WriteIdbByte(int offset, char val);
    void WriteIdbWord(int offset, short int val);

    char FIdb[0x100];
    TBus *FBus;
    TV25Int *FInt;

    int FNs;
};

#endif
