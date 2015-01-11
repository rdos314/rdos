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
* PCI.H
* PC keyboard emulation
*
*##########################################################################*/

#ifndef _PCI_H
#define _PCI_H

#include "bus.h"

class TPci;

class TPciFunction
{
public:
    TPciFunction(TPci *Pci);
    ~TPciFunction();

    virtual char ReadByteConfig(int Register);
    virtual short int ReadWordConfig(int Register);
    virtual long ReadDwordConfig(int Register);
    
    virtual void WriteByteConfig(int Register, char Data);
    virtual void WriteWordConfig(int Register, short int Data);
    virtual void WriteDwordConfig(int Register, long Data);

    int DefineIoBar(int BarNr, int Size);

protected:
    TPci *FPci;
    char FConfig[256];
};

class TPciDevice
{
public:
    TPciDevice();
    ~TPciDevice();

	void WriteByteConfig(int Function, int Register, char Value);
	void WriteWordConfig(int Function, int Register, short int Value);
	void WriteDwordConfig(int Function, int Register, long Value);

	char ReadByteConfig(int Function, int Register);
	short int ReadWordConfig(int Function, int Register);
	long ReadDwordConfig(int Function, int Register);

	void Add(TPciFunction *PciFunction);

    TPciFunction *FunctionArr[8];
};

class TPci : public TBusFunction
{
public:
    TPci(TBus *Bus, int PciBus);
    ~TPci();

	virtual int GetSize();

	virtual void OutByte(int Num, int Offset, char Value);
	virtual void OutWord(int Num, int Offset, short int Value);
	virtual void OutDword(int Num, int Offset, long Value);
	virtual char InByte(int Num, int Offset);
	virtual short int InWord(int Num, int Offset);
	virtual long InDword(int Num, int Offset);

	void WriteByteConfig(int Index, char Value);
	void WriteWordConfig(int Index, short int Value);
	void WriteDwordConfig(int Index, long Value);

	char ReadByteConfig(int Index);
	short int ReadWordConfig(int Index);
	long ReadDwordConfig(int Index);

	TBus *GetBus();
	int AllocateIo(int Size);

	void Add(TPciFunction *PciFunction);
                
private:
    int FIndex;
    int FPciBus;
    TBus *FBus;
    int FIoBase;
    TPciDevice *DeviceArr[32];
};

#endif
