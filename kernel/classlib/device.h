/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
#
# This program is free software; you can reDeviceribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is Deviceributed in the hope that it will be useful,
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
# device.h
# Basic device class
#
########################################################################*/

#ifndef _DEVICE_H
#define _DEVICE_H

#include <stdlib.h>

#include "section.h"
#include "thread.h"
#include "datetime.h"

#define DEVICE_TAG_HEADER             0
#define DEVICE_TAG_ACK                1
#define DEVICE_TAG_REQ                2
#define DEVICE_TAG_REPLY              3
#define DEVICE_TAG_INFO               4
#define DEVICE_TAG_RESET_REQ          5
#define DEVICE_TAG_RESET_ACK          6
#define DEVICE_TAG_POLL_REQ           7
#define DEVICE_TAG_POLL_ACK           8
#define DEVICE_TAG_INSTALL_REQ        9
#define DEVICE_TAG_INSTALL_ACCEPT     10
#define DEVICE_TAG_CONFIG_REQ         11
#define DEVICE_TAG_CONFIG_ACK         12

#define DEVICE_TAG_USER               100

#define DEVICE_VAR_UnitType           0
#define DEVICE_VAR_UnitID             1
#define DEVICE_VAR_MsgID              2
#define DEVICE_VAR_Open               3
#define DEVICE_VAR_Enabled            4
#define DEVICE_VAR_Online             5
#define DEVICE_VAR_Busy               6
#define DEVICE_VAR_PhysicalDevice     7
#define DEVICE_VAR_Name               8

#define DEVICE_VAR_USER               250

class TDeviceAlloc
{
public:
	TDeviceAlloc(int MaxSize);
	~TDeviceAlloc();

	void *Allocate(int size);

protected:
	char *FArr;
	int FPos;
	int FSize;
};

class TDeviceData
{
public:
    TDeviceData();
    virtual ~TDeviceData();
	virtual int GetSize() = 0;
	virtual int GetData(char *data) = 0;
	virtual int GetID() = 0;
	virtual int IsTag();
	virtual int IsVar();

    TDeviceData *FNext;
};

class TDeviceTag;

class TDeviceVar : public TDeviceData
{
friend class TDeviceTag;
public:
	TDeviceVar(unsigned short int ID);
	TDeviceVar(const char *data, int size, int *count);
	TDeviceVar(TDeviceAlloc *alloc, unsigned short int ID);
	TDeviceVar(TDeviceAlloc *alloc, const char *data, int size, int *count);
	virtual ~TDeviceVar();

	virtual int IsVar();
	int IsEmptyVar();
	char GetType();

	void *operator new(size_t size, TDeviceAlloc *alloc);
	void *operator new(size_t size);

	virtual int GetID();
	virtual int GetSize();
	virtual int GetData(char *data);

	void SetUnsigned8(unsigned char data);
	void SetUnsigned16(unsigned short int data);
	void SetUnsigned32(unsigned long data);
	void SetUnsignedShort(unsigned short int data);
	void SetUnsignedInt(unsigned int data);
	void SetUnsignedLong(unsigned long data);
	void SetSigned8(char data);
	void SetSigned16(short int data);
	void SetSigned32(long data);
	void SetSignedShort(short int data);
	void SetSignedInt(int data);
	void SetSignedLong(long data);
	void SetChar(char ch);
	void SetFloat1(long data);
	void SetFloat2(long data);
	void SetFloat3(long data);
	void SetFloat4(long data);
	void SetJulian(long data);
	void SetBinary(int size, const void *data);
	void SetString(const char *str);
	void SetBoolean(int data);
	void SetBoolArray(int size, const char *data);
	void SetByteArray(int size, const void *data);

	unsigned char GetUnsigned8();
	unsigned short int GetUnsigned16();
	unsigned long GetUnsigned32();
	unsigned int GetUnsignedInt();
	unsigned short int GetUnsignedShort();
	unsigned long GetUnsignedLong();
	char GetSigned8();
	short int GetSigned16();
	long GetSigned32();
	int GetSignedInt();
	short int GetSignedShort();
	long GetSignedLong();
	char GetChar();
	long GetFloat1();
	long GetFloat2();
	long GetFloat3();
	long GetFloat4();
	long GetJulian();
	const void *GetBinary(int *size);
	const char *GetString();
	int GetBoolean();
	const char *GetBoolArray(int *size);
	const void *GetByteArray(int *size);

protected:
    void Init(const char *data, int size, int *count);
	void Reinit();
	char *Allocate(int size);

