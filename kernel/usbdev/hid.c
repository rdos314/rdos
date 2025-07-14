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
#define MAX_HID_TABLES      4

extern void InitHid();

extern void InitKey();
extern void InitMouse();
extern void InitTouch();

extern int GetReportDescr(struct THidDevice *dev, char *buf, int size, int interface);
#pragma aux GetReportDescr parm routine [fs esi] [es edi] [ecx] [edx] value [eax]

extern void OpenHidDev(struct THidDevice *dev, char *config);
#pragma aux OpenHidDev parm routine [fs esi] [es edi]

extern void CloseHidDev(struct THidDevice *dev);
#pragma aux CloseHidDev parm routine [fs esi]

extern void OpenIntrPipe(struct THidDevice *dev);
#pragma aux OpenIntrPipe parm routine [fs esi]

extern int IsHidConnected(struct THidDevice *dev);
#pragma aux IsHidConnected parm routine [fs esi] value [eax]

extern char *WaitForReport(struct THidDevice *dev);
#pragma aux WaitForReport parm routine [fs esi] value [es edi]

extern int HasCustomDriver(struct THidDevice *dev);
#pragma aux HasCustomDriver parm routine [fs esi] value [eax]

extern int GetHidTableCount();
#pragma aux GetHidTableCount value [eax]

extern int HidBegin(int Index, struct THidDevice *Dev, struct THidReportIdEntry *Report);
#pragma aux HidBegin parm routine [edi] [gs ebx] [fs esi] value [ebx]

extern void HidDefine(int Index, int Handle, int Entry, int UsagePage, int Usage, int ItemParams);
#pragma aux HidDefine parm routine [edi] [ebx] [esi] [ecx] [eax] [edx]

extern int HidEnd(int Index, int Handle);
#pragma aux HidEnd parm routine [edi] [ebx] value [eax]

extern void HidClose(int Index, int Handle);
#pragma aux HidClose parm routine [edi] [ebx]

extern void HidHandleReport(int Index, int Handle, char *ReportData);
#pragma aux HidHandleReport parm routine [edi] [ebx] [fs esi]

extern int GetSignedValue(char *Buf, int StartBit, int BitCount);
#pragma aux GetSignedValue parm routine [es edi] [edx] [ecx] value [eax]

extern int GetUnsignedValue(char *Buf, int StartBit, int BitCount);
#pragma aux GetUnsignedValue parm routine [es edi] [edx] [ecx] value [eax]

extern void SetIdle(struct THidDevice *dev, int ReportId, int Value);
#pragma aux SetIdle parm routine [fs esi] [ebx] [eax]

extern int CreateOutputReport(struct THidDevice *dev, int ReportId, int Size);
#pragma aux CreateOutputReport parm routine [fs esi] [ebx] [ecx] value [eax]

extern int CreateFeatureReport(struct THidDevice *dev, int ReportId, int Size);
#pragma aux CreateFeatureReport parm routine [fs esi] [ebx] [ecx] value [eax]

extern void FreeReport(int Handle);
#pragma aux FreeReport parm routine [ebx]

extern int GetReportSize(int Handle);
#pragma aux GetReportSize parm routine [ebx] value [ecx]

extern char *GetReportBuf(int Handle);
#pragma aux GetReportBuf parm routine [ebx] value [es edi]

extern void SetReportValue(int Handle, int StartBit, int BitCount, int Value);
#pragma aux SetReportValue parm routine [ebx] [edx] [ecx] [eax]

extern void SendOutputReport(int Handle);
#pragma aux SendOutputReport parm routine [ebx]

extern void ReadFeatureReport(int Handle);
#pragma aux ReadFeatureReport parm routine [ebx]

extern void WriteFeatureReport(int Handle);
#pragma aux WriteFeatureReport parm routine [ebx]

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
    int UsageIdLow;
    int UsageIdHigh;

    int StartBit;
    int BitCount;

    int ItemParams;

    int HasLogical;
    int LogicalMin;
    int LogicalMax;

    int HasPhysical;
    int PhysicalMin;
    int PhysicalMax;
};

struct THidTable
{
    int Index;
    int Handle;
};

struct THidDevice;

struct THidReportIdEntry
{
    struct THidDevice *Device;
    int ReportId;

    int InputCount;
    int OutputCount;
    int FeatureCount;

    int TableCount;
    struct THidTable TableArr[MAX_HID_TABLES];

    int ReportHandle;

    struct THidReportEntry *InputArr;
    struct THidReportEntry *OutputArr;
    struct THidReportEntry *FeatureArr;
};

/* shared with asm */

struct THidDevice
{
    unsigned short int Controller;
    unsigned char Port;

    unsigned char Interface;
    unsigned char Protocol;
    unsigned char IntrIn;

    short int DeviceHandle;
    short int ControlWait;
    short int IntrWait;
    short int IntrSize;
    short int IntrBufSel;
    short int PipeSize;

    unsigned char CountryCode;
    unsigned char DescrCount;

    int StopReq;
    int Thread;

/* not shared */
    char *ConfigBuf;

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
    int UsagePage;

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

    int UsageEmpty;

    int HasLogical;
    int LogicalMin;
    int LogicalMax;

    int HasPhysical;
    int PhysicalMin;
    int PhysicalMax;

    int UsageCount;
    struct TUsageCacheEntry UsageArr[MAX_USAGE_TAGS];
};

struct THidDevice *HidArr[MAX_HID_DEVICES];

#define DEFAULT_KEYBOARD_SIZE  63

