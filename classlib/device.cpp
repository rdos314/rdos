/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
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
# device.cpp
# Basic device class
#
#######################################################################*/

#if defined __GNUC__ || defined MSVC 
#include <string.h>
#else
#include <mem.h>
#endif
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "device.h"
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

TSection TDevice::FListSection;
TDevice *TDevice::FDeviceList = 0;

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

        if (FType < 0)
    {
        FSize = FType & 0x7F;
        terminate = TRUE;
    }
    else
    {
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

        if (FType < 0)
    {
        FStr = Allocate(FSize + 1);
        memcpy(FStr, FData, FSize);
        *(FStr + FSize) = 0;
        return FStr;
    }
    else
    {
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


/*##########################################################################
#
#   Name       : TDeviceDebug::TDeviceDebug
#
#   Purpose....: Virtual base class for device debugging                                           
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDeviceDebug::TDeviceDebug()
{
}

/*##########################################################################
#
#   Name       : TDeviceDebug::~TDeviceDebug
#
#   Purpose....: Destructor for device debugging                                           
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDeviceDebug::~TDeviceDebug()
{
}

/*##########################################################################
#
#   Name       : TDeviceDebug::RequestFile
#
#   Purpose....: Request a file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TDeviceDebug::RequestFile(TDevice *Device)
{
    return 0;
}

/*##########################################################################
#
#   Name       : TDeviceDebug::ReleaseFile
#
#   Purpose....: Release a file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDeviceDebug::ReleaseFile(TDevice *Device)
{
}

/*##########################################################################
#
#   Name       : TDeviceDebug::MaxFileSize
#
#   Purpose....: Get max file size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDeviceDebug::MaxFileSize()
{
    return 0;
}

/*##########################################################################
#
#   Name       : TDevice::InsertDevice
#
#   Purpose....: Insert device into m_DeviceList
#                                Should only done in constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::InsertDevice()
{
        FListSection.Enter();
        FList = FDeviceList;
        FDeviceList = this;
        FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::RemoveDevice
#
#   Purpose....: Remove device from m_DeviceList                   
#                                Should only done in destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::RemoveDevice()
{
        TDevice *ptr;
        TDevice *prev;
        prev = 0;
        FListSection.Enter();
        ptr = FDeviceList;
        while ((ptr != 0) && (ptr != this))
        {
                prev = ptr;
                ptr = ptr->FList;
    }
        if (prev == 0)
                FDeviceList = FDeviceList->FList;
        else
                prev->FList = ptr->FList;
        FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::GetDevice
#
#   Purpose....: Get first device in list                                           
#
#   In params..: DeviceCallb
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::GetDevices(void (*DeviceCallb)(TDevice *Device))
{
        TDevice *ptr;
        FListSection.Enter();
        ptr = FDeviceList;
        while (ptr != 0)
        {
                (*DeviceCallb)(ptr);
                ptr = ptr->FList;
        }
        FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::TDevice
#
#   Purpose....: Constructor for TDevice                                          
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDevice::TDevice()
{
        FIniSection = 0;
        Init();
}

/*##########################################################################
#
#   Name       : TDevice::TDevice
#
#   Purpose....: Constructor for TDevice                                          
#
#   In params..: IniSection to read parameters from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDevice::TDevice(const char *IniSection)
{
        FIniSection = IniSection;
        Init();
}

/*##########################################################################
#
#   Name       : TDevice::~TDevice
#
#   Purpose....: Destructor for TDevice                                   
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDevice::~TDevice()
{
    if (FName)
        delete FName;
        
        RemoveDevice();
}

/*##########################################################################
#
#   Name       : TDevice::Init
#
#   Purpose....: Init method for class. register persistent should              
#                                done here.                                                                    
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Init()
{
    FRemoteUnitList = 0;
    FVirtUnitList = 0;
    FPhysUnit = 0;

    FRemote = FALSE;

    FDebug = 0;
    FDebugFile = 0;

    FName = 0;
        FReset = FALSE;
        FOpen = FALSE;
        FEnabled = FALSE;
        FOnline = FALSE;
        FBusy = FALSE;
        OnOnline = 0;
        OnOffline = 0;
        OnIdle = 0;
        OnBusy = 0;
        OnStateChange = 0;
        InsertDevice();
}

/*##########################################################################
#
#   Name       : TDevice::NotifyStateChange
#
#   Purpose....: Notify of state change
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyStateChange()
{
        if (OnStateChange)
            (*OnStateChange)(this);
}

/*##########################################################################
#
#   Name       : TDevice::NotifyReset
#
#   Purpose....: Notify of system reset                                             
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyReset()
{
        FReset = TRUE;
}

/*##########################################################################
#
#   Name       : TDevice::IsReseted
#
#   Purpose....: Check if device is reseted                                                                 #
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if reseted
#
##########################################################################*/
int TDevice::IsReseted() const
{
        return FReset;
}

/*##########################################################################
#
#   Name       : TDevice::ClearReset
#
#   Purpose....: Clear reset indication
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::ClearReset()
{
        FReset = FALSE;
}

/*##########################################################################
#
#   Name       : TDevice::DeviceName
#
#   Purpose....: Default devicename
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::DeviceName(char *Name, int MaxLen) const
{
    if (FName)
        strncpy(Name, FName, MaxLen);
    else
                strncpy(Name, "NO NAME", MaxLen);
        Name[MaxLen-1] = 0;
}

/*##########################################################################
#
#   Name       : TDevice::NotifyOpen
#
#   Purpose....: Notify open                                                       
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyOpen()
{
    FOpen = TRUE;
}

/*##########################################################################
#
#   Name       : TDevice::Open
#
#   Purpose....: Opens device                                                              
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Open()
{
    FPropertySection.Enter();
    if (!FOpen)
    {
        NotifyOpen();
        NotifyStateChange();

        AddBoolean(FPhysUnit, DEVICE_TAG_INFO, DEVICE_VAR_Open, FOpen);    
        AddBoolean(FVirtUnitList, DEVICE_TAG_INFO, DEVICE_VAR_Open, FOpen);
        AddBoolean(FRemoteUnitList, DEVICE_TAG_INFO, DEVICE_VAR_Open, FOpen);

        SignalMsg(FPhysUnit);
        SignalMsg(FVirtUnitList);
        SignalMsg(FRemoteUnitList);
    }
    FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::NotifyClose
#
#   Purpose....: Notify close                                                      
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyClose()
{
    FOpen = FALSE;
}

/*##########################################################################
#
#   Name       : TDevice::Close
#
#   Purpose....: Closes device                                                             
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Close()
{
    FPropertySection.Enter();
    if (FOpen)
    {
        NotifyClose();
        NotifyStateChange();

        AddBoolean(FPhysUnit, DEVICE_TAG_INFO, DEVICE_VAR_Open, FOpen);    
        AddBoolean(FVirtUnitList, DEVICE_TAG_INFO, DEVICE_VAR_Open, FOpen);
        AddBoolean(FRemoteUnitList, DEVICE_TAG_INFO, DEVICE_VAR_Open, FOpen);

        SignalMsg(FPhysUnit);
        SignalMsg(FVirtUnitList);
        SignalMsg(FRemoteUnitList);
        }
        FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::IsOpen
#
#   Purpose....: Checks if device is open
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if open
#
##########################################################################*/
int TDevice::IsOpen() const
{
        return FOpen;
}

/*##########################################################################
#
#   Name       : TDevice::NotifyEnable
#
#   Purpose....: Notify enable
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyEnable()
{
    FEnabled = TRUE;
}

/*##########################################################################
#
#   Name       : TDevice::Enable
#
#   Purpose....: Enables device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Enable()
{
    FPropertySection.Enter();
    if (!FEnabled)
    {
        NotifyEnable();
        NotifyStateChange();

        if (!FRemote)
            AddBoolean(FPhysUnit, DEVICE_TAG_INFO, DEVICE_VAR_Enabled, FEnabled);

        AddBoolean(FVirtUnitList, DEVICE_TAG_INFO, DEVICE_VAR_Enabled, FEnabled);
        AddBoolean(FRemoteUnitList, DEVICE_TAG_INFO, DEVICE_VAR_Enabled, FEnabled);

        SignalMsg(FPhysUnit);
        SignalMsg(FVirtUnitList);
        SignalMsg(FRemoteUnitList);
    }
    FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::NotifyDisable
#
#   Purpose....: Notify disable
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyDisable()
{
    FEnabled = FALSE;
}

/*##########################################################################
#
#   Name       : TDevice::Disable
#
#   Purpose....: Disables device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Disable()
{
    FPropertySection.Enter();
    if (FEnabled)
    {
        NotifyDisable();
        NotifyStateChange();

        if (!FRemote)
            AddBoolean(FPhysUnit, DEVICE_TAG_INFO, DEVICE_VAR_Enabled, FEnabled);

        AddBoolean(FVirtUnitList, DEVICE_TAG_INFO, DEVICE_VAR_Enabled, FEnabled);
        AddBoolean(FRemoteUnitList, DEVICE_TAG_INFO, DEVICE_VAR_Enabled, FEnabled);

        SignalMsg(FPhysUnit);
        SignalMsg(FVirtUnitList);
        SignalMsg(FRemoteUnitList);
    }
    FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::IsEnabled
#
#   Purpose....: Checks if device is enabled
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if enabled
#
##########################################################################*/
int TDevice::IsEnabled() const
{
        return FEnabled;
}

/*##########################################################################
#
#   Name       : TDevice::Online
#
#   Purpose....: Sets state to online
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Online()
{
    FPropertySection.Enter();
        if (!FOnline)
        {
        FOnline = TRUE;
            if (OnOnline)
                    OnOnline(this);
        NotifyStateChange();

        AddBoolean(FVirtUnitList, DEVICE_TAG_INFO, DEVICE_VAR_Online, FOnline);
        AddBoolean(FRemoteUnitList, DEVICE_TAG_INFO, DEVICE_VAR_Online, FOnline);

        SignalMsg(FVirtUnitList);
        SignalMsg(FRemoteUnitList);
        }
        FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::Offline
#
#   Purpose....: Sets state to offline
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Offline()
{
    FPropertySection.Enter();
        if (FOnline)
        {
                FOnline = FALSE;
                if (OnOffline)
                        OnOffline(this);
        NotifyStateChange();

        AddBoolean(FVirtUnitList, DEVICE_TAG_INFO, DEVICE_VAR_Online, FOnline);
        AddBoolean(FRemoteUnitList, DEVICE_TAG_INFO, DEVICE_VAR_Online, FOnline);

        SignalMsg(FVirtUnitList);
        SignalMsg(FRemoteUnitList);
        }
        FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::IsOnline
#
#   Purpose....: Checks if device is online
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if online
#
##########################################################################*/
int TDevice::IsOnline() const
{
        if (FPhysUnit)
                return FPhysUnit->IsOnline() && FOnline;
    else
        return FOnline;
}

/*##########################################################################
#
#   Name       : TDevice::IsActive
#
#   Purpose....: Checks if device is open and enabled
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if open and enabled
#
##########################################################################*/
int TDevice::IsActive() const
{
        return FEnabled && FOpen;
}

/*##########################################################################
#
#   Name       : TDevice::NotifyIdle
#
#   Purpose....: Notify idle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyIdle()
{
        FBusy = FALSE;
        if (OnIdle)
                OnIdle(this);
}

/*##########################################################################
#
#   Name       : TDevice::Idle
#
#   Purpose....: Sets device to idle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Idle()
{
    FPropertySection.Enter();
        if (FBusy)
    {
        NotifyIdle();
        NotifyStateChange();

        if (!FRemote)
            AddBoolean(FPhysUnit, DEVICE_TAG_INFO, DEVICE_VAR_Busy, FBusy);

        AddBoolean(FVirtUnitList, DEVICE_TAG_INFO, DEVICE_VAR_Busy, FBusy);
        AddBoolean(FRemoteUnitList, DEVICE_TAG_INFO, DEVICE_VAR_Busy, FBusy);

        SignalMsg(FPhysUnit);
        SignalMsg(FVirtUnitList);
        SignalMsg(FRemoteUnitList);
        }
        FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::NotifyBusy
#
#   Purpose....: Notify busy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::NotifyBusy()
{
        FBusy = TRUE;
        if (OnBusy)
                OnBusy(this);
}

/*##########################################################################
#
#   Name       : TDevice::Busy
#
#   Purpose....: Sets device to busy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Busy()
{
    FPropertySection.Enter();
        if (!FBusy)
        {
            NotifyBusy();
        NotifyStateChange();

        if (!FRemote)
            AddBoolean(FPhysUnit, DEVICE_TAG_INFO, DEVICE_VAR_Busy, FBusy);

        AddBoolean(FVirtUnitList, DEVICE_TAG_INFO, DEVICE_VAR_Busy, FBusy);
        AddBoolean(FRemoteUnitList, DEVICE_TAG_INFO, DEVICE_VAR_Busy, FBusy);

        SignalMsg(FPhysUnit);
        SignalMsg(FVirtUnitList);
        SignalMsg(FRemoteUnitList);
        }
        FPropertySection.Leave();
}

/*##########################################################################
#
#   Name       : TDevice::IsBusy
#
#   Purpose....: Check if device is busy
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if busy
#
##########################################################################*/
int TDevice::IsBusy() const
{
        return FBusy;
}

/*##########################################################################
#
#   Name       : TDevice::GetUnitType
#
#   Purpose....: Get unit type
#
#   In params..: *
#   Out params.: *
#   Returns....: Unit type
#
##########################################################################*/
short int TDevice::GetUnitType()
{
        return 0;
}

/*##########################################################################
#
#   Name       : TDevice::GetUnitNumber
#
#   Purpose....: Get unit number
#
#   In params..: *
#   Out params.: *
#   Returns....: Unit number
#
##########################################################################*/
short int TDevice::GetUnitNumber()
{
        return 0;
}

/*##########################################################################
#
#   Name       : TDevice::Install
#
#   Purpose....: Install device debug
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Install(TDeviceDebug *Debug)
{
    FDebug = Debug;
}

/*##########################################################################
#
#   Name       : TDevice::StartDebug
#
#   Purpose....: Starts device debugging
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::StartDebug()
{
    if (FDebug)
        FDebugFile = FDebug->RequestFile(this);
}

/*##########################################################################
#
#   Name       : TDevice::StopDebug
#
#   Purpose....: Stops device debugging
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::StopDebug()
{
    if (FDebug)
        FDebug->ReleaseFile(this);

    FDebugFile = 0;
}

/*##########################################################################
#
#   Name       : TDevice::GetMaxMsgSize
#
#   Purpose....: Get max size of message
#
#   In params..: *
#   Out params.: *
#   Returns....: Unit type
#
##########################################################################*/
int TDevice::GetMaxMsgSize()
{
        return 0x40000;
}

/*##########################################################################
#
#   Name       : TDevice::IsModifyTag
#
#   Purpose....: Check if variables should be added or updated
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
int TDevice::IsModifyTag(unsigned short int TAG)
{
    if (TAG == DEVICE_TAG_INFO)
        return TRUE;
    else
        return FALSE;
}

/*##################  TDevice::AddNone  ###############
*   Purpose....: Add a new empty data entry                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddNone(TDistUnit *unit, unsigned short int TAG, unsigned short int ID)
{
    TDeviceTag *tag;
    
    while (unit)
        {
            tag = unit->LockTag(TAG);
            if (tag)
            {
            tag->AddNone(ID);
            unit->UnlockTag();
        }
        unit = unit->GetNextUnit();
    }
}

/*##################  TDevice::AddUnsignedShort  ###############
*   Purpose....: Add a new unsigned short int data entry                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddUnsignedShort(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, unsigned short int data)
{
        TDeviceTag *tag;

        while (unit)
        {
                tag = unit->LockTag(TAG);
                if (tag)
                {
                        if (IsModifyTag(TAG))
                                tag->ModifyUnsignedShort(ID, data);
                        else
                                tag->AddUnsignedShort(ID, data);
                        unit->UnlockTag();
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddUnsignedLong  ###############
*   Purpose....: Add a new unsigned long data entry                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddUnsignedLong(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, unsigned long data)
{
        TDeviceTag *tag;

        while (unit)
        {
                tag = unit->LockTag(TAG);
                if (tag)
                {
                        if (IsModifyTag(TAG))
                                tag->ModifyUnsignedLong(ID, data);
                        else
                                tag->AddUnsignedLong(ID, data);
                        unit->UnlockTag();
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddUnsignedInt  ###############
*   Purpose....: Add a new unsigned int data entry                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddUnsignedInt(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, unsigned int data)
{
        TDeviceTag *tag;

        while (unit)
        {
                tag = unit->LockTag(TAG);
                if (tag)
                {
                        if (IsModifyTag(TAG))
                                tag->ModifyUnsignedInt(ID, data);
                        else
                                tag->AddUnsignedInt(ID, data);
                        unit->UnlockTag();
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddSignedShort  ###############
*   Purpose....: Add a new signed short int data entry                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddSignedShort(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, short int data)
{
        TDeviceTag *tag;

        while (unit)
        {
                tag = unit->LockTag(TAG);
                if (tag)
                {
                        if (IsModifyTag(TAG))
                                tag->ModifySignedShort(ID, data);
                        else
                                tag->AddSignedShort(ID, data);
                        unit->UnlockTag();
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddSignedLong  ###############
*   Purpose....: Add a new signed long data entry                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddSignedLong(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, long data)
{
        TDeviceTag *tag;

        while (unit)
        {
                tag = unit->LockTag(TAG);
                if (tag)
                {
                        if (IsModifyTag(TAG))
                                tag->ModifySignedLong(ID, data);
                        else
                                tag->AddSignedLong(ID, data);
                        unit->UnlockTag();
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddSignedInt  ###############
*   Purpose....: Add a new signed int data entry                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddSignedInt(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, int data)
{
        TDeviceTag *tag;

        while (unit)
        {
                tag = unit->LockTag(TAG);
                if (tag)
                {
                        if (IsModifyTag(TAG))
                                tag->ModifySignedInt(ID, data);
                        else
                                tag->AddSignedInt(ID, data);
                        unit->UnlockTag();
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddChar  ###############
*   Purpose....: Add a new single char data entry                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddChar(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, char ch)
{
        TDeviceTag *tag;

        while (unit)
        {
                tag = unit->LockTag(TAG);
                if (tag)
                {
                        if (IsModifyTag(TAG))
                                tag->ModifyChar(ID, ch);
                        else
                                tag->AddChar(ID, ch);
                        unit->UnlockTag();
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddFloat1  ###############
*   Purpose....: Add a new 1-decimal float entry                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddFloat1(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, long data)
{
        TDeviceTag *tag;

        while (unit)
        {
                tag = unit->LockTag(TAG);
                if (tag)
                {
                        if (IsModifyTag(TAG))
                                tag->ModifyFloat1(ID, data);
                        else
                                tag->AddFloat1(ID, data);
                        unit->UnlockTag();
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddFloat2  ###############
*   Purpose....: Add a new 2-decimal float entry                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddFloat2(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, long data)
{
        TDeviceTag *tag;

        while (unit)
        {
                tag = unit->LockTag(TAG);
                if (tag)
                {
                        if (IsModifyTag(TAG))
                                tag->ModifyFloat2(ID, data);
                        else
                                tag->AddFloat2(ID, data);
                        unit->UnlockTag();
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddFloat3  ###############
*   Purpose....: Add a new 3-decimal float entry                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddFloat3(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, long data)
{
        TDeviceTag *tag;

        while (unit)
        {
                tag = unit->LockTag(TAG);
                if (tag)
                {
                        if (IsModifyTag(TAG))
                                tag->ModifyFloat3(ID, data);
                        else
                                tag->AddFloat3(ID, data);
                        unit->UnlockTag();
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddFloat4  ###############
*   Purpose....: Add a new 4-decimal float entry                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddFloat4(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, long data)
{
        TDeviceTag *tag;

        while (unit)
        {
                tag = unit->LockTag(TAG);
                if (tag)
                {
                        if (IsModifyTag(TAG))
                                tag->ModifyFloat4(ID, data);
                        else
                                tag->AddFloat4(ID, data);
                        unit->UnlockTag();
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddJulian  ###############
*   Purpose....: Add a new julian data & time                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddJulian(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, long data)
{
        TDeviceTag *tag;

        while (unit)
        {
                tag = unit->LockTag(TAG);
                if (tag)
                {
                        if (IsModifyTag(TAG))
                                tag->ModifyJulian(ID, data);
                        else
                                tag->AddJulian(ID, data);
                        unit->UnlockTag();
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddBinary  ###############
*   Purpose....: Add a new binary                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddBinary(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, int size, const void *data)
{
        TDeviceTag *tag;

        while (unit)
        {
                tag = unit->LockTag(TAG);
                if (tag)
                {
                        tag->AddBinary(ID, size, data);
                        unit->UnlockTag();
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddString  ###############
*   Purpose....: Add a new string                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddString(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, const char *str)
{
        TDeviceTag *tag;

        while (unit)
        {
                tag = unit->LockTag(TAG);
                if (tag)
                {
                        if (IsModifyTag(TAG))
                                tag->ModifyString(ID, str);
                        else
                                tag->AddString(ID, str);
                        unit->UnlockTag();
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddBoolean  ###############
*   Purpose....: Add a new boolean                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddBoolean(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, int data)
{
        TDeviceTag *tag;

        while (unit)
        {
                tag = unit->LockTag(TAG);
                if (tag)
                {
                        if (IsModifyTag(TAG))
                                tag->ModifyBoolean(ID, data);
                        else
                                tag->AddBoolean(ID, data);
                        unit->UnlockTag();
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddBoolArray  ###############
*   Purpose....: Add a new boolean array                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddBoolArray(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, int size, const char *data)
{
        TDeviceTag *tag;

        while (unit)
        {
                tag = unit->LockTag(TAG);
                if (tag)
                {
                        tag->AddBoolArray(ID, size, data);
                        unit->UnlockTag();
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddByteArray  ###############
*   Purpose....: Add a new byte array                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddByteArray(TDistUnit *unit, unsigned short int TAG, unsigned short int ID, int size, const void *data)
{
        TDeviceTag *tag;

        while (unit)
        {
                tag = unit->LockTag(TAG);
                if (tag)
                {
                        tag->AddByteArray(ID, size, data);
                        unit->UnlockTag();
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddNone  ###############
*   Purpose....: Add a new empty data entry                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddNone(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID)
{
    TDeviceTag *tag;
    
    while (unit)
        {
            if (unit != exclude)
            {
            tag = unit->LockTag(TAG);
                if (tag)
                {
                tag->AddNone(ID);
                unit->UnlockTag();
            }
        }
        unit = unit->GetNextUnit();
    }
}

/*##################  TDevice::AddUnsignedShort  ###############
*   Purpose....: Add a new unsigned short int data entry                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddUnsignedShort(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, unsigned short int data)
{
        TDeviceTag *tag;

        while (unit)
        {
            if (unit != exclude)
            {
                tag = unit->LockTag(TAG);
                if (tag)
                    {
                            if (IsModifyTag(TAG))
                                tag->ModifyUnsignedShort(ID, data);
                        else
                                tag->AddUnsignedShort(ID, data);
                        unit->UnlockTag();
                }
            }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddUnsignedLong  ###############
*   Purpose....: Add a new unsigned long data entry                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddUnsignedLong(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, unsigned long data)
{
        TDeviceTag *tag;

        while (unit)
        {
            if (unit != exclude)
            {
                tag = unit->LockTag(TAG);
                if (tag)
                    {
                        if (IsModifyTag(TAG))
                                tag->ModifyUnsignedLong(ID, data);
                        else
                                tag->AddUnsignedLong(ID, data);
                        unit->UnlockTag();
                }
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddUnsignedInt  ###############
*   Purpose....: Add a new unsigned int data entry                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddUnsignedInt(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, unsigned int data)
{
        TDeviceTag *tag;

        while (unit)
        {
            if (unit != exclude)
            {
                tag = unit->LockTag(TAG);
                if (tag)
                    {
                        if (IsModifyTag(TAG))
                                tag->ModifyUnsignedInt(ID, data);
                        else
                                tag->AddUnsignedInt(ID, data);
                        unit->UnlockTag();
                    }
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddSignedShort  ###############
*   Purpose....: Add a new signed short int data entry                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddSignedShort(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, short int data)
{
        TDeviceTag *tag;

        while (unit)
        {
            if (unit != exclude)
            {
                tag = unit->LockTag(TAG);
                if (tag)
                    {
                        if (IsModifyTag(TAG))
                                tag->ModifySignedShort(ID, data);
                        else
                                tag->AddSignedShort(ID, data);
                        unit->UnlockTag();
                }
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddSignedLong  ###############
*   Purpose....: Add a new signed long data entry                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddSignedLong(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, long data)
{
        TDeviceTag *tag;

        while (unit)
        {
            if (unit != exclude)
            {
                tag = unit->LockTag(TAG);
                if (tag)
                    {
                            if (IsModifyTag(TAG))
                                tag->ModifySignedLong(ID, data);
                        else
                                tag->AddSignedLong(ID, data);
                            unit->UnlockTag();
                        }
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddSignedInt  ###############
*   Purpose....: Add a new signed int data entry                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddSignedInt(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, int data)
{
        TDeviceTag *tag;

        while (unit)
        {
            if (unit != exclude)
            {
                tag = unit->LockTag(TAG);
                if (tag)
                    {
                            if (IsModifyTag(TAG))
                                    tag->ModifySignedInt(ID, data);
                        else
                                tag->AddSignedInt(ID, data);
                        unit->UnlockTag();
                    }
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddChar  ###############
*   Purpose....: Add a new single char data entry                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddChar(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, char ch)
{
        TDeviceTag *tag;

        while (unit)
        {
            if (unit != exclude)
            {
                tag = unit->LockTag(TAG);
                if (tag)
                    {
                        if (IsModifyTag(TAG))
                                tag->ModifyChar(ID, ch);
                        else
                                tag->AddChar(ID, ch);
                        unit->UnlockTag();
                }
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddFloat1  ###############
*   Purpose....: Add a new 1-decimal float entry                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddFloat1(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, long data)
{
        TDeviceTag *tag;

        while (unit)
        {
            if (unit != exclude)
            {
                tag = unit->LockTag(TAG);
                if (tag)
                    {
                            if (IsModifyTag(TAG))
                                    tag->ModifyFloat1(ID, data);
                        else
                                tag->AddFloat1(ID, data);
                        unit->UnlockTag();
                    }
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddFloat2  ###############
*   Purpose....: Add a new 2-decimal float entry                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddFloat2(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, long data)
{
        TDeviceTag *tag;

        while (unit)
        {
            if (unit != exclude)
            {
                tag = unit->LockTag(TAG);
                if (tag)
                    {
                            if (IsModifyTag(TAG))
                                    tag->ModifyFloat2(ID, data);
                        else
                                tag->AddFloat2(ID, data);
                        unit->UnlockTag();
                    }
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddFloat3  ###############
*   Purpose....: Add a new 3-decimal float entry                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddFloat3(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, long data)
{
        TDeviceTag *tag;

        while (unit)
        {
            if (unit != exclude)
            {
                tag = unit->LockTag(TAG);
                if (tag)
                    {
                            if (IsModifyTag(TAG))
                                tag->ModifyFloat3(ID, data);
                        else
                                tag->AddFloat3(ID, data);
                            unit->UnlockTag();
                        }
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddFloat4  ###############
*   Purpose....: Add a new 4-decimal float entry                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddFloat4(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, long data)
{
        TDeviceTag *tag;

        while (unit)
        {
            if (unit != exclude)
            {
                tag = unit->LockTag(TAG);
                if (tag)
                    {
                            if (IsModifyTag(TAG))
                                    tag->ModifyFloat4(ID, data);
                        else
                                tag->AddFloat4(ID, data);
                        unit->UnlockTag();
                    }
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddJulian  ###############
*   Purpose....: Add a new julian data & time                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddJulian(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, long data)
{
        TDeviceTag *tag;

        while (unit)
        {
            if (unit != exclude)
            {
                tag = unit->LockTag(TAG);
                if (tag)
                    {
                            if (IsModifyTag(TAG))
                                    tag->ModifyJulian(ID, data);
                        else
                                tag->AddJulian(ID, data);
                        unit->UnlockTag();
                    }
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddBinary  ###############
*   Purpose....: Add a new binary                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddBinary(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, int size, const void *data)
{
        TDeviceTag *tag;

        while (unit)
        {
            if (unit != exclude)
            {
                tag = unit->LockTag(TAG);
                if (tag)
                    {
                            tag->AddBinary(ID, size, data);
                        unit->UnlockTag();
                }
            }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddString  ###############
*   Purpose....: Add a new string                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddString(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, const char *str)
{
        TDeviceTag *tag;

        while (unit)
        {
            if (unit != exclude)
            {
                tag = unit->LockTag(TAG);
                if (tag)
                    {
                            if (IsModifyTag(TAG))
                                    tag->ModifyString(ID, str);
                        else
                                tag->AddString(ID, str);
                        unit->UnlockTag();
                    }
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddBoolean  ###############
*   Purpose....: Add a new boolean                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddBoolean(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, int data)
{
        TDeviceTag *tag;

        while (unit)
        {
            if (unit != exclude)
            {
                tag = unit->LockTag(TAG);
                if (tag)
                    {
                            if (IsModifyTag(TAG))
                                    tag->ModifyBoolean(ID, data);
                        else
                                tag->AddBoolean(ID, data);
                        unit->UnlockTag();
                    }
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddBoolArray  ###############
*   Purpose....: Add a new boolean array                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddBoolArray(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, int size, const char *data)
{
        TDeviceTag *tag;

        while (unit)
        {
            if (unit != exclude)
            {
                tag = unit->LockTag(TAG);
                if (tag)
                    {
                            tag->AddBoolArray(ID, size, data);
                        unit->UnlockTag();
                }
            }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::AddByteArray  ###############
*   Purpose....: Add a new byte array                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::AddByteArray(TDistUnit *unit, TDistUnit *exclude, unsigned short int TAG, unsigned short int ID, int size, const void *data)
{
        TDeviceTag *tag;

        while (unit)
        {
            if (unit != exclude)
            {
                tag = unit->LockTag(TAG);
                if (tag)
                    {
                        tag->AddByteArray(ID, size, data);
                        unit->UnlockTag();
                    }
                }
                unit = unit->GetNextUnit();
        }
}

/*##################  TDevice::SignalMsg  ###############
*   Purpose....: Signal new message                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDevice::SignalMsg(TDistUnit *unit)
{
        while (unit)
        {
                unit->SignalMsg();
                unit = unit->GetNextUnit();
        }
}

/*##########################################################################
#
#   Name       : TDevice::CreateResetTag
#
#   Purpose....: Create a reset tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::CreateResetTag(TDistUnit *unit)
{
        TDeviceTag *tag;

        if (!FRemote)
        {
        tag = unit->LockInfoTag();

        tag->ModifyBoolean(DEVICE_VAR_Open, FOpen);
            tag->ModifyBoolean(DEVICE_VAR_Enabled, FEnabled);

        unit->UnlockTag();
            unit->SignalMsg();
        }
}

/*##########################################################################
#
#   Name       : TDevice::CreateInstallTag
#
#   Purpose....: Create an install tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::CreateInstallTag(TDeviceTag *tag)
{
        char str[101];

        DeviceName(str, 100);

        tag->AddBoolean(DEVICE_VAR_Open, FOpen);
        tag->AddBoolean(DEVICE_VAR_Enabled, FEnabled);
        tag->AddBoolean(DEVICE_VAR_Online, FOnline);
        tag->AddBoolean(DEVICE_VAR_Busy, FBusy);
        tag->AddString(DEVICE_VAR_Name, str);
}

/*##########################################################################
#
#   Name       : TDevice::CreateInstallTag
#
#   Purpose....: Create an install tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::CreateInstallTag(TDistUnit *unit)
{
        TDeviceTag *tag;

    tag = unit->LockInstallTag();
    CreateInstallTag(tag);
    unit->UnlockTag();
    unit->SignalMsg();
}

/*##########################################################################
#
#   Name       : TDevice::NotifyResetTag
#
#   Purpose....: Notify reset tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::NotifyResetTag(TDistUnit *unit)
{
    if (FPhysUnit != unit)
        CreateInstallTag(unit);
}

/*##########################################################################
#
#   Name       : TDevice::NotifyReqTag
#
#   Purpose....: Notify req tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::NotifyReqTag(TDistUnit *unit, TDeviceTag *reqtag, TDeviceTag *replytag)
{
}

/*##########################################################################
#
#   Name       : TDevice::NotifyReplyTag
#
#   Purpose....: Notify req tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::NotifyReplyTag(TDistUnit *unit, TDeviceTag *tag)
{
}

/*##########################################################################
#
#   Name       : TDevice::NotifyInfoTag
#
#   Purpose....: Notify info tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::NotifyInfoTag(TDistUnit *unit, TDeviceTag *tag)
{
    int Val;

    Val = tag->GetBoolean(DEVICE_VAR_Open, FOpen);

    if (Val != FOpen)
    {
        if (Val)
            NotifyOpen();
        else
            NotifyClose();

        AddBoolean(FPhysUnit, unit, DEVICE_TAG_INFO, DEVICE_VAR_Open, FOpen);
        AddBoolean(FVirtUnitList, unit, DEVICE_TAG_INFO, DEVICE_VAR_Open, FOpen);
        AddBoolean(FRemoteUnitList, unit, DEVICE_TAG_INFO, DEVICE_VAR_Open, FOpen);
    }

    Val = tag->GetBoolean(DEVICE_VAR_Enabled, FEnabled);

    if (Val != FEnabled)
    {
        if (Val)
            NotifyEnable();
        else
            NotifyDisable();

        AddBoolean(FPhysUnit, unit, DEVICE_TAG_INFO, DEVICE_VAR_Enabled, FEnabled);
        AddBoolean(FVirtUnitList, unit, DEVICE_TAG_INFO, DEVICE_VAR_Enabled, FEnabled);
        AddBoolean(FRemoteUnitList, unit, DEVICE_TAG_INFO, DEVICE_VAR_Enabled, FEnabled);
    }

    Val = tag->GetBoolean(DEVICE_VAR_Online, FOnline);

    if (Val != FOnline)
    {
        if (Val)
            Online();
        else
            Offline();

        AddBoolean(FRemoteUnitList, unit, DEVICE_TAG_INFO, DEVICE_VAR_Online, FOnline);
    }

    Val = tag->GetBoolean(DEVICE_VAR_Busy, FBusy);

    if (Val != FBusy)
    {
        if (Val)
            NotifyBusy();
        else
            NotifyIdle();

        AddBoolean(FPhysUnit, unit, DEVICE_TAG_INFO, DEVICE_VAR_Busy, FBusy);
        AddBoolean(FVirtUnitList, unit, DEVICE_TAG_INFO, DEVICE_VAR_Busy, FBusy);
        AddBoolean(FRemoteUnitList, unit, DEVICE_TAG_INFO, DEVICE_VAR_Busy, FBusy);
    }    
}

/*##########################################################################
#
#   Name       : TDevice::NotifyInstallTag
#
#   Purpose....: Notify install tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::NotifyInstallTag(TDistUnit *unit, TDeviceTag *tag)
{
    int Val;
    TDeviceTag *resptag = 0;
    const char *ptr;
    int len;

    Val = tag->GetBoolean(DEVICE_VAR_Open, FOpen);

    if (FRemote)
        FOpen = Val;
    else
    {
        if (Val != FOpen)
        {
                resptag = unit->LockInfoTag();
                resptag->ModifyBoolean(DEVICE_VAR_Open, FOpen);
        }
    }

    Val = tag->GetBoolean(DEVICE_VAR_Enabled, FEnabled);

    if (FRemote)
        FEnabled = Val;
    else
    {
        if (Val != FEnabled)
        {
            if (!resptag)
                resptag = unit->LockInfoTag();
                resptag->ModifyBoolean(DEVICE_VAR_Enabled, FEnabled);
        }
    }

    Val = tag->GetBoolean(DEVICE_VAR_Online, FOnline);

    if (Val != FOnline)
    {
        if (Val)
            Online();
        else
            Offline();
    }

    Val = tag->GetBoolean(DEVICE_VAR_Busy, FBusy);

    if (Val != FBusy)
    {
        if (Val)
            Busy();
        else
            Idle();
    }    

    ptr = tag->GetString(DEVICE_VAR_Name, "");
    len = strlen(ptr);
    if (len)
    {
        if (FName)
            delete FName;
            
        FName = new char[len + 1];
        strcpy(FName, ptr);
    }

    if (resptag)
    {
        unit->UnlockTag();
        unit->SignalMsg();
    }
}

/*##########################################################################
#
#   Name       : TDistUnit::TDistUnit
#
#   Purpose....: Constructor for class                                         
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDistUnit::TDistUnit(TDistSystem *DistSystem)
{
        FDistSystem = DistSystem;
        FDistSystem->InsertUnit(this);
        FPhysical = TRUE;

        Init();
}


/*##########################################################################
#
#   Name       : TDistUnit::TDistUnit
#
#   Purpose....: Constructor for class
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDistUnit::TDistUnit(TDistSystem *DistSystem, short int UnitType, short int UnitNumber)
{
        FUnitType = UnitType;
        FUnitNumber = UnitNumber;

        FDistSystem = DistSystem;
        FDistSystem->InsertNoBlockUnit(this);
        FPhysical = FALSE;

        Init();
}

/*##########################################################################
#
#   Name       : TDistUnit::~TDistUnit
#
#   Purpose....: Destructor for TDistUnit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDistUnit::~TDistUnit()
{
    if (FCurrMsg)
        delete FCurrMsg;

    if (FAcceptMsg)
        delete FAcceptMsg;

    if (FAckMsg)
        delete FAckMsg;

        if (FMsg)
        delete FMsg;

        if (FDistSystem)
                FDistSystem->RemoveUnit(this);

    if (FInstallAlloc)
        delete FInstallAlloc;

    if (FPendingInstallTag)
        delete FPendingInstallTag;        

    if (FReplyAlloc)
        delete FReplyAlloc;
}

/*##########################################################################
#
#   Name       : TDistUnit::Init
#
#   Purpose....: Init object                                     
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistUnit::Init()
{
    FAckMsg = 0;
    FAcceptMsg = 0;
    FCurrMsg = 0;
    FReqTag = 0;
    FReplyTag = 0;
    FInfoTag = 0;
    FInstallTag = 0;
    FCurrID = 1;
    FCurrReqID = 0;
    FCurrInfoID = 0;
    FCurrInstallID = 0;
    FCurrAcceptID = 0;
    FReqID = 0;
    FInfoID = 0;
    FInstallID = 0;
    FAcceptID = 0;
        FMsg = 0;
        FDevice = 0;
        FNext = 0;
        FInstalled = FALSE;
        FOnline = FALSE;

    FInstallAlloc = 0;
    FPendingInstallTag = 0;

    FReplyAlloc = 0;
    FLastReplyTag = 0;
    FLastReplyID = 0;

    FAllowMsg = !(FDistSystem->FIsRemote && FPhysical);
}

/*##########################################################################
#
#   Name       : TDistUnit::DefineDevice
#
#   Purpose....: Define device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistUnit::DefineDevice(TDevice *Device)
{
    FDevice = Device;
}

/*##########################################################################
#
#   Name       : TDistUnit::IsRemote
#
#   Purpose....: Is this a remote unit?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDistUnit::IsRemote()
{
    return FDistSystem->FIsRemote;
}

/*##########################################################################
#
#   Name       : TDistUnit::Online
#
#   Purpose....: Set state to online
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistUnit::Online()
{
    if (!FOnline)
    {
        FOnline = TRUE;

        FAllowMsg = !(FDistSystem->FIsRemote && FPhysical);
        
        if (FDevice)
        {
            ClearQueues();

            if (FDevice->FPhysUnit != this)
            {
                FInstalled = TRUE;
                        FDevice->CreateInstallTag(this);
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TDistUnit::Offline
#
#   Purpose....: Set state to offline
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistUnit::Offline()
{
    if (FOnline)
    {
        FOnline = FALSE;
        FInstalled = FALSE;

        ClearQueues();

        FAllowMsg = !(FDistSystem->FIsRemote && FPhysical);
            
            if (FDevice)
                    FDevice->NotifyResetTag(this);
    }
}

/*##########################################################################
#
#   Name       : TDistUnit::IsOnline
#
#   Purpose....: Check if online
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDistUnit::IsOnline()
{
    return FOnline;
}

/*##########################################################################
#
#   Name       : TDistUnit::IsInstalled
#
#   Purpose....: Check if installed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDistUnit::IsInstalled()
{
    return FInstalled;
}

/*##########################################################################
#
#   Name       : TDistUnit::GetUnitType
#
#   Purpose....: Get unit type
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
short int TDistUnit::GetUnitType()
{
        if (FDevice)
                return FDevice->GetUnitType();
        else
                return FUnitType;
}

/*##########################################################################
#
#   Name       : TDistUnit::GetUnitNumber
#
#   Purpose....: Get unit number
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
short int TDistUnit::GetUnitNumber()
{
    if (FDevice)
        return FDevice->GetUnitNumber();
    else
        return FUnitNumber;
}

/*##########################################################################
#
#   Name       : TDistUnit::GetNextUnit
#
#   Purpose....: Get next unit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDistUnit *TDistUnit::GetNextUnit()
{
    return FNext;
}

/*##########################################################################
#
#   Name       : TDistUnit::ResetCurrMsg
#
#   Purpose....: Reset current message
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::ResetCurrMsg()
{
    FReqTag = 0;
    FReplyTag = 0;
    FInfoTag = 0;
    FInstallTag = 0;
                
    FCurrReqID = 0;
    FCurrInfoID = 0;
    FCurrInstallID = 0;
    FCurrAcceptID = 0;
}

/*##########################################################################
#
#   Name       : TDistUnit::ClearQueues
#
#   Purpose....: Clear message queues
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::ClearQueues()
{
        FMsgSection.Enter();

        if (FMsg)
                delete FMsg;
        FMsg = 0;

        if (FCurrMsg)
                delete FCurrMsg;
        FCurrMsg = 0;

        if (FAckMsg)
            delete FAckMsg;
        FAckMsg = 0;

        if (FAcceptMsg)
            delete FAcceptMsg;
        FAcceptMsg = 0;

    if (FReplyAlloc)
        delete FReplyAlloc;
    FReplyAlloc = 0;

    FLastReplyTag = 0;

        ResetCurrMsg();

        FReqID = 0;
        FInfoID = 0;
        FInstallID = 0;
        FAcceptID = 0;
    FLastReplyID = 0;

        FMsgSection.Leave();
}

/*##########################################################################
#
#   Name       : TDistUnit::CreateMsg
#
#   Purpose....: Create a new message
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::CreateMsg()
{
    TDeviceTag *tag;

        if (FDistSystem)
        {
                if (FCurrMsg)
                        delete FCurrMsg;

        if (FDevice)
                FCurrMsg = new TDeviceMsg(FDevice->GetMaxMsgSize());
        else
                FCurrMsg = new TDeviceMsg(1024);

                tag = FCurrMsg->AddTag(DEVICE_TAG_HEADER);
                tag->AddSignedShort(DEVICE_VAR_UnitType, GetUnitType());
                tag->AddSignedShort(DEVICE_VAR_UnitID, GetUnitNumber());

                if (FDevice)
                {
                        if (FDevice->FPhysUnit)
                                tag->AddBoolean(DEVICE_VAR_PhysicalDevice, FALSE);
                        else
                    tag->AddBoolean(DEVICE_VAR_PhysicalDevice, TRUE);
        }
        else
                tag->AddBoolean(DEVICE_VAR_PhysicalDevice, FALSE);

                FReqTag = 0;
                FInfoTag = 0;
                FInstallTag = 0;
        }
}

/*##########################################################################
#
#   Name       : TDistUnit::CreateAcceptMsg
#
#   Purpose....: Create a new accept message
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::CreateAcceptMsg()
{
    TDeviceTag *tag;

        if (FDistSystem && FDevice)
        {
                if (FAcceptMsg)
                        delete FAcceptMsg;

        FAcceptMsg = new TDeviceMsg(FDevice->GetMaxMsgSize());

                tag = FAcceptMsg->AddTag(DEVICE_TAG_HEADER);
                tag->AddSignedShort(DEVICE_VAR_UnitType, GetUnitType());
                tag->AddSignedShort(DEVICE_VAR_UnitID, GetUnitNumber());

        if (FDevice->FPhysUnit)
                tag->AddBoolean(DEVICE_VAR_PhysicalDevice, FALSE);
        else
                tag->AddBoolean(DEVICE_VAR_PhysicalDevice, TRUE);
        }
}

/*##########################################################################
#
#   Name       : TDistUnit::CreateAckMsg
#
#   Purpose....: Create a new ACK message
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::CreateAckMsg()
{
    TDeviceTag *tag;

        if (FDistSystem)
        {
                if (FAckMsg)
                        delete FAckMsg;

                if (FDevice)
                        FAckMsg = new TDeviceMsg(FDevice->GetMaxMsgSize());
                else
                        FAckMsg = new TDeviceMsg(1024);

                tag = FAckMsg->AddTag(DEVICE_TAG_HEADER);
                tag->AddSignedShort(DEVICE_VAR_UnitType, GetUnitType());
                tag->AddSignedShort(DEVICE_VAR_UnitID, GetUnitNumber());

        if (FDevice)
        {
                if (FDevice->FPhysUnit)
                        tag->AddBoolean(DEVICE_VAR_PhysicalDevice, FALSE);
            else
                    tag->AddBoolean(DEVICE_VAR_PhysicalDevice, TRUE);
        }
        else
                tag->AddBoolean(DEVICE_VAR_PhysicalDevice, FALSE);
        
                FReplyTag = 0;
        }
}

/*##########################################################################
#
#   Name       : TDistUnit::IncMsgID
#
#   Purpose....: Increment message ID
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::IncMsgID()
{
    FCurrID++;

    if (FCurrID <= 0)
        FCurrID = 1;
}

/*##########################################################################
#
#   Name       : TDistUnit::CreateAckTag
#
#   Purpose....: Create ack tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::CreateAckTag(TDeviceTag *SrcTag)
{
    short int ID;
        TDeviceTag *tag;

        ID = SrcTag->GetSignedShort(DEVICE_VAR_MsgID, 0);

        if (FDistSystem && ID)
        {
                FMsgSection.Enter();

                if (!FAckMsg)
                        CreateAckMsg();

                if (FAckMsg)
                {
                        tag = FAckMsg->AddTag(DEVICE_TAG_ACK);
                        tag->AddSignedShort(DEVICE_VAR_MsgID, ID);
                }

                FMsgSection.Leave();
        }
}

/*##########################################################################
#
#   Name       : TDistUnit::CreateAcceptTag
#
#   Purpose....: Create install ack tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::CreateAcceptTag()
{
        TDeviceTag *tag;

        if (FDistSystem)
        {
                FMsgSection.Enter();

        if (!FAcceptMsg)
            CreateAcceptMsg();

                if (FAcceptMsg)
                {
                        tag = FAcceptMsg->AddTag(DEVICE_TAG_INSTALL_ACCEPT);
                        tag->AddSignedShort(DEVICE_VAR_MsgID, FCurrID);
            FCurrAcceptID = FCurrID;
            IncMsgID();
                }

                FMsgSection.Leave();
        }
}

/*##########################################################################
#
#   Name       : TDistUnit::LockReqTag
#
#   Purpose....: Lock req tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
TDeviceTag *TDistUnit::LockReqTag()
{
        if (FDistSystem && FAllowMsg)
    {
        FMsgSection.Enter();

        if (!FCurrMsg)
            CreateMsg();

        if (FCurrMsg)
        {
            if (!FReqTag)
            {
                FReqTag = FCurrMsg->AddTag(DEVICE_TAG_REQ);
                                FReqTag->AddSignedShort(DEVICE_VAR_MsgID, FCurrID);
                FCurrReqID = FCurrID;
                IncMsgID();
            }

                    return FReqTag;
                }
                else
                    FMsgSection.Leave();
        }
        
        return 0;
}

/*##########################################################################
#
#   Name       : TDistUnit::LockReplyTag
#
#   Purpose....: Lock reply tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
TDeviceTag *TDistUnit::LockReplyTag(unsigned short int ID)
{
        if (FDistSystem && FAllowMsg)
        {
                FMsgSection.Enter();

                if (!FAckMsg)
                    CreateAckMsg();

                if (FAckMsg)
                {
                        if (!FReplyTag)
                        {
                                FReplyTag = FAckMsg->AddTag(DEVICE_TAG_REPLY);
                                FReplyTag->AddSignedShort(DEVICE_VAR_MsgID, ID);
                        }

                        return FReplyTag;
                }
                else
                    FMsgSection.Leave();
        }
        
        return 0;
}

/*##########################################################################
#
#   Name       : TDistUnit::LockInfoTag
#
#   Purpose....: Lock info tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
TDeviceTag *TDistUnit::LockInfoTag()
{
        if (FDistSystem && FAllowMsg)
        {
        FMsgSection.Enter();

        if (!FCurrMsg)
            CreateMsg();

        if (FCurrMsg)
        {
            if (!FInfoTag)
            {
                FInfoTag = FCurrMsg->AddTag(DEVICE_TAG_INFO);
                                FInfoTag->AddSignedShort(DEVICE_VAR_MsgID, FCurrID);
                FCurrInfoID = FCurrID;
                IncMsgID();
            }

                    return FInfoTag;
                }
                else
                    FMsgSection.Leave();
        }
        
        return 0;
}

/*##########################################################################
#
#   Name       : TDistUnit::LockInstallTag
#
#   Purpose....: Lock install tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
TDeviceTag *TDistUnit::LockInstallTag()
{
        if (FDistSystem)
    {
        FMsgSection.Enter();

        if (!FCurrMsg)
            CreateMsg();

        if (FCurrMsg)
        {
            if (!FInstallTag)
            {
                FInstallTag = FCurrMsg->AddTag(DEVICE_TAG_INSTALL_REQ);
                                FInstallTag->AddSignedShort(DEVICE_VAR_MsgID, FCurrID);
                                FCurrInstallID = FCurrID;
                IncMsgID();
            }

                    return FInstallTag;
                }
                else
                    FMsgSection.Leave();
        }
        
        return 0;
}

/*##########################################################################
#
#   Name       : TDistUnit::LockTag
#
#   Purpose....: Lock tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
TDeviceTag *TDistUnit::LockTag(unsigned short int TAG)
{
    switch (TAG)
    {
        case DEVICE_TAG_REQ:
            return LockReqTag();

//      case DEVICE_TAG_REPLY:
//              return LockReplyTag();

        case DEVICE_TAG_INFO:
            return LockInfoTag();

        case DEVICE_TAG_INSTALL_REQ:
            return LockInstallTag();
    }

    return 0;
}

/*##########################################################################
#
#   Name       : TDistUnit::UnlockTag
#
#   Purpose....: Unlock tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::UnlockTag()
{
    if (FDistSystem)
        FMsgSection.Leave();
}

/*##########################################################################
#
#   Name       : TDistUnit::SignalMsg
#
#   Purpose....: Signal new message
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::SignalMsg()
{
        if (FDistSystem)
                FDistSystem->SignalMsg();
}

/*##########################################################################
#
#   Name       : TDistUnit::HandleAckTag
#
#   Purpose....: Handle an ACK tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::HandleAckTag(TDeviceTag *Tag)
{
        short int ID = Tag->GetSignedShort(DEVICE_VAR_MsgID, 0);

    if (FInfoID == ID)
        FInfoID = 0;

    if (FInstallID == ID)
        FInstallID = 0;

    if (FAcceptID == ID)
    {
                FInstalled = TRUE;
        FAcceptID = 0;

                if (FDevice)
                FDevice->CreateResetTag(this);
    }
}

/*##########################################################################
#
#   Name       : TDistUnit::HandleReqTag
#
#   Purpose....: Handle an REQ tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::HandleReqTag(TDeviceTag *Tag)
{
        short int ID = Tag->GetSignedShort(DEVICE_VAR_MsgID, 0);
        TDeviceTag *replytag;

        if (FDevice)
        {
        if (FLastReplyID == ID)
        {
            FMsgSection.Enter();
            
                if (!FAckMsg)
                    CreateAckMsg();

                if (FAckMsg)
                    FReplyTag = FAckMsg->CopyTag(FLastReplyTag);

            FMsgSection.Leave();
            
                SignalMsg();    
        }
        else
        {
                replytag = LockReplyTag(ID);
                UnlockTag();
                    FDevice->NotifyReqTag(this, Tag, replytag);

            if (FReplyAlloc)
                delete FReplyAlloc;

            if (FDevice)
                                FReplyAlloc = new TDeviceAlloc(FDevice->GetMaxMsgSize());
                else
                FReplyAlloc = new TDeviceAlloc(4096);
                
            FLastReplyTag = replytag->Copy(FReplyAlloc);
            FLastReplyID = ID;
            
                SignalMsg();    
        }
        }
}

/*##########################################################################
#
#   Name       : TDistUnit::HandleReplyTag
#
#   Purpose....: Handle an REPLY tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::HandleReplyTag(TDeviceTag *Tag)
{
        short int ID = Tag->GetSignedShort(DEVICE_VAR_MsgID, 0);

        if (FReqID == ID && FDevice)
        {
            FReqID = 0;
            FDevice->NotifyReplyTag(this, Tag);
        }  
}

/*##########################################################################
#
#   Name       : TDistUnit::HandleInfoTag
#
#   Purpose....: Handle an INFO tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::HandleInfoTag(TDeviceTag *Tag)
{
        if (FDevice)
                FDevice->NotifyInfoTag(this, Tag);
}

/*##########################################################################
#
#   Name       : TDistUnit::HandleInstallTag
#
#   Purpose....: Handle an INSTALL req tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::HandleInstallTag()
{
    ClearQueues();

        if (FDevice && FPendingInstallTag)
        {
                FDevice->NotifyInstallTag(this, FPendingInstallTag);

                FPendingInstallTag = 0;

                if (FInstallAlloc)
                delete FInstallAlloc;
        FInstallAlloc = 0;

        CreateAcceptTag();
        SignalMsg();
        }
}

/*##########################################################################
#
#   Name       : TDistUnit::HandleInstallTag
#
#   Purpose....: Handle an INSTALL req tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::HandleInstallTag(TDeviceTag *Tag)
{
    ClearQueues();

        if (FDevice)
        {
                FDevice->NotifyInstallTag(this, Tag);
        CreateAcceptTag();
    }
    else
    {
        if (FInstallAlloc)
            delete FInstallAlloc;

        if (FDevice)
                FInstallAlloc = new TDeviceAlloc(FDevice->GetMaxMsgSize());
        else
            FInstallAlloc = new TDeviceAlloc(4096);
            
                FPendingInstallTag = Tag->Copy(FInstallAlloc);
        }
}

/*##########################################################################
#
#   Name       : TDistUnit::HandleAcceptTag
#
#   Purpose....: Handle an INSTALL accept tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::HandleAcceptTag(TDeviceTag *Tag)
{
    FAllowMsg = TRUE;
}

/*##########################################################################
#
#   Name       : TDistUnit::HandleMsg
#
#   Purpose....: Handle a new message
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDistUnit::HandleMsg(TDeviceMsg *Msg)
{
        TDeviceTag *tag;

        tag = Msg->GotoFirstTag();

        while (tag)
        {
                switch (tag->GetID())
                {
                        case DEVICE_TAG_ACK:
                                HandleAckTag(tag);
                                break;

                        case DEVICE_TAG_REQ:
                            if (FInstalled)
                                HandleReqTag(tag);
                                break;

                        case DEVICE_TAG_REPLY:
                            if (FInstalled)
                                HandleReplyTag(tag);
                                break;

                        case DEVICE_TAG_INFO:
                            if (FInstalled)
                            {
                                HandleInfoTag(tag);
                                CreateAckTag(tag);
                        }
                                break;

                        case DEVICE_TAG_INSTALL_REQ:
                                HandleInstallTag(tag);
                                CreateAckTag(tag);
                                break;

                        case DEVICE_TAG_INSTALL_ACCEPT:
                            FInstalled = TRUE;
                                HandleAcceptTag(tag);
                                CreateAckTag(tag);
                                break;

                        default:
                                break;
                }
                tag = Msg->GotoNextTag();
        }

        if (FReqID == 0 && FInfoID == 0 && FInstallID == 0 && FAcceptID == 0)
        {
            FMsgSection.Enter();
            
                if (FMsg)
                        delete FMsg;

                FMsg = 0;

                FMsgSection.Leave();
        }

        SignalMsg();
}

/*##########################################################################
#
#   Name       : TDistUnit::GetMsg
#
#   Purpose....: Get message to send
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
TDeviceMsg *TDistUnit::GetMsg()
{
    TDeviceMsg *msg = 0;
    
        if (FDistSystem)
    {
                if (FAckMsg)
        {
                FMsgSection.Enter();

            msg = FAckMsg;
            FAckMsg = 0;
         
            FMsgSection.Leave();

            if (msg)
                msg->FDeleteOnSend = TRUE;

            return msg;
        }

        if (FMsg)
        {
            if (FMsg->FResend.HasExpired())
            {
                        FMsg->FResend = TDateTime();
                                FMsg->FResend.AddMilli(FDistSystem->GetTimeout());

                return FMsg;
            }
        }

        if (FAcceptMsg)
        {
                msg = 0;
                FMsgSection.Enter();

                if (FMsg == 0)
                {
                FMsg = FAcceptMsg;
                msg = FMsg;
                FAcceptMsg = 0;

                FAcceptID = FCurrAcceptID;
                FCurrAcceptID = 0;
            }
         
            FMsgSection.Leave();

            if (msg)
            {
                msg->FResend = TDateTime();
                msg->FResend.AddMilli(FDistSystem->GetTimeout());
                return msg;
            }
        }

        if (FDevice && FInstalled && FCurrMsg)
        {
            msg = 0;
            FMsgSection.Enter();

            if (FMsg == 0)
            {
                FMsg = FCurrMsg;
                msg = FMsg;

                FReqID = FCurrReqID;
                        FInfoID = FCurrInfoID;
                FInstallID = FCurrInstallID;

                    FCurrMsg = 0;

                ResetCurrMsg();
            }

            FMsgSection.Leave();

            if (msg)
            {
                msg->FResend = TDateTime();
                                msg->FResend.AddMilli(FDistSystem->GetTimeout());
                return msg;
            }
            }
        }

        return 0;
}

/*##########################################################################
#
#   Name       : TDeviceConfig::TDeviceConfig
#
#   Purpose....: Constructor for device configuration
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDeviceConfig::TDeviceConfig(unsigned short int UnitType, unsigned short int UnitNumber, int MaxSize)
{
        TDeviceTag *tag;

        FConfigMsg = new TDeviceMsg(MaxSize);

        tag = FConfigMsg->AddTag(DEVICE_TAG_HEADER);
        tag->AddSignedShort(DEVICE_VAR_UnitType, UnitType);
        tag->AddSignedShort(DEVICE_VAR_UnitID, UnitNumber);

        FConfigTag = FConfigMsg->AddTag(DEVICE_TAG_CONFIG_REQ);

        FUnitType = UnitType;
        FUnitNumber = UnitNumber;
        FActive = FALSE;
}

/*##########################################################################
#
#   Name       : TDeviceConfig::~TDeviceConfig
#
#   Purpose....: Destructor for device configuration
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDeviceConfig::~TDeviceConfig()
{
    delete FConfigMsg;
}

/*##########################################################################
#
#   Name       : TDeviceConfig::GetConfigTag
#
#   Purpose....: Get configuration tag
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDeviceTag *TDeviceConfig::GetConfigTag()
{
    return FConfigTag;
}

/*##########################################################################
#
#   Name       : TDistSystem::InsertUnit
#
#   Purpose....: Insert unit into list of active units
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::InsertUnit(TDistUnit *unit)
{
    FHasUnits = TRUE;

        FUnitSection.Enter();
        unit->FList = FUnitList;
        FUnitList = unit;
        FUnitSection.Leave();
}

/*##########################################################################
#
#   Name       : TDistSystem::InsertNoBlockUnit
#
#   Purpose....: Insert unit into list of active units, don't take section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::InsertNoBlockUnit(TDistUnit *unit)
{
    FHasUnits = TRUE;

        unit->FList = FUnitList;
        FUnitList = unit;
}

/*##########################################################################
#
#   Name       : TDistSystem::RemoveUnit
#
#   Purpose....: Remove unit from list of active units                  
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::RemoveUnit(TDistUnit *unit)
{
        TDistUnit *ptr;
        TDistUnit *prev;
        prev = 0;
        
        FUnitSection.Enter();

        ptr = FUnitList;
        while ((ptr != 0) && (ptr != unit))
        {
                prev = ptr;
                ptr = ptr->FList;
    }
    
        if (prev == 0)
                FUnitList = FUnitList->FList;
        else
                prev->FList = ptr->FList;
                
        FUnitSection.Leave();
}

/*##########################################################################
#
#   Name       : TDistSystem::TDistSystem
#
#   Purpose....: Constructor for TDistSystem                                      
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDistSystem::TDistSystem(TDistDevice *DistDevice, long Signature)
{
        FSignature = Signature;
        FDistDevice = DistDevice;

        Init();
}

/*##########################################################################
#
#   Name       : TDistSystem::TDistSystem
#
#   Purpose....: Constructor for TDistSystem                                      
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDistSystem::TDistSystem(TDistDevice *DistDevice, long s1, long s2, long s3, long s4)
{
    long sign;

    sign = s1 | (s2 << 8) | (s3 << 16) | (s4 << 24);

        FSignature = sign;
        FDistDevice = DistDevice;

        Init();
}

/*##########################################################################
#
#   Name       : TDistSystem::Init
#
#   Purpose....: Init TDistSystem                                         
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::Init()
{
        OnConfig = 0;
        OnMsg = 0;
        FOnline = FALSE;
        FHasUnits = FALSE;
        FMsgQueue = 0;
        FUnitList = 0;
        FConfigList = 0;
        FPendingPoll = FALSE;
        FPendingResetReq = TRUE;
        FPendingResetAck = FALSE;
        FIsRemote = FALSE;

        FDistDevice->AddSystem(this);
}

/*##########################################################################
#
#   Name       : TDistSystem::~TDistSystem
#
#   Purpose....: Destructor for TDistSystem
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDistSystem::~TDistSystem()
{
}

/*##########################################################################
#
#   Name       : TDistSystem::DefineAsVirtual
#
#   Purpose....: Define this side as virtual device provider, e.g. terminal side
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::DefineAsVirtual()
{
    FIsRemote = FALSE;
}

/*##########################################################################
#
#   Name       : TDistSystem::DefineAsRemote
#
#   Purpose....: Define this side as remote device listener
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::DefineAsRemote()
{
    FIsRemote = TRUE;
}

/*##########################################################################
#
#   Name       : TDistSystem::GetSignature
#
#   Purpose....: Get signature of system
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
long TDistSystem::GetSignature()
{
    return FSignature;
}

/*##########################################################################
#
#   Name       : TDistSystem::InsertConfig
#
#   Purpose....: Insert configuration into list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::InsertConfig(TDeviceConfig *config)
{
        FConfigSection.Enter();
        config->FNext = FConfigList;
        FConfigList = config;
        FConfigSection.Leave();
}

/*##########################################################################
#
#   Name       : TDistSystem::RemoveConfig
#
#   Purpose....: Remove configuration from list                  
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::RemoveConfig(TDeviceConfig *config)
{
        TDeviceConfig *ptr;
        TDeviceConfig *prev;
        prev = 0;
        
        FConfigSection.Enter();

        ptr = FConfigList;
        while ((ptr != 0) && (ptr != config))
        {
                prev = ptr;
                ptr = ptr->FNext;
    }
    
        if (prev == 0)
                FConfigList = FConfigList->FNext;
        else
                prev->FNext = ptr->FNext;
                
        FConfigSection.Leave();
}

/*##########################################################################
#
#   Name       : TDistSystem::HasConfig
#
#   Purpose....: Check if config is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDistSystem::HasConfig(unsigned short int UnitType, unsigned short int UnitNumber)
{
        TDeviceConfig *ptr;
        int ok;

        FConfigSection.Enter();

        ok = FALSE;
        ptr = FConfigList;
        while (!ok && ptr)
        {
                if (ptr->FUnitType == UnitType && ptr->FUnitNumber == UnitNumber)
                        ok = TRUE;
                ptr = ptr->FNext;
        }

        FConfigSection.Leave();

        return ok;
}

/*##########################################################################
#
#   Name       : TDistSystem::Config
#
#   Purpose....: Configure device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::Config(TDeviceConfig *config)
{
        TDeviceConfig *ptr;

        FConfigSection.Enter();

        ptr = FConfigList;
        while (ptr)
        {
                if (ptr->FUnitType == config->FUnitType && ptr->FUnitNumber == config->FUnitNumber)
                {
                        RemoveConfig(ptr);
                    delete ptr;
                    break;
                }
                ptr = ptr->FNext;
        }

        FConfigSection.Leave();

    InsertConfig(config);
    config->FActive = TRUE;
}

/*##########################################################################
#
#   Name       : TDistSystem::IsOnline
#
#   Purpose....: Check if online
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDistSystem::IsOnline()
{
    return FOnline;
}

/*##########################################################################
#
#   Name       : TDistSystem::Online
#
#   Purpose....: Sets state to online
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::Online()
{
        TDistUnit *ptr;

        if (!FOnline)
        {
            FOnline = TRUE;

        FUnitSection.Enter();

        ptr = FUnitList;
            while (ptr)
        {
            ptr->Online();
            ptr = ptr->FList;
            }

        FUnitSection.Leave();
        }
}

/*##########################################################################
#
#   Name       : TDistSystem::Offline
#
#   Purpose....: Sets state to offline
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::Offline()
{
        TDistUnit *ptr;
        TDeviceConfig *config;

        if (FOnline)
        {
        FPendingResetReq = TRUE;

        FOnline = FALSE;

        FUnitSection.Enter();

        ptr = FUnitList;
            while (ptr)
        {
            ptr->Offline();
                        ptr = ptr->FList;
                }

        FUnitSection.Leave();

        FConfigSection.Enter();

        config = FConfigList;
        while (config)
            {
                config->FActive = TRUE;
                config = config->FNext;
        }

            FConfigSection.Leave();

        }
}

/*##########################################################################
#
#   Name       : TDistSystem::HasUnit
#
#   Purpose....: Check if unit is available & uninstalled
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDistSystem::HasUnit(unsigned short int UnitType)
{
        TDistUnit *ptr;
        int ok;

        FUnitSection.Enter();

        ok = FALSE;
        ptr = FUnitList;
        while (!ok && ptr)
        {
                if (!ptr->FInstalled && ptr->GetUnitType() == UnitType)
                        ok = TRUE;
                ptr = ptr->FList;
        }

        FUnitSection.Leave();

        return ok;
}

/*##########################################################################
#
#   Name       : TDistSystem::HasUnit
#
#   Purpose....: Check if unit is available & uninstalled
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDistSystem::HasUnit(unsigned short int UnitType, unsigned short int UnitNumber)
{
        TDistUnit *ptr;
        int ok;

        FUnitSection.Enter();

        ok = FALSE;
        ptr = FUnitList;
        while (!ok && ptr)
    {
            if (!ptr->FInstalled && ptr->GetUnitType() == UnitType && ptr->GetUnitNumber() == UnitNumber)
                ok = TRUE;
                ptr = ptr->FList;
        }

    FUnitSection.Leave();

    return ok;
}

/*##########################################################################
#
#   Name       : TDistSystem::InstallRemote
#
#   Purpose....: Install a remote device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::InstallRemote(TDevice *Device)
{
        TDistUnit *ptr;
        int found;

        FUnitSection.Enter();

        Device->FRemote = TRUE;

        found = FALSE;
        ptr = FUnitList;
        while (!found && ptr)
        {
                if (ptr->GetUnitType() == Device->GetUnitType() && ptr->GetUnitNumber() == Device->GetUnitNumber())
                {
                        Device->FPhysUnit = ptr;
                        ptr->DefineDevice(Device);
                        if (IsOnline())
                                ptr->Online();
                        ptr->HandleInstallTag();
                        found = TRUE;
                }
                ptr = ptr->FList;
        }

        if (!found)
        {
                ptr = new TDistUnit(this, Device->GetUnitType(), Device->GetUnitNumber());
                Device->FPhysUnit = ptr;
                ptr->DefineDevice(Device);
                if (IsOnline())
                        ptr->Online();
        }

        FUnitSection.Leave();
}

/*##########################################################################
#
#   Name       : TDistSystem::InstallVirtual
#
#   Purpose....: Install a virtual device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::InstallVirtual(TDevice *Device)
{
        TDistUnit *ptr;
        int found;

    FUnitSection.Enter();

        found = FALSE;
        ptr = FUnitList;
        while (!found && ptr)
    {
            if (ptr->GetUnitType() == Device->GetUnitType() && ptr->GetUnitNumber() == Device->GetUnitNumber())
            {
                        Device->FPhysUnit = ptr;
            ptr->DefineDevice(Device);
            if (IsOnline())
                ptr->Online();
            ptr->HandleInstallTag();
                found = TRUE;
            }
            ptr = ptr->FList;
        }

        if (!found)
        {
                ptr = new TDistUnit(this, Device->GetUnitType(), Device->GetUnitNumber());
        Device->FPhysUnit = ptr;
        ptr->DefineDevice(Device);
        if (IsOnline())
            ptr->Online();
        }

        FUnitSection.Leave();
}

/*##########################################################################
#
#   Name       : TDistSystem::InstallPhysical
#
#   Purpose....: Install a physical device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::InstallPhysical(TDevice *Device)
{
    TDistUnit *ptr;

    ptr = new TDistUnit(this);

    ptr->FNext = Device->FVirtUnitList;
        Device->FVirtUnitList = ptr;
    ptr->DefineDevice(Device);
        if (IsOnline())
                ptr->Online();
}

/*##########################################################################
#
#   Name       : TDistSystem::AddRemote
#
#   Purpose....: Add remote support for device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::AddRemote(TDevice *Device)
{
    TDistUnit *ptr;

    ptr = new TDistUnit(this);

    ptr->FNext = Device->FRemoteUnitList;
    Device->FRemoteUnitList = ptr;
    ptr->DefineDevice(Device);
    if (IsOnline())
                ptr->Online();
}

/*##########################################################################
#
#   Name       : TDistSystem::SignalMsg
#
#   Purpose....: Signal new message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::SignalMsg()
{
        FDistDevice->SignalMsg();
}

/*##########################################################################
#
#   Name       : TDistSystem::GetTimeout
#
#   Purpose....: Get timeout
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDistSystem::GetTimeout()
{
        if (FDistDevice)
            return FDistDevice->GetTimeout();
        else
            return 1000;
}

/*##########################################################################
#
#   Name       : TDistSystem::SendMsg
#
#   Purpose....: Send msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::SendMsg(const char *data, int size)
{
        if (FDistDevice)
                FDistDevice->SendMsg(data, size);
}

/*##########################################################################
#
#   Name       : TDistSystem::SendMsg
#
#   Purpose....: Send an external msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::SendMsg(TDeviceMsg *msg)
{
    char *data;
    int size;

    size = msg->GetSize();
    data = new char[size];
        msg->GetData(FSignature, data);
        delete msg;
        SendMsg(data, size);
        delete data;
}

/*##########################################################################
#
#   Name       : TDistSystem::SendResetReq
#
#   Purpose....: Send a reset req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::SendResetReq()
{
    TDeviceMsg *msg;
    TDeviceTag *tag;
    char *data;
    int size;

    FDistDevice->Reset();

        msg = new TDeviceMsg(128);
    tag = msg->AddTag(DEVICE_TAG_RESET_REQ);

        size = msg->GetSize();
        data = new char[size];
        msg->GetData(FSignature, data);
        delete msg;
        SendMsg(data, size);
        delete data;
}

/*##########################################################################
#
#   Name       : TDistSystem::SendResetAck
#
#   Purpose....: Send a reset ack
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::SendResetAck()
{
    TDeviceMsg *msg;
    TDeviceTag *tag;
    char *data;
    int size;

    FDistDevice->Reset();

        msg = new TDeviceMsg(128);
        tag = msg->AddTag(DEVICE_TAG_RESET_ACK);

    size = msg->GetSize();
    data = new char[size];
        msg->GetData(FSignature, data);
        delete msg;
        SendMsg(data, size);
        delete data;
}

/*##########################################################################
#
#   Name       : TDistSystem::SendPollReq
#
#   Purpose....: Send a poll req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::SendPollReq()
{
        TDeviceMsg *msg;
        TDeviceTag *tag;
        char *data;
    int size;

    if (FHasUnits && !FPendingResetReq && !FPendingResetAck)
    {
        msg = new TDeviceMsg(128);
        tag = msg->AddTag(DEVICE_TAG_POLL_REQ);

        size = msg->GetSize();
        data = new char[size];
                msg->GetData(FSignature, data);
            delete msg;
        SendMsg(data, size);
            delete data;
        }
}

/*##########################################################################
#
#   Name       : TDistSystem::SendPollAck
#
#   Purpose....: Send a poll ack
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::SendPollAck()
{
    TDeviceMsg *msg;
    TDeviceTag *tag;
    char *data;
    int size;

    if (!FPendingResetReq && !FPendingResetAck)
    {
        msg = new TDeviceMsg(128);
        tag = msg->AddTag(DEVICE_TAG_POLL_ACK);

        size = msg->GetSize();
        data = new char[size];
                msg->GetData(FSignature, data);
        delete msg;
            SendMsg(data, size);
        delete data;
    }
}

/*##########################################################################
#
#   Name       : TDistSystem::SendConfigAck
#
#   Purpose....: Send a config ack
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::SendConfigAck(unsigned short int UnitType, unsigned short int UnitNumber)
{
    TDeviceMsg *msg;
    TDeviceTag *tag;
    char *data;
    int size;

    if (!FPendingResetReq && !FPendingResetAck)
    {
        msg = new TDeviceMsg(256);

                tag = msg->AddTag(DEVICE_TAG_HEADER);
                tag->AddSignedShort(DEVICE_VAR_UnitType, UnitType);
                tag->AddSignedShort(DEVICE_VAR_UnitID, UnitNumber);

                tag = msg->AddTag(DEVICE_TAG_CONFIG_ACK);

        size = msg->GetSize();
        data = new char[size];
        msg->GetData(FSignature, data);
        delete msg;
            SendMsg(data, size);
        delete data;
    }
}

/*##########################################################################
#
#   Name       : TDistSystem::UpdateMsg
#
#   Purpose....: Update message queues
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::UpdateMsg()
{
        TDistUnit *ptr;
        TDeviceConfig *config;
    TDeviceMsg *msg;
    char *data;
    int size;
    int more;
    int sent;

    if (!FHasUnits)
        return;

    more = TRUE;
    sent = FALSE;

    if (FPendingResetReq)
    {
        more = FALSE;
        sent = TRUE;
        SendResetReq();
    }

    if (FPendingResetAck)
    {
        more = FALSE;
        sent = TRUE;
        SendResetAck();
        FPendingResetAck = FALSE;
        }

        if (more)
    {
        FConfigSection.Enter();

        config = FConfigList;
            while (config)
        {
            if (config->FActive)
            {
                    msg = config->FConfigMsg;
                size = msg->GetSize();
                data = new char[size];
                                msg->GetData(FSignature, data);
                    SendMsg(data, size);
                    delete data;
                    sent = TRUE;
            }
            config = config->FNext;
        }

        FConfigSection.Leave();
    }

        while (more)
        {
                more = FALSE;

        FUnitSection.Enter();

        ptr = FUnitList;
            while (ptr)
        {
                msg = ptr->GetMsg();
                if (msg)
            {
                size = msg->GetSize();
                data = new char[size];
                msg->GetData(FSignature, data);
                if (msg->FDeleteOnSend)
                        delete msg;
                    SendMsg(data, size);
                    delete data;

                    more = TRUE;
                    sent = TRUE;
            }
                ptr = ptr->FList;
            }

                FUnitSection.Leave();
        }

    if (!sent && FPendingPoll)
    {
        FPendingPoll = FALSE;
        SendPollAck();
    }
}

/*##########################################################################
#
#   Name       : TDistSystem::HandleMsg
#
#   Purpose....: Handle incoming message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::HandleMsg(TDeviceMsg *Msg)
{
    TDistUnit *ptr;
        TDeviceConfig *cfg;
        TDeviceTag *header;
    TDeviceTag *poll;
    TDeviceTag *reset;
    TDeviceTag *config;
    short int UnitType = 0;
    short int UnitID = 0;
    int found;

    reset = Msg->GetTag(DEVICE_TAG_RESET_REQ);
    if (reset)
    {
        FHasUnits = TRUE;
    
        Offline();
        Online();
        
        FPendingResetAck = TRUE;
        FPendingResetReq = FALSE;
        SignalMsg();
    }

    reset = Msg->GetTag(DEVICE_TAG_RESET_ACK);
    if (reset)
        FPendingResetReq = FALSE;

        if (!FPendingResetReq && !FPendingResetAck)
        {
                poll = Msg->GetTag(DEVICE_TAG_POLL_REQ);
        if (poll)
        {
            FHasUnits = TRUE;
            FPendingPoll = TRUE;
            SignalMsg();
        }

        header = Msg->GetTag(DEVICE_TAG_HEADER);
        if (header)
        {
            FHasUnits = TRUE;
                        UnitType = header->GetSignedShort(DEVICE_VAR_UnitType, 0);
            UnitID = header->GetSignedShort(DEVICE_VAR_UnitID, 0);
        }
        else
        {
            if (OnMsg)
                (*OnMsg)(this, Msg);
        }

        if (UnitType)
        {

                        found = FALSE;
                        FPendingPoll = FALSE;

                        config = Msg->GetTag(DEVICE_TAG_CONFIG_REQ);
            if (config)
            {
                        SendConfigAck(UnitType, UnitID);

                if (!HasUnit(UnitType, UnitID))
                {                    
                    if (OnConfig)
                        (*OnConfig)(this, UnitType, UnitID, config);
                }
            }

            if (!config)
            {
                config = Msg->GetTag(DEVICE_TAG_CONFIG_ACK);
                if (config)
                {
                    FConfigSection.Enter();

                        cfg = FConfigList;
                        
                    while (cfg)
                                        {
                                                if (cfg->FUnitType == UnitType && cfg->FUnitNumber == UnitID)
                                                        cfg->FActive = FALSE;

                                cfg = cfg->FNext;
                        }

                        FConfigSection.Leave();
                }
            }
                     
            if (!config)
            {
                FUnitSection.Enter();

                ptr = FUnitList;
                    while (!found && ptr)
                {
                        if (ptr->GetUnitType() == UnitType && ptr->GetUnitNumber() == UnitID)
                    {
                        ptr->HandleMsg(Msg);
                        found = TRUE;
                    }
                
                                ptr = ptr->FList;
                                }

                                if (!found)
                                {
                    ptr = new TDistUnit(this, UnitType, UnitID);
                    ptr->HandleMsg(Msg);                
                }
                        
                FUnitSection.Leave();
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TDistSystem::NotifyMsg
#
#   Purpose....: Notify new msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistSystem::NotifyMsg(const char *Data, int Size)
{
        TDeviceMsg *msg;

        msg = new TDeviceMsg(8 * Size);
        if (msg->Parse(FSignature, Data, Size + 8))
            HandleMsg(msg);

        delete msg;
}

/*##########################################################################
#
#   Name       : TDistDevice::TDistDevice
#
#   Purpose....: Constructor for TDistDevice
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDistDevice::TDistDevice()
{
    FSystemList = 0;
        FSignal = new TSignalDevice;
}

/*##########################################################################
#
#   Name       : TDistDevice::~TDistDevice
#
#   Purpose....: Destructor for TDistDevice
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDistDevice::~TDistDevice()
{
        delete FSignal;
}

/*##########################################################################
#
#   Name       : TDistDevice::AddSystem
#
#   Purpose....: Add a system
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistDevice::AddSystem(TDistSystem *system)
{
        system->FNext = FSystemList;
        FSystemList = system;
}

/*##########################################################################
#
#   Name       : TDistDevice::SignalMsg
#
#   Purpose....: Signal a new message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistDevice::SignalMsg()
{
        FSignal->Signal();
}

/*##########################################################################
#
#   Name       : TDistDevice::CheckSignature
#
#   Purpose....: Check if system with given signature is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDistDevice::CheckSignature(long signature)
{
        TDistSystem *ptr;

        ptr = FSystemList;

        while (ptr)
        {
                if (ptr->GetSignature() == signature)
                        return TRUE;
                        
                ptr = ptr->FNext;
        }
        
        return FALSE;
}

/*##########################################################################
#
#   Name       : TDistDevice::CheckSignature
#
#   Purpose....: Check if system with given signature is available
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistDevice::NotifyMsg(long signature, const char *Data, int Size)
{
        TDistSystem *ptr;

        ptr = FSystemList;

        while (ptr)
        {
                if (ptr->GetSignature() == signature)
                {
                    ptr->NotifyMsg(Data, Size);
                    break;
                }
                        
                ptr = ptr->FNext;
        }
}

/*##########################################################################
#
#   Name       : TDistDevice::Online
#
#   Purpose....: Sets state to online
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistDevice::Online()
{
        TDistSystem *ptr;

        if (!FOnline)
        {
            TDevice::Online();

        ptr = FSystemList;

        while (ptr)
            {
                    ptr->Online();
                        ptr = ptr->FNext;
            }
        }
}

/*##########################################################################
#
#   Name       : TDistDevice::Offline
#
#   Purpose....: Sets state to offline
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistDevice::Offline()
{
        TDistSystem *ptr;

        if (FOnline)
        {
            TDevice::Offline();

        ptr = FSystemList;

        while (ptr)
            {
                    ptr->Offline();
                        ptr = ptr->FNext;
                }
        }
}

/*##########################################################################
#
#   Name       : TDistDevice::UpdateMsg
#
#   Purpose....: Update message queues
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistDevice::UpdateMsg()
{
        TDistSystem *ptr;

        ptr = FSystemList;

        while (ptr)
        {
                ptr->UpdateMsg();
                ptr = ptr->FNext;
        }
}

/*##########################################################################
#
#   Name       : TDistDevice::SendPollReq
#
#   Purpose....: Send poll req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistDevice::SendPollReq()
{
        TDistSystem *ptr;

        ptr = FSystemList;

        while (ptr)
        {
                ptr->SendPollReq();
                ptr = ptr->FNext;
        }
}