	unsigned short int FID;
	char FType;
	int FSize;
	char *FData;
	char *FStr;
	TDeviceAlloc *FAlloc;
};

class TDeviceMsg;

class TDeviceTag : public TDeviceData
{
friend class TDeviceMsg;

public:
    TDeviceTag(unsigned short int ID);
    TDeviceTag(const char *data, int size, int *count);
    TDeviceTag(TDeviceAlloc *alloc, unsigned short int ID);
    TDeviceTag(TDeviceAlloc *alloc, const char *data, int size, int *count);
	virtual ~TDeviceTag();

	virtual int IsTag();
	int IsEmptyTag();

	void *operator new(size_t size, TDeviceAlloc *alloc);
	void *operator new(size_t size);

	virtual int GetID();
    virtual int GetSize();
    virtual int GetData(char *data);

	TDeviceTag *Copy();
	TDeviceTag *Copy(TDeviceAlloc *alloc);
    TDeviceTag *CopyTag(TDeviceTag *tag);
    
    TDeviceTag *AddTag(unsigned short int ID);
    TDeviceVar *AddNone(unsigned short int ID);
    
    TDeviceVar *AddUnsignedShort(unsigned short int ID, unsigned short int data);
    TDeviceVar *AddUnsignedLong(unsigned short int ID, unsigned long data);
    TDeviceVar *AddUnsignedInt(unsigned short int ID, unsigned int data);
    TDeviceVar *AddSignedShort(unsigned short int ID, short int data);
    TDeviceVar *AddSignedLong(unsigned short int ID, long data);
    TDeviceVar *AddSignedInt(unsigned short int ID, int data);
    TDeviceVar *AddChar(unsigned short int ID, char ch);
    TDeviceVar *AddFloat1(unsigned short int ID, long data);
	TDeviceVar *AddFloat2(unsigned short int ID, long data);
    TDeviceVar *AddFloat3(unsigned short int ID, long data);
    TDeviceVar *AddFloat4(unsigned short int ID, long data);
    TDeviceVar *AddJulian(unsigned short int ID, long data);
    TDeviceVar *AddBinary(unsigned short int ID, int size, const void *data);
    TDeviceVar *AddString(unsigned short int ID, const char *str);
    TDeviceVar *AddBoolean(unsigned short int ID, int data);
    TDeviceVar *AddBoolArray(unsigned short int ID, int size, const char *data);
    TDeviceVar *AddByteArray(unsigned short int ID, int size, const void *data);

    TDeviceVar *ModifyUnsignedShort(unsigned short int ID, unsigned short int data);
	TDeviceVar *ModifyUnsignedLong(unsigned short int ID, unsigned long data);
    TDeviceVar *ModifyUnsignedInt(unsigned short int ID, unsigned int data);
    TDeviceVar *ModifySignedShort(unsigned short int ID, short int data);
    TDeviceVar *ModifySignedLong(unsigned short int ID, long data);
    TDeviceVar *ModifySignedInt(unsigned short int ID, int data);
    TDeviceVar *ModifyChar(unsigned short int ID, char ch);
    TDeviceVar *ModifyFloat1(unsigned short int ID, long data);
    TDeviceVar *ModifyFloat2(unsigned short int ID, long data);
    TDeviceVar *ModifyFloat3(unsigned short int ID, long data);
    TDeviceVar *ModifyFloat4(unsigned short int ID, long data);
    TDeviceVar *ModifyJulian(unsigned short int ID, long data);
    TDeviceVar *ModifyBinary(unsigned short int ID, int size, const void *data);
    TDeviceVar *ModifyString(unsigned short int ID, const char *str);
    TDeviceVar *ModifyBoolean(unsigned short int ID, int data);
	TDeviceVar *ModifyBoolArray(unsigned short int ID, int size, const char *data);
    TDeviceVar *ModifyByteArray(unsigned short int ID, int size, const void *data);

