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

    virtual char ReadConfig(int Register);
    virtual void WriteConfig(int Register, char Data);

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

	void WriteConfig(int Function, int Register, char Value);
	char ReadConfig(int Function, int Register);

	void Add(TPciFunction *PciFunction);

    TPciFunction *FunctionArr[8];
};

class TPci : public TBusFunction
{
public:
    TPci(TBus *Bus, int PciBus);
    ~TPci();

	virtual int GetSize();

	virtual void Out(int Num, int Offset, char Value);
	virtual char InByte(int Num, int Offset);

	void WriteConfig(int Index, char Value);
	char ReadConfig(int Index);

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