static unsigned char DefaultKeyboardDescriptor[DEFAULT_KEYBOARD_SIZE] =
        {
            0x5, 0x1,
            0x9, 0x6,
            0xA1,0x1,
            0x5, 0x7,
            0x19,0xE0,
            0x29,0xE7,
            0x15,0x0,
            0x25,0x1,
            0x75,0x1,
            0x95,0x8,
            0x81,0x2,
            0x95,0x1,
            0x75,0x8,
            0x81,0x1,
            0x95,0x5,
            0x75,0x1,
            0x5, 0x8,
            0x19,0x1,
            0x29,0x5,
            0x91,0x2,
            0x95,0x1,
            0x75,0x3,
            0x91,0x1,
            0x95,0x6,
            0x75,0x8,
            0x15,0x0,
            0x25,0x65,
            0x5, 0x7,
            0x19,0x0,
            0x29,0x65,
            0x81,0x0,
            0xC0
        };

#define DEFAULT_MOUSE_SIZE  50

static unsigned char DefaultMouseDescriptor[DEFAULT_MOUSE_SIZE] =
        {
            0x5, 0x1,
            0x9, 0x2,
            0xA1,0x1,
            0x9, 0x1,
            0xA1,0x0,
            0x5, 0x9,
            0x19,0x1,
            0x29,0x3,
            0x15,0x0,
            0x25,0x1,
            0x95,0x3,
            0x75,0x1,
            0x81,0x2,
            0x95,0x1,
            0x75,0x5,
            0x81,0x1,
            0x5, 0x1,
            0x9, 0x30,
            0x9, 0x31,
            0x15,0x81,
            0x25,0x7F,
            0x75,0x8,
            0x95,0x2,
            0x81,0x6,
            0xC0, 0xC0
        };


#define EFF_TOUCH_SIZE  45

static unsigned char EffTouchDescriptor[EFF_TOUCH_SIZE] =
        {
            0x5, 0xd,
            0x9, 0x4,
            0xA1,0x1,
            0x85,0x1,
            0x9, 0x22,
            0xA1,0x2,
            0x9, 0x42,
            0x15,0x0,
            0x25,0x1,
            0x75,0x1,
            0x95,0x1,
            0x81,0x2,
            0x75,0x7,
            0x81,0x3,
            0x5, 0x1,
            0x26,0xFF, 0xF,
            0x75,0x10,
            0x9, 0x30,
            0x81,0x2,
            0x9, 0x31,
            0x81,0x2,
            0xC0,
            0xC0
        };


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
    int i;
    int j;
    struct THidReportIdEntry *report;

    if (dev->ItemArr)
        RdosFreeMem(RdosPointerToSelector(dev->ItemArr));

    for (i = 0; i < MAX_REPORT_IDS; i++)
    {
        report = dev->ReportIdArr[i];

        if (report)
        {
            for (j = 0; j < report->TableCount; j++)
                HidClose(report->TableArr[j].Index, report->TableArr[j].Handle);

            if (report->InputCount)
                RdosFreeMem(RdosPointerToSelector(report->InputArr));

            if (report->OutputCount)
                RdosFreeMem(RdosPointerToSelector(report->OutputArr));

            if (report->FeatureCount)
                RdosFreeMem(RdosPointerToSelector(report->FeatureArr));

            if (report->ReportHandle)
                FreeReport(report->ReportHandle);

            RdosFreeMem(RdosPointerToSelector(report));
        }
    }

    CloseHidDev(dev);
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

    OpenHidDev(dev, dev->ConfigBuf);

    size = GetReportDescr(dev, dev->ReportDescrData, dev->ReportDescrSize, 0);

    if (size == dev->ReportDescrSize)
        return TRUE;
    else
    {
        dev->ReportDescrSize = EFF_TOUCH_SIZE;
        memcpy(dev->ReportDescrData, EffTouchDescriptor, EFF_TOUCH_SIZE);
        return TRUE;

        switch (dev->Protocol)
        {
            case 1:
                if (dev->ReportDescrSize >= DEFAULT_KEYBOARD_SIZE)
                {
                    dev->ReportDescrSize = DEFAULT_KEYBOARD_SIZE;
                    memcpy(dev->ReportDescrData, DefaultKeyboardDescriptor, DEFAULT_KEYBOARD_SIZE);
                    return TRUE;
                }
                else
                    break;

           case 2:
                if (dev->ReportDescrSize >= DEFAULT_KEYBOARD_SIZE)
                {
                    dev->ReportDescrSize = DEFAULT_MOUSE_SIZE;
                    memcpy(dev->ReportDescrData, DefaultMouseDescriptor, DEFAULT_MOUSE_SIZE);
                    return TRUE;
                }
                else
                    break;

            default:
                break;
        }

        dev->ItemCount = 0;
        dev->ReportDescrSize = 0;
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

                CurrReport->Device = dev;
                CurrReport->ReportId = ReportId;

                CurrReport->InputCount = 0;
                CurrReport->OutputCount = 0;
                CurrReport->FeatureCount = 0;

                CurrReport->InputArr = 0;
                CurrReport->OutputArr = 0;
                CurrReport->FeatureArr = 0;

                CurrReport->ReportHandle = 0;
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

                    CurrReport->Device = dev;
                    CurrReport->ReportId = ReportId;

                    CurrReport->InputCount = 0;
                    CurrReport->OutputCount = 0;
                    CurrReport->FeatureCount = 0;

                    CurrReport->InputArr = 0;
                    CurrReport->OutputArr = 0;
                    CurrReport->FeatureArr = 0;

                    CurrReport->ReportHandle = 0;
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
    entry->UsageIdLow = 0;
    entry->UsageIdHigh = 0;
    entry->StartBit = 0;
    entry->BitCount = 0;
    entry->ItemParams = 0;
    entry->HasLogical = FALSE;
    entry->HasPhysical = FALSE;
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

    cache->UsageEmpty = FALSE;

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
    cache->HasMin = FALSE;
    cache->HasMax = FALSE;
    cache->HasLogical = FALSE;
    cache->HasPhysical = FALSE;

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
    cache->HasMin = FALSE;
    cache->HasMax = FALSE;
    cache->HasLogical = FALSE;
    cache->HasPhysical = FALSE;
}

