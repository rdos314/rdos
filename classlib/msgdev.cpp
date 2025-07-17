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
# msgdev.cpp
# Message device class
#
#######################################################################*/

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "msgdev.h"
#include "sigdev.h"

#if !defined(MSVC) && defined(__RDOS__)
#include "rdos.h"
#endif

#define FALSE 0
#define TRUE !FALSE

#define DEVICE_TAGRANGE_LOW             1
#define DEVICE_TAGRANGE_HIGH        10000
#define DEVICE_VARIABLERANGE_LOW        30001
#define DEVICE_VARIABLERANGE_HIGH       40000
#define DEVICE_TAGEND               65535

#define DEVICE_DATA_UNKNOWN         0
#define DEVICE_DATA_NONE            1
#define DEVICE_DATA_UNSIGNED8       2
#define DEVICE_DATA_UNSIGNED16      3
#define DEVICE_DATA_UNSIGNED32      4
#define DEVICE_DATA_SIGNED8         5
#define DEVICE_DATA_SIGNED16        6
#define DEVICE_DATA_SIGNED32        7
#define DEVICE_DATA_CHAR            8
#define DEVICE_DATA_FLOAT1          9
#define DEVICE_DATA_FLOAT2          10
#define DEVICE_DATA_FLOAT3          11
#define DEVICE_DATA_FLOAT4          12
#define DEVICE_DATA_JULIANDATE      13
#define DEVICE_DATA_BINARY8         14
#define DEVICE_DATA_BINARY16        15
#define DEVICE_DATA_STRING8         16
#define DEVICE_DATA_STRING16        17
#define DEVICE_DATA_BOOLEAN         18
#define DEVICE_DATA_BOOLARRAY       19
#define DEVICE_DATA_BYTEARRAY       20
#define DEVICE_DATA_SHORTSTRING     128

#if !defined(MSVC) && defined(__RDOS__)
int CrcHandle = RdosCreateCrc(0x8005);
#endif

