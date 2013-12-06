/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2011, Leif Ekblad
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
# hid.c
# HID device
#
########################################################################*/

#include "rdos.h"
#include "rdosdev.h"
#include "string.h"

#include <stdio.h>

#define FALSE 0
#define TRUE !FALSE

#define MAX_HID_DEVICES 32
#define MAX_REPORT_IDS  64

#define MAX_USAGE_TAGS      128
#define MAX_INPUT_TAGS      128
#define MAX_OUTPUT_TAGS     128
#define MAX_FEATURE_TAGS    128

extern void InitHid();

extern int GetReportDescr(struct THidDevice *dev, char *buf, int size, int interface);
#pragma aux GetReportDescr parm routine [fs esi] [es edi] [ecx] [edx] value [eax]

struct THidDescriptor
{
    unsigned char Len;
    char Type;
    char Ver[2];
    char CountryCode;
    char NumDescriptors;
    char DescriptorType;
    unsigned short int DescriptorLen;
};

typedef enum {MAIN_ITEM, GLOBAL_ITEM, LOCAL_ITEM} TItemType;

typedef enum {
         MAIN_RESV1,    GLOBAL_USAGE,       LOCAL_USE,     INV1,
         MAIN_RESV2,    GLOBAL_LOG_MIN,     LOCAL_USE_MIN, INV2,
         MAIN_RESV3,    GLOBAL_LOG_MAX,     LOCAL_USE_MAX, INV3,
         MAIN_RESV4,    GLOBAL_PHYS_MIN,    LOCAL_DES_IND, INV4,
         MAIN_RESV5,    GLOBAL_PHYS_MAX,    LOCAL_DES_MIN, INV5,
         MAIN_RESV6,    GLOBAL_UNIT_EXP,    LOCAL_DES_MAX, INV6,
         MAIN_RESV7,    GLOBAL_UNIT,        LOCAL_STR_IND, INV7,
         MAIN_RESV8,    GLOBAL_REPORT_SIZE, LOCAL_STR_MIN, INV8,
         MAIN_INPUT,    GLOBAL_REPORT_ID,   LOCAL_STR_MAX, INV9,
         MAIN_OUTPUT,   GLOBAL_REPORT_COUNT,LOCAL_DELIM,   INV10,
         MAIN_BEGIN,    GLOBAL_PUSH,        LOCAL_RESV1,   INV11,
         MAIN_FEATURE,  GLOBAL_POP,         LOCAL_RESV2,   INV12,
         MAIN_END,      GLOBAL_RESV1,       LOCAL_RESV3,   INV13,
         MAIN_RESV9,    GLOBAL_RESV2,       LOCAL_RESV4,   INV14,
         MAIN_RESV10,   GLOBAL_RESV3,       LOCAL_RESV5,   INV15,
         MAIN_RESV11,   GLOBAL_RESV4,       LOCAL_RESV6,   INV16
             } TItemTag;

struct THidReportItem
{
    unsigned char Len;
    TItemType Type;
    TItemTag Tag;
    char *Data;
};

struct THidReportEntry
{
    int UsagePage;
    int UsageId;

    int StartBit;
    int BitCount;

    int ItemParams;
};

struct THidReportIdEntry
{
    int InputCount;
    int OutputCount;
    int FeatureCount;
    
    struct THidReportEntry *InputArr;
    struct THidReportEntry *OutputArr;
    struct THidReportEntry *FeatureArr;
};
    
struct THidDevice
{
/* shared with asm */    
    int Controller;
    int Device;
    int ControlPipe;
    int ControlWait;

/* not shared with asm */    
    int DeviceNr;
    int IsRunning;
    int ItemCount;
    struct THidReportItem *ItemArr;
    struct THidReportIdEntry *ReportIdArr[MAX_REPORT_IDS];
    int ReportDescrSize;
    char ReportDescrData[1];
};

struct TUsageCacheEntry
{
    int MinUsage;
    int MaxUsage;
};

struct TTagCache
{
    int ReportCount;
    int ReportSize;
    
    int InputBit;
    int OutputBit;
    int FeatureBit;

    int InputEntry;
    int OutputEntry;
    int FeatureEntry;

    struct THidReportIdEntry *CurrReport;

    int HasMin;
    int UsageMin;

    int HasMax;
    int UsageMax;

    int UsageCount;
    struct TUsageCacheEntry UsageArr[MAX_USAGE_TAGS];

    int InputCount;
    int InputArr[MAX_INPUT_TAGS];    

    int OutputCount;
    int OutputArr[MAX_OUTPUT_TAGS];    

    int FeatureCount;
    int FeatureArr[MAX_OUTPUT_TAGS];    
};

struct THidDevice *HidArr[MAX_HID_DEVICES];