    TDeviceTag *GotoFirstTag();
    TDeviceTag *GotoNextTag();
    TDeviceVar *GotoFirstVar();
    TDeviceVar *GotoNextVar();

    TDeviceTag *GetTag(unsigned short int ID);
    TDeviceVar *GetVar(unsigned short int ID);
    int HasEmptyVar(unsigned short int ID);
	int HasEmptyTag(unsigned short int ID);

    unsigned short int GetUnsignedShort(unsigned short int ID, unsigned short int Default);
    unsigned long GetUnsignedLong(unsigned short int ID, unsigned long Default);
    unsigned int GetUnsignedInt(unsigned short int ID, unsigned int Default);
    short int GetSignedShort(unsigned short int ID, short int Default);
    long GetSignedLong(unsigned short int ID, long Default);
    int GetSignedInt(unsigned short int ID, int Default);
    char GetChar(unsigned short int ID, char Default);
    long GetFloat1(unsigned short int ID, long Default);
    long GetFloat2(unsigned short int ID, long Default);
    long GetFloat3(unsigned short int ID, long Default);
    long GetFloat4(unsigned short int ID, long Default);
    long GetJulian(unsigned short int ID, long Default);
	const void *GetBinary(unsigned short int ID, int *size);
    const char *GetString(unsigned short int ID, const char *Default);
    int GetBoolean(unsigned short int ID, int Default);
    const char *GetBoolArray(unsigned short int ID, int *size);
    const void *GetByteArray(unsigned short int ID, int *size);     

	void UpdateUnsignedShort(TDeviceTag *DestTag, unsigned short int ID, unsigned short int *Val);
	void UpdateUnsignedLong(TDeviceTag *DestTag, unsigned short int ID, unsigned long *Val);
	void UpdateUnsignedInt(TDeviceTag *DestTag, unsigned short int ID, unsigned int *Val);
	void UpdateSignedShort(TDeviceTag *DestTag, unsigned short int ID, short int *Val);
	void UpdateSignedLong(TDeviceTag *DestTag, unsigned short int ID, long *Val);
	void UpdateSignedInt(TDeviceTag *DestTag, unsigned short int ID, int *Val);
	void UpdateChar(TDeviceTag *DestTag, unsigned short int ID, char *Val);
	void UpdateFloat1(TDeviceTag *DestTag, unsigned short int ID, long *Val);
	void UpdateFloat2(TDeviceTag *DestTag, unsigned short int ID, long *Val);
	void UpdateFloat3(TDeviceTag *DestTag, unsigned short int ID, long *Val);
	void UpdateFloat4(TDeviceTag *DestTag, unsigned short int ID, long *Val);
	void UpdateJulian(TDeviceTag *DestTag, unsigned short int ID, long *Val);
	void UpdateBoolean(TDeviceTag *DestTag, unsigned short int ID, int *Val);
	void UpdateString(TDeviceTag *DestTag, unsigned short int ID, char **Val);

	void UpdateUnsignedShort(TDeviceTag *DestTag, unsigned short int ID, unsigned short int Val);
	void UpdateUnsignedLong(TDeviceTag *DestTag, unsigned short int ID, unsigned long Val);
	void UpdateUnsignedInt(TDeviceTag *DestTag, unsigned short int ID, unsigned int Val);
	void UpdateSignedShort(TDeviceTag *DestTag, unsigned short int ID, short int Val);
	void UpdateSignedLong(TDeviceTag *DestTag, unsigned short int ID, long Val);
	void UpdateSignedInt(TDeviceTag *DestTag, unsigned short int ID, int Val);
	void UpdateChar(TDeviceTag *DestTag, unsigned short int ID, char Val);
	void UpdateFloat1(TDeviceTag *DestTag, unsigned short int ID, long Val);
	void UpdateFloat2(TDeviceTag *DestTag, unsigned short int ID, long Val);
	void UpdateFloat3(TDeviceTag *DestTag, unsigned short int ID, long Val);
	void UpdateFloat4(TDeviceTag *DestTag, unsigned short int ID, long Val);
	void UpdateJulian(TDeviceTag *DestTag, unsigned short int ID, long Val);
	void UpdateBoolean(TDeviceTag *DestTag, unsigned short int ID, int Val);
	void UpdateString(TDeviceTag *DestTag, unsigned short int ID, char *Val);
    
protected:
    void Init(const char *data, int size, int *count);

