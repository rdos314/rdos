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

#include <mem.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "device.h"
#include "sigdev.h"

#define FALSE 0
#define TRUE !FALSE

#define MSG_SIGN    0x01CE01DE

#define DEVICE_TAGRANGE_LOW	        1
#define DEVICE_TAGRANGE_HIGH	    10000
#define DEVICE_VARIABLERANGE_LOW	30001
#define DEVICE_VARIABLERANGE_HIGH	40000
#define DEVICE_TAGEND	            65535

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
*   Purpose....: Constructor for var	                        #
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
TDeviceVar::TDeviceVar(TDeviceAlloc *alloc, const char *data, int size, int *count)
{
    unsigned short int Id;
    int overhead;
	int terminate;

    FAlloc = alloc;   
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
*   Purpose....: Destructor for var	                        #
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
*   Purpose....: Confirm this is a variable                   	                        #
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
*   Purpose....: Is this an empty var?                     	                        #
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
*   Purpose....: Return type                     	                        #
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
*   Purpose....: Reinit var                     	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::Reinit()
{
//    if (FData)
//        delete FData;
    FData = 0;

//    if (FStr)
//        delete FStr;
	FStr = 0;
    
    FType = DEVICE_DATA_NONE;
    FSize = 0;
}

/*##################  TDeviceVar::Allocate  ###############
*   Purpose....: Allocate memory                              	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char *TDeviceVar::Allocate(int size)
{
    return (char *)FAlloc->Allocate(size);
}

/*##################  TDeviceVar::operator new  ###############
*   Purpose....: operator new                      	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void *TDeviceVar::operator new(size_t size, TDeviceAlloc *alloc)
{
    return alloc->Allocate(size);
}

/*##################  TDeviceVar::SetUnsigned8  ###############
*   Purpose....: Set variable a unsigned8          	                        #
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
*   Purpose....: Set variable a unsigned16          	                        #
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
*   Purpose....: Set variable a unsigned32          	                        #
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

/*##################  TDeviceVar::SetSigned8  ###############
*   Purpose....: Set variable a signed8          	                        #
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
*   Purpose....: Set variable a signed16          	                        #
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
*   Purpose....: Set variable a signed32          	                        #
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

/*##################  TDeviceVar::SetChar  ###############
*   Purpose....: Set variable as char          	                        #
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
*   Purpose....: Set variable as float1          	                        #
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
*   Purpose....: Set variable as float2          	                        #
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
*   Purpose....: Set variable as float3          	                        #
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
*   Purpose....: Set variable as float4          	                        #
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
*   Purpose....: Set variable as julian          	                        #
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
*   Purpose....: Set variable as binary          	                        #
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
		FSize = 1 + size;
		FData = Allocate(FSize);
		memcpy(FData, &size, 1);
		memcpy(FData + 1, data, size);
	}
	else
	{
        FType = DEVICE_DATA_BINARY16;
        FSize = 2 + size;
        FData = Allocate(FSize);
        memcpy(FData, &size, 2);
        memcpy(FData + 2, data, size);
	}
}

/*##################  TDeviceVar::SetString  ###############
*   Purpose....: Set variable as string          	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceVar::SetString(const char *str)
{
    int size = strlen(str);
    
    Reinit();

    if (size < 128)
    {
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
    else
    {
        if (size < 256)
        {
            FType = DEVICE_DATA_STRING8;
            FSize = 1 + size;
            FData = Allocate(FSize);
            memcpy(FData, &size, 1);
            memcpy(FData + 1, str, size);
        }
        else
        {
            FType = DEVICE_DATA_STRING16;
            FSize = 2 + size;
            FData = Allocate(FSize);
            memcpy(FData, &size, 2);
            memcpy(FData + 2, str, size);
        }
    }
}

/*##################  TDeviceVar::SetBoolean  ###############
*   Purpose....: Set variable as boolean          	                        #
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
*   Purpose....: Set variable as boolean array         	                        #
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
	const char *bool;

    Reinit();

    if (size >= 2040)
        return;
    
    FType = DEVICE_DATA_BOOLARRAY;
    
    if (size % 8 == 0)
        len = size / 8;
    else
        len = size / 8 + 1;

    FSize = 1 + len;
    FData = Allocate(FSize);
    memcpy(FData, &len, 1);

    for (i = 0; i < len; i++)       
		*(FData + i + 1) = 0;

    bitnr = 0;
    ptr = FData;
    bool = data;
    for (i = 0; i < size; i++)
    {
        if (*bool)
            *ptr |= 1 << bitnr;
        
        bitnr++;
        if (bitnr == 8)
        {
            bitnr = 0;
            ptr++;
        }
        bool++;
    }                 
}

/*##################  TDeviceVar::SetByteArray  ###############
*   Purpose....: Set variable as byte array         	                        #
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
    FSize = 1 + size;
    FData = Allocate(FSize);
    memcpy(FData, &size, 1);
    memcpy(FData + 1, data, size);
}    

/*##################  TDeviceVar::GetUnsigned8  ###############
*   Purpose....: Get variable a unsigned8          	                        #
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
*   Purpose....: Get variable a unsigned16          	                        #
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
*   Purpose....: Get variable a unsigned32          	                        #
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
                sscanf(str, "%U", &val);
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

/*##################  TDeviceVar::GetSigned8  ###############
*   Purpose....: Get variable a signed8          	                        #
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
*   Purpose....: Get variable a signed16          	                        #
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
*   Purpose....: Get variable a signed32          	                        #
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
                sscanf(str, "%D", &val);
            break;
    }
    return val;
}

/*##################  TDeviceVar::GetChar  ###############
*   Purpose....: Get variable as char          	                        #
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
*   Purpose....: Get variable as float1          	                        #
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
*   Purpose....: Get variable as float2          	                        #
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
*   Purpose....: Get variable as float3          	                        #
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
*   Purpose....: Get variable as float4          	                        #
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
*   Purpose....: Get variable as julian          	                        #
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
*   Purpose....: Get variable as binary          	                        #
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
*   Purpose....: Get variable as string          	                        #
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
    
//    if (FStr)
//        delete FStr;
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
*   Purpose....: Get variable as boolean          	                        #
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
*   Purpose....: Get variable as boolean array         	                        #
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
*   Purpose....: Get variable as byte array         	                        #
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
*   Purpose....: Get ID                         	                        #
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
*   Purpose....: Get size of data                	                        #
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
*   Purpose....: Get data                	                        #
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
TDeviceTag::TDeviceTag(TDeviceAlloc *alloc, const char *data, int size, int *count)
{
	unsigned short int Id;
	int used;
	TDeviceData *elem;
	int ElemSize = 1;

	FAlloc = alloc;
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
				elem = new(alloc) TDeviceTag(alloc, data, size, &ElemSize);
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
					elem = new(alloc) TDeviceVar(alloc, data, size, &ElemSize);
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

    elem = FHead;
    while (elem)
    {
		next = elem->FNext;
//        delete elem;
        elem = next;
    }   
}

/*##################  TDeviceTag::Allocate  ###############
*   Purpose....: Allocate memory                  	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char *TDeviceTag::Allocate(int size)
{
    return (char *)FAlloc->Allocate(size);
}

/*##################  TDeviceTag::operator new  ###############
*   Purpose....: operator new                      	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void *TDeviceTag::operator new(size_t size, TDeviceAlloc *alloc)
{
    return alloc->Allocate(size);
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

		newtag = new(alloc) TDeviceTag(alloc, data, size, &count);
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

			newtag = new(FAlloc) TDeviceTag(FAlloc, data, size, &count);
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
	TDeviceTag *Tag = new(FAlloc) TDeviceTag(FAlloc, ID);
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
	TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
	Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddUnsigned8  ###############
*   Purpose....: Add a new unsigned-8 data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddUnsigned8(unsigned short int ID, unsigned char data)
{
    TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    Var->SetUnsigned8(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddUnsigned16  ###############
*   Purpose....: Add a new unsigned-16 data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddUnsigned16(unsigned short int ID, unsigned short int data)
{
    TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
	Var->SetUnsigned16(data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::AddUnsigned32  ###############
*   Purpose....: Add a new unsigned-32 data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::AddUnsigned32(unsigned short int ID, unsigned long data)
{
    TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    Var->SetUnsigned32(data);
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
    TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
    TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
    TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
    Var->SetSigned32(data);
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
    TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
    TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
    TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
    TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
    TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
    TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
    TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
    TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
    TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
    TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
    TDeviceVar *Var = new(FAlloc) TDeviceVar(FAlloc, ID);
	Var->SetByteArray(size, data);
    Add(Var);
    return Var;
}

/*##################  TDeviceTag::ModifyUnsigned8  ###############
*   Purpose....: Modify unsigned-8 data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifyUnsigned8(unsigned short int ID, unsigned char data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        Add(Var);
    }
        
    Var->SetUnsigned8(data);
    return Var;
}

/*##################  TDeviceTag::ModifyUnsigned16  ###############
*   Purpose....: Modify unsigned-16 data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifyUnsigned16(unsigned short int ID, unsigned short int data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        Add(Var);
    }
    
    Var->SetUnsigned16(data);
    return Var;
}

/*##################  TDeviceTag::ModifyUnsigned32  ###############
*   Purpose....: Modify unsigned-32 data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifyUnsigned32(unsigned short int ID, unsigned long data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        Add(Var);
    }
    
    Var->SetUnsigned32(data);
    return Var;
}

/*##################  TDeviceTag::ModifySigned8  ###############
*   Purpose....: Modify signed-8 data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifySigned8(unsigned short int ID, char data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        Add(Var);
    }
    
    Var->SetSigned8(data);
    return Var;
}

/*##################  TDeviceTag::ModifySigned16  ###############
*   Purpose....: Modify signed-16 data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifySigned16(unsigned short int ID, short int data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        Add(Var);
    }
    
    Var->SetSigned16(data);
    return Var;
}

/*##################  TDeviceTag::ModifySigned32  ###############
*   Purpose....: Modify signed-32 data entry                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceVar *TDeviceTag::ModifySigned32(unsigned short int ID, long data)
{
    TDeviceVar *Var;

    Var = GetVar(ID);
    if (!Var)
    {
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        Add(Var);
    }
    
    Var->SetSigned32(data);
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
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
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
        Var = new(FAlloc) TDeviceVar(FAlloc, ID);
        Add(Var);
    }
    
	Var->SetByteArray(size, data);
    return Var;
}

/*##################  TDeviceTag::GotoFirstTag  ###############
*   Purpose....: Goto first tag                       	                        #
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
*   Purpose....: Goto next tag                       	                        #
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
*   Purpose....: Goto first var                       	                        #
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
*   Purpose....: Goto next var                       	                        #
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
*   Purpose....: Get tag by number                       	                        #
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
*   Purpose....: Check if empty tag exists         	                        #
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
*   Purpose....: Get var by number                     	                        #
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
*   Purpose....: Check if empty var exists        	                        #
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
*   Purpose....: Get ID                            	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceTag::GetID()
{
    return FID;
}

/*##################  TDeviceTag::GetUnsigned8  ###############
*   Purpose....: Get var as unsigned8                       	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
unsigned char TDeviceTag::GetUnsigned8(unsigned short int ID, unsigned char Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var->GetUnsigned8();
        Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetUnsigned16  ###############
*   Purpose....: Get var as unsigned16                       	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
unsigned short int TDeviceTag::GetUnsigned16(unsigned short int ID, unsigned short int Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
	while (Var)
    {
        if (Var->FID == ID)
            return Var->GetUnsigned16();
        Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetUnsigned32  ###############
*   Purpose....: Get var as unsigned32                       	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
unsigned long TDeviceTag::GetUnsigned32(unsigned short int ID, unsigned long Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var->GetUnsigned32();
		Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetSigned8  ###############
*   Purpose....: Get var as signed8                       	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
char TDeviceTag::GetSigned8(unsigned short int ID, char Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var->GetSigned8();
        Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetSigned16  ###############
*   Purpose....: Get var as signed16                       	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
short int TDeviceTag::GetSigned16(unsigned short int ID, short int Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var->GetSigned16();
        Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetSigned32  ###############
*   Purpose....: Get var as signed32                       	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
long TDeviceTag::GetSigned32(unsigned short int ID, long Default)
{
    TDeviceVar *Var;

    Var = GotoFirstVar();
    while (Var)
    {
        if (Var->FID == ID)
            return Var->GetSigned32();
        Var = GotoNextVar();
    }
    return Default;
}

/*##################  TDeviceTag::GetChar  ###############
*   Purpose....: Get var as single char                       	                        #
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
*   Purpose....: Get var as 1-decimal long                       	                        #
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
*   Purpose....: Get var as 2-decimal long                       	                        #
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
*   Purpose....: Get var as 3-decimal long                       	                        #
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
*   Purpose....: Get var as 4-decimal long                       	                        #
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
*   Purpose....: Get var as julian date & time                       	                        #
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
*   Purpose....: Get var as binary                       	                        #
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
*   Purpose....: Get var as string                       	                        #
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
*   Purpose....: Get var as boolean                       	                        #
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
*   Purpose....: Get var as boolean array                       	                        #
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
*   Purpose....: Get var as byte array                       	                        #
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

/*##################  TDeviceTag::UpdateSigned8  ###############
*   Purpose....: Update signed8 value                	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateUnsigned8(TDeviceTag *DestTag, unsigned short int ID, unsigned char *Val)
{
	TDeviceVar *Var;

	Var = GetVar(ID);
	if (Var)
	{
		if (Var->IsEmptyVar())
		{
			if (DestTag)
				DestTag->AddUnsigned8(ID, *Val);
		}
		else
			*Val = Var->GetUnsigned8();
	}
	else
		if (DestTag && IsEmptyTag())
			DestTag->AddUnsigned8(ID, *Val);
}

/*##################  TDeviceTag::UpdateUnsigned16  ###############
*   Purpose....: Update unsigned16 value                	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateUnsigned16(TDeviceTag *DestTag, unsigned short int ID, unsigned int *Val)
{
	TDeviceVar *Var;

	Var = GetVar(ID);
    if (Var)
	{
        if (Var->IsEmptyVar())
        {
            if (DestTag)
                DestTag->AddUnsigned16(ID, *Val);
        }
        else
            *Val = Var->GetUnsigned16();
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddUnsigned16(ID, *Val);
}

/*##################  TDeviceTag::UpdateUnsigned32  ###############
*   Purpose....: Update unsigned32 value                	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateUnsigned32(TDeviceTag *DestTag, unsigned short int ID, unsigned long *Val)
{
	TDeviceVar *Var;

	Var = GetVar(ID);
	if (Var)
	{
		if (Var->IsEmptyVar())
		{
            if (DestTag)
                DestTag->AddUnsigned32(ID, *Val);
        }
        else
            *Val = Var->GetUnsigned32();
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddUnsigned32(ID, *Val);
}

/*##################  TDeviceTag::UpdateSigned8  ###############
*   Purpose....: Update signed8 value                	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateSigned8(TDeviceTag *DestTag, unsigned short int ID, char *Val)
{
	TDeviceVar *Var;
    
	Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
        {
            if (DestTag)
                DestTag->AddSigned8(ID, *Val);
        }
        else
            *Val = Var->GetSigned8();
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddSigned8(ID, *Val);
}

/*##################  TDeviceTag::UpdateSigned16  ###############
*   Purpose....: Update signed16 value                	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateSigned16(TDeviceTag *DestTag, unsigned short int ID, short int *Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
        {
            if (DestTag)
                DestTag->AddSigned16(ID, *Val);
        }
        else
            *Val = Var->GetSigned16();
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddSigned16(ID, *Val);
}

/*##################  TDeviceTag::UpdateSigned16  ###############
*   Purpose....: Update signed16 value                	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateSigned16(TDeviceTag *DestTag, unsigned short int ID, int *Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
        {
            if (DestTag)
                DestTag->AddSigned16(ID, *Val);
        }
        else
            *Val = Var->GetSigned16();
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddSigned16(ID, *Val);
}

/*##################  TDeviceTag::UpdateSigned32  ###############
*   Purpose....: Update signed32 value                	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateSigned32(TDeviceTag *DestTag, unsigned short int ID, long *Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
        {
            if (DestTag)
                DestTag->AddSigned32(ID, *Val);
        }
        else
            *Val = Var->GetSigned32();
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddSigned32(ID, *Val);
}

/*##################  TDeviceTag::UpdateChar  ###############
*   Purpose....: Update char value                	                        #
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
*   Purpose....: Update float1 value                	                        #
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
*   Purpose....: Update float2 value                	                        #
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
*   Purpose....: Update float3 value                	                        #
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
*   Purpose....: Update float4 value                	                        #
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
*   Purpose....: Update julian value                	                        #
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
*   Purpose....: Update boolean value                	                        #
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
*   Purpose....: Update string                  	                        #
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

/*##################  TDeviceTag::UpdateSigned8  ###############
*   Purpose....: Update signed8 value                	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateUnsigned8(TDeviceTag *DestTag, unsigned short int ID, unsigned char Val)
{
	TDeviceVar *Var;

	Var = GetVar(ID);
	if (Var)
	{
		if (Var->IsEmptyVar())
			if (DestTag)
				DestTag->AddUnsigned8(ID, Val);
	}
	else
		if (DestTag && IsEmptyTag())
			DestTag->AddUnsigned8(ID, Val);
}

/*##################  TDeviceTag::UpdateUnsigned16  ###############
*   Purpose....: Update unsigned16 value                	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateUnsigned16(TDeviceTag *DestTag, unsigned short int ID, unsigned int Val)
{
	TDeviceVar *Var;

	Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
            if (DestTag)
                DestTag->AddUnsigned16(ID, Val);
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddUnsigned16(ID, Val);
}

/*##################  TDeviceTag::UpdateUnsigned32  ###############
*   Purpose....: Update unsigned32 value                	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateUnsigned32(TDeviceTag *DestTag, unsigned short int ID, unsigned long Val)
{
	TDeviceVar *Var;

	Var = GetVar(ID);
	if (Var)
	{
		if (Var->IsEmptyVar())
            if (DestTag)
                DestTag->AddUnsigned32(ID, Val);
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddUnsigned32(ID, Val);
}

/*##################  TDeviceTag::UpdateSigned8  ###############
*   Purpose....: Update signed8 value                	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateSigned8(TDeviceTag *DestTag, unsigned short int ID, char Val)
{
    TDeviceVar *Var;
    
	Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
            if (DestTag)
                DestTag->AddSigned8(ID, Val);
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddSigned8(ID, Val);
}

/*##################  TDeviceTag::UpdateSigned16  ###############
*   Purpose....: Update signed16 value                	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateSigned16(TDeviceTag *DestTag, unsigned short int ID, int Val)
{
    TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
            if (DestTag)
                DestTag->AddSigned16(ID, Val);
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddSigned16(ID, Val);
}

/*##################  TDeviceTag::UpdateSigned32  ###############
*   Purpose....: Update signed32 value                	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateSigned32(TDeviceTag *DestTag, unsigned short int ID, long Val)
{
	TDeviceVar *Var;
    
    Var = GetVar(ID);
    if (Var)
    {
        if (Var->IsEmptyVar())
            if (DestTag)
                DestTag->AddSigned32(ID, Val);
    }
    else
        if (DestTag && IsEmptyTag())          
            DestTag->AddSigned32(ID, Val);
}

/*##################  TDeviceTag::UpdateChar  ###############
*   Purpose....: Update char value                	                        #
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
*   Purpose....: Update float1 value                	                        #
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
*   Purpose....: Update float2 value                	                        #
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
*   Purpose....: Update float3 value                	                        #
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
*   Purpose....: Update float4 value                	                        #
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
*   Purpose....: Update julian value                	                        #
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
*   Purpose....: Update boolean value                	                        #
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
*   Purpose....: Update string                  	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceTag::UpdateString(TDeviceTag *DestTag, unsigned short int ID, char *Val)
{
    TDeviceVar *Var;
	const char *str;
    
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
*   Purpose....: Get size of data                	                        #
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
*   Purpose....: Get data                          	                        #
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
*   Purpose....: Constructor for msg        		                        #
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
*   Purpose....: Destructor for msg           	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
TDeviceMsg::~TDeviceMsg()
{
    Free();
    delete FAlloc;
}

/*##################  TDeviceMsg::GetAlloc  ###############
*   Purpose....: Get allocation object           	                        #
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
*   Purpose....: Delete all entries           	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceMsg::Free()
{
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
    TDeviceTag *tag = new(FAlloc) TDeviceTag(FAlloc, ID);
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

            newtag = new(FAlloc) TDeviceTag(FAlloc, data, size, &count);
            Add(newtag);
            delete data;
            return newtag;
        }
    }
    return 0;
}

/*##################  TDeviceMsg::GetSize  ###############
*   Purpose....: Get size of data                	                        #
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
*   Purpose....: Calculate CRC	                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
unsigned short int TDeviceMsg::Crc(const char *Data, int Size) const
{
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
}

/*##################  TDeviceMsg::GetData  ###############
*   Purpose....: Get data                          	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
void TDeviceMsg::GetData(char *data)
{
    unsigned short int CrcVal;
    int size;
	TDeviceData *elem;
	long sign = MSG_SIGN;

	memcpy(data, &sign, 4);
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
*   Purpose....: Parse data                          	                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-30 le                                                #
*##########################################################################*/
int TDeviceMsg::Parse(const char *data, int size)
{
    unsigned short int CrcVal;
    int MsgSize = 0;
	int count;
	long sign;
	TDeviceTag *tag;

	Free();

	memcpy(&sign, data, 4);
	if (sign != MSG_SIGN)
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
		tag = new(FAlloc) TDeviceTag(FAlloc, data, size, &count);
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
*   Purpose....: Goto first tag                       	                        #
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
*   Purpose....: Goto next tag                       	                        #
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
*   Purpose....: Get a tag                       	                        #
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
#   Name       : TDevice::InsertDevice
#
#   Purpose....: Insert device into m_DeviceList
#				 Should only done in constructor
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
#				 Should only done in destructor
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
	FDistDevice = 0;
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
	FDistDevice = 0;
	Init();
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
TDevice::TDevice(TDistDevice *DistDevice)
{
	FIniSection = 0;
	FDistDevice = DistDevice;
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
TDevice::TDevice(const char *IniSection, TDistDevice *DistDevice)
{
	FIniSection = IniSection;
	FDistDevice = DistDevice;
	Init();
}

/*##########################################################################
#
#   Name       : TDevice::LoadProperty
#
#   Purpose....: Loads an integer property		                          
#
#   In params..: Name   name of property
#                Def    default value
#   Out params.: *
#   Returns....: Property value
#
##########################################################################*/
int TDevice::LoadProperty(const char *Name, int Def)
{
	int value;

	if (FIniSection == 0)
    {
    	value = Def;
    }
	else
    {
//		value = GetProfileInt(FIniSection, Name, Def);
        value = Def;
    }
	SaveProperty(Name, value);
	return value;
}

/*##########################################################################
#
#   Name       : TDevice::LoadProperty
#
#   Purpose....: Loads a long property		                          
#
#   In params..: Name   name of property
#                Def    default value
#   Out params.: *
#   Returns....: Property value
#
##########################################################################*/
long TDevice::LoadProperty(const char *Name, long Def)
{
	char value_str[12];
	char default_str[12];
	long value;

	if (FIniSection == 0)
    {
		value = Def;
    }
	else
    {
		ltoa(Def, default_str, 10);
//		if (GetProfileString(FIniSection, Name, default_str, value_str, 12) > 0)
//        {
//			value = atol(value_str);
//        }
//		else
        {
			value = Def;
        }
    }
	SaveProperty(Name, value);
	return value;
}

/*##########################################################################
#
#   Name       : TDevice::SaveProperty
#
#   Purpose....: Save an integer property		                          
#
#   In params..: Name   name of property
#                Value  value to save
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::SaveProperty(const char *Name, int Value)
{
	char stat_str[7];

	if (FIniSection != 0)
    {
		itoa(Value, stat_str, 10);
//		WriteProfileString(FIniSection, Name, stat_str);
	}
}

/*##########################################################################
#
#   Name       : TDevice::SaveProperty
#
#   Purpose....: Save a long property		                          
#
#   In params..: Name   name of property
#                Value  value to save
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::SaveProperty(const char *Name, long Value)
{
	char stat_str[12];

	if (FIniSection != 0)
    {
		ltoa(Value, stat_str, 10);
//		WriteProfileString(FIniSection, Name, stat_str);
	}
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
    if (FCurrMsg)
        delete FCurrMsg;

	if (FMsg)
        delete FMsg;

    if (FDistDevice)
        FDistDevice->RemoveUnit(this);
        
	RemoveDevice();
}

/*##########################################################################
#
#   Name       : TDevice::Init
#
#   Purpose....: Init method for class. register persistent should		
#				 done here.					                               
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDevice::Init()
{
    FCurrMsg = 0;
    FReqTag = 0;
    FReplyTag = 0;
    FInfoTag = 0;
    FInstallTag = 0;
    FCurrID = 1;
    FCurrReqID = 0;
    FCurrInfoID = 0;
    FCurrInstallID = 0;
    FCurrResetID = 0;
    FReqID = 0;
    FInfoID = 0;
    FInstallID = 0;
    FResetID = 0;
	FMsg = 0;
   	FReset = FALSE;
	FEnabled = FALSE;
	FOnline = FALSE;
	FBusy = FALSE;
	OnOnline = 0;
	OnOffline = 0;
	OnIdle = 0;
	OnBusy = 0;
	InsertDevice();
	FOpen = LoadProperty("Open", FALSE);

	if (FDistDevice)
	{
	    CreateResetTag();
	    NotifyResetTag();
	}
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
#   Purpose....: Check if device is reseted					                            #
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
    TDeviceTag *tag;

    if (!FOpen)
    {
    	FOpen = TRUE;
	    SaveProperty("Open", FOpen);

	    if (FDistDevice)
	    {
            tag = LockInfoTag();
            tag->ModifyBoolean(DEVICE_VAR_Open, FOpen);
            UnlockTag();
            SignalMsg();
        }
    }
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
    TDeviceTag *tag;

    if (FOpen)
    {
    	FOpen = FALSE;
	    SaveProperty("Open", FOpen);

	    if (FDistDevice)
	    {
            tag = LockInfoTag();
            tag->ModifyBoolean(DEVICE_VAR_Open, FOpen);
            UnlockTag();
            SignalMsg();
        }
	}
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
    TDeviceTag *tag;

    if (!FEnabled)
    {
    	FEnabled = TRUE;

	    if (FDistDevice)
	    {
            tag = LockInfoTag();
            tag->ModifyBoolean(DEVICE_VAR_Enabled, FEnabled);
            UnlockTag();
            SignalMsg();
        }
    }
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
    TDeviceTag *tag;

    if (FEnabled)
    {
    	FEnabled = FALSE;

	    if (FDistDevice)
	    {
            tag = LockInfoTag();
            tag->ModifyBoolean(DEVICE_VAR_Enabled, FEnabled);
            UnlockTag();
            SignalMsg();
        }
    }
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
    TDeviceTag *tag;

	if (!FOnline)
	{
        FOnline = TRUE;
	    if (OnOnline)
		    OnOnline(this);

    	if (FDistDevice && !IsVirtualDevice())
	    {
            tag = LockInfoTag();
            tag->ModifyBoolean(DEVICE_VAR_Online, FOnline);
            UnlockTag();
            SignalMsg();
        }
	}
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
    TDeviceTag *tag;

	if (FOnline)
	{
		FOnline = FALSE;
		if (OnOffline)
			OnOffline(this);

	    if (FDistDevice && !IsVirtualDevice())
	    {
            tag = LockInfoTag();
            tag->ModifyBoolean(DEVICE_VAR_Online, FOnline);
            UnlockTag();
            SignalMsg();
        }
	}
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
    TDeviceTag *tag;

	if (FBusy)
    {
		FBusy = FALSE;
		if (OnIdle)
			OnIdle(this);

	    if (FDistDevice && !IsVirtualDevice())
	    {
            tag = LockInfoTag();
            tag->ModifyBoolean(DEVICE_VAR_Busy, FBusy);
            UnlockTag();
            SignalMsg();
        }
	}
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
    TDeviceTag *tag;

	if (!FBusy)
	{
		FBusy = TRUE;
		if (OnBusy)
			OnBusy(this);

	    if (FDistDevice && !IsVirtualDevice())
	    {
            tag = LockInfoTag();
            tag->ModifyBoolean(DEVICE_VAR_Busy, FBusy);
            UnlockTag();
            SignalMsg();
        }
	}
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
	return 1024;
}

/*##########################################################################
#
#   Name       : TDevice::IsVirtualDevice
#
#   Purpose....: Check if device is virtual
#
#   In params..: *
#   Out params.: *
#   Returns....: Unit type
#
##########################################################################*/
int TDevice::IsVirtualDevice()
{
	return FALSE;
}

/*##########################################################################
#
#   Name       : TDevice::ResetCurrMsg
#
#   Purpose....: Reset current message
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::ResetCurrMsg()
{
    FReqTag = 0;
    FReplyTag = 0;
    FInfoTag = 0;
    FInstallTag = 0;
                
    FCurrReqID = 0;
    FCurrInfoID = 0;
    FCurrInstallID = 0;
    FCurrResetID = 0;
}

/*##########################################################################
#
#   Name       : TDevice::CreateMsg
#
#   Purpose....: Create a new message
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::CreateMsg()
{
    TDeviceTag *tag;

    if (FDistDevice)
    {
        if (FCurrMsg)
            delete FCurrMsg;

        FCurrMsg = new TDeviceMsg(GetMaxMsgSize());

        tag = FCurrMsg->AddTag(DEVICE_TAG_HEADER);
        tag->AddSigned16(DEVICE_VAR_UnitType, GetUnitType());
		tag->AddSigned16(DEVICE_VAR_UnitID, GetUnitNumber());

		FReqTag = 0;
		FReplyTag = 0;
		FInfoTag = 0;
		FInstallTag = 0;
	}
}

/*##########################################################################
#
#   Name       : TDevice::GetMsg
#
#   Purpose....: Get message to send
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
TDeviceMsg *TDevice::GetMsg()
{
    TDeviceMsg *msg;
    
    if (FDistDevice)
    {
        if (FMsg)
        {
            if (FMsg->FResend.HasExpired())
            {
        		FMsg->FResend = TDateTime();
        		FMsg->FResend.AddMilli(FDistDevice->GetTimeout());

        		return FMsg;
        	}
        }
        else
        {
    		if (FCurrMsg)
    		{
          		FMsgSection.Enter();

            	FMsg = FCurrMsg;

        		FReqID = FCurrReqID;
		        FInfoID = FCurrInfoID;
        		FInstallID = FCurrInstallID;
        		FResetID = FCurrResetID;

		        FCurrMsg = 0;

                ResetCurrMsg();

        		FMsgSection.Leave();

                if (FReqID == 0 && FInfoID == 0 && FInstallID == 0 && FResetID == 0)
                {
                    FMsg->FDeleteOnSend = TRUE;
                    msg = FMsg;
                    FMsg = 0;
                    return msg;
                }
                else
                {
               		FMsg->FResend = TDateTime();
             		FMsg->FResend.AddMilli(FDistDevice->GetTimeout());
                	return FMsg;
                }
            }
        }
	}

	return 0;
}

/*##########################################################################
#
#   Name       : TDevice::IncMsgID
#
#   Purpose....: Increment message ID
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::IncMsgID()
{
    FCurrID++;

    if (FCurrID <= 0)
        FCurrID = 1;
}

/*##########################################################################
#
#   Name       : TDevice::SignalMsg
#
#   Purpose....: Signal new message
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::SignalMsg()
{
    if (FDistDevice)
        FDistDevice->SignalMsg();
}

/*##########################################################################
#
#   Name       : TDevice::CreateResetTag
#
#   Purpose....: Create reset tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::CreateResetTag()
{
    if (FDistDevice)
    {
        FMsgSection.Enter();

        if (!FCurrMsg)
            CreateMsg();

        if (FCurrMsg)
        {
            if (!FReqTag)
            {
                FReqTag = FCurrMsg->AddTag(DEVICE_TAG_RESET);
                FReqTag->AddSigned16(DEVICE_VAR_MsgID, FCurrID);
                FCurrResetID = FCurrID;
                IncMsgID();
            }
		}

		FMsgSection.Leave();
	}
}

/*##########################################################################
#
#   Name       : TDevice::LockReqTag
#
#   Purpose....: Lock req tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
TDeviceTag *TDevice::LockReqTag()
{
    if (FDistDevice)
    {
        FMsgSection.Enter();

        if (!FCurrMsg)
            CreateMsg();

        if (FCurrMsg)
        {
            if (!FReqTag)
            {
                FReqTag = FCurrMsg->AddTag(DEVICE_TAG_REQ);
                FReqTag->AddSigned16(DEVICE_VAR_MsgID, FCurrID);
                FCurrReqID = FCurrID;
                IncMsgID();
            }

		    return FReqTag;
		}
	}
	
	return 0;
}

/*##########################################################################
#
#   Name       : TDevice::LockReplyTag
#
#   Purpose....: Lock reply tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
TDeviceTag *TDevice::LockReplyTag(short int ID)
{
	if (FDistDevice)
	{
		FMsgSection.Enter();

		if (!FCurrMsg)
			CreateMsg();

		if (FCurrMsg)
		{
			if (!FReqTag)
			{
				FReqTag = FCurrMsg->AddTag(DEVICE_TAG_REPLY);
				FReqTag->AddSigned16(DEVICE_VAR_MsgID, ID);
			}

			return FReqTag;
		}
	}
	
	return 0;
}

/*##########################################################################
#
#   Name       : TDevice::LockInfoTag
#
#   Purpose....: Lock info tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
TDeviceTag *TDevice::LockInfoTag()
{
    if (FDistDevice)
    {
        FMsgSection.Enter();

        if (!FCurrMsg)
            CreateMsg();

        if (FCurrMsg)
        {
            if (!FReqTag)
            {
                FReqTag = FCurrMsg->AddTag(DEVICE_TAG_INFO);
                FReqTag->AddSigned16(DEVICE_VAR_MsgID, FCurrID);
                FCurrInfoID = FCurrID;
                IncMsgID();
            }

		    return FReqTag;
		}
	}
	
	return 0;
}

/*##########################################################################
#
#   Name       : TDevice::LockInstallTag
#
#   Purpose....: Lock install tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
TDeviceTag *TDevice::LockInstallTag()
{
    if (FDistDevice)
    {
        FMsgSection.Enter();

        if (!FCurrMsg)
            CreateMsg();

        if (FCurrMsg)
        {
            if (!FReqTag)
            {
                FReqTag = FCurrMsg->AddTag(DEVICE_TAG_INSTALL);
                FReqTag->AddSigned16(DEVICE_VAR_MsgID, FCurrID);
                FCurrInstallID = FCurrID;
                IncMsgID();
            }

		    return FReqTag;
		}
	}
	
	return 0;
}

/*##########################################################################
#
#   Name       : TDevice::UnlockTag
#
#   Purpose....: Unlock tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::UnlockTag()
{
    if (FDistDevice)
        FMsgSection.Leave();
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
void TDevice::NotifyResetTag()
{
    TDeviceTag *tag;

    if (IsVirtualDevice())
    {
        tag = LockReqTag();
        tag->ModifyBoolean(DEVICE_VAR_Open, FOpen);
        tag->ModifyBoolean(DEVICE_VAR_Enabled, FEnabled);
        UnlockTag();
        SignalMsg();
    }
    else
    {
        tag = LockInfoTag();
        tag->ModifyBoolean(DEVICE_VAR_Open, FOpen);
        tag->ModifyBoolean(DEVICE_VAR_Enabled, FEnabled);
        tag->ModifyBoolean(DEVICE_VAR_Online, FOnline);
        tag->ModifyBoolean(DEVICE_VAR_Busy, FBusy);
        UnlockTag();
    	SignalMsg();
    }
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
void TDevice::NotifyReqTag(TDeviceTag *Tag)
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
void TDevice::NotifyReplyTag(TDeviceTag *Tag)
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
void TDevice::NotifyInfoTag(TDeviceTag *Tag)
{
    int Val;

    Val = Tag->GetBoolean(DEVICE_VAR_Open, FOpen);

    if (Val != FOpen)
    {
        if (Val)
            Open();
        else
            Close();
    }

    Val = Tag->GetBoolean(DEVICE_VAR_Enabled, FEnabled);

    if (Val != FEnabled)
    {
        if (Val)
            Enable();
        else
            Disable();
    }

    Val = Tag->GetBoolean(DEVICE_VAR_Online, FOnline);

    if (Val != FOnline)
    {
        if (Val)
            Online();
        else
            Offline();
    }

    Val = Tag->GetBoolean(DEVICE_VAR_Busy, FBusy);

    if (Val != FBusy)
    {
        if (Val)
            Busy();
        else
            Idle();
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
void TDevice::NotifyInstallTag(TDeviceTag *Tag)
{
}

/*##########################################################################
#
#   Name       : TDevice::HandleAckTag
#
#   Purpose....: Handle an ACK tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::HandleAckTag(TDeviceTag *Tag)
{
    short int ID = Tag->GetSigned16(DEVICE_VAR_MsgID, 0);

    if (FInfoID == ID)
        FInfoID = 0;

    if (FInstallID == ID)
        FInstallID = 0;

    if (FResetID == ID)
        FResetID = 0;
}

/*##########################################################################
#
#   Name       : TDevice::HandleReqTag
#
#   Purpose....: Handle an REQ tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::HandleReqTag(TDeviceTag *Tag)
{
    NotifyReqTag(Tag);
}

/*##########################################################################
#
#   Name       : TDevice::HandleReplyTag
#
#   Purpose....: Handle an REPLY tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::HandleReplyTag(TDeviceTag *Tag)
{
    short int ID = Tag->GetSigned16(DEVICE_VAR_MsgID, 0);

    if (FReqID == ID)
        NotifyReplyTag(Tag);
}

/*##########################################################################
#
#   Name       : TDevice::HandleInfoTag
#
#   Purpose....: Handle an INFO tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::HandleInfoTag(TDeviceTag *Tag)
{
    NotifyInfoTag(Tag);
}

/*##########################################################################
#
#   Name       : TDevice::HandleResetTag
#
#   Purpose....: Handle an RESET tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::HandleResetTag(TDeviceTag *Tag)
{
    if (FMsg)
        delete FMsg;

    FMsg = 0;
    FReqID = 0;
    FInfoID = 0;
    FInstallID = 0;
    FResetID = 0;

    FMsgSection.Enter();

    if (FCurrMsg)
        delete FCurrMsg;

    FCurrMsg = 0;

    ResetCurrMsg();

    FMsgSection.Leave();  

    NotifyResetTag();
}

/*##########################################################################
#
#   Name       : TDevice::HandleInstallTag
#
#   Purpose....: Handle an INSTALL tag
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::HandleInstallTag(TDeviceTag *Tag)
{
    NotifyInstallTag(Tag);
}

/*##########################################################################
#
#   Name       : TDevice::HandleMsg
#
#   Purpose....: Handle a new message
#
#   In params..: *
#   Out params.: *
#
##########################################################################*/
void TDevice::HandleMsg(TDeviceMsg *Msg)
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
                HandleReqTag(tag);
                break;

            case DEVICE_TAG_REPLY:
                HandleReplyTag(tag);
                break;

            case DEVICE_TAG_INFO:
                HandleInfoTag(tag);
                break;

            case DEVICE_TAG_RESET:
                HandleResetTag(tag);
                break;
                    
            case DEVICE_TAG_INSTALL:
                HandleInstallTag(tag);
                break;
                    
            default:
                break;
        }
        tag = Msg->GotoNextTag();
    }

    if (FReqID == 0 && FInfoID == 0 && FInstallID == 0 && FResetID == 0)
    {
        if (FMsg)
            delete FMsg;

        FMsg = 0;
    }
}