/*##########################################################################
#
#   Name       : CloseHid
#
#   Purpose....: Close HID
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void CloseHid(struct THidDevice *dev)
{
    RdosCloseUsbPipe(dev->ControlPipe);
    RdosCloseWait(dev->ControlWait);
}

/*##########################################################################
#
#   Name       : OpenHid
#
#   Purpose....: Open HID
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int OpenHid(struct THidDevice *dev)
{
    int size;
    
    dev->ControlPipe = RdosOpenUsbPipe(dev->Controller, dev->Device, 0);
    dev->ControlWait = RdosCreateWait();
    size = GetReportDescr(dev, dev->ReportDescrData, dev->ReportDescrSize, 0);

    if (size == dev->ReportDescrSize)
        return TRUE;
    else
    {
        CloseHid(dev);
        return FALSE;
    }
}

/*##########################################################################
#
#   Name       : GetReportItemSigned
#
#   Purpose....: Get report item signed value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetReportItemSigned(struct THidReportItem *item)
{
    signed char cval;
    signed short int sval;
    int val = 0;

    switch (item->Len)
    {
        case 1:
            memcpy(&cval, item->Data, 1);
            val = cval;
            break;

        case 2:
            memcpy(&sval, item->Data, 2);
            val = sval;
            break;
            
        case 4:
            memcpy(&val, item->Data, 4);
            break;
    }
    return val;
}

/*##########################################################################
#
#   Name       : GetReportItemUnsigned
#
#   Purpose....: Get report item unsigned value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetReportItemUnsigned(struct THidReportItem *item)
{
    unsigned char cval;
    unsigned short int sval;
    unsigned int val = 0;

    switch (item->Len)
    {
        case 1:
            memcpy(&cval, item->Data, 1);
            val = cval;
            break;

        case 2:
            memcpy(&sval, item->Data, 2);
            val = sval;
            break;
            
        case 4:
            memcpy(&val, item->Data, 4);
            break;
    }
    return (int)val;
}

/*##########################################################################
#
#   Name       : GetReportItems
#
#   Purpose....: Get report item count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GetReportItems(struct THidDevice *dev)
{
    int count = 0;
    int size;
    int len;
    unsigned char *ptr;

    ptr = (unsigned char *)dev->ReportDescrData;
    size = dev->ReportDescrSize;

    while (size)
    {
        if (*ptr == 0xFE)
        {
            len = ptr[1];
            len += 3;
        }
        else
        {
            switch ((*ptr) & 3)
            {
                case 0:
                    len = 0;
                    break;

                case 1:
                    len = 1;
                    break;

                case 2:
                    len = 2;
                    break;

                case 3:
                    len = 4;
                    break;
            }
            len++;
        }
        ptr += len;
        size -= len;
        count++;
    }

    dev->ItemCount = count;
}

/*##########################################################################
#
#   Name       : LoadReportItems
#
#   Purpose....: Load report items
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void LoadReportItems(struct THidDevice *dev)
{
    int pos = 0;
    int size;
    int len;
    unsigned char *ptr;
    struct THidReportItem *item;

    dev->ItemArr = (struct THidReportItem *)RdosAllocateSmallGlobalMem(dev->ItemCount * sizeof(struct THidReportItem));

    ptr = (unsigned char *)dev->ReportDescrData;
    size = dev->ReportDescrSize;
    item = dev->ItemArr;

    while (size)
    {
        if (*ptr == 0xFE)
        {
            len = ptr[1];
            item->Len = len;
            item->Type = 3;
            item->Tag = ptr[2]; 
            item->Data = ptr + 3;
            len += 3;
        }
        else
        {
            switch ((*ptr) & 3)
            {
                case 0:
                    len = 0;
                    break;

                case 1:
                    len = 1;
                    break;

                case 2:
                    len = 2;
                    break;

                case 3:
                    len = 4;
                    break;
            }
            item->Len = len;
            item->Type = ((*ptr) >> 2) & 3;
            item->Tag = ((*ptr) >> 2) & 0x3F; 
            item->Data = ptr + 1;
            len++;
        }
        ptr += len;
        size -= len;
        pos++;
        item++;
    }
};

/*##########################################################################
#
#   Name       : PrepareReportIds
#
#   Purpose....: Prepare report IDs
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void PrepareReportIds(struct THidDevice *dev)
{
    int HasReport = FALSE;
    int Index;
    int ReportCount = 1;
    int ReportId = 0;
    struct THidReportItem *item;
    struct THidReportIdEntry *CurrReport = 0;

    for (Index = 0; Index < dev->ItemCount; Index++)
    {
        item = dev->ItemArr + Index;
        if (item->Tag == GLOBAL_REPORT_ID)
        {
            ReportId = GetReportItemUnsigned(item);
            if (ReportId > 0 && ReportId < MAX_REPORT_IDS)
            {
                HasReport = TRUE;
                CurrReport = (struct THidReportIdEntry *)RdosAllocateSmallGlobalMem(sizeof(struct THidReportIdEntry));
                dev->ReportIdArr[ReportId] = CurrReport;

                CurrReport->InputCount = 0;
                CurrReport->OutputCount = 0;
                CurrReport->FeatureCount = 0;
                    
                CurrReport->InputArr = 0;
                CurrReport->OutputArr = 0;
                CurrReport->FeatureArr = 0;
            }
            else
                CurrReport = 0;
        }

        switch (item->Tag)
        {
            case MAIN_INPUT:
            case MAIN_OUTPUT:
            case MAIN_FEATURE:
                if (!CurrReport && !HasReport)
                {
                    ReportId = 0;
                    HasReport = TRUE;
                    CurrReport = (struct THidReportIdEntry *)RdosAllocateSmallGlobalMem(sizeof(struct THidReportIdEntry));
                    dev->ReportIdArr[ReportId] = CurrReport;

                    CurrReport->InputCount = 0;
                    CurrReport->OutputCount = 0;
                    CurrReport->FeatureCount = 0;
                    
                    CurrReport->InputArr = 0;
                    CurrReport->OutputArr = 0;
                    CurrReport->FeatureArr = 0;
                }
                break;

            case GLOBAL_REPORT_COUNT:
                ReportCount = GetReportItemUnsigned(item);
                break;

        }

        if (CurrReport)
        {                    
            if (item->Tag == MAIN_INPUT)
                CurrReport->InputCount += ReportCount;
            
            if (item->Tag == MAIN_OUTPUT)
                CurrReport->OutputCount += ReportCount;

            if (item->Tag == MAIN_FEATURE)
                CurrReport->FeatureCount += ReportCount;
        }         
    }
}

/*##########################################################################
#
#   Name       : InitReportEntry
#
#   Purpose....: Initialize report entry fields
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void InitReportEntry(struct THidReportEntry *entry)
{
    entry->UsagePage = 0;
    entry->UsageId = 0;
    entry->StartBit = 0;
    entry->BitCount = 0;
    entry->ItemParams = 0;
}

/*##########################################################################
#
#   Name       : CreateReportIdArrays
#
#   Purpose....: Create report ID arrays
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void CreateReportIdArrays(struct THidDevice *dev)
{
    int i;
    int ReportId;
    struct THidReportIdEntry *report;
    struct THidReportEntry *arr;

    for (ReportId = 0; ReportId < MAX_REPORT_IDS; ReportId++)
    {
        report = dev->ReportIdArr[ReportId];
        if (report)
        {
            if (report->InputCount)
            {
                arr = (struct THidReportEntry *)RdosAllocateSmallGlobalMem(report->InputCount * sizeof(struct THidReportEntry));
                for (i = 0; i < report->InputCount; i++)
                    InitReportEntry(&arr[i]);
                report->InputArr = arr;
            }            

            if (report->OutputCount)
            {
                arr = (struct THidReportEntry *)RdosAllocateSmallGlobalMem(report->OutputCount * sizeof(struct THidReportEntry));
                for (i = 0; i < report->OutputCount; i++)
                    InitReportEntry(&arr[i]);
                report->OutputArr = arr;
            }            

            if (report->FeatureCount)
            {
                arr = (struct THidReportEntry *)RdosAllocateSmallGlobalMem(report->FeatureCount * sizeof(struct THidReportEntry));
                for (i = 0; i < report->FeatureCount; i++)
                    InitReportEntry(&arr[i]);
                report->FeatureArr = arr;
            }            
        }
    }    
}

/*##########################################################################
#
#   Name       : LoadReportIdArrays
#
#   Purpose....: Load report ID arrays
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void LoadReportIdArrays(struct THidDevice *dev)
{
    int i;
    int Index;
    int ReportCount = 1;
    int ReportSize = 1;
    int InputBit = 0;
    int OutputBit = 0;
    int FeatureBit = 0;
    int InputEntry = 0;
    int OutputEntry = 0;
    int FeatureEntry = 0;
    int ReportId = 0;
    int UsagePage = 0;
    int UsageId = 0;
    struct THidReportItem *item;
    struct THidReportIdEntry *CurrReport = 0;
    struct THidReportEntry *entry;

    CurrReport = dev->ReportIdArr[0];

    for (Index = 0; Index < dev->ItemCount; Index++)
    {
        item = dev->ItemArr + Index;
        if (item->Tag == GLOBAL_REPORT_ID)
        {
            InputBit = 0;
            OutputBit = 0;
            FeatureBit = 0;

            InputEntry = 0;
            OutputEntry = 0;
            FeatureEntry = 0;
            
            ReportId = GetReportItemUnsigned(item);
            if (ReportId > 0 && ReportId < MAX_REPORT_IDS)
                CurrReport = dev->ReportIdArr[ReportId];
            else
                CurrReport = 0;
        }

        if (CurrReport)
        {                    
            switch (item->Tag)
            {
                case GLOBAL_REPORT_SIZE:
                    ReportSize = GetReportItemUnsigned(item);
                    break;

                case GLOBAL_REPORT_COUNT:
                    ReportCount = GetReportItemUnsigned(item);
                    break;

                case GLOBAL_USAGE:
                    UsagePage = GetReportItemUnsigned(item);
                    break;
                    
                case LOCAL_USE:
                    UsageId = GetReportItemUnsigned(item);
                    break;

                case MAIN_INPUT:
                    for (i = 0; i < ReportCount; i++)
                    {
                        entry = &CurrReport->InputArr[InputEntry + i];
                        entry->StartBit = InputBit;
                        entry->BitCount = ReportSize;
                        entry->UsagePage = UsagePage;
                        entry->UsageId = UsageId;
                        entry->ItemParams = GetReportItemUnsigned(item);
                        InputBit += ReportSize;
                    }
                    InputEntry += ReportCount;
                    break;

                case MAIN_OUTPUT:
                    for (i = 0; i < ReportCount; i++)
                    {
                        entry = &CurrReport->OutputArr[OutputEntry + i];
                        entry->StartBit = OutputBit;
                        entry->BitCount = ReportSize;
                        entry->UsagePage = UsagePage;
                        entry->UsageId = UsageId;
                        entry->ItemParams = GetReportItemUnsigned(item);
                        OutputBit += ReportSize;
                    }
                    OutputEntry += ReportCount;
                    break;

                case MAIN_FEATURE:
                    for (i = 0; i < ReportCount; i++)
                    {
                        entry = &CurrReport->FeatureArr[FeatureEntry + i];
                        entry->StartBit = FeatureBit;
                        entry->BitCount = ReportSize;
                        entry->UsagePage = UsagePage;
                        entry->UsageId = UsageId;
                        entry->ItemParams = GetReportItemUnsigned(item);
                        FeatureBit += ReportSize;
                    }
                    FeatureEntry += ReportCount;
                    break;
            }
        }         
    }
}

/*##########################################################################
#
#   Name       : InitReport
#
#   Purpose....: Init cache report
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void InitReport(struct TTagCache *cache)
{
    cache->InputBit = 0;
    cache->OutputBit = 0;
    cache->FeatureBit = 0;

    cache->InputEntry = 0;
    cache->OutputEntry = 0;
    cache->FeatureEntry = 0;   

    cache->CurrReport = 0;
}

/*##########################################################################
#
#   Name       : CreateTagCache
#
#   Purpose....: Create tag cache
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct TTagCache *CreateTagCache()
{
    struct TTagCache *cache = RdosAllocateSmallGlobalMem(sizeof(struct TTagCache));

    cache->UsageCount = 0;
    cache->InputCount = 0;
    cache->OutputCount = 0;
    cache->FeatureCount = 0;    
    cache->HasMin = FALSE;
    cache->HasMax = FALSE;

    InitReport(cache);

    return cache;
}

/*##########################################################################
#
#   Name       : FreeTagCache
#
#   Purpose....: Free tag cache
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void FreeTagCache(struct TTagCache *cache)
{
    RdosFreeMem(RdosPointerToSelector(cache));
}

/*##########################################################################
#
#   Name       : ClearReport
#
#   Purpose....: Clear cache report
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ClearCache(struct TTagCache *cache)
{
    cache->UsageCount = 0;
    cache->InputCount = 0;
    cache->OutputCount = 0;
    cache->FeatureCount = 0;    
    cache->HasMin = FALSE;
    cache->HasMax = FALSE;
}

/*##########################################################################
#
#   Name       : SetReport
#
#   Purpose....: Set report for cache
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SetReport(struct TTagCache *cache, struct THidReportIdEntry *report)
{
    ClearCache(cache);
    InitReport(cache);

    cache->CurrReport = report;
}

/*##########################################################################
#
#   Name       : SetReportCount
#
#   Purpose....: Set report count
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SetReportCount(struct TTagCache *cache, int count)
{
    if (cache->CurrReport)
    {
        cache->ReportCount = count;
    }
}

/*##########################################################################
#
#   Name       : SetReportSize
#
#   Purpose....: Set report size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SetReportSize(struct TTagCache *cache, int size)
{
    if (cache->CurrReport)
    {
        cache->ReportSize = size;
    }
}

/*##########################################################################
#
#   Name       : AddUsageMin
#
#   Purpose....: Add usage min
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddUsageMin(struct TTagCache *cache, int UsageId)
{
    struct TUsageCacheEntry *entry;

    if (cache->CurrReport && cache->UsageCount < MAX_USAGE_TAGS)
    {      
        if (cache->HasMax)
        {
            entry = &cache->UsageArr[cache->UsageCount];
            entry->MinUsage = UsageId;
            entry->MaxUsage = cache->UsageMax;
            cache->UsageCount++;
            cache->HasMin = FALSE;
            cache->HasMax = FALSE;
        }
        else
        {
            cache->UsageMin = UsageId;
            cache->HasMin = TRUE;
        }
    }                    
}

/*##########################################################################
#
#   Name       : AddUsageMax
#
#   Purpose....: Add usage max
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddUsageMax(struct TTagCache *cache, int UsageId)
{
    struct TUsageCacheEntry *entry;

    if (cache->CurrReport && cache->UsageCount < MAX_USAGE_TAGS)
    {      
        if (cache->HasMin)
        {
            entry = &cache->UsageArr[cache->UsageCount];
            entry->MaxUsage = UsageId;
            entry->MinUsage = cache->UsageMin;
            cache->UsageCount++;
            cache->HasMin = FALSE;
            cache->HasMax = FALSE;
        }
        else
        {
            cache->UsageMax = UsageId;
            cache->HasMax = TRUE;
        }
    }                    
}

/*##########################################################################
#
#   Name       : AddUsage
#
#   Purpose....: Add usage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddUsage(struct TTagCache *cache, int UsageId)
{
    struct TUsageCacheEntry *entry;

    if (cache->CurrReport && cache->UsageCount < MAX_USAGE_TAGS)
    {      
        entry = &cache->UsageArr[cache->UsageCount];
        entry->MinUsage = UsageId;
        entry->MaxUsage = UsageId;
        cache->UsageCount++;
        cache->HasMin = FALSE;
        cache->HasMax = FALSE;
    }
}

/*##########################################################################
#
#   Name       : AddInput
#
#   Purpose....: Add input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddInput(struct TTagCache *cache, int Input)
{
    if (cache->CurrReport && cache->InputCount < MAX_INPUT_TAGS)
    {      
        cache->InputArr[cache->InputCount] = Input;
        cache->InputCount++;
    }
}

/*##########################################################################
#
#   Name       : AddOutput
#
#   Purpose....: Add output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddOutput(struct TTagCache *cache, int Output)
{
    if (cache->CurrReport && cache->OutputCount < MAX_OUTPUT_TAGS)
    {      
        cache->OutputArr[cache->OutputCount] = Output;
        cache->OutputCount++;
    }
}

/*##########################################################################
#
#   Name       : AddFeature
#
#   Purpose....: Add feature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddFeature(struct TTagCache *cache, int Feature)
{
    if (cache->CurrReport && cache->FeatureCount < MAX_FEATURE_TAGS)
    {      
        cache->FeatureArr[cache->FeatureCount] = Feature;
        cache->FeatureCount++;
    }
}

/*##########################################################################
#
#   Name       : Test gate
#
##########################################################################*/

