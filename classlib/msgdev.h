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
# msgdev.h
# Message device class
#
########################################################################*/

#ifndef _MSGDEV_H
#define _MSGDEV_H

#include <stdlib.h>

#include "section.h"
#include "device.h"
#include "datetime.h"
#include "file.h"

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

#endif