/*##########################################################################
#
#   Name       : TDistDevice::InsertUnit
#
#   Purpose....: Insert device into list of active devices
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistDevice::InsertUnit(TDevice *Device)
{
	FUnitSection.Enter();
	Device->FComList = FUnitList;
	FUnitList = Device;
	FUnitSection.Leave();
}

/*##########################################################################
#
#   Name       : TDistDevice::RemoveUnit
#
#   Purpose....: Remove device from list of active devices                  
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistDevice::RemoveUnit(TDevice *Device)
{
	TDevice *ptr;
	TDevice *prev;
	prev = 0;
	
	FUnitSection.Enter();

	ptr = FUnitList;
	while ((ptr != 0) && (ptr != Device))
	{
		prev = ptr;
		ptr = ptr->FComList;
    }
    
	if (prev == 0)
		FUnitList = FUnitList->FComList;
	else
		prev->FComList = ptr->FComList;
		
	FUnitSection.Leave();
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
	FSignal = new TSignalDevice;

	FMsgQueue = 0;
	FUnitList = 0;
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
#   Name       : TDistDevice::SignalMsg
#
#   Purpose....: Signal new message
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
    TDevice *ptr;
    TDeviceMsg *msg;
    char *data;
    int size;

    FUnitSection.Enter();

	ptr = FUnitList;
	while (ptr)
	{
	    msg = ptr->GetMsg();
	    if (msg)
	    {
            size = msg->GetSize();
            data = new char[size];
            msg->GetData(data);
	        if (msg->FDeleteOnSend)
	            delete msg;
	        SendMsg(data, size);
	        delete data;

	    }
	    ptr = ptr->FComList;
	}

    FUnitSection.Leave();
}

/*##########################################################################
#
#   Name       : TDistDevice::HandleMsg
#
#   Purpose....: Handle incoming message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistDevice::HandleMsg(TDeviceMsg *Msg)
{
    TDevice *ptr;
    TDeviceMsg *msg;
    TDeviceTag *header;
    short int UnitType = 0;
    short int UnitID = 0;

    header = Msg->GetTag(DEVICE_TAG_HEADER);

    if (header)
    {
        UnitType = header->GetSigned16(DEVICE_VAR_UnitType, 0);
        UnitID = header->GetSigned16(DEVICE_VAR_UnitID, 0);
    }

    if (UnitType)
    {
    
        FUnitSection.Enter();

	    ptr = FUnitList;
    	while (ptr)
	    {
			if (ptr->GetUnitType() == UnitType && ptr->GetUnitNumber() == UnitID)
                ptr->HandleMsg(Msg);
                
    	    ptr = ptr->FComList;
    	}
    	
        FUnitSection.Leave();
	}

}

/*##########################################################################
#
#   Name       : TDistDevice::NotifyMsg
#
#   Purpose....: Notify new msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDistDevice::NotifyMsg(const char *Data, int Size)
{
    TDeviceMsg *msg;

	msg = new TDeviceMsg(8 * Size);
	if (msg->Parse(Data, Size + 8))
	    HandleMsg(msg);

	delete msg;
}