#pragma aux ImplTestGate "*" rdosdev parm routine [es edi]
void __far ImplTestGate(const char *msg)
{
    int Index;
    int val;
    struct THidDevice *dev;
    struct THidReportItem *item;
    struct TTagCache *cache;

    dev = HidArr[0];

    cache = CreateTagCache();
    SetReport(cache, dev->ReportIdArr[0]);

    for (Index = 0; Index < dev->ItemCount; Index++)
    {
        item = dev->ItemArr + Index;

        switch (item->Tag)
        {
            case GLOBAL_REPORT_ID:
                val = GetReportItemUnsigned(item);
                if (val > 0 && val < MAX_REPORT_IDS)
                SetReport(cache, dev->ReportIdArr[val]);
                break;
            
            case GLOBAL_REPORT_SIZE:
                val = GetReportItemUnsigned(item);
                SetReportSize(cache, val);
                break;

            case GLOBAL_REPORT_COUNT:
                val = GetReportItemUnsigned(item);
                SetReportCount(cache, val);
                break;
                    
            case LOCAL_USE:
                val = GetReportItemUnsigned(item);
                AddUsage(cache, val);
                break;

            case LOCAL_USE_MIN:
                val = GetReportItemUnsigned(item);
                AddUsageMin(cache, val);
                break;

            case LOCAL_USE_MAX:
                val = GetReportItemUnsigned(item);
                AddUsageMax(cache, val);
                break;
                
            case MAIN_INPUT:
                val = GetReportItemUnsigned(item);
                AddInput(cache, val);
                break;

            case MAIN_OUTPUT:
                val = GetReportItemUnsigned(item);
                AddOutput(cache, val);
                break;

            case MAIN_FEATURE:
                val = GetReportItemUnsigned(item);
                AddFeature(cache, val);
                break;
        }         
    }
    FreeTagCache(cache);
}