	TDeviceVar *AddUnsigned8(unsigned short int ID, unsigned char data);
    TDeviceVar *AddUnsigned16(unsigned short int ID, unsigned short int data);
    TDeviceVar *AddUnsigned32(unsigned short int ID, unsigned long data);
    TDeviceVar *AddSigned8(unsigned short int ID, char data);
    TDeviceVar *AddSigned16(unsigned short int ID, short int data);
    TDeviceVar *AddSigned32(unsigned short int ID, long data);

    void Add(TDeviceData *data);
	char *Allocate(int size);

    unsigned short int FID;
    TDeviceData *FHead;
    TDeviceTag *FCurrTag;
    TDeviceVar *FCurrVar;
	TDeviceAlloc *FAlloc;
};

class TDeviceMsg
{
public:
    TDeviceMsg();
    TDeviceMsg(int MaxSize);
    ~TDeviceMsg();

    int GetSize();
    void GetData(long signature, char *data);
    int Parse(long signature, const char *data, int size);

    TDeviceAlloc *GetAlloc();

    TDeviceTag *CopyTag(TDeviceTag *tag);
    TDeviceTag *AddTag(unsigned short int ID);

    TDeviceTag *GotoFirstTag();
    TDeviceTag *GotoNextTag();

    TDeviceTag *GetTag(unsigned short int ID);

    void Add(TDeviceTag *tag);
    void Free();

    TDateTime FResend;
    int FDeleteOnSend;

protected:
	unsigned short int Crc(const char *Data, int Size) const;

	TDeviceTag *FHead;
	TDeviceTag *FCurrTag;
	TDeviceAlloc *FAlloc;

private:
};

class TDistUnit;

class TDevice : public TThread
{
	friend class TDistUnit;
	friend class TDistSystem;

public:
	TDevice();
	TDevice(const char *IniSection);
	virtual ~TDevice();

	virtual void NotifyReset();

	void Open();
	void Close();
	int IsOpen() const;
	void Enable();
	void Disable();
	int IsEnabled() const;
	
	virtual int IsActive() const;
	virtual int IsBusy() const;
	virtual int IsOnline() const;
	virtual void DeviceName(char *Name, int MaxLen) const;
	static void GetDevices(void (*DeviceCallb)(TDevice *Device));

	virtual short int GetUnitType();
	virtual short int GetUnitNumber();

	void *Owner;
	void (*OnOnline)(TDevice *Device);
	void (*OnOffline)(TDevice *Device);
	void (*OnIdle)(TDevice *Device);
	void (*OnBusy)(TDevice *Device);

protected:
    virtual void NotifyOpen();
    virtual void NotifyClose();
    virtual void NotifyEnable();
    virtual void NotifyDisable();
    virtual void NotifyIdle();
    virtual void NotifyBusy();

	virtual void Online();
	virtual void Offline();

	void Idle();
	void Busy();

	int IsReseted() const;
	void ClearReset();

	virtual int GetMaxMsgSize();
	virtual int IsModifyTag(unsigned short int TAG);

    void AddNone(TDistUnit *unit, unsigned short int TAG, unsigned short int ID);
    void AddUnsignedShort(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, unsigned short int data);
    void AddUnsignedLong(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, unsigned long data);
    void AddUnsignedInt(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, unsigned int data);
    void AddSignedShort(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, short int data);
    void AddSignedLong(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, long data);
    void AddSignedInt(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, int data);
    void AddChar(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, char ch);
    void AddFloat1(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, long data);
	void AddFloat2(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, long data);
    void AddFloat3(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, long data);
    void AddFloat4(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, long data);
    void AddJulian(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, long data);
    void AddBinary(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, int size, const void *data);
    void AddString(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, const char *str);
    void AddBoolean(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, int data);
    void AddBoolArray(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, int size, const char *data);
    void AddByteArray(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, int size, const void *data);