/*##########################################################################
#
#   Name       : DeleteUsageHead
#
#   Purpose....: Delete usage head if multiple entries
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DeleteUsageHead(struct TTagCache *cache)
{
    int i;

    if (cache->UsageCount > 1)
    {
        for (i = 1; i < cache->UsageCount; i++)
        {
            cache->UsageArr[i - 1].MinUsage = cache->UsageArr[i].MinUsage;
            cache->UsageArr[i - 1].MaxUsage = cache->UsageArr[i].MaxUsage;
        }
        cache->UsageCount--;
    }
    else
        cache->UsageEmpty = TRUE;
}

/*##########################################################################
#
#   Name       : ProcessInputCache
#
#   Purpose....: Process input cache
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ProcessInputCache(struct TTagCache *cache, int val)
{
    int Count;
    struct THidReportEntry *entry;

    Count = cache->ReportCount;

    while (Count)
    {
        if (cache->UsageCount)
        {
            entry = &cache->CurrReport->InputArr[cache->InputEntry];
            entry->StartBit = cache->InputBit;
            entry->BitCount = cache->ReportSize;
            entry->HasLogical = cache->HasLogical;
            entry->LogicalMin = cache->LogicalMin;
            entry->LogicalMax = cache->LogicalMax;
            entry->HasPhysical = cache->HasPhysical;
            entry->PhysicalMin = cache->PhysicalMin;
            entry->PhysicalMax = cache->PhysicalMax;
            entry->ItemParams = val;
            cache->InputBit += cache->ReportSize;

            if (entry->ItemParams & 0x2)
            {
                entry->UsageIdLow = cache->UsageArr[0].MinUsage;
                entry->UsageIdHigh = cache->UsageArr[0].MinUsage;

                if (cache->UsageArr[0].MinUsage == cache->UsageArr[0].MaxUsage)
                    DeleteUsageHead(cache);
                else
                    cache->UsageArr[0].MinUsage++;
            }
            else
            {
                entry->UsageIdLow = cache->UsageArr[0].MinUsage;
                entry->UsageIdHigh = cache->UsageArr[0].MaxUsage;

                DeleteUsageHead(cache);
            }

            entry->UsagePage = cache->UsagePage;
            cache->InputEntry++;
        }
        else
        {
            entry = &cache->CurrReport->InputArr[cache->InputEntry];
            entry->StartBit = cache->InputBit;
            entry->BitCount = cache->ReportSize;
            entry->ItemParams = val;
            entry->HasLogical = cache->HasLogical;
            entry->LogicalMin = cache->LogicalMin;
            entry->LogicalMax = cache->LogicalMax;
            entry->HasPhysical = cache->HasPhysical;
            entry->PhysicalMin = cache->PhysicalMin;
            entry->PhysicalMax = cache->PhysicalMax;
            cache->InputBit += cache->ReportSize;

            entry->UsageIdLow = -1;
            entry->UsageIdHigh = -1;
            entry->UsagePage = cache->UsagePage;
            cache->InputEntry++;
        }
        Count--;
    }

    if (cache->UsageEmpty)
        cache->UsageCount = 0;

    cache->HasMin = FALSE;
    cache->HasMax = FALSE;
}

/*##########################################################################
#
#   Name       : ProcessOutputCache
#
#   Purpose....: Process output cache
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ProcessOutputCache(struct TTagCache *cache, int val)
{
    int Count;
    struct THidReportEntry *entry;

    Count = cache->ReportCount;

    while (Count)
    {
        if (cache->UsageCount)
        {
            entry = &cache->CurrReport->OutputArr[cache->OutputEntry];
            entry->StartBit = cache->OutputBit;
            entry->BitCount = cache->ReportSize;
            entry->ItemParams = val;
            entry->HasLogical = cache->HasLogical;
            entry->LogicalMin = cache->LogicalMin;
            entry->LogicalMax = cache->LogicalMax;
            entry->HasPhysical = cache->HasPhysical;
            entry->PhysicalMin = cache->PhysicalMin;
            entry->PhysicalMax = cache->PhysicalMax;
            cache->OutputBit += cache->ReportSize;

            if (entry->ItemParams & 0x2)
            {
                entry->UsageIdLow = cache->UsageArr[0].MinUsage;
                entry->UsageIdHigh = cache->UsageArr[0].MinUsage;

                if (cache->UsageArr[0].MinUsage == cache->UsageArr[0].MaxUsage)
                    DeleteUsageHead(cache);
                else
                    cache->UsageArr[0].MinUsage++;
            }
            else
            {
                entry->UsageIdLow = cache->UsageArr[0].MinUsage;
                entry->UsageIdHigh = cache->UsageArr[0].MaxUsage;

                DeleteUsageHead(cache);
            }

            entry->UsagePage = cache->UsagePage;
            cache->OutputEntry++;
        }
        else
        {
            entry = &cache->CurrReport->OutputArr[cache->OutputEntry];
            entry->StartBit = cache->OutputBit;
            entry->BitCount = cache->ReportSize;
            entry->ItemParams = val;
            entry->HasLogical = cache->HasLogical;
            entry->LogicalMin = cache->LogicalMin;
            entry->LogicalMax = cache->LogicalMax;
            entry->HasPhysical = cache->HasPhysical;
            entry->PhysicalMin = cache->PhysicalMin;
            entry->PhysicalMax = cache->PhysicalMax;
            cache->OutputBit += cache->ReportSize;

            entry->UsageIdLow = -1;
            entry->UsageIdHigh = -1;
            entry->UsagePage = cache->UsagePage;
            cache->OutputEntry++;
        }
        Count--;
    }

    if (cache->UsageEmpty)
        cache->UsageCount = 0;

    cache->HasMin = FALSE;
    cache->HasMax = FALSE;
}

/*##########################################################################
#
#   Name       : ProcessFeatureCache
#
#   Purpose....: Process feature cache
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ProcessFeatureCache(struct TTagCache *cache, int val)
{
    int Count;
    struct THidReportEntry *entry;

    Count = cache->ReportCount;

    while (Count)
    {
        if (cache->UsageCount)
        {
            entry = &cache->CurrReport->FeatureArr[cache->FeatureEntry];
            entry->StartBit = cache->FeatureBit;
            entry->BitCount = cache->ReportSize;
            entry->ItemParams = val;
            entry->HasLogical = cache->HasLogical;
            entry->LogicalMin = cache->LogicalMin;
            entry->LogicalMax = cache->LogicalMax;
            entry->HasPhysical = cache->HasPhysical;
            entry->PhysicalMin = cache->PhysicalMin;
            entry->PhysicalMax = cache->PhysicalMax;
            cache->FeatureBit += cache->ReportSize;

            if (entry->ItemParams & 0x2)
            {
                entry->UsageIdLow = cache->UsageArr[0].MinUsage;
                entry->UsageIdHigh = cache->UsageArr[0].MinUsage;

                if (cache->UsageArr[0].MinUsage == cache->UsageArr[0].MaxUsage)
                    DeleteUsageHead(cache);
                else
                    cache->UsageArr[0].MinUsage++;
            }
            else
            {
                entry->UsageIdLow = cache->UsageArr[0].MinUsage;
                entry->UsageIdHigh = cache->UsageArr[0].MaxUsage;

                DeleteUsageHead(cache);
            }

            entry->UsagePage = cache->UsagePage;
            cache->FeatureEntry++;
        }
        else
        {
            entry = &cache->CurrReport->FeatureArr[cache->FeatureEntry];
            entry->StartBit = cache->FeatureBit;
            entry->BitCount = cache->ReportSize;
            entry->ItemParams = val;
            entry->HasLogical = cache->HasLogical;
            entry->LogicalMin = cache->LogicalMin;
            entry->LogicalMax = cache->LogicalMax;
            entry->HasPhysical = cache->HasPhysical;
            entry->PhysicalMin = cache->PhysicalMin;
            entry->PhysicalMax = cache->PhysicalMax;
            cache->FeatureBit += cache->ReportSize;

            entry->UsageIdLow = -1;
            entry->UsageIdHigh = -1;
            entry->UsagePage = cache->UsagePage;
            cache->FeatureEntry++;
        }
        Count--;
    }

    if (cache->UsageEmpty)
        cache->UsageCount = 0;

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
#   Name       : SetUsagePage
#
#   Purpose....: Set usage page
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SetUsagePage(struct TTagCache *cache, int val)
{
    cache->UsagePage = val;
    cache->UsageCount = 0;
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
        cache->ReportCount = count;
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
        cache->ReportSize = size;
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
        cache->UsageEmpty = FALSE;

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
        cache->UsageEmpty = FALSE;

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
        cache->UsageEmpty = FALSE;

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
    if (cache->CurrReport)
        ProcessInputCache(cache, Input);
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
    if (cache->CurrReport)
        ProcessOutputCache(cache, Output);
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
    if (cache->CurrReport)
        ProcessFeatureCache(cache, Feature);
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
    int Index;
    int val;
    struct THidReportItem *item;
    struct TTagCache *cache;

    cache = CreateTagCache();
    SetReport(cache, dev->ReportIdArr[0]);

    for (Index = 0; Index < dev->ItemCount; Index++)
    {
        item = dev->ItemArr + Index;

        switch (item->Tag)
        {
            case MAIN_BEGIN:
            case MAIN_END:
                cache->UsageCount = 0;
                cache->HasMin = FALSE;
                cache->HasMax = FALSE;
                cache->HasLogical = FALSE;
                cache->HasPhysical = FALSE;
                break;

            case GLOBAL_REPORT_ID:
                val = GetReportItemUnsigned(item);
                if (val > 0 && val < MAX_REPORT_IDS)
                    SetReport(cache, dev->ReportIdArr[val]);
                else
                    SetReport(cache, 0);
                break;

            case GLOBAL_REPORT_SIZE:
                val = GetReportItemUnsigned(item);
                SetReportSize(cache, val);
                break;

            case GLOBAL_REPORT_COUNT:
                val = GetReportItemUnsigned(item);
                SetReportCount(cache, val);
                break;

            case GLOBAL_USAGE:
                val = GetReportItemUnsigned(item);
                SetUsagePage(cache, val);
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

            case GLOBAL_LOG_MIN:
                val = GetReportItemSigned(item);
                if (cache->HasLogical)
                    cache->LogicalMin = val;
                else
                {
                    cache->LogicalMin = val;
                    cache->LogicalMax = val;
                    cache->HasLogical = TRUE;
                }
                break;

            case GLOBAL_LOG_MAX:
                val = GetReportItemSigned(item);
                if (cache->HasLogical)
                    cache->LogicalMax = val;
                else
                {
                    cache->LogicalMin = val;
                    cache->LogicalMax = val;
                    cache->HasLogical = TRUE;
                }
                break;

            case GLOBAL_PHYS_MIN:
                val = GetReportItemSigned(item);
                if (cache->HasPhysical)
                    cache->PhysicalMin = val;
                else
                {
                    cache->PhysicalMin = val;
                    cache->PhysicalMax = val;
                    cache->HasPhysical = TRUE;
                }
                break;

            case GLOBAL_PHYS_MAX:
                val = GetReportItemSigned(item);
                if (cache->HasPhysical)
                    cache->PhysicalMax = val;
                else
                {
                    cache->PhysicalMin = val;
                    cache->PhysicalMax = val;
                    cache->HasPhysical = TRUE;
                }
                break;

        }
    }
    FreeTagCache(cache);
}

/*##########################################################################
#
#   Name       : StartInputReports
#
#   Purpose....: Start input reports
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void StartInputReports(struct THidDevice *dev)
{
    int Index;
    int Count;
    int Report;
    int Inp;
    int Handle;
    int ok;
    struct THidReportIdEntry *report;
    struct THidReportEntry *entry;

    Count = GetHidTableCount();

    for (Report = 0; Report < MAX_REPORT_IDS; Report++)
    {
        report = dev->ReportIdArr[Report];

        if (report)
        {
            report->TableCount = 0;

            for (Index = 0; Index < Count; Index++)
            {
                Handle = HidBegin(Index, dev, report);

                if (Handle)
                {
                    for (Inp = 0; Inp < report->InputCount; Inp++)
                    {
                        entry = &report->InputArr[Inp];
                        HidDefine(Index, Handle, Inp, entry->UsagePage, entry->UsageIdLow + (entry->UsageIdHigh << 8), entry->ItemParams);
                    }

                    ok = HidEnd(Index, Handle);
                    if (ok)
                    {
                        report->TableArr[report->TableCount].Index = Index;
                        report->TableArr[report->TableCount].Handle = Handle;
                        report->TableCount++;
                    }
                }
            }
        }
    }
}

/*##########################################################################
#
#   Name       : CreateIntrPipe
#
#   Purpose....: Create intr pipe
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int CreateIntrPipe(struct THidDevice *dev)
{
    int i;
    int size;
    int maxsize = 0;
    struct THidReportIdEntry *report;
    struct THidReportEntry *entry;

    for (i = 0; i < MAX_REPORT_IDS; i++)
    {
        report = dev->ReportIdArr[i];

        if (report && report->InputCount)
        {
            entry = &report->InputArr[report->InputCount - 1];
            size = entry->StartBit + entry->BitCount;
            if (size > maxsize)
                maxsize = size;
        }
    }

    size = maxsize;
    size--;
    size = size / 8;
    size++;

    if (!dev->ReportIdArr[0])
        size++;

    dev->IntrSize = size;

    OpenIntrPipe(dev);
    return TRUE;
}

/*##########################################################################
#
#   Name       : ImplGetSignedHidInput
#
#   Purpose....: Get signed HID input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetSignedHidInput "*" rdosdev parm routine [es edi] [fs esi] [ebx] value [eax]
int __far ImplGetSignedHidInput(struct THidReportIdEntry *report, char *buf, int entry)
{
    struct THidReportEntry *Entry = &report->InputArr[entry];
    int StartBit = Entry->StartBit;
    int BitCount = Entry->BitCount;

    if (BitCount < 0)
        BitCount = 0;

    if (BitCount > 32)
        BitCount = 32;

    return GetSignedValue(buf, StartBit, BitCount);
}

/*##########################################################################
#
#   Name       : ImplGetUnsignedHidInput
#
#   Purpose....: Get unsigned HID input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetUnsignedHidInput "*" rdosdev parm routine [es edi] [fs esi] [ebx] value [eax]
int __far ImplGetUnsignedHidInput(struct THidReportIdEntry *report, char *buf, int entry)
{
    struct THidReportEntry *Entry = &report->InputArr[entry];
    int StartBit = Entry->StartBit;
    int BitCount = Entry->BitCount;

    if (BitCount < 0)
        BitCount = 0;

    if (BitCount > 32)
        BitCount = 32;

    return GetUnsignedValue(buf, StartBit, BitCount);
}

/*##########################################################################
#
#   Name       : ImplGetHidLogMin
#
#   Purpose....: Get logical min
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetHidLogMin "*" rdosdev parm routine [es edi] [ebx] value [eax]
int __far ImplGetHidLogMin(struct THidReportIdEntry *report, int entry)
{
    struct THidReportEntry *Entry = &report->InputArr[entry];

    if (Entry->HasLogical)
        return Entry->LogicalMin;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : ImplGetHidLogMax
#
#   Purpose....: Get logical max
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetHidLogMax "*" rdosdev parm routine [es edi] [ebx] value [eax]
int __far ImplGetHidLogMax(struct THidReportIdEntry *report, int entry)
{
    struct THidReportEntry *Entry = &report->InputArr[entry];

    if (Entry->HasLogical)
        return Entry->LogicalMax;
    else
        return 0;
}

/*##########################################################################
#
#   Name       : GetOutputReport
#
#   Purpose....: Get output report
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct THidReportIdEntry *GetOutputReport(struct THidDevice *dev, int UsagePage, int UsageId)
{
    int ReportId;
    int Index;
    struct THidReportIdEntry *report;
    struct THidReportEntry *entry;

    for (ReportId = 0; ReportId < MAX_REPORT_IDS; ReportId++)
    {
        report = dev->ReportIdArr[ReportId];

        if (report)
        {
            for (Index = 0; Index < report->OutputCount; Index++)
            {
                entry = &report->OutputArr[Index];

                if (entry->UsagePage == UsagePage && entry->UsageIdLow == UsageId)
                    return report;
            }
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : GetOutputReportSize
#
#   Purpose....: Get output report size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetOutputReportSize(struct THidReportIdEntry *report)
{
    int size = 0;
    struct THidReportEntry *entry;

    if (report && report->OutputCount)
    {
        entry = &report->OutputArr[report->OutputCount - 1];
        size = entry->StartBit + entry->BitCount;
    }

    if (size)
    {
        size--;
        size = size / 8;
        size++;
    }

    return size;
}

/*##########################################################################
#
#   Name       : GetFeatureReport
#
#   Purpose....: Get feature report
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct THidReportIdEntry *GetFeatureReport(struct THidDevice *dev, int UsagePage, int UsageId)
{
    int ReportId;
    int Index;
    struct THidReportIdEntry *report;
    struct THidReportEntry *entry;

    for (ReportId = 0; ReportId < MAX_REPORT_IDS; ReportId++)
    {
        report = dev->ReportIdArr[ReportId];

        if (report)
        {
            for (Index = 0; Index < report->FeatureCount; Index++)
            {
                entry = &report->FeatureArr[Index];

                if (entry->UsagePage == UsagePage && entry->UsageIdLow == UsageId)
                    return report;
            }
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : GetFeatureReportSize
#
#   Purpose....: Get feature report size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetFeatureReportSize(struct THidReportIdEntry *report)
{
    int size = 0;
    struct THidReportEntry *entry;

    if (report && report->FeatureCount)
    {
        entry = &report->FeatureArr[report->FeatureCount - 1];
        size = entry->StartBit + entry->BitCount;
    }

    if (size)
    {
        size--;
        size = size / 8;
        size++;
    }

    return size;
}

/*##########################################################################
#
#   Name       : IsCustomHid
#
#   Purpose....: Check if custom hid
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int IsCustomHid(struct THidDevice *dev)
{
    int r;
    int i;
    struct THidReportIdEntry *report;
    struct THidReportEntry *entry;

    for (r = 0; r < MAX_REPORT_IDS; r++)
    {
        report = dev->ReportIdArr[r];
        if (report)
        {
            for (i = 0; i < report->InputCount; i++)
            {
                entry = &report->InputArr[i];
                if (entry->UsagePage < 0xFF00)
                    return FALSE;
            }

            for (i = 0; i < report->OutputCount; i++)
            {
                entry = &report->OutputArr[i];
                if (entry->UsagePage < 0xFF00)
                    return FALSE;
            }
        }
    }
    return TRUE;
}

/*##########################################################################
#
#   Name       : ImplFindHidOutput
#
#   Purpose....: Find HID output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplFindHidOutput "*" rdosdev parm routine [ebx] [ecx] [edx] value [dx esi]
struct THidReportIdEntry * __far ImplFindHidOutput(int DevSel, int Page, int ID)
{
    struct THidDevice *dev = (struct THidDevice *)RdosSelectorToPointer(DevSel);
    int UsagePage = Page & 0xFFFF;
    int UsageId = ID & 0xFF;
    int size;
    struct THidReportIdEntry *report;

    report = GetOutputReport(dev, UsagePage, UsageId);

    if (report && !report->ReportHandle)
    {
        size = GetOutputReportSize(report);
        report->ReportHandle = CreateOutputReport(dev, report->ReportId, size);
    }

    if (report)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return report;
}

/*##########################################################################
#
#   Name       : ImplSetHidOutput
#
#   Purpose....: Set HID output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplSetHidOutput "*" rdosdev parm routine [fs esi] [ecx] [edx] [eax]
void __far ImplSetHidOutput(struct THidReportIdEntry *Report, int Page, int ID, int Value)
{
    int UsagePage = Page & 0xFFFF;
    int UsageId = ID & 0xFF;
    int Index;
    struct THidReportEntry *entry;
    int StartBit;
    int BitCount;

    _asm push esi;

    for (Index = 0; Index < Report->OutputCount; Index++)
    {
        entry = &Report->OutputArr[Index];

        if (entry->UsagePage == UsagePage && entry->UsageIdLow == UsageId)
        {
            StartBit = entry->StartBit;
            BitCount = entry->BitCount;

            if (BitCount < 0)
                BitCount = 0;

            if (BitCount > 32)
                BitCount = 32;

            SetReportValue(Report->ReportHandle, StartBit, BitCount, Value);
            break;
        }
    }

    _asm pop esi;
}

/*##########################################################################
#
#   Name       : ImplUpdateHidOutput
#
#   Purpose....: Update HID output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplUpdateHidOutput "*" rdosdev parm routine [fs esi]
void __far ImplUpdateHidOutput(struct THidReportIdEntry *Report)
{
    SendOutputReport(Report->ReportHandle);
}

/*##########################################################################
#
#   Name       : ImplFindHidFeature
#
#   Purpose....: Find HID feature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplFindHidFeature "*" rdosdev parm routine [ebx] [ecx] [edx] value [dx esi]
struct THidReportIdEntry * __far ImplFindHidFeature(int DevSel, int Page, int ID)
{
    struct THidDevice *dev = (struct THidDevice *)RdosSelectorToPointer(DevSel);
    int UsagePage = Page & 0xFFFF;
    int UsageId = ID & 0xFF;
    int size;
    struct THidReportIdEntry *report;

    report = GetFeatureReport(dev, UsagePage, UsageId);

    if (report && !report->ReportHandle)
    {
        size = GetFeatureReportSize(report);
        report->ReportHandle = CreateFeatureReport(dev, report->ReportId, size);
    }

    if (report)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return report;
}

/*##########################################################################
#
#   Name       : ImplGetHidReportSize
#
#   Purpose....: Get HID report size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetHidReportSize "*" rdosdev parm routine [fs esi] value [ecx]
int __far ImplGetHidReportSize(struct THidReportIdEntry *Report)
{
    if (Report->ReportHandle)
        return GetReportSize(Report->ReportHandle);
    else
        return 0;
}

/*##########################################################################
#
#   Name       : ImplGetHidReportBuf
#
#   Purpose....: Get HID report buffer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetHidReportBuf "*" rdosdev parm routine [fs esi] value [dx eax]
char * __far ImplGetHidReportBuf(struct THidReportIdEntry *Report)
{
    if (Report->ReportHandle)
        return GetReportBuf(Report->ReportHandle);
    else
        return 0;
}

/*##########################################################################
#
#   Name       : ImplReadHidFeature
#
#   Purpose....: Read HID feature report
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplReadHidFeature "*" rdosdev parm routine [fs esi]
void __far ImplReadHidFeature(struct THidReportIdEntry *Report)
{
    ReadFeatureReport(Report->ReportHandle);
}

/*##########################################################################
#
#   Name       : ImplWriteHidFeature
#
#   Purpose....: Write HID feature report
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplWriteHidFeature "*" rdosdev parm routine [fs esi]
void __far ImplWriteHidFeature(struct THidReportIdEntry *Report)
{
    WriteFeatureReport(Report->ReportHandle);
}

/*##########################################################################
#
#   Name       : ImplSetHidIdle
#
#   Purpose....: Set HID idle time
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplSetHidIdle "*" rdosdev parm routine [es edi] [eax]
void __far ImplSetHidIdle(struct THidReportIdEntry *report, int value)
{
    struct THidDevice *dev = report->Device;
    int ReportId = report->ReportId;

    SetIdle(dev, ReportId, value);
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

                        if (entry->BitCount <= 1)
                            sprintf(Buf, "bit %d: ", entry->StartBit);
                        else
                            sprintf(Buf, "bit %d-%d: ", entry->StartBit, entry->StartBit + entry->BitCount - 1);

                        if (entry->UsageIdLow != -1)
                        {
                            if (entry->UsageIdLow == entry->UsageIdHigh)
                                sprintf(str, "%02hX.%02hX ", entry->UsagePage, entry->UsageIdLow);
                            else
                                sprintf(str, "%02hX.%02hX-%02hX ", entry->UsagePage, entry->UsageIdLow, entry->UsageIdHigh);
                            strcat(Buf, str);

                            AddReportControl(Buf, entry->ItemParams);
                        }

                        if (entry->HasLogical)
                        {
                            sprintf(str, " Logical [%d, %d]", entry->LogicalMin, entry->LogicalMax);
                            strcat(Buf, str);
                        }

                        if (entry->HasPhysical)
                        {
                            sprintf(str, " Physical [%d, %d]", entry->PhysicalMin, entry->PhysicalMax);
                            strcat(Buf, str);
                        }

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

                        if (entry->BitCount <= 1)
                            sprintf(Buf, "bit %d: ", entry->StartBit);
                        else
                            sprintf(Buf, "bit %d-%d: ", entry->StartBit, entry->StartBit + entry->BitCount - 1);

                        if (entry->UsageIdLow != -1)
                        {
                            if (entry->UsageIdLow == entry->UsageIdHigh)
                                sprintf(str, "%02hX.%02hX ", entry->UsagePage, entry->UsageIdLow);
                            else
                                sprintf(str, "%02hX.%02hX-%02hX ", entry->UsagePage, entry->UsageIdLow, entry->UsageIdHigh);
                            strcat(Buf, str);

                            AddReportControl(Buf, entry->ItemParams);
                        }

                        if (entry->HasLogical)
                        {
                            sprintf(str, " Logical [%d, %d]", entry->LogicalMin, entry->LogicalMax);
                            strcat(Buf, str);
                        }

                        if (entry->HasPhysical)
                        {
                            sprintf(str, " Physical [%d, %d]", entry->PhysicalMin, entry->PhysicalMax);
                            strcat(Buf, str);
                        }

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

                        if (entry->BitCount <= 1)
                            sprintf(Buf, "bit %d: ", entry->StartBit);
                        else
                            sprintf(Buf, "bit %d-%d: ", entry->StartBit, entry->StartBit + entry->BitCount - 1);

                        if (entry->UsageIdLow != -1)
                        {
                            if (entry->UsageIdLow == entry->UsageIdHigh)
                                sprintf(str, "%02hX.%02hX ", entry->UsagePage, entry->UsageIdLow);
                            else
                                sprintf(str, "%02hX.%02hX-%02hX ", entry->UsagePage, entry->UsageIdLow, entry->UsageIdHigh);
                            strcat(Buf, str);

                            AddReportControl(Buf, entry->ItemParams);
                        }

                        if (entry->HasLogical)
                        {
                            sprintf(str, " Logical [%d, %d]", entry->LogicalMin, entry->LogicalMax);
                            strcat(Buf, str);
                        }

                        if (entry->HasPhysical)
                        {
                            sprintf(str, " Physical [%d, %d]", entry->PhysicalMin, entry->PhysicalMax);
                            strcat(Buf, str);
                        }
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
    int Table;
    int ok;
    int Report;
    struct THidDevice *dev;
    struct THidReportIdEntry *report;
    char *ReportData;

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

        if (IsCustomHid(dev))
            ok = HasCustomDriver(dev);

        if (ok)
        {
            StartInputReports(dev);
            if (CreateIntrPipe(dev))
            {
                while (IsHidConnected(dev) && !dev->StopReq)
                {
                    ReportData = WaitForReport(dev);

                    if (dev->StopReq)
                        break;

                    if (ReportData)
                    {
                        if (dev->ReportIdArr[0])
                            Report = 0;
                        else
                        {
                            Report = *ReportData;
                            ReportData++;
                        }

                        report = dev->ReportIdArr[Report];

                        if (report)
                            for (Table = 0; Table < report->TableCount; Table++)
                                HidHandleReport(report->TableArr[Table].Index,
                                            report->TableArr[Table].Handle,
                                            ReportData);
                    }
                }
            }
            CloseHid(dev);
        }
    }

    dev->IsRunning = FALSE;
    dev->Thread = 0;
    RdosTerminateThread();
}


/*##########################################################################
#
#   Name       : HidGetReportSize
#
#   Purpose....: Get HID report size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux HidGetReportSize "*" rdosdev parm routine [es edi] [ebx] value [ecx]
int HidGetReportSize(struct THidDevice *dev, int id)
{
    int size = 0;
    struct THidReportIdEntry *report;
    struct THidReportEntry *entry;

    if (dev->ReportIdArr[0])
        id = 0;

    if (id >= 0 && id < MAX_REPORT_IDS)
    {
        report = dev->ReportIdArr[id];

        if (report && report->InputCount)
        {
            entry = &report->InputArr[report->InputCount - 1];
            size = entry->StartBit + entry->BitCount;
        }
    }

    return size;
}

/*##########################################################################
#
#   Name       : CreateHid
#
#   Purpose....: Create HID structure
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux CreateHid "*" rdosdev parm routine [ebx] [eax] [es edi]
void CreateHid(int controller, int port, char *config)
{
    int i;
    int j;
    struct THidDevice *dev = 0;
    int size;
    struct THidDescriptor *descr;
    char *buf = RdosAllocateSmallGlobalMem(0x1000);
    char *ptr;
    char ThreadName[64];

    for (i = 0; i < MAX_HID_DEVICES; i++)
    {
        if (HidArr[i] == 0)
        {
            size = RdosGetUsbConfig(controller, port, 0, buf, 0x1000);

            ptr = buf;
            while (size > 0)
            {
                descr = (struct THidDescriptor *)ptr;
                if (descr->Type == 0x21 && descr->DescriptorType == 0x22)
                {
                    dev = (struct THidDevice *)RdosAllocateSmallGlobalMem(sizeof(struct THidDevice) + descr->DescriptorLen);
                    dev->Controller = controller;
                    dev->Port = port;
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
            dev->StopReq = FALSE;
            dev->ConfigBuf = config;
            dev->Thread = 0;

                sprintf(ThreadName, "Hid %02hX.%02hX", controller, port);
                RdosCreateKernelThread(5, 0x1000, HidThread, ThreadName, dev);

            break;
        }
    }
    RdosFreeMem(RdosPointerToSelector(buf));
}

/*##########################################################################
#
#   Name       : RemoveHid
#
#   Purpose....: Remove Hid dev
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux RemoveHid "*" rdosdev parm routine [ebx] [eax]
void RemoveHid(int controller, int port)
{
    int i;
    struct THidDevice *dev;

    for (i = 0; i < MAX_HID_DEVICES; i++)
    {
        dev = HidArr[i];
        if (dev)
        {
            if (dev->Controller == controller && dev->Port == port)
            {
                dev->StopReq = TRUE;
                HidArr[i] = 0;

                while (dev->IsRunning)
                {
                    RdosSignal(dev->Thread);
                    RdosWaitMilli(25);
                }

                RdosWaitMilli(25);

                RdosFreeMem(RdosPointerToSelector(dev));
                break;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : GetHid
#
#   Purpose....: Get Hid dev
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux GetHid "*" rdosdev parm routine [ebx] [eax]
struct THidDevice *GetHid(int controller, int port)
{
    int i;
    struct THidDevice *dev;

    for (i = 0; i < MAX_HID_DEVICES; i++)
    {
        dev = HidArr[i];
        if (dev)
        {
            if (dev->Controller == controller && dev->Port == port)
            {
                if (dev->Thread)
                    return 0;
                else
                    return dev;
            }
        }
    }

    return 0;
}

/*##########################################################################
#
#   Name       : GetHidController
#
#   Purpose....: Get Hid controller
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux GetHidController "*" rdosdev parm routine [eax]  value [eax]
int GetHidController(int device)
{
    if (device >= 0 && device < MAX_HID_DEVICES)
        if (HidArr[device])
            return HidArr[device]->Controller;

    return -1;
}

/*##########################################################################
#
#   Name       : GetHidPort
#
#   Purpose....: Get Hid port
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux GetHidPort "*" rdosdev parm routine [eax]  value [eax]
int GetHidPort(int device)
{
    if (device >= 0 && device < MAX_HID_DEVICES)
        if (HidArr[device])
            return HidArr[device]->Port;

    return -1;
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
    InitKey();
    InitMouse();
    InitTouch();

    RdosRegisterOsGate(osgate_get_signed_hid_input, (__rdos_gate_callback *)&ImplGetSignedHidInput, "Get Signed Hid Input");
    RdosRegisterOsGate(osgate_get_unsigned_hid_input, (__rdos_gate_callback *)&ImplGetUnsignedHidInput, "Get Unsigned Hid Input");
    RdosRegisterOsGate(osgate_set_hid_idle, (__rdos_gate_callback *)&ImplSetHidIdle, "Set Hid Idle");

    RdosRegisterOsGate(osgate_get_hid_log_min, (__rdos_gate_callback *)&ImplGetHidLogMin, "Get Hid Log Min");
    RdosRegisterOsGate(osgate_get_hid_log_max, (__rdos_gate_callback *)&ImplGetHidLogMax, "Get Hid Log Max");

    RdosRegisterOsGate(osgate_get_hid_report_size, (__rdos_gate_callback *)&ImplGetHidReportSize, "Get Hid Report Size");
    RdosRegisterOsGate(osgate_get_hid_report_buf, (__rdos_gate_callback *)&ImplGetHidReportBuf, "Get Hid Report Buf");

    RdosRegisterOsGate(osgate_find_hid_output_report, (__rdos_gate_callback *)&ImplFindHidOutput, "Find Hid Output");
    RdosRegisterOsGate(osgate_set_hid_output, (__rdos_gate_callback *)&ImplSetHidOutput, "Set Hid Output");
    RdosRegisterOsGate(osgate_update_hid_output, (__rdos_gate_callback *)&ImplUpdateHidOutput, "Update Hid Output");

    RdosRegisterOsGate(osgate_find_hid_feature_report, (__rdos_gate_callback *)&ImplFindHidFeature, "Find Hid Feature");
    RdosRegisterOsGate(osgate_read_hid_feature, (__rdos_gate_callback *)&ImplReadHidFeature, "Read Hid Feature");
    RdosRegisterOsGate(osgate_write_hid_feature, (__rdos_gate_callback *)&ImplWriteHidFeature, "Write Hid Feature");

    RdosRegisterBimodalUserGate(usergate_get_hid_report_item, (__rdos_gate_callback *)&ImplGetHidReportItem, "Get Hid Report Item");
    RdosRegisterBimodalUserGate(usergate_get_hid_report_input_data, (__rdos_gate_callback *)&ImplGetHidReportInputData, "Get Hid Report Input Data");
    RdosRegisterBimodalUserGate(usergate_get_hid_report_output_data, (__rdos_gate_callback *)&ImplGetHidReportOutputData, "Get Hid Report Output Data");
    RdosRegisterBimodalUserGate(usergate_get_hid_report_feature_data, (__rdos_gate_callback *)&ImplGetHidReportFeatureData, "Get Hid Report Feature Data");

//    RdosRegisterBimodalUserGate(usergate_test_gate, (__rdos_gate_callback *)&ImplTestGate, "Test Gate");

    return TRUE;
}
