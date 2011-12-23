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
# acpi.c
# ACPI device
#
########################################################################*/

#include "rdos.h"
#include "rdosdev.h"
#include "string.h"
#include "acpi.h"

#include "acconfig.h"
#include "aclocal.h"
#include "acobject.h"
#include "acstruct.h"
#include "acutils.h"

#include <stdio.h>

extern void InitAcpiTables();
extern void InitOsAcpi();

#define MAX_DEVICE_COUNT        1024
#define MAX_PCI_ROOT_COUNT      8
#define MAX_PCI_IRQ_COUNT       256
#define MAX_PCI_DEV_COUNT       256

/* do not reorganize these. Shared with assembly-code and gate definitions */

struct TIrqBase
{
    UINT8  IntNum;
    UINT8  Share;
    UINT8  Polarity;
    UINT8  Triggering;
};

struct TIoBase
{
    UINT16 Start;
    UINT16 Stop;
};

struct TMemBase
{
    UINT32 Start;
    UINT32 Stop;
};


/* local definitions */

struct TObjectEntry
{
    char AcpiName[5];
    ACPI_HANDLE Handle;
    ACPI_OBJECT_TYPE Type;
    struct TObjectEntry *Next;
};

struct TResourceBase
{
    struct TResourceBase *Next;
};

struct TResourceIrq
{
    struct TResourceIrq *Next;
    ACPI_RESOURCE_IRQ Data;
};

struct TResourceExtendedIrq
{
    struct TResourceExtendedIrq *Next;
    ACPI_RESOURCE_EXTENDED_IRQ Data;
};

struct TResourceDma
{
    struct TResourceDma *Next;
    ACPI_RESOURCE_DMA Data;
};

struct TResourceIo
{
    struct TResourceIo *Next;
    ACPI_RESOURCE_IO Data;
};

struct TResourceFixedIo
{
    struct TResourceFixedIo *Next;
    ACPI_RESOURCE_FIXED_IO Data;
};

struct TResourceMemory24
{
    struct TResourceMemory24 *Next;
    ACPI_RESOURCE_MEMORY24 Data;
};

struct TResourceMemory32
{
    struct TResourceMemory32 *Next;
    ACPI_RESOURCE_MEMORY32 Data;
};

struct TResourceFixedMemory32
{
    struct TResourceFixedMemory32 *Next;
    ACPI_RESOURCE_FIXED_MEMORY32 Data;
};

struct TResourceAddress16
{
    struct TResourceAddress16 *Next;
    ACPI_RESOURCE_ADDRESS16 Data;
};

struct TResourceAddress32
{
    struct TResourceAddress32 *Next;
    ACPI_RESOURCE_ADDRESS32 Data;
};

struct TDeviceEntry
{
    char AcpiName[5];
    ACPI_HANDLE Handle;
    ACPI_PCI_ID PciId;
    int IsPci;
    struct TDeviceEntry *DeviceList;
    struct TDeviceEntry *DeviceNext;
    struct TObjectEntry *ObjectList;
    struct TResourceIrq *IrqResourceList;
    struct TResourceExtendedIrq *ExtendedIrqResourceList;
    struct TResourceDma *DmaResourceList;
    struct TResourceIo *IoResourceList;
    struct TResourceFixedIo *FixedIoResourceList;
    struct TResourceMemory24 *Memory24ResourceList;
    struct TResourceMemory32 *Memory32ResourceList;
    struct TResourceMemoryFixed32 *FixedMemory32ResourceList;
    struct TResourceAddress16 *Address16ResourceList;
    struct TResourceAddress32 *Address32ResourceList;

};

ACPI_STATUS Status;
UINT16 CurrSegment;
UINT16 CurrBus;

struct TDeviceEntry *Root;

int DeviceCount = 0;
struct TDeviceEntry *DeviceArr[MAX_DEVICE_COUNT];

int HardwareCount = 0;
struct TDeviceEntry *HardwareArr[MAX_DEVICE_COUNT];

int PciRootCount = 0;
struct TDeviceEntry *PciRootArr[MAX_PCI_ROOT_COUNT];

int PciDevCount = 0;
struct TDeviceEntry *PciDevArr[MAX_PCI_DEV_COUNT];

int IrqRoutingCount = 0;
ACPI_PCI_ROUTING_TABLE *IrqRoutingTable[MAX_PCI_IRQ_COUNT];