/*##################  TDeviceAlloc:TDeviceAlloc  ###############
*   Purpose....: Constructor for msg allocation                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceAlloc::TDeviceAlloc(int MaxSize)
{
    FSize = MaxSize;
    FPos = 0;
    FArr = new char[MaxSize];
}

/*##################  TDeviceAlloc::~TDeviceAlloc  ###############
*   Purpose....: Destructor for msg allocation                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceAlloc::~TDeviceAlloc()
{
    if (FArr)
                delete FArr;
}

/*##################  TDeviceAlloc::Allocate  ###############
*   Purpose....: Allocate a memory segment                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void *TDeviceAlloc::Allocate(int size)
{
    char *p;
    
    if (FPos + size < FSize)
    {
        p = FArr + FPos;
        FPos += size;
                return p;
    }
    else
        return 0;
}

/*##################  TDeviceData:TDeviceData  ###############
*   Purpose....: Constructor for msg data                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceData::TDeviceData()
{
    FNext = 0;
}

/*##################  TDeviceData::~TDeviceData  ###############
*   Purpose....: Destructor for msg data                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceData::~TDeviceData()
{
}

/*##################  TDeviceData::IsTag  ###############
*   Purpose....: Check if this is a tag                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceData::IsTag()
{
    return FALSE;
}

/*##################  TDeviceData::IsVar  ###############
*   Purpose....: Check if this is a variable                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceData::IsVar()
{
        return FALSE;
}

/*##################  TDeviceVar::TDeviceVar  ###############
*   Purpose....: Constructor for var                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar::TDeviceVar(unsigned short int ID)
{
    FAlloc = 0;
    FID = ID;
    FType = DEVICE_DATA_NONE;
    FSize = 0;
    FData = 0;
    FStr = 0;
}

/*##################  TDeviceVar::TDeviceVar  ###############
*   Purpose....: Constructor for var                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar::TDeviceVar(TDeviceAlloc *alloc, unsigned short int ID)
{
    FAlloc = alloc;
    FID = ID;
    FType = DEVICE_DATA_NONE;
    FSize = 0;
    FData = 0;
    FStr = 0;
}

/*##################  TDeviceVar::TDeviceVar  ###############
*   Purpose....: Constructor for var                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar::TDeviceVar(const char *data, int size, int *count)
{
    FAlloc = 0;   
    Init(data, size, count);
}

/*##################  TDeviceVar::TDeviceVar  ###############
*   Purpose....: Constructor for var                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar::TDeviceVar(TDeviceAlloc *alloc, const char *data, int size, int *count)
{
        FAlloc = alloc;
        Init(data, size, count);
}

/*##################  TDeviceVar::TDeviceVar  ###############
*   Purpose....: Constructor for var                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::Init(const char *data, int size, int *count)
{
    unsigned short int Id;
    int overhead;
        int terminate;

    FSize = 0;
    FData = 0;
    FStr = 0;
    *count = 0;
    overhead = 3;
    terminate = FALSE;

    if (size < 3)
        return;
    
    memcpy(&Id, data, 2);
    if (Id < DEVICE_VARIABLERANGE_LOW || Id > DEVICE_VARIABLERANGE_HIGH)
        return;

    FID = Id - DEVICE_VARIABLERANGE_LOW;

    size -= 2;
    data += 2;

    memcpy(&FType, data, 1);
    data++;
    size--;

    switch (FType)
    {
        case DEVICE_DATA_NONE:
            FSize = 0;
            break;
                
        case DEVICE_DATA_UNSIGNED8:
        case DEVICE_DATA_SIGNED8:
        case DEVICE_DATA_CHAR:
        case DEVICE_DATA_BOOLEAN:
            FSize = 1;
            break;

        case DEVICE_DATA_UNSIGNED16:
        case DEVICE_DATA_SIGNED16:
            FSize = 2;
            break;

        case DEVICE_DATA_UNSIGNED32:
        case DEVICE_DATA_SIGNED32:
        case DEVICE_DATA_FLOAT1:
        case DEVICE_DATA_FLOAT2:
        case DEVICE_DATA_FLOAT3:
        case DEVICE_DATA_FLOAT4:
        case DEVICE_DATA_JULIANDATE:
            FSize = 4;
            break;

        case DEVICE_DATA_STRING8:
            terminate = TRUE;

        case DEVICE_DATA_BINARY8:
        case DEVICE_DATA_BOOLARRAY:
        case DEVICE_DATA_BYTEARRAY:
            FSize = 0;
            memcpy(&FSize, data, 1);
            data++;
            overhead++;
            break;

        case DEVICE_DATA_STRING16:
            terminate = TRUE;

        case DEVICE_DATA_BINARY16:
            FSize = 0;
            memcpy(&FSize, data, 2);
            data += 2;
            overhead += 2;
            break;

        default:
            return;
    }

        if (FSize <= size)
        {
                if (terminate)
                {
                        FData = Allocate(FSize + 1);
                        memcpy(FData, data, FSize);
                        *(FData + FSize) = 0;
        }
        else
        {
            if (FSize)
            {
                        FData = Allocate(FSize);
                                memcpy(FData, data, FSize);
            }
            else
                FData = 0;
        }
        *count = overhead + FSize;
    }
}

/*##################  TDeviceVar::~TDeviceVar  ###############
*   Purpose....: Destructor for var                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar::~TDeviceVar()
{
    Reinit();
}

/*##################  TDeviceVar::IsVar  ###############
*   Purpose....: Confirm this is a variable                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceVar::IsVar()
{
    return TRUE;
}

/*##################  TDeviceVar::IsEmptyVar  ###############
*   Purpose....: Is this an empty var?                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceVar::IsEmptyVar()
{
    if (FType == DEVICE_DATA_NONE)
        return TRUE;
    else
        return FALSE;
}

/*##################  TDeviceVar::GetType  ###############
*   Purpose....: Return type                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TDeviceVar::GetType()
{
    return FType;
}

/*##################  TDeviceVar::Reinit  ###############
*   Purpose....: Reinit var                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::Reinit()
{
    if (FData && FAlloc == 0)
        delete FData;
    FData = 0;

    if (FStr && FAlloc == 0)
        delete FStr;
        FStr = 0;
    
    FType = DEVICE_DATA_NONE;
    FSize = 0;
}

/*##################  TDeviceVar::Allocate  ###############
*   Purpose....: Allocate memory                                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char *TDeviceVar::Allocate(int size)
{
    if (FAlloc)
        return (char *)FAlloc->Allocate(size);
    else
        return new char[size];
}

/*##################  TDeviceVar::operator new  ###############
*   Purpose....: operator new                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void *TDeviceVar::operator new(size_t size)
{
    return ::new char[size];
}

/*##################  TDeviceVar::operator new  ###############
*   Purpose....: operator new                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void *TDeviceVar::operator new(size_t size, TDeviceAlloc *alloc)
{
    if (alloc)
        return alloc->Allocate(size);
    else
        return new char[size];
}

/*##################  TDeviceVar::SetUnsigned8  ###############
*   Purpose....: Set variable a unsigned8                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetUnsigned8(unsigned char data)
{
    if (FType != DEVICE_DATA_UNSIGNED8)
    {
        Reinit();
        FType = DEVICE_DATA_UNSIGNED8;
        FSize = 1;
        FData = Allocate(1);
    }
    memcpy(FData, &data, 1);
}

/*##################  TDeviceVar::SetUnsigned16  ###############
*   Purpose....: Set variable a unsigned16                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetUnsigned16(unsigned short int data)
{
    if (FType != DEVICE_DATA_UNSIGNED16)
    {
        Reinit();
        FType = DEVICE_DATA_UNSIGNED16;
        FSize = 2;
        FData = Allocate(2);
    }
        memcpy(FData, &data, 2);
}

/*##################  TDeviceVar::SetUnsigned32  ###############
*   Purpose....: Set variable a unsigned32                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetUnsigned32(unsigned long data)
{
    if (FType != DEVICE_DATA_UNSIGNED32)
    {
        Reinit();
            FType = DEVICE_DATA_UNSIGNED32;
        FSize = 4;
            FData = Allocate(4);
        }
        memcpy(FData, &data, 4);
}

/*##################  TDeviceVar::SetUnsignedShort  ###############
*   Purpose....: Set short int variable to shortest representation                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetUnsignedShort(unsigned short int data)
{
    if (data >= 255)
        SetUnsigned16(data);
    else
        SetUnsigned8((unsigned char)data);
}

/*##################  TDeviceVar::SetUnsignedLong  ###############
*   Purpose....: Set long int variable to shortest representation                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetUnsignedLong(unsigned long data)
{
    if (data > 65535)
        SetUnsigned32(data);
    else
    {
        if (data > 255)
            SetUnsigned16((unsigned short int)data);
        else
            SetUnsigned8((unsigned char)data);
    }
}

/*##################  TDeviceVar::SetUnsignedint  ###############
*   Purpose....: Set int variable to shortest representation                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetUnsignedInt(unsigned int data)
{
#if defined __GNUC__ || defined MSVC || defined __WATCOMC__
    SetUnsignedLong(data);
#else
#if sizeof(int) == 2
    SetUnsignedShort(data);
#else
    SetUnsignedLong(data);
#endif
#endif
}

/*##################  TDeviceVar::SetSigned8  ###############
*   Purpose....: Set variable a signed8                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetSigned8(char data)
{
    if (FType != DEVICE_DATA_SIGNED8)
    {
        Reinit();
            FType = DEVICE_DATA_SIGNED8;
        FSize = 1;
            FData = Allocate(1);
        }
        memcpy(FData, &data, 1);
}

/*##################  TDeviceVar::SetSigned16  ###############
*   Purpose....: Set variable a signed16                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetSigned16(short int data)
{
    if (FType != DEVICE_DATA_SIGNED16)
    {
        Reinit();
            FType = DEVICE_DATA_SIGNED16;
        FSize = 2;
            FData = Allocate(2);
        }
        memcpy(FData, &data, 2);
}

/*##################  TDeviceVar::SetSigned32  ###############
*   Purpose....: Set variable a signed32                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetSigned32(long data)
{
    if (FType != DEVICE_DATA_SIGNED32)
    {
        Reinit();
            FType = DEVICE_DATA_SIGNED32;
        FSize = 4;
        FData = Allocate(4);
    }
        memcpy(FData, &data, 4);
}

/*##################  TDeviceVar::SetSignedShort  ###############
*   Purpose....: Set short int variable to shortest representation                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetSignedShort(short int data)
{
    if (data >= 0)
    {
        if (data > 255)
            SetSigned16((signed short int)data);
        else
        {
            if (data > 127)
                SetUnsigned8((unsigned char)data);
            else
                SetSigned8((signed char)data);
        }
    }
    else
    {
        if (data < -128)
            SetSigned16(data);
        else
            SetSigned8((signed char)data);
    }
}

/*##################  TDeviceVar::SetSignedLong  ###############
*   Purpose....: Set long int variable to shortest representation                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetSignedLong(long data)
{
    if (data >= 0)
    {
        if (data > 65535)
            SetSigned32(data);
        else
        {
            if (data > 32767)
                SetUnsigned16((unsigned short int)data);
            else
            {
                if (data > 255)
                    SetSigned16((signed short int)data);
                else
                {
                    if (data > 127)
                        SetUnsigned8((unsigned char)data);
                    else
                        SetSigned8((signed char)data);
                }
            }
        }
    }
    else
    {
        if (data < -32768)
            SetSigned32(data);
        else
        {
            if (data < -128)
                SetSigned16((signed short int)data);
            else
                SetSigned8((signed char)data);
        }
    }
}

/*##################  TDeviceVar::SetSignedint  ###############
*   Purpose....: Set int variable to shortest representation                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetSignedInt(int data)
{
#if defined __GNUC__ || defined MSVC || defined __WATCOMC__
    SetSignedLong(data);
#else
#if sizeof(int) == 2
    SetSignedShort(data);
#else
    SetSignedLong(data);
#endif
#endif
}

/*##################  TDeviceVar::SetChar  ###############
*   Purpose....: Set variable as char                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetChar(char ch)
{
    if (FType != DEVICE_DATA_CHAR)
    {
        Reinit();
            FType = DEVICE_DATA_CHAR;
        FSize = 1;
            FData = Allocate(1);
        }
        memcpy(FData, &ch, 1);
}

/*##################  TDeviceVar::SetFloat1  ###############
*   Purpose....: Set variable as float1                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetFloat1(long data)
{
    if (FType != DEVICE_DATA_FLOAT1)
    {
        Reinit();
            FType = DEVICE_DATA_FLOAT1;
        FSize = 4;
            FData = Allocate(4);
        }
        memcpy(FData, &data, 4);
}

/*##################  TDeviceVar::SetFloat2  ###############
*   Purpose....: Set variable as float2                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetFloat2(long data)
{
    if (FType != DEVICE_DATA_FLOAT2)
    {
        Reinit();
            FType = DEVICE_DATA_FLOAT2;
        FSize = 4;
            FData = Allocate(4);
        }
        memcpy(FData, &data, 4);
}

/*##################  TDeviceVar::SetFloat3  ###############
*   Purpose....: Set variable as float3                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetFloat3(long data)
{
    if (FType != DEVICE_DATA_FLOAT3)
    {
        Reinit();
            FType = DEVICE_DATA_FLOAT3;
        FSize = 4;
            FData = Allocate(4);
        }
        memcpy(FData, &data, 4);
}

/*##################  TDeviceVar::SetFloat4  ###############
*   Purpose....: Set variable as float4                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetFloat4(long data)
{
    if (FType != DEVICE_DATA_FLOAT4)
    {
        Reinit();
        FType = DEVICE_DATA_FLOAT4;
        FSize = 4;
        FData = Allocate(4);
    }
        memcpy(FData, &data, 4);
}

/*##################  TDeviceVar::SetJulian  ###############
*   Purpose....: Set variable as julian                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetJulian(long data)
{
    if (FType != DEVICE_DATA_JULIANDATE)
    {
        Reinit();
            FType = DEVICE_DATA_JULIANDATE;
        FSize = 4;
            FData = Allocate(4);
        }
        memcpy(FData, &data, 4);
}

/*##################  TDeviceVar::SetBinary  ###############
*   Purpose....: Set variable as binary                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetBinary(int size, const void *data)
{
        Reinit();
        if (size < 0)
                return;

        if (size < 256)
        {
                FType = DEVICE_DATA_BINARY8;
                FSize = size;
                FData = Allocate(FSize);
                memcpy(FData, data, size);
        }
        else
        {
        FType = DEVICE_DATA_BINARY16;
        FSize = size;
        FData = Allocate(FSize);
        memcpy(FData, data, size);
        }
}

/*##################  TDeviceVar::SetString  ###############
*   Purpose....: Set variable as string                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetString(const char *str)
{
    int size = strlen(str);

    if (size < 128)
    {
        if (FType == DEVICE_DATA_SHORTSTRING + (char)size)
            memcpy(FData, str, size);
        else
        {
            Reinit();
            FType = DEVICE_DATA_SHORTSTRING + (char)size;
            FSize = size;

            if (FSize)
            {
                FData = Allocate(size);
                memcpy(FData, str, size);        
            }
            else
                FData = 0;

        }
    }
    else
    {
        if (size < 256)
        {
            if (FType == DEVICE_DATA_STRING8 && FSize == size)
                memcpy(FData, str, size);
            else
            {
                Reinit();           
                FType = DEVICE_DATA_STRING8;
                FSize = size;
                FData = Allocate(FSize);
                memcpy(FData, str, size);
            }
        }
        else
        {
            if (FType == DEVICE_DATA_STRING16 && FSize == size)
                memcpy(FData, str, size);
            else
            {
                Reinit();
                FType = DEVICE_DATA_STRING16;
                FSize = size;
                FData = Allocate(FSize);
                memcpy(FData, str, size);
            }
        }
    }
}

/*##################  TDeviceVar::SetBoolean  ###############
*   Purpose....: Set variable as boolean                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetBoolean(int data)
{
    if (FType != DEVICE_DATA_BOOLEAN)
    {
        Reinit();
        FType = DEVICE_DATA_BOOLEAN;
        FSize = 1;
        FData = Allocate(1);
    }
    
    if (data)
        *FData = 1;
    else
        *FData = 0;
}    

/*##################  TDeviceVar::SetBoolArray  ###############
*   Purpose....: Set variable as boolean array                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetBoolArray(int size, const char *data)
{
    int len;
    int i;
    char *ptr;
    int bitnr;
        const char *cbool;

    Reinit();

    if (size >= 2040)
        return;
    
    FType = DEVICE_DATA_BOOLARRAY;
    
    if (size % 8 == 0)
        len = size / 8;
    else
        len = size / 8 + 1;

    FSize = len;
    FData = Allocate(FSize);

    for (i = 0; i < len; i++)       
                *(FData + i) = 0;

    bitnr = 0;
    ptr = FData;
    cbool = data;
    for (i = 0; i < size; i++)
    {
        if (*cbool)
            *ptr |= 1 << bitnr;
        
        bitnr++;
        if (bitnr == 8)
        {
            bitnr = 0;
            ptr++;
        }
        cbool++;
    }                 
}

/*##################  TDeviceVar::SetByteArray  ###############
*   Purpose....: Set variable as byte array                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetByteArray(int size, const void *data)
{
    Reinit();

    if (size >= 256)
        return;
        
    FType = DEVICE_DATA_BYTEARRAY;
    FSize = size;
    FData = Allocate(FSize);
    memcpy(FData, data, size);
}    

/*##################  TDeviceVar::GetUnsigned8  ###############
*   Purpose....: Get variable a unsigned8                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
unsigned char TDeviceVar::GetUnsigned8()
{
        unsigned char val = 0;
    long val_long;
    unsigned long val_ulong;
    
    switch (FType)
    {
        case DEVICE_DATA_CHAR:
        case DEVICE_DATA_UNSIGNED8:
        case DEVICE_DATA_BINARY8:
        case DEVICE_DATA_BINARY16:
        case DEVICE_DATA_BOOLEAN:
        case DEVICE_DATA_BOOLARRAY:
        case DEVICE_DATA_BYTEARRAY:
            memcpy(&val, FData, 1);
            break;

        case DEVICE_DATA_SIGNED8:
        case DEVICE_DATA_SIGNED16:
        case DEVICE_DATA_SIGNED32:
        case DEVICE_DATA_FLOAT1:
        case DEVICE_DATA_FLOAT2:
        case DEVICE_DATA_FLOAT3:
        case DEVICE_DATA_FLOAT4:
            val_long = GetSigned32();
            if (val_long < 0)
                                val = 0;
            else
            {
                if (val_long > 0x100)
                    val = 0xFF;
                else
                    val = (unsigned char)val_long;
            }
            break;

        default:
            val_ulong = GetUnsigned32();
            if (val_ulong > 0x100)
                val = 0xFF;
            else
                val = (unsigned char)val_ulong;
            break;
    }
    
    return val;
}

/*##################  TDeviceVar::GetUnsigned16  ###############
*   Purpose....: Get variable a unsigned16                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
unsigned short int TDeviceVar::GetUnsigned16()
{
    unsigned short int val = 0;
    long val_long;
    unsigned long val_ulong;
    
    switch (FType)
    {
        case DEVICE_DATA_CHAR:
        case DEVICE_DATA_UNSIGNED8:
        case DEVICE_DATA_BINARY8:
        case DEVICE_DATA_BINARY16:
        case DEVICE_DATA_BOOLEAN:
        case DEVICE_DATA_BOOLARRAY:
        case DEVICE_DATA_BYTEARRAY:
            val = GetUnsigned8();
            break;

        case DEVICE_DATA_UNSIGNED16:
            memcpy(&val, FData, 2);
            break;

        case DEVICE_DATA_SIGNED8:
        case DEVICE_DATA_SIGNED16:
        case DEVICE_DATA_SIGNED32:
        case DEVICE_DATA_FLOAT1:
        case DEVICE_DATA_FLOAT2:
        case DEVICE_DATA_FLOAT3:
        case DEVICE_DATA_FLOAT4:
            val_long = GetSigned32();
            if (val_long < 0)
                val = 0;
            else
            {
                if (val_long > 0xFFFF)
                    val = 0xFFFF;
                else
                    val = (unsigned short int)val_long;
            }
            break;

        default:
            val_ulong = GetUnsigned32();
            if (val_ulong > 0xFFFF)
                val = 0xFFFF;
            else
                                val = (unsigned short int)val_ulong;
            break;
    }
    
    return val;
}

/*##################  TDeviceVar::GetUnsigned32  ###############
*   Purpose....: Get variable a unsigned32                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
unsigned long TDeviceVar::GetUnsigned32()
{
    unsigned long val = 0;
    long val_long;
    const char *str;
    
    switch (FType)
    {
        case DEVICE_DATA_CHAR:
        case DEVICE_DATA_UNSIGNED8:
        case DEVICE_DATA_BINARY8:
                case DEVICE_DATA_BINARY16:
        case DEVICE_DATA_BOOLEAN:
        case DEVICE_DATA_BOOLARRAY:
        case DEVICE_DATA_BYTEARRAY:
            val = GetUnsigned8();
            break;

        case DEVICE_DATA_UNSIGNED16:
            val = GetUnsigned16();
            break;
        
        case DEVICE_DATA_UNSIGNED32:
            memcpy(&val, FData, 4);
            break;

        default:
            str = GetString();
            if (str)
                sscanf(str, "%lu", &val);
            else
            {
                val_long = GetSigned32();
                if (val_long < 0)
                    val = 0;
                else
                                        val = (unsigned long)val_long;
                break;
            }
    }
    return val;
}

/*##################  TDeviceVar::GetUnsignedInt  ###############
*   Purpose....: Get variable a unsigned short int                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
unsigned int TDeviceVar::GetUnsignedInt()
{
#if defined __GNUC__ || defined MSVC || defined __WATCOMC__
        return GetUnsigned32();
#else
#if sizeof(int) == 2
        return GetUnsigned16();
#else
        return GetUnsigned32();
#endif
#endif
}

/*##################  TDeviceVar::GetUnsignedShort  ###############
*   Purpose....: Get variable a unsigned short int                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
unsigned short int TDeviceVar::GetUnsignedShort()
{
        return GetUnsigned16();
}

/*##################  TDeviceVar::GetUnsignedLong  ###############
*   Purpose....: Get variable a unsigned long int                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
unsigned long TDeviceVar::GetUnsignedLong()
{
        return GetUnsigned32();
}

/*##################  TDeviceVar::GetSigned8  ###############
*   Purpose....: Get variable a signed8                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TDeviceVar::GetSigned8()
{
    char val = 0;
    long val_long;
    unsigned long val_ulong;
    
    switch (FType)
    {
        case DEVICE_DATA_CHAR:
        case DEVICE_DATA_BINARY8:
        case DEVICE_DATA_BINARY16:
                case DEVICE_DATA_BOOLEAN:
        case DEVICE_DATA_BOOLARRAY:
        case DEVICE_DATA_BYTEARRAY:
        case DEVICE_DATA_SIGNED8:
            memcpy(&val, FData, 1);
            break;

        case DEVICE_DATA_UNSIGNED8:
        case DEVICE_DATA_UNSIGNED16:
        case DEVICE_DATA_UNSIGNED32:
            val_ulong = GetUnsigned32();
            if (val_ulong > 0x7F)
                val = 0x7F;
            else
                val = (char)val_ulong;
            break;

        default:
            val_long = GetSigned32();
            if (val_long < -0x80)
                val = -0x80;
            else
            {
                if (val_long > 0x7F)
                    val = 0x7F;
                                else
                    val = (char)val_long;
            }
            break;
    }
    
    return val;
}

/*##################  TDeviceVar::GetSigned16  ###############
*   Purpose....: Get variable a signed16                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
short int TDeviceVar::GetSigned16()
{
    short int val = 0;
    long val_long;
    unsigned long val_ulong;
    
    switch (FType)
    {
        case DEVICE_DATA_CHAR:
                case DEVICE_DATA_BINARY8:
        case DEVICE_DATA_BINARY16:
        case DEVICE_DATA_BOOLEAN:
        case DEVICE_DATA_BOOLARRAY:
        case DEVICE_DATA_BYTEARRAY:
        case DEVICE_DATA_SIGNED8:
            val = GetSigned8();
            break;
        
        case DEVICE_DATA_SIGNED16:
            memcpy(&val, FData, 2);
            break;

        case DEVICE_DATA_UNSIGNED8:
        case DEVICE_DATA_UNSIGNED16:
        case DEVICE_DATA_UNSIGNED32:
            val_ulong = GetUnsigned32();
            if (val_ulong > 0x7FFF)
                val = 0x7FFF;
            else
                val = (short int)val_ulong;
            break;

        default:
            val_long = GetSigned32();
                        if (val_long < -32768)
                val = -32768;
            else
            {
                if (val_long > 0x7FFF)
                    val = 0x7FFF;
                else
                    val = (short int)val_long;
            }
            break;
    }
    
    return val;
}

/*##################  TDeviceVar::GetSigned32  ###############
*   Purpose....: Get variable a signed32                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TDeviceVar::GetSigned32()
{
        long val = 0;
        unsigned long val_ulong;
        const char *str;
    
    switch (FType)
    {
        case DEVICE_DATA_CHAR:
        case DEVICE_DATA_BINARY8:
        case DEVICE_DATA_BINARY16:
        case DEVICE_DATA_BOOLEAN:
        case DEVICE_DATA_BOOLARRAY:
        case DEVICE_DATA_BYTEARRAY:
        case DEVICE_DATA_SIGNED8:
            val = GetSigned8();
            break;

        case DEVICE_DATA_SIGNED16:
            val = GetSigned16();
            break;
        
        case DEVICE_DATA_SIGNED32:
            memcpy(&val, FData, 4);
            break;

        case DEVICE_DATA_UNSIGNED8:
        case DEVICE_DATA_UNSIGNED16:
                case DEVICE_DATA_UNSIGNED32:
            val_ulong = GetUnsigned32();
            if (val_ulong > 0x7FFFFFFF)
                val = 0x7FFFFFFF;
            else
                val = (long)val_ulong;
            break;

        case DEVICE_DATA_FLOAT1:
            memcpy(&val, FData, 4);
            val = val / 10;
            break;

        case DEVICE_DATA_FLOAT2:
            memcpy(&val, FData, 4);
            val = val / 100;
            break;

        case DEVICE_DATA_FLOAT3:
            memcpy(&val, FData, 4);
            val = val / 1000;
            break;

        case DEVICE_DATA_FLOAT4:
            memcpy(&val, FData, 4);
                        val = val / 10000;
            break;
            
        default:
            str = GetString();
            if (str)
                sscanf(str, "%ld", &val);
            break;
    }
    return val;
}

/*##################  TDeviceVar::GetSignedInt  ###############
*   Purpose....: Get variable a short int                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceVar::GetSignedInt()
{
#if defined __GNUC__ || defined MSVC || defined __WATCOMC__
        return GetSigned32();
#else
#if sizeof(int) == 2
        return GetSigned16();
#else
        return GetSigned32();
#endif
#endif
}

/*##################  TDeviceVar::GetSignedShort  ###############
*   Purpose....: Get variable a short int                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
short int TDeviceVar::GetSignedShort()
{
        return GetSigned16();
}

/*##################  TDeviceVar::GetSignedLong  ###############
*   Purpose....: Get variable a long int                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TDeviceVar::GetSignedLong()
{
        return GetSigned32();
}

/*##################  TDeviceVar::GetChar  ###############
*   Purpose....: Get variable as char                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TDeviceVar::GetChar()
{
        char val = 0;
        unsigned long val_ulong;
        long val_long;
        const char *str;

    switch (FType)
    {
        case DEVICE_DATA_BOOLEAN:
        case DEVICE_DATA_BOOLARRAY:
            if (*FData)
                val = 'T';
            else
                val = 'F';
            break;
        
        case DEVICE_DATA_CHAR:
        case DEVICE_DATA_BINARY8:
        case DEVICE_DATA_BINARY16:
        case DEVICE_DATA_BYTEARRAY:
        case DEVICE_DATA_UNSIGNED8:
        case DEVICE_DATA_SIGNED8:
            memcpy(&val, FData, 1);
            break;

        case DEVICE_DATA_UNSIGNED16:
        case DEVICE_DATA_UNSIGNED32:
            val_ulong = GetUnsigned32();
            if (val_ulong > 0xFF)
                val = 0xFF;
                        else
                val = (char)val_ulong;
            break;

        default:
            str = GetString();
            if (str)
                val = *str;
            else
            {
                val_long = GetSigned32();
                if (val_long < -0x80)
                    val = -0x80;
                else
                {
                    if (val_long > 0x7F)
                        val = 0x7F;
                    else
                        val = (char)val_long;
                }
            }
            break;
    }
    return val;
}

/*##################  TDeviceVar::GetFloat1  ###############
*   Purpose....: Get variable as float1                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TDeviceVar::GetFloat1()
{
        long val;
    
    switch (FType)
    {
        case DEVICE_DATA_FLOAT1:
            memcpy(&val, FData, 4);
            break;

        case DEVICE_DATA_FLOAT2:
            memcpy(&val, FData, 4);
            val = val / 10;
            break;

        case DEVICE_DATA_FLOAT3:
            memcpy(&val, FData, 4);
                        val = val / 100;
            break;

        case DEVICE_DATA_FLOAT4:
            memcpy(&val, FData, 4);
            val = val / 1000;
            break;
            
        default:
            val = GetSigned32();
            if (val >= 0x7FFFFFFF / 10)
                val = 0x7FFFFFFF;
            else
                val = 10 * val;
            break;
    }
    return val;
}

/*##################  TDeviceVar::GetFloat2  ###############
*   Purpose....: Get variable as float2                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TDeviceVar::GetFloat2()
{
        long val;
    
    switch (FType)
    {
        case DEVICE_DATA_FLOAT2:
            memcpy(&val, FData, 4);
            break;

        case DEVICE_DATA_FLOAT3:
            memcpy(&val, FData, 4);
            val = val / 10;
            break;

        case DEVICE_DATA_FLOAT4:
            memcpy(&val, FData, 4);
            val = val / 100;
            break;
            
        default:
            val = GetFloat1();
            if (val >= 0x7FFFFFFF / 10)
                val = 0x7FFFFFFF;
                        else
                val = 10 * val;
            break;
    }
    return val;
}

/*##################  TDeviceVar::GetFloat3  ###############
*   Purpose....: Get variable as float3                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TDeviceVar::GetFloat3()
{
        long val;
    
    switch (FType)
    {
        case DEVICE_DATA_FLOAT3:
            memcpy(&val, FData, 4);
            break;

        case DEVICE_DATA_FLOAT4:
                        memcpy(&val, FData, 4);
            val = val / 10;
            break;
            
        default:
            val = GetFloat2();
            if (val >= 0x7FFFFFFF / 10)
                val = 0x7FFFFFFF;
            else
                val = 10 * val;
            break;

    }
    return val;
}

/*##################  TDeviceVar::GetFloat4  ###############
*   Purpose....: Get variable as float4                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TDeviceVar::GetFloat4()
{
        long val;
    
    switch (FType)
    {
        case DEVICE_DATA_FLOAT4:
            memcpy(&val, FData, 4);
            break;
            
        default:
            val = GetFloat3();
            if (val >= 0x7FFFFFFF / 10)
                val = 0x7FFFFFFF;
            else
                val = 10 * val;
            break;

    }
    return val;
}

/*##################  TDeviceVar::GetJulian  ###############
*   Purpose....: Get variable as julian                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TDeviceVar::GetJulian()
{
    long val;
    
    switch (FType)
    {
                case DEVICE_DATA_JULIANDATE:
            memcpy(&val, FData, 4);
            break;

        default:
            val = 0;
            
    }
    return val;
}

/*##################  TDeviceVar::GetBinary  ###############
*   Purpose....: Get variable as binary                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
const void *TDeviceVar::GetBinary(int *size)
{
    *size = FSize;
    return FData;
}

/*##################  TDeviceVar::GetString  ###############
*   Purpose....: Get variable as string                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
const char *TDeviceVar::GetString()
{
    char tempstr[15];
    long sval;
    long rval;
    unsigned long uval;
    
    if (FStr && FAlloc == 0)
        delete FStr;
    FStr = 0;

    switch (FType)
    {
        case DEVICE_DATA_STRING8:
        case DEVICE_DATA_STRING16:
            FStr = Allocate(FSize + 1);
            memcpy(FStr, FData, FSize);
            *(FStr + FSize) = 0;
            return FStr;

        case DEVICE_DATA_CHAR:
        case DEVICE_DATA_BINARY8:
        case DEVICE_DATA_BINARY16:
        case DEVICE_DATA_BOOLEAN:
        case DEVICE_DATA_BOOLARRAY:
        case DEVICE_DATA_BYTEARRAY:
        case DEVICE_DATA_SIGNED8:
        case DEVICE_DATA_SIGNED32:
            sval = GetSigned32();
            sprintf(tempstr, "%ld", sval);
            FStr = Allocate(strlen(tempstr) + 1);
            strcpy(FStr, tempstr);
            return FStr;

        case DEVICE_DATA_UNSIGNED8:
        case DEVICE_DATA_UNSIGNED16:
        case DEVICE_DATA_UNSIGNED32:
            uval = GetUnsigned32();
            sprintf(tempstr, "%lu", uval);
            FStr = Allocate(strlen(tempstr) + 1);
            strcpy(FStr, tempstr);
            return FStr;

        case DEVICE_DATA_FLOAT1:
            memcpy(&sval, FData, 4);
            rval = sval % 10;
            sval = sval / 10;
                
            sprintf(tempstr, "%ld.%01ld", sval, rval);
            FStr = Allocate(strlen(tempstr) + 1);
            strcpy(FStr, tempstr);
            return FStr;

        case DEVICE_DATA_FLOAT2:
            memcpy(&sval, FData, 4);
            rval = sval % 100;
            sval = sval / 100;
                
            sprintf(tempstr, "%ld.%02ld", sval, rval);
            FStr = Allocate(strlen(tempstr) + 1);
            strcpy(FStr, tempstr);
            return FStr;

        case DEVICE_DATA_FLOAT3:
            memcpy(&sval, FData, 4);
            rval = sval % 1000;
            sval = sval / 1000;
                
            sprintf(tempstr, "%ld.%03ld", sval, rval);
            FStr = Allocate(strlen(tempstr) + 1);
            strcpy(FStr, tempstr);
            return FStr;

        case DEVICE_DATA_FLOAT4:
            memcpy(&sval, FData, 4);
            rval = sval % 10000;
            sval = sval / 10000;

            sprintf(tempstr, "%ld.%04ld", sval, rval);
            FStr = Allocate(strlen(tempstr) + 1);
            strcpy(FStr, tempstr);
            return FStr;

    }
    return 0;
}

/*##################  TDeviceVar::GetBoolean  ###############
*   Purpose....: Get variable as boolean                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceVar::GetBoolean()
{
        int val = 0;
        unsigned long val_ulong;
        long val_long;
        const char *str;
    
        switch (FType)
    {
        case DEVICE_DATA_BOOLEAN:
        case DEVICE_DATA_BOOLARRAY:
            if (*FData)
                val = TRUE;
            else
                val = FALSE;
            break;
        
        case DEVICE_DATA_UNSIGNED8:
        case DEVICE_DATA_UNSIGNED16:
        case DEVICE_DATA_UNSIGNED32:
            val_ulong = GetUnsigned32();
            if (val_ulong)
                return TRUE;
            else
                return FALSE;

        default:
            str = GetString();
            if (str)
                switch (*str)
                {
                    case 'T':
                                        case 'J':
                    case 'Y':
                        val = TRUE;
                        break;

                    default:
                        val = FALSE;
                        break;
                }                    
            else
            {
                val_long = GetSigned32();
                if (val_long)
                    return TRUE;
                else
                    return FALSE;
            }
            break;
    }
    return val;
}    

/*##################  TDeviceVar::GetBoolArray  ###############
*   Purpose....: Get variable as boolean array                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
const char *TDeviceVar::GetBoolArray(int *size)
{
    switch (FType)
    {
        case DEVICE_DATA_BOOLARRAY:
            *size = FSize;
            return FData;

        default:
            *size = 0;
            return 0;
    }
}

/*##################  TDeviceVar::GetByteArray  ###############
*   Purpose....: Get variable as byte array                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
const void *TDeviceVar::GetByteArray(int *size)
{
    switch (FType)
    {
        case DEVICE_DATA_BYTEARRAY:
            *size = FSize;
            return FData;

        default:
            *size = 0;
            return 0;
    }
}    

/*##################  TDeviceVar::GetID  ###############
*   Purpose....: Get ID                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceVar::GetID()
{
    return FID;
}

/*##################  TDeviceVar::GetSize  ###############
*   Purpose....: Get size of data                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceVar::GetSize()
{
    switch (FType)
    {
        case DEVICE_DATA_STRING8:
        case DEVICE_DATA_BINARY8:
        case DEVICE_DATA_BOOLARRAY:
        case DEVICE_DATA_BYTEARRAY:
            return 4 + FSize;
                
        case DEVICE_DATA_STRING16:
        case DEVICE_DATA_BINARY16:
            return 5 + FSize;

        default:
            return 3 + FSize;
    }
}

/*##################  TDeviceVar::GetData  ###############
*   Purpose....: Get data                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceVar::GetData(char *data)
{
    short int RealId = FID + DEVICE_VARIABLERANGE_LOW;
    int overhead = 0;

    memcpy(data, &RealId, 2);
    data += 2;
    memcpy(data, &FType, 1);
    data++;

    switch (FType)
    {
        case DEVICE_DATA_STRING8:
        case DEVICE_DATA_BINARY8:
        case DEVICE_DATA_BOOLARRAY:
        case DEVICE_DATA_BYTEARRAY:
                        memcpy(data, &FSize, 1);
            data++;
            overhead++;
            break;
                
        case DEVICE_DATA_STRING16:
        case DEVICE_DATA_BINARY16:
            memcpy(data, &FSize, 2);
            data += 2;
            overhead += 2;
            break;

        default:
            break;
    }
    
    memcpy(data, FData, FSize);

    return 3 + overhead + FSize;
}

/*##################  TDeviceTag::TDeviceTag  ###############
*   Purpose....: Constructor for tag                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceTag::TDeviceTag(unsigned short int ID)
{
        FAlloc = 0;
        FID = ID;
        FHead = 0;
        FCurrVar = 0;
        FCurrTag = 0;
}

/*##################  TDeviceTag::TDeviceTag  ###############
*   Purpose....: Constructor for tag                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceTag::TDeviceTag(TDeviceAlloc *alloc, unsigned short int ID)
{
        FAlloc = alloc;
        FID = ID;
        FHead = 0;
        FCurrVar = 0;
        FCurrTag = 0;
}

/*##################  TDeviceTag::TDeviceTag  ###############
*   Purpose....: Constructor for tag                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceTag::TDeviceTag(const char *data, int size, int *count)
{
        FAlloc = 0;
        Init(data, size, count);
}

/*##################  TDeviceTag::TDeviceTag  ###############
*   Purpose....: Constructor for tag                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceTag::TDeviceTag(TDeviceAlloc *alloc, const char *data, int size, int *count)
{
        FAlloc = alloc;
        Init(data, size, count);
}

/*##################  TDeviceTag::Init  ###############
*   Purpose....: Init tag from data                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::Init(const char *data, int size, int *count)
{
        unsigned short int Id;
        int used;
        TDeviceData *elem;
        int ElemSize = 1;

        FHead = 0;
        FCurrVar = 0;
        FCurrTag = 0;
        *count = 0;

        memcpy(&Id, data, 2);
        if (Id < DEVICE_TAGRANGE_LOW || Id > DEVICE_TAGRANGE_HIGH)
                return;

        FID = Id - DEVICE_TAGRANGE_LOW;

        size -= 2;
        data += 2;
        used = 2;

        while (size)
        {
                memcpy(&Id, data, 2);
                if (Id >= DEVICE_TAGRANGE_LOW && Id <= DEVICE_TAGRANGE_HIGH)
                {
                        if (ElemSize == 0)
                                return;
                        else
                        {
                            if (FAlloc)
                                elem = new(FAlloc) TDeviceTag(FAlloc, data, size, &ElemSize);
                        else
                                elem = new TDeviceTag(data, size, &ElemSize);
                                
                                Add(elem);
                                size -= ElemSize;
                                data += ElemSize;
                                used += ElemSize;
                        }
                }
                else
                {
                        if (Id >= DEVICE_VARIABLERANGE_LOW && Id <= DEVICE_VARIABLERANGE_HIGH)
                        {
                                if (ElemSize == 0)
                                        return;
                                else
                                {
                                    if (FAlloc)
                                        elem = new(FAlloc) TDeviceVar(FAlloc, data, size, &ElemSize);
                                else
                                        elem = new TDeviceVar(data, size, &ElemSize);
                                        
                                        Add(elem);
                                        size -= ElemSize;
                                        data += ElemSize;
                                        used += ElemSize;
                                }
                        }
                        else
                                if (Id  == DEVICE_TAGEND)
                                {
                                        used += 2;
                                        break;
                                }
                }
        }

        *count = used;
}

/*##################  TDeviceTag::~TDeviceTag  ###############
*   Purpose....: Destructor for tag                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceTag::~TDeviceTag()
{
    TDeviceData *elem;
    TDeviceData *next;

    if (FAlloc == 0)
    {
        elem = FHead;
        while (elem)
        {
                next = elem->FNext;
            delete elem;
            elem = next;
        }
    }   
}

/*##################  TDeviceTag::Allocate  ###############
*   Purpose....: Allocate memory                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char *TDeviceTag::Allocate(int size)
{
    if (FAlloc)
        return (char *)FAlloc->Allocate(size);
    else
        return new char[size];
}

/*##################  TDeviceTag::operator new  ###############
*   Purpose....: operator new                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void *TDeviceTag::operator new(size_t size)
{
    return ::new char[size];
}

/*##################  TDeviceTag::operator new  ###############
*   Purpose....: operator new                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void *TDeviceTag::operator new(size_t size, TDeviceAlloc *alloc)
{
    if (alloc)
        return alloc->Allocate(size);
    else
        return new char[size];
}

/*##################  TDeviceTag::IsTag  ###############
*   Purpose....: Confirm this is a tag                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceTag::IsTag()
{
    return TRUE;
}

/*##################  TDeviceTag::IsEmptyTag  ###############
*   Purpose....: Check if tag i empty                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceTag::IsEmptyTag()
{
    if (FHead)
        return FALSE;
    else
        return TRUE;
}

/*##################  TDeviceTag::Add  ###############
*   Purpose....: Add entry to tag                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::Add(TDeviceData *data)
{
    TDeviceData *elem;

    if (data)
    {
        if (FHead)
        {
            elem = FHead;
            while (elem->FNext)
                elem = elem->FNext;
                        elem->FNext = data;
        
        }
        else
                    FHead = data;

        data->FNext = 0;
    }
}

/*##################  TDeviceTag::Copy  ###############
*   Purpose....: Copy a tag                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceTag *TDeviceTag::Copy()
{
    int size;
    char *data;
    TDeviceTag *newtag;
    int count;

    size = GetSize();
        if (size)
    {
        data = new char[size];
        GetData(data);

                newtag = new TDeviceTag(data, size, &count);
        delete data;
        return newtag;
    }
    else
        return 0;
}

/*##################  TDeviceTag::Copy  ###############
*   Purpose....: Copy a tag                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceTag *TDeviceTag::Copy(TDeviceAlloc *alloc)
{
    int size;
    char *data;
    TDeviceTag *newtag;
    int count;

    size = GetSize();
        if (size)
    {
        data = new char[size];
        GetData(data);

        if (alloc)
                newtag = new(alloc) TDeviceTag(alloc, data, size, &count);
                else
                    newtag = new TDeviceTag(data, size, &count);
                    
        delete data;
        return newtag;
    }
    else
        return 0;
}

/*##################  TDeviceTag::CopyTag  ###############
*   Purpose....: Add a copy of a tag                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceTag *TDeviceTag::CopyTag(TDeviceTag *tag)
{
    int size;
    char *data;
    TDeviceTag *newtag;
        int count;

    if (tag)
    {
        size = tag->GetSize();
        if (size)
        {
            data = new char[size];
            tag->GetData(data);

            if (FAlloc)
                        newtag = new(FAlloc) TDeviceTag(FAlloc, data, size, &count);
                else
                        newtag = new TDeviceTag(data, size, &count);

            delete data;
            Add(newtag);
            return newtag;
        }
        else
            return 0;
    }
    else
        return 0;
}

/*##################  TDeviceTag::AddTag  ###############
*   Purpose....: Add a new tag                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceTag *TDeviceTag::AddTag(unsigned short int ID)
{
        TDeviceTag *Tag;

        if (FAlloc)
        Tag = new(FAlloc) TDeviceTag(FAlloc, ID);
    else
        Tag = new TDeviceTag(ID);

    Add(Tag);
    return Tag;
}

/*##################  TDeviceTag::AddNone  ###############
*   Purpose....: Add a new empty data entry                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddNone(unsigned short int ID)
{
        TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);

        Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddUnsigned8  ###############
*   Purpose....: Add a new unsigned-8 entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddUnsigned8(unsigned short int ID, unsigned char data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);

        Var->SetUnsigned8(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddUnsigned16  ###############
*   Purpose....: Add a new unsigned-16 entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddUnsigned16(unsigned short int ID, unsigned short int data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
        Var->SetUnsigned16(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddUnsigned32  ###############
*   Purpose....: Add a new unsigned-32 entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddUnsigned32(unsigned short int ID, unsigned long data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
        Var->SetUnsigned32(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddUnsignedShort  ###############
*   Purpose....: Add a new unsigned short int data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddUnsignedShort(unsigned short int ID, unsigned short int data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
        Var->SetUnsignedShort(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddUnsignedLong  ###############
*   Purpose....: Add a new unsigned long data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddUnsignedLong(unsigned short int ID, unsigned long data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
    Var->SetUnsignedLong(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddUnsignedInt  ###############
*   Purpose....: Add a new unsigned int data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddUnsignedInt(unsigned short int ID, unsigned int data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
        Var->SetUnsignedInt(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddSigned8  ###############
*   Purpose....: Add a new signed-8 data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddSigned8(unsigned short int ID, char data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
    Var->SetSigned8(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddSigned16  ###############
*   Purpose....: Add a new signed-16 data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddSigned16(unsigned short int ID, short int data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
    Var->SetSigned16(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddSigned32  ###############
*   Purpose....: Add a new signed-32 data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddSigned32(unsigned short int ID, long data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
    Var->SetSigned32(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddSignedShort  ###############
*   Purpose....: Add a new signed short int data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddSignedShort(unsigned short int ID, short int data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
    Var->SetSignedShort(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddSignedLong  ###############
*   Purpose....: Add a new signed long data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddSignedLong(unsigned short int ID, long data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
    Var->SetSignedLong(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddSignedInt  ###############
*   Purpose....: Add a new signed int data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddSignedInt(unsigned short int ID, int data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
    Var->SetSignedInt(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddChar  ###############
*   Purpose....: Add a new single char entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddChar(unsigned short int ID, char ch)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
        Var->SetChar(ch);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddFloat1  ###############
*   Purpose....: Add a new 1-decimal float                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddFloat1(unsigned short int ID, long data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
    Var->SetFloat1(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddFloat2  ###############
*   Purpose....: Add a new 2-decimal float                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddFloat2(unsigned short int ID, long data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
    Var->SetFloat2(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddFloat3  ###############
*   Purpose....: Add a new 3-decimal float                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddFloat3(unsigned short int ID, long data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
    Var->SetFloat3(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddFloat4  ###############
*   Purpose....: Add a new 4-decimal float                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddFloat4(unsigned short int ID, long data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
    Var->SetFloat4(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddJulian  ###############
*   Purpose....: Add a new julian date & time                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddJulian(unsigned short int ID, long data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
        Var->SetJulian(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddBinary  ###############
*   Purpose....: Add a new binary                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddBinary(unsigned short int ID, int size, const void *data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
    Var->SetBinary(size, data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddString  ###############
*   Purpose....: Add a new string                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddString(unsigned short int ID, const char *str)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);
        
    Var->SetString(str);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddBoolean  ###############
*   Purpose....: Add a new boolean                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddBoolean(unsigned short int ID, int data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);

    Var->SetBoolean(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddBoolArray  ###############
*   Purpose....: Add a new boolean array                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddBoolArray(unsigned short int ID, int size, const char *data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);

    Var->SetBoolArray(size, data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddByteArray  ###############
*   Purpose....: Add a new boolean array                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddByteArray(unsigned short int ID, int size, const void *data)
{
    TDeviceVar *Var;

    if (FAlloc)
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    else
        Var = new TDeviceVar(ID);

        Var->SetByteArray(size, data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::ModifyUnsignedShort  ###############
*   Purpose....: Modify unsigned short data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifyUnsignedShort(unsigned short int ID, unsigned short int data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        if (FAlloc)
            Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        else
            Var = new TDeviceVar(ID);

        Add(Var);
    }
    
    Var->SetUnsigned16(data);
    return Var;
}

/*##################  TDeviceTag::ModifyUnsignedLong  ###############
*   Purpose....: Modify unsigned long data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifyUnsignedLong(unsigned short int ID, unsigned long data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        if (FAlloc)
            Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        else
            Var = new TDeviceVar(ID);

        Add(Var);
    }
    
    Var->SetUnsigned32(data);
    return Var;
}

/*##################  TDeviceTag::ModifyUnsignedInt  ###############
*   Purpose....: Modify unsigned int data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifyUnsignedInt(unsigned short int ID, unsigned int data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        if (FAlloc)
            Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        else
            Var = new TDeviceVar(ID);

        Add(Var);
    }

#if defined __GNUC__ || defined MSVC || __WATCOMC__
    Var->SetUnsigned32(data);
#else
#if sizeof(int) == 2    
    Var->SetUnsigned16(data);
#else
    Var->SetUnsigned32(data);
#endif
#endif

    return Var;
}

/*##################  TDeviceTag::ModifySignedShort  ###############
*   Purpose....: Modify signed short data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifySignedShort(unsigned short int ID, short int data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        if (FAlloc)
            Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        else
            Var = new TDeviceVar(ID);

        Add(Var);
    }
    
    Var->SetSigned16(data);
    return Var;
}

/*##################  TDeviceTag::ModifySignedLong  ###############
*   Purpose....: Modify signed long data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifySignedLong(unsigned short int ID, long data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        if (FAlloc)
            Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        else
            Var = new TDeviceVar(ID);

        Add(Var);
    }
    
    Var->SetSigned32(data);
    return Var;
}

/*##################  TDeviceTag::ModifySignedInt  ###############
*   Purpose....: Modify signed int data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifySignedInt(unsigned short int ID, int data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        if (FAlloc)
            Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        else
            Var = new TDeviceVar(ID);

        Add(Var);
    }

#if defined __GNUC__ || defined MSVC || defined __WATCOMC__
    Var->SetSigned32(data);
#else
#if sizeof(int) == 2    
    Var->SetSigned16(data);
#else
    Var->SetSigned32(data);
#endif
#endif

    return Var;
}

/*##################  TDeviceTag::ModifyChar  ###############
*   Purpose....: Modify single char entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifyChar(unsigned short int ID, char ch)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        if (FAlloc)
            Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        else
            Var = new TDeviceVar(ID);

        Add(Var);
    }
    
        Var->SetChar(ch);
    return Var;
}

/*##################  TDeviceTag::ModifyFloat1  ###############
*   Purpose....: Modify 1-decimal float                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifyFloat1(unsigned short int ID, long data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        if (FAlloc)
            Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        else
            Var = new TDeviceVar(ID);

        Add(Var);
    }
    
    Var->SetFloat1(data);
    return Var;
}

/*##################  TDeviceTag::ModifyFloat2  ###############
*   Purpose....: Modify 2-decimal float                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifyFloat2(unsigned short int ID, long data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        if (FAlloc)
            Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        else
            Var = new TDeviceVar(ID);

        Add(Var);
    }
    
    Var->SetFloat2(data);
    return Var;
}

/*##################  TDeviceTag::ModifyFloat3  ###############
*   Purpose....: Modify 3-decimal float                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifyFloat3(unsigned short int ID, long data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        if (FAlloc)
            Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        else
            Var = new TDeviceVar(ID);

        Add(Var);
    }
    
    Var->SetFloat3(data);
    return Var;
}

/*##################  TDeviceTag::ModifyFloat4  ###############
*   Purpose....: Modify 4-decimal float                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifyFloat4(unsigned short int ID, long data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        if (FAlloc)
            Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        else
            Var = new TDeviceVar(ID);

        Add(Var);
    }
    
    Var->SetFloat4(data);
    return Var;
}

/*##################  TDeviceTag::ModifyJulian  ###############
*   Purpose....: Modify julian date & time                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifyJulian(unsigned short int ID, long data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        if (FAlloc)
            Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        else
            Var = new TDeviceVar(ID);

        Add(Var);
    }
    
        Var->SetJulian(data);
    return Var;
}

/*##################  TDeviceTag::ModifyBinary  ###############
*   Purpose....: Modify binary                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifyBinary(unsigned short int ID, int size, const void *data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        if (FAlloc)
            Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        else
            Var = new TDeviceVar(ID);

        Add(Var);
    }
    
    Var->SetBinary(size, data);
    return Var;
}

/*##################  TDeviceTag::ModifyString  ###############
*   Purpose....: Modify string                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifyString(unsigned short int ID, const char *str)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        if (FAlloc)
            Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        else
            Var = new TDeviceVar(ID);

        Add(Var);
    }
    
    Var->SetString(str);
    return Var;
}

/*##################  TDeviceTag::ModifyBoolean  ###############
*   Purpose....: Modify boolean                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifyBoolean(unsigned short int ID, int data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        if (FAlloc)
            Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        else
            Var = new TDeviceVar(ID);

        Add(Var);
    }
    
    Var->SetBoolean(data);
    return Var;
}

/*##################  TDeviceTag::ModifyBoolArray  ###############
*   Purpose....: Modify boolean array                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifyBoolArray(unsigned short int ID, int size, const char *data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        if (FAlloc)
            Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        else
            Var = new TDeviceVar(ID);

        Add(Var);
    }
    
    Var->SetBoolArray(size, data);
    return Var;
}

/*##################  TDeviceTag::ModifyByteArray  ###############
*   Purpose....: Modify boolean array                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifyByteArray(unsigned short int ID, int size, const void *data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        if (FAlloc)
            Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        else
            Var = new TDeviceVar(ID);

        Add(Var);
    }
    
        Var->SetByteArray(size, data);
    return Var;
}

/*##################  TDeviceTag::GotoFirstTag  ###############
*   Purpose....: Goto first tag                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceTag *TDeviceTag::GotoFirstTag()
{
    TDeviceData *curr;
    
    curr = FHead;

    while (curr)
    {
        if (curr->IsTag())
            break;
        else
            curr = curr->FNext;
    }

    FCurrTag = (TDeviceTag *)curr;
    return FCurrTag;
}

/*##################  TDeviceTag::GotoNextTag  ###############
*   Purpose....: Goto next tag                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceTag *TDeviceTag::GotoNextTag()
{
    TDeviceData *curr;

    curr = FCurrTag;
    
    if (curr)
        curr = curr->FNext;

    while (curr)
    {
        if (curr->IsTag())
            break;
                else
            curr = curr->FNext;
    }
    
    FCurrTag = (TDeviceTag *)curr;
    return FCurrTag;
}

/*##################  TDeviceTag::GotoFirstVar  ###############
*   Purpose....: Goto first var                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::GotoFirstVar()
{
    TDeviceData *curr;
    
    curr = FHead;

    while (curr)
    {
        if (curr->IsVar())
            break;
                else
            curr = curr->FNext;
    }

    FCurrVar = (TDeviceVar *)curr;
    return FCurrVar;
}

/*##################  TDeviceTag::GotoNextVar  ###############
*   Purpose....: Goto next var                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::GotoNextVar()
{
    TDeviceData *curr;

    curr = FCurrVar;
    
    if (curr)
        curr = curr->FNext;

    while (curr)
        {
        if (curr->IsVar())
            break;
        else
            curr = curr->FNext;
    }
    
    FCurrVar = (TDeviceVar *)curr;
    return FCurrVar;
}

/*##################  TDeviceTag::GetTag  ###############
*   Purpose....: Get tag by number                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceTag *TDeviceTag::GetTag(unsigned short int ID)
{
    TDeviceTag *Tag;

    Tag = GotoFirstTag();
    while (Tag)
    {
                if (Tag->FID == ID)
            return Tag;
        Tag = GotoNextTag();
    }
    return 0;
}

/*##################  TDeviceTag::HasEmptyTag  ###############
*   Purpose....: Check if empty tag exists                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceTag::HasEmptyTag(unsigned short int ID)
{
    TDeviceTag *Tag;

    Tag = GotoFirstTag();
    while (Tag)
    {
        if (Tag->FID == ID)
        {
                        if (Tag->IsEmptyTag())
                return TRUE;
                        else
                return FALSE;
        }
        Tag = GotoNextTag();
    }
    return FALSE;
}

/*##################  TDeviceTag::GetVar  ###############
*   Purpose....: Get var by number                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::GetVar(unsigned short int ID)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var;
        Var = GotoNextVar();
        }
    return 0;
}

/*##################  TDeviceTag::HasEmptyVar  ###############
*   Purpose....: Check if empty var exists                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceTag::HasEmptyVar(unsigned short int ID)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
        {
            if (Var->IsEmptyVar())
                return TRUE;
            else
                return FALSE;
        }
                Var = GotoNextVar();
    }
    return FALSE;
}

/*##################  TDeviceTag::GetID  ###############
*   Purpose....: Get ID                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceTag::GetID()
{
    return FID;
}

/*##################  TDeviceTag::GetUnsignedShort  ###############
*   Purpose....: Get var as unsigned short int                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
unsigned short int TDeviceTag::GetUnsignedShort(unsigned short int ID, unsigned short int Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
        while (Var)
    {
        if (Var->FID == ID)
            return Var->GetUnsignedShort();
        Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetUnsignedLong  ###############
*   Purpose....: Get var as unsigned long                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
unsigned long TDeviceTag::GetUnsignedLong(unsigned short int ID, unsigned long Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var->GetUnsignedLong();
                Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetUnsignedInt  ###############
*   Purpose....: Get var as unsigned int                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
unsigned int TDeviceTag::GetUnsignedInt(unsigned short int ID, unsigned int Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
        while (Var)
    {
        if (Var->FID == ID)
            return Var->GetUnsignedInt();
        Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetSignedShort  ###############
*   Purpose....: Get var as signed short int                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
short int TDeviceTag::GetSignedShort(unsigned short int ID, short int Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var->GetSignedShort();
        Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetSignedLong  ###############
*   Purpose....: Get var as signed long                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TDeviceTag::GetSignedLong(unsigned short int ID, long Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var->GetSignedLong();
        Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetSignedInt  ###############
*   Purpose....: Get var as signed int                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceTag::GetSignedInt(unsigned short int ID, int Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var->GetSignedInt();
        Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetChar  ###############
*   Purpose....: Get var as single char                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TDeviceTag::GetChar(unsigned short int ID, char Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var->GetChar();
        Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetFloat1  ###############
*   Purpose....: Get var as 1-decimal long                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TDeviceTag::GetFloat1(unsigned short int ID, long Default)
{
    TDeviceVar *Var;

        Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var->GetFloat1();
        Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetFloat2  ###############
*   Purpose....: Get var as 2-decimal long                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TDeviceTag::GetFloat2(unsigned short int ID, long Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
                        return Var->GetFloat2();
        Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetFloat3  ###############
*   Purpose....: Get var as 3-decimal long                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TDeviceTag::GetFloat3(unsigned short int ID, long Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var->GetFloat3();
        Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetFloat4  ###############
*   Purpose....: Get var as 4-decimal long                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TDeviceTag::GetFloat4(unsigned short int ID, long Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var->GetFloat4();
        Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetJulian  ###############
*   Purpose....: Get var as julian date & time                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TDeviceTag::GetJulian(unsigned short int ID, long Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var->GetJulian();
        Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetBinary  ###############
*   Purpose....: Get var as binary                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
const void *TDeviceTag::GetBinary(unsigned short int ID, int *size)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var->GetBinary(size);
        Var = GotoNextVar();
    }
    *size = 0;
    return 0;
}

/*##################  TDeviceTag::GetString  ###############
*   Purpose....: Get var as string                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
const char *TDeviceTag::GetString(unsigned short int ID, const char *Default)
{
        TDeviceVar *Var;
    const char *str = 0;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
        {
            str = Var->GetString();
            break;
        }
        Var = GotoNextVar();
    }

    if (str == 0)
        return Default;
    else
        return str;
}

/*##################  TDeviceTag::GetBoolean  ###############
*   Purpose....: Get var as boolean                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceTag::GetBoolean(unsigned short int ID, int Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var->GetBoolean();
        Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetBoolArray  ###############
*   Purpose....: Get var as boolean array                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
const char *TDeviceTag::GetBoolArray(unsigned short int ID, int *size)
{
        TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var->GetBoolArray(size);
        Var = GotoNextVar();
    }
    *size = 0;
    return 0;
}

/*##################  TDeviceTag::GetByteArray  ###############
*   Purpose....: Get var as byte array                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
const void *TDeviceTag::GetByteArray(unsigned short int ID, int *size)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
        while (Var)
    {
        if (Var->FID == ID)
            return Var->GetByteArray(size);
        Var = GotoNextVar();
    }
    *size = 0;
    return 0;
}

/*##################  TDeviceTag::UpdateUnsignedShort  ###############
*   Purpose....: Update unsigned short int value                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateUnsignedShort(TDeviceTag *DestTag, unsigned short int ID, unsigned short int *Val)
{
        TDeviceVar *Var;

        Var = GetVar(ID);
    if (Var)
        {
        if (Var->IsEmptyVar())
        {
            if (DestTag)
                DestTag->AddUnsignedShort(ID, *Val);
        }
        else
            *Val = Var->GetUnsignedShort();
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddUnsignedShort(ID, *Val);
}

/*##################  TDeviceTag::UpdateUnsignedLong  ###############
*   Purpose....: Update unsigned long value                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateUnsignedLong(TDeviceTag *DestTag, unsigned short int ID, unsigned long *Val)
{
        TDeviceVar *Var;

        Var = GetVar(ID);
        if (Var)
        {
                if (Var->IsEmptyVar())
                {
            if (DestTag)
                DestTag->AddUnsignedLong(ID, *Val);
        }
        else
            *Val = Var->GetUnsignedLong();
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddUnsignedLong(ID, *Val);
}

/*##################  TDeviceTag::UpdateUnsignedInt  ###############
*   Purpose....: Update unsigned int value                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateUnsignedInt(TDeviceTag *DestTag, unsigned short int ID, unsigned int *Val)
{
        TDeviceVar *Var;

        Var = GetVar(ID);
    if (Var)
        {
        if (Var->IsEmptyVar())
        {
            if (DestTag)
                DestTag->AddUnsignedInt(ID, *Val);
        }
        else
            *Val = Var->GetUnsignedInt();
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddUnsignedInt(ID, *Val);
}

/*##################  TDeviceTag::UpdateSignedShort  ###############
*   Purpose....: Update signed short int value                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateSignedShort(TDeviceTag *DestTag, unsigned short int ID, short int *Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
        {
            if (DestTag)
                DestTag->AddSignedShort(ID, *Val);
        }
        else
            *Val = Var->GetSignedShort();
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddSignedShort(ID, *Val);
}

/*##################  TDeviceTag::UpdateSignedLong  ###############
*   Purpose....: Update signed long value                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateSignedLong(TDeviceTag *DestTag, unsigned short int ID, long *Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
        {
            if (DestTag)
                DestTag->AddSignedLong(ID, *Val);
        }
        else
            *Val = Var->GetSignedLong();
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddSignedLong(ID, *Val);
}

/*##################  TDeviceTag::UpdateSignedInt  ###############
*   Purpose....: Update signed int value                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateSignedInt(TDeviceTag *DestTag, unsigned short int ID, int *Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
        {
            if (DestTag)
                DestTag->AddSignedInt(ID, *Val);
        }
        else
            *Val = Var->GetSignedInt();
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddSignedInt(ID, *Val);
}

/*##################  TDeviceTag::UpdateChar  ###############
*   Purpose....: Update char value                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateChar(TDeviceTag *DestTag, unsigned short int ID, char *Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
        {
            if (DestTag)
                DestTag->AddChar(ID, *Val);
        }
        else
            *Val = Var->GetChar();
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddChar(ID, *Val);
}

/*##################  TDeviceTag::UpdateFloat1  ###############
*   Purpose....: Update float1 value                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateFloat1(TDeviceTag *DestTag, unsigned short int ID, long *Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
        {
            if (DestTag)
                DestTag->AddFloat1(ID, *Val);
        }
        else
            *Val = Var->GetFloat1();
    }
    else
        if (DestTag && IsEmptyTag())          
                        DestTag->AddFloat1(ID, *Val);
}

/*##################  TDeviceTag::UpdateFloat2  ###############
*   Purpose....: Update float2 value                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateFloat2(TDeviceTag *DestTag, unsigned short int ID, long *Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
        {
            if (DestTag)
                DestTag->AddFloat2(ID, *Val);
        }
        else
            *Val = Var->GetFloat2();
    }
        else
        if (DestTag && IsEmptyTag())          
            DestTag->AddFloat2(ID, *Val);
}

/*##################  TDeviceTag::UpdateFloat3  ###############
*   Purpose....: Update float3 value                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateFloat3(TDeviceTag *DestTag, unsigned short int ID, long *Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
        {
            if (DestTag)
                DestTag->AddFloat3(ID, *Val);
        }
        else
                        *Val = Var->GetFloat3();
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddFloat3(ID, *Val);
}

/*##################  TDeviceTag::UpdateFloat4  ###############
*   Purpose....: Update float4 value                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateFloat4(TDeviceTag *DestTag, unsigned short int ID, long *Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
        {
            if (DestTag)
                DestTag->AddFloat4(ID, *Val);
                }
        else
            *Val = Var->GetFloat4();
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddFloat4(ID, *Val);
}

/*##################  TDeviceTag::UpdateJulian  ###############
*   Purpose....: Update julian value                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateJulian(TDeviceTag *DestTag, unsigned short int ID, long *Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
        {
                        if (DestTag)
                DestTag->AddJulian(ID, *Val);
        }
        else
            *Val = Var->GetJulian();
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddJulian(ID, *Val);
}

/*##################  TDeviceTag::UpdateBoolean  ###############
*   Purpose....: Update boolean value                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateBoolean(TDeviceTag *DestTag, unsigned short int ID, int *Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
                if (Var->IsEmptyVar())
        {
            if (DestTag)
                DestTag->AddBoolean(ID, *Val);
        }
        else
            *Val = Var->GetBoolean();
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddBoolean(ID, *Val);
}

/*##################  TDeviceTag::UpdateString  ###############
*   Purpose....: Update string                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateString(TDeviceTag *DestTag, unsigned short int ID, char **Val)
{
    TDeviceVar *Var;
        const char *str;
    
        Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
        {
            if (DestTag && (*Val))
                DestTag->AddString(ID, *Val);
        }
        else
        {
            str = Var->GetString();
            if (str)
            {
                if (*Val)
                    delete *Val;

                *Val = new char[strlen(str) + 1];
                strcpy(*Val, str);
            }         
        }
    }
    else
        if (DestTag && IsEmptyTag() && *Val)          
            DestTag->AddString(ID, *Val);
}

/*##################  TDeviceTag::UpdateUnsignedShort  ###############
*   Purpose....: Update unsigned short int value                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateUnsignedShort(TDeviceTag *DestTag, unsigned short int ID, unsigned short int Val)
{
        TDeviceVar *Var;

        Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
            if (DestTag)
                DestTag->AddUnsignedShort(ID, Val);
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddUnsignedShort(ID, Val);
}

/*##################  TDeviceTag::UpdateUnsignedLong  ###############
*   Purpose....: Update unsigned long value                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateUnsignedLong(TDeviceTag *DestTag, unsigned short int ID, unsigned long Val)
{
        TDeviceVar *Var;

        Var = GetVar(ID);
        if (Var)
        {
                if (Var->IsEmptyVar())
            if (DestTag)
                DestTag->AddUnsignedLong(ID, Val);
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddUnsignedLong(ID, Val);
}

/*##################  TDeviceTag::UpdateUnsignedInt  ###############
*   Purpose....: Update unsigned int value                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateUnsignedInt(TDeviceTag *DestTag, unsigned short int ID, unsigned int Val)
{
        TDeviceVar *Var;

        Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
            if (DestTag)
                DestTag->AddUnsignedInt(ID, Val);
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddUnsignedInt(ID, Val);
}

/*##################  TDeviceTag::UpdateSignedShort  ###############
*   Purpose....: Update signed short int value                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateSignedShort(TDeviceTag *DestTag, unsigned short int ID, short int Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
            if (DestTag)
                DestTag->AddSignedShort(ID, Val);
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddSignedShort(ID, Val);
}

/*##################  TDeviceTag::UpdateSignedLong  ###############
*   Purpose....: Update signed long value                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateSignedLong(TDeviceTag *DestTag, unsigned short int ID, long Val)
{
        TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
            if (DestTag)
                DestTag->AddSignedLong(ID, Val);
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddSignedLong(ID, Val);
}

/*##################  TDeviceTag::UpdateSignedInt  ###############
*   Purpose....: Update signed int value                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateSignedInt(TDeviceTag *DestTag, unsigned short int ID, int Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
            if (DestTag)
                DestTag->AddSignedInt(ID, Val);
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddSignedInt(ID, Val);
}

/*##################  TDeviceTag::UpdateChar  ###############
*   Purpose....: Update char value                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateChar(TDeviceTag *DestTag, unsigned short int ID, char Val)
{
    TDeviceVar *Var;
    
        Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
            if (DestTag)
                DestTag->AddChar(ID, Val);
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddChar(ID, Val);
}

/*##################  TDeviceTag::UpdateFloat1  ###############
*   Purpose....: Update float1 value                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateFloat1(TDeviceTag *DestTag, unsigned short int ID, long Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
        {
        if (Var->IsEmptyVar())
            if (DestTag)
                DestTag->AddFloat1(ID, Val);
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddFloat1(ID, Val);
}

/*##################  TDeviceTag::UpdateFloat2  ###############
*   Purpose....: Update float2 value                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateFloat2(TDeviceTag *DestTag, unsigned short int ID, long Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
                        if (DestTag)
                DestTag->AddFloat2(ID, Val);
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddFloat2(ID, Val);
}

/*##################  TDeviceTag::UpdateFloat3  ###############
*   Purpose....: Update float3 value                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateFloat3(TDeviceTag *DestTag, unsigned short int ID, long Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
            if (DestTag)
                DestTag->AddFloat3(ID, Val);
        }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddFloat3(ID, Val);
}

/*##################  TDeviceTag::UpdateFloat4  ###############
*   Purpose....: Update float4 value                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateFloat4(TDeviceTag *DestTag, unsigned short int ID, long Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
            if (DestTag)
                DestTag->AddFloat4(ID, Val);
    }
    else
                if (DestTag && IsEmptyTag())
            DestTag->AddFloat4(ID, Val);
}

/*##################  TDeviceTag::UpdateJulian  ###############
*   Purpose....: Update julian value                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateJulian(TDeviceTag *DestTag, unsigned short int ID, long Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
            if (DestTag)
                DestTag->AddJulian(ID, Val);
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddJulian(ID, Val);
}

/*##################  TDeviceTag::UpdateBoolean  ###############
*   Purpose....: Update boolean value                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateBoolean(TDeviceTag *DestTag, unsigned short int ID, int Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
            if (DestTag)
                DestTag->AddBoolean(ID, Val);
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddBoolean(ID, Val);
}

/*##################  TDeviceTag::UpdateString  ###############
*   Purpose....: Update string                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateString(TDeviceTag *DestTag, unsigned short int ID, char *Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
            if (DestTag && (*Val))
                DestTag->AddString(ID, Val);
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddString(ID, Val);
}

/*##################  TDeviceTag::GetSize  ###############
*   Purpose....: Get size of data                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceTag::GetSize()
{
        TDeviceData *elem;
    int size;

    size = 4;
    elem = FHead;
    while (elem)
    {
        size += elem->GetSize();
        elem = elem->FNext;
    }        
    
    return size;
}

/*##################  TDeviceTag::GetData  ###############
*   Purpose....: Get data                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceTag::GetData(char *data)
{
    int size;
    TDeviceData *elem;
    short int Id;

    Id = FID + DEVICE_TAGRANGE_LOW;
        memcpy(data, &Id, 2);
    size = 2;
   
    elem = FHead;
    while (elem)
    {
        size += elem->GetData(data + size);
        elem = elem->FNext;
    }        

    Id = DEVICE_TAGEND;
        memcpy(data + size, &Id, 2);
    size += 2;
        
        return size;
}

/*##################  TDeviceMsg::TDeviceMsg  ###############
*   Purpose....: Constructor for msg                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceMsg::TDeviceMsg()
{
    FDeleteOnSend = FALSE;
    FHead = 0;
    FCurrTag = 0;
    FAlloc = 0;
}

/*##################  TDeviceMsg::TDeviceMsg  ###############
*   Purpose....: Constructor for msg                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceMsg::TDeviceMsg(int MaxSize)
{
    FDeleteOnSend = FALSE;
    FHead = 0;
    FCurrTag = 0;
    FAlloc = new TDeviceAlloc(MaxSize);
}

/*##################  TDeviceMsg::~TDeviceMsg  ###############
*   Purpose....: Destructor for msg                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceMsg::~TDeviceMsg()
{
    Free();
    
    if (FAlloc)
        delete FAlloc;
}

/*##################  TDeviceMsg::GetAlloc  ###############
*   Purpose....: Get allocation object                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceAlloc *TDeviceMsg::GetAlloc()
{
    return FAlloc;
}

/*##################  TDeviceMsg::Free  ###############
*   Purpose....: Delete all entries                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceMsg::Free()
{
    TDeviceData *elem;
    TDeviceData *next;

    if (FAlloc == 0)
    {
        elem = FHead;
        while (elem)
        {
                next = elem->FNext;
            delete elem;
            elem = next;
        }
    }   


    FCurrTag = 0;
    FHead = 0;
}

/*##################  TDeviceMsg::Add  ###############
*   Purpose....: Add tag entry                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceMsg::Add(TDeviceTag *data)
{
        TDeviceData *elem;

    if (data)
    {
        if (FHead)
        {
            elem = FHead;
            while (elem->FNext)
                elem = elem->FNext;
            elem->FNext = data;
        
        }
        else
                    FHead = data;

        data->FNext = 0;
    }
}

/*##################  TDeviceMsg::AddTag  ###############
*   Purpose....: Add tag entry                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceTag *TDeviceMsg::AddTag(unsigned short int ID)
{
    TDeviceTag *tag;

    if (FAlloc)
        tag = new(FAlloc) TDeviceTag(FAlloc, ID);
    else
        tag = new TDeviceTag(ID);
        
    Add(tag);
    return tag;
}

/*##################  TDeviceMsg::CopyTag  ###############
*   Purpose....: Add a copy of a tag                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceTag *TDeviceMsg::CopyTag(TDeviceTag *tag)
{
    int size;
    char *data;
    TDeviceTag *newtag;
    int count;

    if (tag)
    {
        size = tag->GetSize();
                if (size)
        {
            data = new char[size];
            tag->GetData(data);

            if (FAlloc)
                newtag = new(FAlloc) TDeviceTag(FAlloc, data, size, &count);
            else
                newtag = new TDeviceTag(data, size, &count);
                
            Add(newtag);
            delete data;
            return newtag;
        }
    }
    return 0;
}

/*##################  TDeviceMsg::GetSize  ###############
*   Purpose....: Get size of data                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceMsg::GetSize()
{
        TDeviceData *elem;
    int size;

    size = 8;
    elem = FHead;
        while (elem)
        {
                size += elem->GetSize();
                elem = elem->FNext;
        }

        return size;
}

/*##################  TDeviceMsg::Crc ############
*   Purpose....: Calculate CRC                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
unsigned short int TDeviceMsg::Crc(const char *Data, int Size) const
{
#if !defined(MSVC) && defined(__RDOS__)
        return RdosCalcCrc(CrcHandle, 0, Data, Size);
#else

        unsigned short int Crc = 0;
        int i;
        unsigned short int Temp1, Temp2;
        char ch;

        while (Size)
        {
                ch = *Data;
                for (i = 0; i != 8; i++)
                {
                        Temp1 = (ch & 0x80) << 8;
                        Temp2 = Crc & 0x8000;
                        Crc = Crc << 1;
                        if ((Temp1 ^ Temp2) != 0)
                                Crc = Crc ^ 0x8005;
                        ch = ch << 1;
                }
                Size--;
                Data++;
        }
        return Crc;
#endif
}

/*##################  TDeviceMsg::GetData  ###############
*   Purpose....: Get data                                                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceMsg::GetData(long signature, char *data)
{
    unsigned short int CrcVal;
    int size;
        TDeviceData *elem;

        memcpy(data, &signature, 4);
        size = 6;

        elem = FHead;
        while (elem)
        {
                size += elem->GetData(data + size);
                elem = elem->FNext;
        }
        size -= 6;
        memcpy(data + 4, &size, 2);
        CrcVal = Crc(data + 6, size);
        memcpy(data + size + 6, &CrcVal, 2);

}

/*##################  TDeviceMsg::Parse  ###############
*   Purpose....: Parse data                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceMsg::Parse(long signature, const char *data, int size)
{
    unsigned short int CrcVal;
    int MsgSize = 0;
        int count;
        long sign;
        TDeviceTag *tag;

        Free();

        memcpy(&sign, data, 4);
        if (sign != signature)
                return FALSE;

        memcpy(&MsgSize, data + 4, 2);

        if (MsgSize < size - 8)
                size = MsgSize + 8;
        else
                if (MsgSize != size - 8)
                        return FALSE;

        memcpy(&CrcVal, data + MsgSize + 6, 2);
        if (CrcVal != Crc(data + 6, MsgSize))
                return FALSE;

        data += 6;
        size -= 8;

        while (size)
        {
            if (FAlloc)
                tag = new(FAlloc) TDeviceTag(FAlloc, data, size, &count);
        else
                tag = new TDeviceTag(data, size, &count);

                Add(tag);
                if (count)
                {
                        data += count;
                        size -= count;
                }
                else
                        return FALSE;
        }

        return TRUE;
}

/*##################  TDeviceMsg::GotoFirstTag  ###############
*   Purpose....: Goto first tag                                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceTag *TDeviceMsg::GotoFirstTag()
{
        FCurrTag = FHead;
        return FHead;
}

/*##################  TDeviceMsg::GotoNextTag  ###############
*   Purpose....: Goto next tag                                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceTag *TDeviceMsg::GotoNextTag()
{
    if (FCurrTag)
        FCurrTag = (TDeviceTag *)FCurrTag->FNext;

    return FCurrTag;
}

/*##################  TDeviceMsg::GetTag  ###############
*   Purpose....: Get a tag                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceTag *TDeviceMsg::GetTag(unsigned short int ID)
{
    TDeviceTag *Tag;

    Tag = GotoFirstTag();
        while (Tag)
    {
        if (Tag->FID == ID)
                        return Tag;
                Tag = GotoNextTag();
        }
        return 0;
}