    void AddNone(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID);
    void AddUnsignedShort(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, unsigned short int data);
    void AddUnsignedLong(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, unsigned long data);
    void AddUnsignedInt(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, unsigned int data);
    void AddSignedShort(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, short int data);
    void AddSignedLong(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, long data);
    void AddSignedInt(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, int data);
    void AddChar(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, char ch);
    void AddFloat1(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, long data);
	void AddFloat2(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, long data);
    void AddFloat3(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, long data);
    void AddFloat4(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, long data);
    void AddJulian(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, long data);
    void AddBinary(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, int size, const void *data);
    void AddString(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, const char *str);
    void AddBoolean(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, int data);
    void AddBoolArray(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, int size, const char *data);
    void AddByteArray(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, int size, const void *data);

    void SignalMsg(TDistUnit *unit);

    void CreateInstallTag(TDistUnit *unit);

    virtual void CreateResetTag(TDistUnit *unit);
    virtual void CreateInstallTag(TDeviceTag *tag);
	virtual void NotifyResetTag(TDistUnit *unit);
	virtual void NotifyReqTag(TDistUnit *unit, TDeviceTag *reqtag, TDeviceTag *replytag);
	virtual void NotifyReplyTag(TDistUnit *unit, TDeviceTag *tag);
	virtual void NotifyInfoTag(TDistUnit *unit, TDeviceTag *tag);
	virtual void NotifyInstallTag(TDistUnit *unit, TDeviceTag *tag);

	TDistUnit *FVirtUnitList;
	TDistUnit *FPhysUnit;

	int	FOpen;
	int FEnabled;
	int FOnline;
	int FBusy;
	int FReset;
	char *FName;
	TSection FPropertySection;

private:
	void Init();
	void InsertDevice();
	void RemoveDevice();

	static TSection FListSection;
	static TDevice *FDeviceList;
	TDevice *FList;
	const char *FIniSection;
};

class TDistSystem;

class TDistUnit
{    
	friend class TDevice;
	friend class TDistSystem;
    
public:
	TDistUnit(TDistSystem *DistSystem);
	~TDistUnit();

	void DefineDevice(TDevice *Device);
	int IsOnline();
    int IsInstalled();
    
	short int GetUnitType();
    short int GetUnitNumber();

	TDeviceTag *LockTag(unsigned short int TAG); 
	void UnlockTag();
	void SignalMsg();
	
	TDistUnit *GetNextUnit();

protected:
    void Online();
    void Offline();
    
	TDistUnit(TDistSystem *DistSystem, short int UnitType, short int UnitNumber);
	
    void CreateResetTag();
    void CreateAckTag(TDeviceTag *Tag);
    void CreateAcceptTag();
    
	TDeviceTag *LockReqTag();
	TDeviceTag *LockReplyTag(unsigned short int ID);
	TDeviceTag *LockInfoTag();
	TDeviceTag *LockInstallTag();

	void HandleMsg(TDeviceMsg *Msg);
    TDeviceMsg *GetMsg();

    void ClearQueues();
    void ResetCurrMsg();
	void CreateMsg();
	void CreateAcceptMsg();
	void CreateAckMsg();
    void IncMsgID();

	void HandleAckTag(TDeviceTag *Tag);
	void HandleReqTag(TDeviceTag *Tag);
	void HandleReplyTag(TDeviceTag *Tag);
	void HandleInfoTag(TDeviceTag *Tag);
	void HandleInstallTag();
	void HandleInstallTag(TDeviceTag *Tag);
	void HandleAcceptTag(TDeviceTag *Tag);

    TDistUnit *FNext;
    TDistUnit *FList;
  	TDevice *FDevice;
	TDistSystem *FDistSystem;

    TDeviceMsg *FMsg;
    TDeviceMsg *FAcceptMsg;
    TDeviceMsg *FAckMsg;
	
	short int FReqID;
	short int FInfoID;
	short int FInstallID;
	short int FAcceptID;