char TempResourceBuf[0x4000];


/*##########################################################################
#
#   Name       : AddPciObject
#
#   Purpose....: Walk callback for creating PCI device tree
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
ACPI_STATUS AddPciObject(ACPI_HANDLE Object, UINT32 Nesting, void *Context, void **ReturnVal)
{
    ACPI_DEVICE_INFO *DevInfo;
    ACPI_STATUS DevStatus;
    int i;
            
    DevStatus = AcpiGetObjectInfo(Object, &DevInfo);
    if (DevStatus == AE_OK)
    {
        if (DevInfo->Valid & ACPI_VALID_ADR)
        {
            for (i = 0; i < DeviceCount; i++)
            {
                if (DeviceArr[i]->Handle == Object)
                {
                    DeviceArr[i]->PciId.Segment = CurrSegment;
                    DeviceArr[i]->PciId.Bus = CurrBus;
                    DeviceArr[i]->PciId.Device   = ACPI_HIWORD (ACPI_LODWORD (DevInfo->Address));
                    DeviceArr[i]->PciId.Function = ACPI_LOWORD (ACPI_LODWORD (DevInfo->Address));
                    DeviceArr[i]->IsPci = TRUE;
                    PciDevArr[PciDevCount] = DeviceArr[i];
                    PciDevCount++;
                    break;
                }
            }
        }
    }
    return AE_OK;
}

#pragma aux ImplTestGate "*" rdosdev parm routine [es edi]

void __far ImplTestGate(const char *msg)
{
    int i;    
    ACPI_STATUS DevStatus;
    UINT64 PciValue;
    ACPI_HANDLE Handle;

    Load();
    
    for (i = 0; i < PciRootCount; i++)
    {
        Handle = PciRootArr[i]->Handle;
        
        DevStatus = AcpiUtEvaluateNumericObject (METHOD_NAME__SEG, Handle, &PciValue);

        if (DevStatus == AE_OK)
            CurrSegment = ACPI_LOWORD (PciValue);
        else
            CurrSegment = 0;

        DevStatus = AcpiUtEvaluateNumericObject (METHOD_NAME__BBN, Handle, &PciValue);

        if (DevStatus == AE_OK)
            CurrBus = ACPI_LOWORD (PciValue);
        else
            CurrBus = 0;

        AcpiWalkNamespace(ACPI_TYPE_DEVICE, Handle, 1, AddPciObject, 0, 0, 0);
    }
}

/*##########################################################################
#
#   Name       : GetAcpiDeviceIrqBase
#
#   Purpose....: Get ACPI device IRQ
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux GetAcpiDeviceIrqBase "*" rdosdev parm routine [eax] [edx] [es edi] value [eax]
int GetAcpiDeviceIrqBase(int DevNr, int Index, struct TIrqBase *Irq)
{
    struct TResourceIrq *IrqEntry;
    struct TResourceExtendedIrq *ExtIrqEntry;
    struct TDeviceEntry *DevEntry;

    if (DevNr < HardwareCount)
    {
        DevEntry = HardwareArr[DevNr];
        IrqEntry = DevEntry->IrqResourceList;

        while (Index && IrqEntry)
        {
            Index--;
            IrqEntry = IrqEntry->Next;
        }

        if (IrqEntry)
        {
            if (IrqEntry->Data.InterruptCount == 1)
            {
                Irq->IntNum = IrqEntry->Data.Interrupts[0];
                Irq->Share = IrqEntry->Data.Sharable;
                if (IrqEntry->Data.Polarity)
                    Irq->Polarity = -1;
                else
                    Irq->Polarity = 1;
                Irq->Triggering = IrqEntry->Data.Triggering;

                return 1;
            }
        }
        else
        {
            ExtIrqEntry = DevEntry->ExtendedIrqResourceList;

            while (Index && ExtIrqEntry)
            {
                Index--;
                ExtIrqEntry = ExtIrqEntry->Next;
            }

            if (ExtIrqEntry)
            {
                if (ExtIrqEntry->Data.InterruptCount == 1)
                {
                    Irq->IntNum = ExtIrqEntry->Data.Interrupts[0];
                    Irq->Share = ExtIrqEntry->Data.Sharable;
                    if (ExtIrqEntry->Data.Polarity)
                        Irq->Polarity = -1;
                    else
                        Irq->Polarity = 1;
                    Irq->Triggering = ExtIrqEntry->Data.Triggering;

                    return 1;
                }
            }
        }
    }
    return 0;    
}

/*##########################################################################
#
#   Name       : GetAcpiDeviceIoBase
#
#   Purpose....: Get ACPI device IO
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux GetAcpiDeviceIoBase "*" rdosdev parm routine [eax] [edx] [es edi] value [eax]
int GetAcpiDeviceIoBase(int DevNr, int Index, struct TIoBase *Io)
{
    struct TResourceIo *IoEntry;
    struct TResourceFixedIo *FixedIoEntry;
    struct TDeviceEntry *DevEntry;
    
    if (DevNr < HardwareCount)
    {
        DevEntry = HardwareArr[DevNr];
        IoEntry = DevEntry->IoResourceList;

        while (Index && IoEntry)
        {
            Index--;
            IoEntry = IoEntry->Next;
        }

        if (IoEntry)
        {
            Io->Start = IoEntry->Data.Minimum;
            Io->Stop = IoEntry->Data.Maximum;
            return IoEntry->Data.AddressLength;
        }
        else
        {
            FixedIoEntry = DevEntry->FixedIoResourceList;

            while (Index && FixedIoEntry)
            {
                Index--;
                FixedIoEntry = FixedIoEntry->Next;
            }

            if (FixedIoEntry)
            {
                Io->Start = FixedIoEntry->Data.Address;
                Io->Stop = FixedIoEntry->Data.Address;
                return FixedIoEntry->Data.AddressLength;
            }
        }
    }
    return 0;    
}

/*##########################################################################
#
#   Name       : GetAcpiDeviceMemBase
#
#   Purpose....: Get ACPI device memory usage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux GetAcpiDeviceMemBase "*" rdosdev parm routine [eax] [edx] [es edi] value [eax]
int GetAcpiDeviceMemBase(int DevNr, int Index, struct TMemBase *Mem)
{
    struct TResourceMemory24 *Mem24Entry;
    struct TResourceMemory32 *Mem32Entry;
    struct TResourceFixedMemory32 *FixedMem32Entry;
    struct TDeviceEntry *DevEntry;
    
    if (DevNr < HardwareCount)
    {
        DevEntry = HardwareArr[DevNr];
        Mem24Entry = DevEntry->Memory24ResourceList;

        while (Index && Mem24Entry)
        {
            Index--;
            Mem24Entry = Mem24Entry->Next;
        }

        if (Mem24Entry)
        {
            Mem->Start = Mem24Entry->Data.Minimum << 8;
            Mem->Stop = Mem24Entry->Data.Maximum << 8;
            return Mem24Entry->Data.AddressLength << 8;
        }
        else
        {
            Mem32Entry = DevEntry->Memory32ResourceList;

            while (Index && Mem32Entry)
            {
                Index--;
                Mem32Entry = Mem32Entry->Next;
            }

            if (Mem32Entry)
            {
                Mem->Start = Mem32Entry->Data.Minimum;
                Mem->Stop = Mem32Entry->Data.Maximum;
                return Mem32Entry->Data.AddressLength;
            }
            else
            {
                FixedMem32Entry = DevEntry->FixedMemory32ResourceList;

                while (Index && FixedMem32Entry)
                {
                    Index--;
                    FixedMem32Entry = FixedMem32Entry->Next;
                }

                if (FixedMem32Entry)
                {
                    Mem->Start = FixedMem32Entry->Data.Address;
                    Mem->Stop = FixedMem32Entry->Data.Address;
                    return FixedMem32Entry->Data.AddressLength;
                }
            }
        }
    }
    return 0;    
}

/*##########################################################################
#
#   Name       : GetAcpiStatus
#
#   Purpose....: Get ACPI status
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAcpiStatus "*" rdosdev parm routine value [eax]
long __far ImplGetAcpiStatus()
{
    RdosSetSuccess();
    return Status;
}

/*##########################################################################
#
#   Name       : GetAcpiDevice
#
#   Purpose....: Get ACPI device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetAcpiDevice(int Index, char *AcpiName)
{
    ACPI_STATUS Status;
    ACPI_BUFFER Buffer;
    struct TDeviceEntry *DevEntry;
    
    if (Index < HardwareCount)
    {
        DevEntry = HardwareArr[Index];
        Buffer.Length = 128;
        Buffer.Pointer = AcpiName;
        Status = AcpiGetName(DevEntry->Handle, ACPI_FULL_PATHNAME, &Buffer);
        if (Status == AE_OK)
            return TRUE;
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : GetAcpiDevice16
#
#   Purpose....: Get ACPI device, 16-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAcpiDevice16 "*" rdosdev parm routine [eax] [es edi]
void __far ImplGetAcpiDevice16(int Index, char *AcpiName)
{
    RdosSaveEax();
    RdosExtendSi();
    RdosExtendDi();

    if (GetAcpiDevice(Index, AcpiName))
        RdosSetSuccess();
    else
        RdosSetFailure();

    RdosRestoreEax();
}

/*##########################################################################
#
#   Name       : GetAcpiDevice32
#
#   Purpose....: Get ACPI device, 32-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAcpiDevice32 "*" rdosdev parm routine [eax] [es edi]
void __far ImplGetAcpiDevice32(int Index, char *AcpiName)
{
    RdosSaveEax();

    if (GetAcpiDevice(Index, AcpiName))
        RdosSetSuccess();
    else
        RdosSetFailure();
    RdosRestoreEax();
}

/*##########################################################################
#
#   Name       : GetAcpiObject
#
#   Purpose....: Get ACPI object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetAcpiObject(int Index, char *AcpiName)
{
    ACPI_STATUS Status;
    ACPI_BUFFER Buffer;
    struct TDeviceEntry *DevEntry;
    
    if (Index < DeviceCount)
    {
        DevEntry = DeviceArr[Index];
        Buffer.Length = 128;
        Buffer.Pointer = AcpiName;
        Status = AcpiGetName(DevEntry->Handle, ACPI_FULL_PATHNAME, &Buffer);
        if (Status == AE_OK)
            return TRUE;
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : GetAcpiObject16
#
#   Purpose....: Get ACPI object, 16-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAcpiObject16 "*" rdosdev parm routine [eax] [es edi]
void __far ImplGetAcpiObject16(int Index, char *AcpiName)
{
    RdosSaveEax();
    RdosExtendSi();
    RdosExtendDi();

    if (GetAcpiObject(Index, AcpiName))
        RdosSetSuccess();
    else
        RdosSetFailure();

    RdosRestoreEax();
}

/*##########################################################################
#
#   Name       : GetAcpiObject32
#
#   Purpose....: Get ACPI object, 32-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAcpiObject32 "*" rdosdev parm routine [eax] [es edi]
void __far ImplGetAcpiObject32(int Index, char *AcpiName)
{
    RdosSaveEax();

    if (GetAcpiObject(Index, AcpiName))
        RdosSetSuccess();
    else
        RdosSetFailure();
    RdosRestoreEax();
}

/*##########################################################################
#
#   Name       : GetAcpiMethod
#
#   Purpose....: Get ACPI method
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetAcpiMethod(int Device, int Index, char *AcpiName)
{
    struct TDeviceEntry *DevEntry;
    struct TObjectEntry *ObjEntry;
    
    if (Device < DeviceCount)
    {
        DevEntry = DeviceArr[Device];

        ObjEntry = DevEntry->ObjectList;

        while (Index && ObjEntry)
        {
            Index--;
            ObjEntry = ObjEntry->Next;
        }

        if (ObjEntry)
        {        
            strcpy(AcpiName, ObjEntry->AcpiName);
            return TRUE;
        }
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : GetAcpiMethod16
#
#   Purpose....: Get ACPI method, 16-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAcpiMethod16 "*" rdosdev parm routine [eax] [edx] [es edi]
void __far ImplGetAcpiMethod16(int Device, int Index, char *AcpiName)
{
    RdosSaveEax();
    RdosExtendSi();
    RdosExtendDi();

    if (GetAcpiMethod(Device, Index, AcpiName))
        RdosSetSuccess();
    else
        RdosSetFailure();

    RdosRestoreEax();
}

/*##########################################################################
#
#   Name       : GetAcpiMethod32
#
#   Purpose....: Get ACPI method, 32-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAcpiMethod32 "*" rdosdev parm routine [eax] [edx] [es edi]
void __far ImplGetAcpiMethod32(int Device, int Index, char *AcpiName)
{
    RdosSaveEax();

    if (GetAcpiMethod(Device, Index, AcpiName))
        RdosSetSuccess();
    else
        RdosSetFailure();
    RdosRestoreEax();
}

/*##########################################################################
#
#   Name       : GetCpuTemperature
#
#   Purpose....: Get CPU temperature
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetCpuTemperature "*" rdosdev parm routine
int __far ImplGetCpuTemperature()
{
    ACPI_STATUS Status;
    ACPI_HANDLE Object;
    ACPI_BUFFER Buffer;
    char ValStr[11];

    Status = AcpiGetHandle(0, "\\PCI0\\PIDE", &Object);
    if (Status == AE_OK)
    {
        Buffer.Length = 10;
        Buffer.Pointer = ValStr;
        Status = AcpiEvaluateObject(Object, "_ADS", 0, &Buffer);
        if (Status == AE_OK)
        {
            RdosSetSuccess();
        }
        else
            RdosSetFailure();
    }
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : GetListDev
#
#   Purpose....: Get position in device-tree
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct TDeviceEntry *GetListDev(struct TDeviceEntry *DevList, ACPI_HANDLE Object)
{
    struct TDeviceEntry *Dev;
    struct TDeviceEntry *ListDev;

    Dev = DevList;
    
    while (Dev)        
    {
        if (Dev->Handle == Object)
            return Dev;

        ListDev = GetListDev(Dev->DeviceList, Object);
        if (ListDev)
            return ListDev;

        Dev = Dev->DeviceNext;
    }
    return 0;            
}

/*##########################################################################
#
#   Name       : GetParentDev
#
#   Purpose....: Get parent in device-tree
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct TDeviceEntry *GetParentDevice(ACPI_HANDLE Object)
{
    ACPI_HANDLE Parent;
    struct TDeviceEntry *Dev;
    struct TDeviceEntry *ListDev;

    Parent = 0;
    AcpiGetParent(Object, &Parent);

    Dev = Root;
    
    while (Dev)        
    {
        if (Dev->Handle == Parent)
            return Dev;

        ListDev = GetListDev(Dev->DeviceList, Parent);
        if (ListDev)
            return ListDev;

        Dev = Dev->DeviceNext;
    }
    return 0;            
}

/*##########################################################################
#
#   Name       : InsertRoot
#
#   Purpose....: Insert root device
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void InsertRoot(struct TDeviceEntry *Device)
{
    struct TDeviceEntry *Entry;

    Entry = Root;

    while (Entry->DeviceNext)
        Entry = Entry->DeviceNext;

    Entry->DeviceNext = Device;
}

/*##########################################################################
#
#   Name       : AddDevice
#
#   Purpose....: Add device to device-tree
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddDevice(struct TDeviceEntry *Parent, struct TDeviceEntry *Device)
{
    struct TDeviceEntry *Entry;

    if (Parent->DeviceList)
    {
        Entry = Parent->DeviceList;

        while (Entry->DeviceNext)
            Entry = Entry->DeviceNext;

        Entry->DeviceNext = Device;
    }
    else
        Parent->DeviceList = Device;
}

/*##########################################################################
#
#   Name       : AddObject
#
#   Purpose....: Add object to device-tree
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddObject(struct TDeviceEntry *Parent, struct TObjectEntry *Object)
{
    struct TObjectEntry *Entry;

    if (Parent->ObjectList)
    {
        Entry = Parent->ObjectList;

        while (Entry->Next)
            Entry = Entry->Next;

        Entry->Next = Object;
    }
    else
        Parent->ObjectList = Object;
}

/*##########################################################################
#
#   Name       : AddAcpiObject
#
#   Purpose....: Walk callback for creating device-tree
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
ACPI_STATUS AddAcpiObject(ACPI_HANDLE Object, UINT32 Nesting, void *Context, void **ReturnVal)
{
    ACPI_STATUS Status;
    ACPI_OBJECT_TYPE Type;
    ACPI_BUFFER Buffer;
    struct TObjectEntry *ObjEntry;
    struct TDeviceEntry *DevEntry;
    struct TDeviceEntry *OwnerDev;
        
    Status = AcpiGetType(Object, &Type);

    if (Status == AE_OK)
    {
        OwnerDev = GetParentDevice(Object);

        if (Type == ACPI_TYPE_DEVICE)
        {
            DevEntry = (struct TDeviceEntry *)AcpiOsAllocate(sizeof(struct TDeviceEntry));
            DevEntry->Handle = Object;
            DevEntry->DeviceList = 0;
            DevEntry->DeviceNext = 0;
            DevEntry->ObjectList = 0;
            Buffer.Length = 5;
            Buffer.Pointer = DevEntry->AcpiName;
            AcpiGetName(Object, ACPI_SINGLE_NAME, &Buffer);

            if (OwnerDev)
                AddDevice(OwnerDev, DevEntry);
            else
            {
                if (Root)
                    InsertRoot(DevEntry);
                else
                    Root = DevEntry;
            }

            if (DeviceCount < MAX_DEVICE_COUNT)
            {
                DeviceArr[DeviceCount] = DevEntry;
                DeviceCount++;
            }
            return AE_OK;
        }
        else
        {
            if (OwnerDev)
            {
                ObjEntry = (struct TObjectEntry *)AcpiOsAllocate(sizeof(struct TObjectEntry));
                ObjEntry->Type = Type;
                ObjEntry->Handle = Object;
                ObjEntry->Next = 0;
                Buffer.Length = 5;
                Buffer.Pointer = ObjEntry->AcpiName;
                AcpiGetName(Object, ACPI_SINGLE_NAME, &Buffer);
                AddObject(OwnerDev, ObjEntry);
            }
            return AE_CTRL_DEPTH;
        }
    }
    return AE_CTRL_TERMINATE;
}

/*##########################################################################
#
#   Name       : GetIrqRouting
#
#   Purpose....: Get IRQ routing tables
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GetIrqRouting()
{
    ACPI_STATUS Status;
    ACPI_BUFFER Buffer;
    struct TDeviceEntry *DevEntry;
    ACPI_PCI_ROUTING_TABLE *RouteEntry;
    char *ptr;
    int i;

    for (i = 0; i < MAX_DEVICE_COUNT; i++)
    {
        DevEntry = DeviceArr[i];
        if (DevEntry)
        {        
            Buffer.Length = 0x4000;
            Buffer.Pointer = TempResourceBuf;
            Status = AcpiGetIrqRoutingTable(DevEntry->Handle, &Buffer);

            if (Status == AE_OK && Buffer.Length > 0)
            {
                ptr = (char *)AcpiOsAllocate(Buffer.Length);
                memcpy(ptr, TempResourceBuf, Buffer.Length);
                RouteEntry = (ACPI_PCI_ROUTING_TABLE *)ptr;

                while (RouteEntry->Length)
                {
                    IrqRoutingTable[IrqRoutingCount] = RouteEntry;
                    IrqRoutingCount++;
                    ptr +=  RouteEntry->Length;
                    RouteEntry = (ACPI_PCI_ROUTING_TABLE *)ptr;
                }   
            }
        }
    }
}

/*##########################################################################
#
#   Name       : AddResource
#
#   Purpose....: Add an resource entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddResource(struct TDeviceEntry *DevEntry, int size)
{
    int CopyLen;
    int AllocLen;
    char *ptr;
    ACPI_RESOURCE *Resource;
    struct TResourceIrq *IrqResource;
    struct TResourceExtendedIrq *ExtendedIrqResource;
    struct TResourceDma *DmaResource;
    struct TResourceIo *IoResource;
    struct TResourceFixedIo *FixedIoResource;
    struct TResourceMemory24 *Memory24Resource;
    struct TResourceMemory32 *Memory32Resource;
    struct TResourceFixedMemory32 *FixedMemory32Resource;
    struct TResourceAddress16 *Address16Resource;
    struct TResourceAddress32 *Address32Resource;
    
    ptr = &TempResourceBuf;
    Resource = (ACPI_RESOURCE *)ptr;

    while (size > 0)
    {            
        CopyLen = Resource->Length - 2 * sizeof(UINT32);
        if (CopyLen > 0 && CopyLen < 0x1000)
        {
            AllocLen = sizeof(struct TResourceBase) + CopyLen; 
            switch (Resource->Type)
            {
                case ACPI_RESOURCE_TYPE_IRQ:
                    IrqResource = (struct TResourceIrq *)AcpiOsAllocate(AllocLen);
                    memcpy(&IrqResource->Data, &Resource->Data, CopyLen);
                    IrqResource->Next = DevEntry->IrqResourceList;
                    DevEntry->IrqResourceList = IrqResource;
                    break;
                            
                case ACPI_RESOURCE_TYPE_EXTENDED_IRQ:
                    ExtendedIrqResource = (struct TResourceExtendedIrq *)AcpiOsAllocate(AllocLen);
                    memcpy(&ExtendedIrqResource->Data, &Resource->Data, CopyLen);
                    ExtendedIrqResource->Next = DevEntry->ExtendedIrqResourceList;
                    DevEntry->ExtendedIrqResourceList = ExtendedIrqResource;
                    break;
                            
                case ACPI_RESOURCE_TYPE_DMA:
                    DmaResource = (struct TResourceDma *)AcpiOsAllocate(AllocLen);
                    memcpy(&DmaResource->Data, &Resource->Data, CopyLen);
                    DmaResource->Next = DevEntry->DmaResourceList;
                    DevEntry->DmaResourceList = DmaResource;
                    break;

                case ACPI_RESOURCE_TYPE_IO:
                    IoResource = (struct TResourceIo *)AcpiOsAllocate(AllocLen);
                    memcpy(&IoResource->Data, &Resource->Data, CopyLen);
                    IoResource->Next = DevEntry->IoResourceList;
                    DevEntry->IoResourceList = IoResource;
                    break;

                case ACPI_RESOURCE_TYPE_FIXED_IO:
                    FixedIoResource = (struct TResourceFixedIo *)AcpiOsAllocate(AllocLen);
                    memcpy(&FixedIoResource->Data, &Resource->Data, CopyLen);
                    FixedIoResource->Next = DevEntry->FixedIoResourceList;
                    DevEntry->FixedIoResourceList = FixedIoResource;
                    break;

                case ACPI_RESOURCE_TYPE_MEMORY24:
                    Memory24Resource = (struct TResourceMemory24 *)AcpiOsAllocate(AllocLen);
                    memcpy(&Memory24Resource->Data, &Resource->Data, CopyLen);
                    Memory24Resource->Next = DevEntry->Memory24ResourceList;
                    DevEntry->Memory24ResourceList = Memory24Resource;
                    break;

                case ACPI_RESOURCE_TYPE_MEMORY32:
                    Memory32Resource = (struct TResourceMemory32 *)AcpiOsAllocate(AllocLen);
                    memcpy(&Memory32Resource->Data, &Resource->Data, CopyLen);
                    Memory32Resource->Next = DevEntry->Memory32ResourceList;
                    DevEntry->Memory32ResourceList = Memory32Resource;
                    break;

                case ACPI_RESOURCE_TYPE_FIXED_MEMORY32:
                    FixedMemory32Resource = (struct TResourceFixedMemory32 *)AcpiOsAllocate(AllocLen);
                    memcpy(&FixedMemory32Resource->Data, &Resource->Data, CopyLen);
                    FixedMemory32Resource->Next = DevEntry->FixedMemory32ResourceList;
                    DevEntry->FixedMemory32ResourceList = FixedMemory32Resource;
                    break;

                case ACPI_RESOURCE_TYPE_ADDRESS16:
                    Address16Resource = (struct TResourceAddress16 *)AcpiOsAllocate(AllocLen);
                    memcpy(&Address16Resource->Data, &Resource->Data, CopyLen);
                    Address16Resource->Next = DevEntry->Address16ResourceList;
                    DevEntry->Address16ResourceList = Address16Resource;
                    break;

                case ACPI_RESOURCE_TYPE_ADDRESS32:
                    Address32Resource = (struct TResourceAddress32 *)AcpiOsAllocate(AllocLen);
                    memcpy(&Address32Resource->Data, &Resource->Data, CopyLen);
                    Address32Resource->Next = DevEntry->Address32ResourceList;
                    DevEntry->Address32ResourceList = Address32Resource;
                    break;

                default:
                    break;
            }
        }
        size -= Resource->Length;
        ptr += Resource->Length;
        Resource = (ACPI_RESOURCE *)ptr;        
    }
}

/*##########################################################################
#
#   Name       : GetHardware
#
#   Purpose....: Get hardware devices
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GetHardware()
{
    ACPI_STATUS Status;
    ACPI_BUFFER Buffer;
    ACPI_DEVICE_INFO *DevInfo;
    struct TResourceList *List;
    struct TDeviceEntry *DevEntry;
    int i;

    for (i = 0; i < MAX_DEVICE_COUNT; i++)
    {
        DevEntry = DeviceArr[i];
        if (DevEntry)
        {        
            DevEntry->IsPci = FALSE;
            DevEntry->IrqResourceList = 0;
            DevEntry->ExtendedIrqResourceList = 0;
            DevEntry->DmaResourceList = 0;
            DevEntry->IoResourceList = 0;
            DevEntry->FixedIoResourceList = 0;
            DevEntry->Memory24ResourceList = 0;
            DevEntry->Memory32ResourceList = 0;
            DevEntry->FixedMemory32ResourceList = 0;
            DevEntry->Address16ResourceList = 0;
            DevEntry->Address32ResourceList = 0;
            
            Buffer.Length = 0x10;
            Buffer.Pointer = TempResourceBuf;
            Status = AcpiGetName(DevEntry->Handle, ACPI_SINGLE_NAME, &Buffer);

            if (strstr(TempResourceBuf, "MEM"))
                Status = -1;

            if (Status == AE_OK)
            {
                Buffer.Length = 0x4000;
                Buffer.Pointer = TempResourceBuf;

                Status = AcpiGetCurrentResources(DevEntry->Handle, &Buffer);

                if (Status == AE_OK)
                {
                    AddResource(DevEntry, Buffer.Length);
                    HardwareArr[HardwareCount] = DevEntry;
                    HardwareCount++;
                }

                Status = AcpiGetObjectInfo(DevEntry->Handle, &DevInfo);
                if (Status == AE_OK)
                {
                    if (DevInfo->Flags & ACPI_PCI_ROOT_BRIDGE)
                    {
                        PciRootArr[PciRootCount] = DevEntry;
                        PciRootCount++;
                    }        
                }
            }
        }
    }
}

/*##########################################################################
#
#   Name       : Load
#
#   Purpose....: Make sure tables are loaded & initialized
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void Load()
{
    int i;

    if (Status == 0)
    {
        Status = AcpiLoadTables();
        if (Status != 0)
            Status |= 0x20000;
    }

    if (Status == 0)
    {
        Status = AcpiEnableSubsystem(ACPI_FULL_INITIALIZATION);
        if (Status != 0)
            Status |= 0x30000;
    }

    if (Status == 0)
    {
        Status = AcpiInitializeObjects(ACPI_FULL_INITIALIZATION);
        if (Status != 0)
            Status |= 0x40000;
    }
    if (Status == 0)
    {
        AcpiWalkNamespace(ACPI_TYPE_ANY, ACPI_ROOT_OBJECT, 10, AddAcpiObject, 0, 0, 0);
        GetHardware();        
        GetIrqRouting();
    }
}

/*##########################################################################
#
#   Name       : InitTasking
#
#   Purpose....: Init tasking callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux InitTasking "*" rdosdev parm routine
void __far InitTasking()
{
    InitOsAcpi();
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
    InitAcpiTables();

    Status = AcpiInitializeSubsystem();
    if (Status == 0)
    {
        Status = AcpiInitializeTables(0, 0, 0);
        if (Status != 0)
            Status |= 0x10000;
    }

    RdosHookInitTasking(&InitTasking);
    RdosRegisterBimodalUserGate(usergate_get_acpi_status, &ImplGetAcpiStatus, "Get ACPI Status");
    RdosRegisterUserGate(usergate_get_acpi_object, &ImplGetAcpiObject16, &ImplGetAcpiObject32, "Get ACPI Object");
    RdosRegisterUserGate(usergate_get_acpi_method, &ImplGetAcpiMethod16, &ImplGetAcpiMethod32, "Get ACPI Method");
    RdosRegisterUserGate(usergate_get_acpi_device, &ImplGetAcpiDevice16, &ImplGetAcpiDevice32, "Get ACPI Device");
    RdosRegisterBimodalUserGate(usergate_get_cpu_temperature, &ImplGetCpuTemperature, "Get CPU Temperature");

    RdosRegisterBimodalUserGate(usergate_test_gate, &ImplTestGate, "Test Gate");
}