/*##########################################################################
#
#   Name       : AddReportItemSigned
#
#   Purpose....: Add report item signed value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddReportItemSigned(struct THidReportItem *item, char *buf)
{
    char str[10];    
    int val = GetReportItemSigned(item);
    sprintf(str, " (%d)", val);
    strcat(buf, str);     
}

/*##########################################################################
#
#   Name       : AddReportItemUnsigned
#
#   Purpose....: Add report item unsigned value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddReportItemUnsigned(struct THidReportItem *item, char *buf)
{
    char str[10];    
    int val = GetReportItemUnsigned(item);
    sprintf(str, " (%d)", val);
    strcat(buf, str);     
}

/*##########################################################################
#
#   Name       : AddReportUsageItem
#
#   Purpose....: Add report usage item
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddReportUsageItem(struct THidReportItem *item, char *buf)
{
    char str[10];    
    int val = GetReportItemUnsigned(item);

    if (item->Len == 4)
        sprintf(str, " (%04hX)", val);
    else    
        sprintf(str, " (%02hX)", val);

    strcat(buf, str);     
}

/*##########################################################################
#
#   Name       : AddReportControl
#
#   Purpose....: Add report input, output or feature value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddReportControl(char *buf, int val)
{
    strcat(buf, " (");

    if (val & 1)
        strcat(buf, "Const");
    else
        strcat(buf, "Data");

    if (val & 2)    
        strcat(buf, ", Var");
    else
        strcat(buf, ", Array");

    if (val & 4)
        strcat(buf, ", Rel");
    else
        strcat(buf, ", Abs");

    if (val & 8)
        strcat(buf, ", Wrap");

    if (val & 0x10)
        strcat(buf, ", Non-lin");
    else
        strcat(buf, ", Lin");

    if (val & 0x20 == 0)
        strcat(buf, ", Pref");

    if (val & 0x40)
        strcat(buf, ", Null");

    if (val & 0x80)
        strcat(buf, ", Volatile");
                
    strcat(buf, ")");
}

/*##########################################################################
#
#   Name       : AddReportControlItem
#
#   Purpose....: Add report input, output or feature value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddReportControlItem(struct THidReportItem *item, char *buf)
{
    int val = GetReportItemUnsigned(item);

    AddReportControl(buf, val);
}

/*##########################################################################
#
#   Name       : AddReportCollectionItem
#
#   Purpose....: Add report collection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddReportCollectionItem(struct THidReportItem *item, char *buf)
{
    int val = GetReportItemUnsigned(item);

    switch (val)
    {
        case 0:
            strcat(buf, " (Physical)");
            break;

        case 1:
            strcat(buf, " (Application)");
            break;

        case 2:
            strcat(buf, " (Logical)");
            break;

        case 3:
            strcat(buf, " (Report)");
            break;

        case 4:
            strcat(buf, " (Array)");
            break;

        case 5:
            strcat(buf, " (Usage Switch)");
            break;

        case 6:
            strcat(buf, " (Usage Modified)");
            break;
    }
}

/*##########################################################################
#
#   Name       : AddReportUnitItem
#
#   Purpose....: Add report unit
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddReportUnitItem(struct THidReportItem *item, char *buf)
{
    int val = GetReportItemUnsigned(item);
    
    strcat(buf, " (");

    if (val & 0xF)
    {
        switch (val & 0xF)
        {
            case 1:
                strcat(buf, "SI Lin");
                break;

            case 2:
                strcat(buf, "SI Rot");
                break;

            case 3:
                strcat(buf, "Eng Lin");
                break;

            case 4:
                strcat(buf, "Eng Rot");
                break;

            default:
                strcat(buf, "Resv");
                break;
        }

        switch ((val & 0xF0) >> 4)
        {
            case 1:
                strcat(buf, " cm");
                break;

            case 2:
                strcat(buf, " radians");
                break;

            case 3:
                strcat(buf, " inch");
                break;

            case 4:
                strcat(buf, " degrees");
                break;
         }

        switch ((val & 0xF00) >> 8)
        {
            case 1:
            case 2:
                strcat(buf, " gram");
                break;

            case 3:
            case 4:
                strcat(buf, " slug");
                break;
        }

        if (val & 0xF000)
            strcat(buf, " seconds");
            
        switch ((val & 0xF0000) >> 16)
        {
            case 1:
            case 2:
                strcat(buf, " kelvin");
                break;

            case 3:
            case 4:
                strcat(buf, " fahrenheit");
                break;
        }

        if (val & 0xF00000)
            strcat(buf, " ampere");

        if (val & 0xF000000)
            strcat(buf, " candela");
    }

    strcat(buf, ")");

}

/*##########################################################################
#
#   Name       : AddReportExpItem
#
#   Purpose....: Add report unit exponent
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddReportExpItem(struct THidReportItem *item, char *buf)
{
    char str[10];    
    int val = GetReportItemSigned(item);

    if (val & 8)
        val -= 0x10;

    sprintf(str, " (%d)", val);
    strcat(buf, str);     
}

/*##########################################################################
#
#   Name       : ImplGetHidReportItem
#
#   Purpose....: Get HID report item
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetHidReportItem "*" rdosdev parm routine [eax] [edx] [es edi]
void __far ImplGetHidReportItem(int Device, int Index, char *Buf)
{
    int i;
    int Ins;
    struct THidDevice *dev;
    struct THidReportItem *item;
    int ok = FALSE;

    RdosSaveEax();

    if (Device >= 0 && Device < MAX_HID_DEVICES)
    {
        dev = HidArr[Device];

        if (dev)
        {
            if (Index >= 0 && Index < dev->ItemCount)
            {
                Ins = 0;
                item = dev->ItemArr;
                for (i = 0; i < Index; i++)
                {
                    if (item->Tag == MAIN_BEGIN)
                        Ins++;
                    if (item->Tag == MAIN_END)
                        Ins--;
                    item++;
                }  

                if (item->Tag == MAIN_END)
                    Ins--;

                Buf[0] = 0;
                for (i = 0; i < Ins; i++)
                    strcat(Buf, "  ");                  
                
                ok = TRUE;
                
                item = dev->ItemArr + Index;

                switch (item->Tag)
                {
                    case MAIN_INPUT:
                        strcat(Buf, "Input");
                        AddReportControlItem(item, Buf);
                        break;

                    case MAIN_OUTPUT:
                        strcat(Buf, "Output");
                        AddReportControlItem(item, Buf);
                        break;

                    case MAIN_BEGIN:
                        strcat(Buf, "Collection");
                        AddReportCollectionItem(item, Buf);
                        break;

                    case MAIN_FEATURE:
                        strcat(Buf, "Feature");
                        AddReportControlItem(item, Buf);
                        break;

                    case MAIN_END:
                        strcat(Buf, "End Collection");
                        break;

                    case GLOBAL_USAGE:
                        strcat(Buf, "Usage Page");
                        AddReportUsageItem(item, Buf);
                        break;

                    case GLOBAL_LOG_MIN:
                        strcat(Buf, "Logical Min");
                        AddReportItemSigned(item, Buf);
                        break;

                    case GLOBAL_LOG_MAX:
                        strcat(Buf, "Logical Max");
                        AddReportItemSigned(item, Buf);
                        break;

                    case GLOBAL_PHYS_MIN:
                        strcat(Buf, "Physical Min");
                        AddReportItemSigned(item, Buf);
                        break;

                    case GLOBAL_PHYS_MAX:
                        strcat(Buf, "Physical Max");
                        AddReportItemSigned(item, Buf);
                        break;
                        
                    case GLOBAL_UNIT_EXP:
                        strcat(Buf, "Unit Exp");
                        AddReportExpItem(item, Buf);
                        break;
                        
                    case GLOBAL_UNIT:
                        strcat(Buf, "Unit");
                        AddReportUnitItem(item, Buf);
                        break;
                        
                    case GLOBAL_REPORT_SIZE:
                        strcat(Buf, "Report Size");
                        AddReportItemUnsigned(item, Buf);
                        break;
                        
                    case GLOBAL_REPORT_ID:
                        strcat(Buf, "Report ID");
                        AddReportItemUnsigned(item, Buf);
                        break;
                        
                    case GLOBAL_REPORT_COUNT:
                        strcat(Buf, "Report Count");
                        AddReportItemUnsigned(item, Buf);
                        break;
                                                
                    case GLOBAL_PUSH:
                        strcat(Buf, "Push");
                        break;
                                                
                    case GLOBAL_POP:
                        strcat(Buf, "Pop");
                        break;
                        
                    case LOCAL_USE:
                        strcat(Buf, "Usage ID");
                        AddReportUsageItem(item, Buf);
                        break;

                    case LOCAL_USE_MIN:
                        strcat(Buf, "Usage Min");
                        AddReportUsageItem(item, Buf);
                        break;

                    case LOCAL_USE_MAX:
                        strcat(Buf, "Usage Max");
                        AddReportUsageItem(item, Buf);
                        break;

                    case LOCAL_DES_IND:
                        strcat(Buf, "Descriptor Index");
                        break;

                    case LOCAL_DES_MIN:
                        strcat(Buf, "Descriptor Min");
                        break;

                    case LOCAL_DES_MAX:
                        strcat(Buf, "Descriptor Max");
                        break;

                    case LOCAL_STR_IND:
                        strcat(Buf, "String Index");
                        break;

                    case LOCAL_STR_MIN:
                        strcat(Buf, "String Min");
                        break;

                    case LOCAL_STR_MAX:
                        strcat(Buf, "String Max");
                        break;

                    case LOCAL_DELIM:
                        strcat(Buf, "Delimiter");
                        break;

                    default:
                        strcat(Buf, "Unknown");
                        break;
                }
                
            }
        }
    }

    if (ok)
        RdosSetSuccess();
    else
        RdosSetFailure();

    RdosRestoreEax();
}

/*##########################################################################
#
#   Name       : ImplGetHidReportInputData
#
#   Purpose....: Get HID report input data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetHidReportInputData "*" rdosdev parm routine [eax] [ebx] [edx] [es edi]
void __far ImplGetHidReportInputData(int Device, int ReportId, int Index, char *Buf)
{
    struct THidDevice *dev;
    struct THidReportIdEntry *report;
    struct THidReportEntry *entry;
    char str[80];
    int ok = FALSE;

    RdosSaveEax();

    if (Device >= 0 && Device < MAX_HID_DEVICES)
    {
        dev = HidArr[Device];

        if (dev)
        {
            if (ReportId >= 0 && ReportId < MAX_REPORT_IDS)
            {
                report = dev->ReportIdArr[ReportId];
            
                if (report)
                {
                    if (Index >= 0 && Index < report->InputCount)
                    {
                        ok = TRUE;
                        
                        entry = &report->InputArr[Index];

                        sprintf(Buf, "bit %d-%d: ", entry->StartBit, entry->StartBit + entry->BitCount - 1);

                        sprintf(str, "%02hX.%02hX ", entry->UsagePage, entry->UsageId);
                        strcat(Buf, str);

                        AddReportControl(Buf, entry->ItemParams);

                    }
                }
            }
        }
    }

    if (ok)
        RdosSetSuccess();
    else
        RdosSetFailure();

    RdosRestoreEax();
}

/*##########################################################################
#
#   Name       : ImplGetHidReportOutputData
#
#   Purpose....: Get HID report output data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetHidReportOutputData "*" rdosdev parm routine [eax] [ebx] [edx] [es edi]
void __far ImplGetHidReportOutputData(int Device, int ReportId, int Index, char *Buf)
{
    struct THidDevice *dev;
    struct THidReportIdEntry *report;
    struct THidReportEntry *entry;
    char str[80];
    int ok = FALSE;

    RdosSaveEax();

    if (Device >= 0 && Device < MAX_HID_DEVICES)
    {
        dev = HidArr[Device];

        if (dev)
        {
            if (ReportId >= 0 && ReportId < MAX_REPORT_IDS)
            {
                report = dev->ReportIdArr[ReportId];
            
                if (report)
                {
                    if (Index >= 0 && Index < report->OutputCount)
                    {
                        ok = TRUE;
                        
                        entry = &report->OutputArr[Index];

                        sprintf(Buf, "bit %d-%d: ", entry->StartBit, entry->StartBit + entry->BitCount - 1);

                        sprintf(str, "%02hX.%02hX ", entry->UsagePage, entry->UsageId);
                        strcat(Buf, str);

                        AddReportControl(Buf, entry->ItemParams);
                    }
                }
            }
        }
    }

    if (ok)
        RdosSetSuccess();
    else
        RdosSetFailure();

    RdosRestoreEax();
}

/*##########################################################################
#
#   Name       : ImplGetHidReportFeatureData
#
#   Purpose....: Get HID report feature data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetHidReportFeatureData "*" rdosdev parm routine [eax] [ebx] [edx] [es edi]
void __far ImplGetHidReportFeatureData(int Device, int ReportId, int Index, char *Buf)
{
    struct THidDevice *dev;
    struct THidReportIdEntry *report;
    struct THidReportEntry *entry;
    char str[80];
    int ok = FALSE;

    RdosSaveEax();

    if (Device >= 0 && Device < MAX_HID_DEVICES)
    {
        dev = HidArr[Device];

        if (dev)
        {
            if (ReportId >= 0 && ReportId < MAX_REPORT_IDS)
            {
                report = dev->ReportIdArr[ReportId];
            
                if (report)
                {
                    if (Index >= 0 && Index < report->FeatureCount)
                    {
                        ok = TRUE;
                        
                        entry = &report->FeatureArr[Index];

                        sprintf(Buf, "bit %d-%d: ", entry->StartBit, entry->StartBit + entry->BitCount - 1);

                        sprintf(str, "%02hX.%02hX ", entry->UsagePage, entry->UsageId);
                        strcat(Buf, str);

                        AddReportControl(Buf, entry->ItemParams);
                    }
                }
            }
        }
    }

    if (ok)
        RdosSetSuccess();
    else
        RdosSetFailure();

    RdosRestoreEax();
}

/*##########################################################################
#
#   Name       : HidThread
#
#   Purpose....: Hid thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux HidThread "*" rdosdev parm routine [gs ebx]
void __far HidThread(void *param)
{
    int Index;
    int ok;
    struct THidDevice *dev;

    dev = (struct THidDevice *)param;
    Index = dev->DeviceNr;

    ok = OpenHid(dev);
    if (ok)
    {
        GetReportItems(dev);
        LoadReportItems(dev);
        PrepareReportIds(dev);
        CreateReportIdArrays(dev);
        LoadReportIdArrays(dev);
    
        for (;;)
        {
            if (!HidArr[Index])
                break;

            RdosWaitMilli(100);
        }
        CloseHid(dev);
    }

    dev->IsRunning = FALSE;
    RdosTerminateThread();
}

/*##########################################################################
#
#   Name       : UsbAttach
#
#   Purpose....: USB attach notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux UsbAttach "*" rdosdev parm routine [ebx] [eax]
void UsbAttach(int controller, int device)
{
    int i;
    int j;
    struct THidDevice *dev;
    int size;
    struct THidDescriptor *descr;
    char *buf = RdosAllocateSmallGlobalMem(0x1000);
    char *ptr;
    char ThreadName[64];

    for (i = 0; i < MAX_HID_DEVICES; i++)
    {
        if (HidArr[i] == 0)
        {
            size = RdosGetUsbConfig(controller, device, 0, buf, 0x1000);
                   
            ptr = buf;
            while (size > 0)
            {
                descr = (struct THidDescriptor *)ptr;
                if (descr->Type == 0x21 && descr->DescriptorType == 0x22)
                {
                    dev = (struct THidDevice *)RdosAllocateSmallGlobalMem(sizeof(struct THidDevice) + descr->DescriptorLen);
                    dev->Controller = controller;
                    dev->Device = device;
                    dev->ReportDescrSize = descr->DescriptorLen;
                    HidArr[i] = dev;        
                    break;
                }
                ptr += descr->Len;
                size -= descr->Len;
            }

            for (j = 0; j < MAX_REPORT_IDS; j++)
                dev->ReportIdArr[j] = 0;

            dev->DeviceNr = i;
            dev->IsRunning = TRUE;
            sprintf(ThreadName, "Hid %02hX.%02hX", controller, device);
            RdosCreateKernelThread(5, 0x1000, HidThread, ThreadName, dev);
            break;
        }
    }
    RdosFreeMem(RdosPointerToSelector(buf));
}

/*##########################################################################
#
#   Name       : UsbDetach
#
#   Purpose....: USB detach notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux UsbDetach "*" rdosdev parm routine [ebx] [eax]
void UsbDetach(int controller, int device)
{
    int i;
    struct THidDevice *dev;

    for (i = 0; i < MAX_HID_DEVICES; i++)
    {
        dev = HidArr[i];
        if (dev)
        {
            if (dev->Controller == controller && dev->Device == device)
            {
                HidArr[i] = 0;

                while (dev->IsRunning)
                    RdosWaitMilli(100);

                RdosFreeMem(RdosPointerToSelector(dev));
                break;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....: Initialization
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main()
{
    int i;

    for (i = 0; i < MAX_HID_DEVICES; i++)
        HidArr[i] = 0;

    InitHid();
    RdosRegisterBimodalUserGate(usergate_get_hid_report_item, (__rdos_gate_callback *)&ImplGetHidReportItem, "Get Hid Report Item"); 
    RdosRegisterBimodalUserGate(usergate_get_hid_report_input_data, (__rdos_gate_callback *)&ImplGetHidReportInputData, "Get Hid Report Input Data"); 
    RdosRegisterBimodalUserGate(usergate_get_hid_report_output_data, (__rdos_gate_callback *)&ImplGetHidReportOutputData, "Get Hid Report Output Data"); 
    RdosRegisterBimodalUserGate(usergate_get_hid_report_feature_data, (__rdos_gate_callback *)&ImplGetHidReportFeatureData, "Get Hid Report Feature Data"); 

    RdosRegisterBimodalUserGate(usergate_test_gate, (__rdos_gate_callback *)&ImplTestGate, "Test Gate");

    return TRUE;
}
