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

class TPci;

class TPciAreaData
{
public:
    unsigned long Base;
    unsigned long Size;
    char *Data;
};

class TPciFunction
{
public:
	TPciFunction(TPci *Pci);

    virtual int ReadConfig(int Index);
    virtual int ReadData(int Index);
    virtual void WriteConfig(int Index, int Data);
    virtual void WriteData(int Index, int Data);

	virtual void Out(int Num, int Offset, char Value);
	virtual char In(int Num, int Offset);
	virtual void WriteMem(int Num, unsigned unsigned long Offset, char Value);
	virtual char ReadMem(int Num, unsigned unsigned long Offset);

protected:
    void DefineIo(int Num, int Base, int Size, char *Data);
    void UndefineIo(int Num);
    void DefineMem(int Num, int Base, int Size, char *Data);
    void UndefineMem(int Num);

	TPci *FPci;
    char FConfig[256];
    char FData[256];
    TPciAreaData *FIoArr[256];
    TPciAreaData *FMemArr[256];
    
};

class TPciArea
{
public:
	unsigned long Base;
	unsigned long Size;
	TPciFunction *func;
	int Num;
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
	void WriteMem(unsigned long Address, char Value);
	char ReadMem(unsigned long Address);
	
	void RegisterFunction(TPciFunction *func, int Bus, int Device, int Function);
	void DefineIo(TPciFunction *func, int Num, int Base, int Size);
	void UndefineIo(TPciFunction *func, int Num);
	void DefineMem(TPciFunction *func, int Num, int Base, int Size);
	void UndefineMem(TPciFunction *func, int Num);

	int IsKeyboardEnabled();
	void EnableKeyboard();

protected:
	int ReadData(int Index);
	void WriteData(int Index, int Data);

	void DefaultOut(int Port, char Value);
	char DefaultIn(int Port);
		
private:
	long FIndex;
	long FValue;
	int FIndexChanged;
	int FDataChanged;
    int FKeyboardEnabled;

    TPciBus *FBusArr[256];
	TPciArea *FHookIoArr[256];
	TPciArea *FHookMemArr[256];
	    
};

#endif