    short int FUnitType;
    short int FUnitNumber;
    
	int FInstalled;
	int FOnline;

private:
    void Init();

	TDeviceAlloc *FInstallAlloc;
	TDeviceTag *FPendingInstallTag;

    TDeviceAlloc *FReplyAlloc;
    TDeviceTag *FLastReplyTag;
    short int FLastReplyID;
    
	TSection FMsgSection;
	TDeviceMsg *FCurrMsg;
	TDeviceTag *FReqTag;
	TDeviceTag *FReplyTag;
	TDeviceTag *FInfoTag;
	TDeviceTag *FInstallTag;
	short int FCurrID;
	short int FCurrReqID;
	short int FCurrInfoID;
	short int FCurrInstallID;
	short int FCurrAcceptID;
};

class TDeviceConfig
{
    friend class TDistSystem;
    
public:
    TDeviceConfig(unsigned short int UnitType, unsigned short int UnitNumber, int MaxSize);
    ~TDeviceConfig();

    TDeviceTag *GetConfigTag();


protected:
    unsigned short int FUnitType;
    unsigned short int FUnitNumber;
    int FActive;
    
    TDeviceConfig *FNext;
    TDeviceMsg *FConfigMsg;
    TDeviceTag *FConfigTag;
};

class TDistDevice;

class TDistSystem
{
	friend class TDistUnit;
	friend class TDistDevice;

public:
	TDistSystem(TDistDevice *DistDevice, long signature);
	TDistSystem(TDistDevice *DistDevice, long s1, long s2, long s3, long s4);
	virtual ~TDistSystem();

	int HasUnit(unsigned short int UnitType);
	int HasUnit(unsigned short int UnitType, unsigned short int UnitNumber);
    int HasConfig(unsigned short int UnitType, unsigned short int UnitNumber);

    long GetSignature();

    int IsOnline();

	void InstallVirtual(TDevice *Device);
	void InstallPhysical(TDevice *Device);

	void Config(TDeviceConfig *config);
	void SendMsg(TDeviceMsg *Msg);

	void (*OnConfig)(TDistSystem *Dist, unsigned short int UnitType, unsigned short int UnitNumber, TDeviceTag *config);
    void (*OnMsg)(TDistSystem *Dist, TDeviceMsg *Msg);

    void *Owner;

protected:
	void InsertUnit(TDistUnit *unit);
	void InsertNoBlockUnit(TDistUnit *unit);
	void RemoveUnit(TDistUnit *unit);

	void InsertConfig(TDeviceConfig *config);
	void RemoveConfig(TDeviceConfig *config);

	void Online();
	void Offline();

    void SendMsg(const char *Data, int Size);    
	int GetTimeout();
	
    void SendResetReq();
    void SendResetAck();
	
    void SendPollReq();
    void SendPollAck();

    void SendConfigAck(unsigned short int UnitType, unsigned short int UnitNumber);
    
	void NotifyMsg(const char *Data, int Size);
	void SignalMsg();

    void UpdateMsg();
    void HandleMsg(TDeviceMsg *Msg);

	TDeviceMsg *FMsgQueue;
	TSection FUnitSection;
	TDistUnit *FUnitList;

	int FHasUnits;

	TDeviceConfig *FConfigList;
	TSection FConfigSection;

	TDistSystem *FNext;

private:
    void Init();

    TDistDevice *FDistDevice;
    long FSignature;
    int FOnline;
    int FPendingResetReq;
    int FPendingResetAck;
    int FPendingPoll;
};

class TSignalDevice;

class TDistDevice : public TDevice
{
    friend class TDistSystem;
    
public:
    TDistDevice();
    ~TDistDevice();

    virtual void SendMsg(const char *Data, int Size) = 0;    
	virtual int GetTimeout() = 0;
        
protected:
    void AddSystem(TDistSystem *system);
    int CheckSignature(long Signature);
	void SignalMsg();
	void NotifyMsg(long signature, const char *Data, int Size);
    void UpdateMsg();
    void SendPollReq();
	
    virtual void Online();
    virtual void Offline();

	TSignalDevice *FSignal;
    TDistSystem *FSystemList;    
};

#endif

