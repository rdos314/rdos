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
* PCI.H
* PC keyboard emulation
*
*##########################################################################*/

#ifndef	_PCI_H
#define _PCI_H


class TPciFunction
{
	public:
		TPciFunction();

        virtual int ReadConfig(int Index);
        virtual int ReadData(int Index);
        virtual void WriteConfig(int Index, int Data);
        virtual void WriteData(int Index, int Data);

    protected:
        char FConfig[256];
        char FData[256];
};

class TPciDevice
{
    public:
        TPciDevice();
        ~TPciDevice();

        TPciFunction *FunctionArr[8];
};

class TPciBus
{
    public:
        TPciBus();
        ~TPciBus();

        TPciDevice *DeviceArr[32];
};

class TPci
{
	public:
		TPci();
		~TPci();

		void Out(int Port, char Value);
		char In(int Port);
		void RegisterFunction(TPciFunction *func, int Bus, int Device, int Function);

	protected:
	    int ReadData(int Index);
	    void WriteData(int Index, int Data);

	private:
	    long FIndex;
	    long FValue;
	    int FIndexChanged;
	    int FDataChanged;

        TPciBus *FBusArr[256];
	    
};

#endif
