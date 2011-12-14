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

#include <stdio.h>

extern void InitAcpiTables();
extern void InitOsAcpi();

#define MAX_DEVICE_COUNT        1024
#define MAX_PCI_IRQ_COUNT       256

struct TObjectEntry
{
    char AcpiName[5];
    ACPI_HANDLE Handle;
    ACPI_OBJECT_TYPE Type;
    struct TObjectEntry *Next;
};

struct TResourceBase
{
    struct TResourceBase *Next
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

struct TResourceList
{
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

struct TDeviceEntry
{
    char AcpiName[5];
    ACPI_HANDLE Handle;
    struct TDeviceEntry *DeviceList;
    struct TDeviceEntry *DeviceNext;
    struct TObjectEntry *ObjectList;
    struct TResourceList PossibleResourceList;
    struct TResourceList CurrentResourceList;
};

ACPI_STATUS Status;

struct TDeviceEntry *Root;

int DeviceCount = 0;
struct TDeviceEntry *DeviceArr[MAX_DEVICE_COUNT];

int HardwareCount = 0;
struct TDeviceEntry *HardwareArr[MAX_DEVICE_COUNT];

int IrqRoutingCount = 0;
ACPI_PCI_ROUTING_TABLE *IrqRoutingTable[MAX_PCI_IRQ_COUNT];

char TempResourceBuf[0x4000];

#pragma aux ImplTestGate "*" rdosdev parm routine [es edi]

void __far ImplTestGate(const char *msg)
{
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
int GetAcpiObject(int Device, int Index, char *AcpiName)
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
#   Name       : GetAcpiObject16
#
#   Purpose....: Get ACPI object, 16-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetAcpiObject16 "*" rdosdev parm routine [eax] [edx] [es edi]
void __far ImplGetAcpiObject16(int Device, int Index, char *AcpiName)
{
    RdosSaveEax();
    RdosExtendSi();
    RdosExtendDi();

    if (GetAcpiObject(Device, Index, AcpiName))
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
#pragma aux ImplGetAcpiObject32 "*" rdosdev parm routine [eax] [edx] [es edi]
void __far ImplGetAcpiObject32(int Device, int Index, char *AcpiName)
{
    RdosSaveEax();

    if (GetAcpiObject(Device, Index, AcpiName))
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

            if (Status == AE_OK)
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
#   Name       : InitResource
#
#   Purpose....: Init an resource list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void InitResource(struct TResourceList *list)
{
    list->IrqResourceList = 0;
    list->ExtendedIrqResourceList = 0;
    list->DmaResourceList = 0;
    list->IoResourceList = 0;
    list->FixedIoResourceList = 0;
    list->Memory24ResourceList = 0;
    list->Memory32ResourceList = 0;
    list->FixedMemory32ResourceList = 0;
    list->Address16ResourceList = 0;
    list->Address32ResourceList = 0;
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
void AddResource(struct TResourceList *list, int size)
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
        if (CopyLen)
        {
            AllocLen = sizeof(struct TResourceBase) + CopyLen; 
            switch (Resource->Type)
            {
                case ACPI_RESOURCE_TYPE_IRQ:
                    IrqResource = (struct TResourceIrq *)AcpiOsAllocate(AllocLen);
                    memcpy(&IrqResource->Data, &Resource->Data, CopyLen);
                    IrqResource->Next = list->IrqResourceList;
                    list->IrqResourceList = IrqResource;
                    break;
                            
                case ACPI_RESOURCE_TYPE_EXTENDED_IRQ:
                    ExtendedIrqResource = (struct TResourceExtendedIrq *)AcpiOsAllocate(AllocLen);
                    memcpy(&ExtendedIrqResource->Data, &Resource->Data, CopyLen);
                    ExtendedIrqResource->Next = list->ExtendedIrqResourceList;
                    list->ExtendedIrqResourceList = ExtendedIrqResource;
                    break;
                            
                case ACPI_RESOURCE_TYPE_DMA:
                    DmaResource = (struct TResourceDma *)AcpiOsAllocate(AllocLen);
                    memcpy(&DmaResource->Data, &Resource->Data, CopyLen);
                    DmaResource->Next = list->DmaResourceList;
                    list->DmaResourceList = DmaResource;
                    break;

                case ACPI_RESOURCE_TYPE_IO:
                    IoResource = (struct TResourceIo *)AcpiOsAllocate(AllocLen);
                    memcpy(&IoResource->Data, &Resource->Data, CopyLen);
                    IoResource->Next = list->IoResourceList;
                    list->IoResourceList = IoResource;
                    break;

                case ACPI_RESOURCE_TYPE_FIXED_IO:
                    FixedIoResource = (struct TResourceFixedIo *)AcpiOsAllocate(AllocLen);
                    memcpy(&FixedIoResource->Data, &Resource->Data, CopyLen);
                    FixedIoResource->Next = list->FixedIoResourceList;
                    list->FixedIoResourceList = FixedIoResource;
                    break;

                case ACPI_RESOURCE_TYPE_MEMORY24:
                    Memory24Resource = (struct TResourceMemory24 *)AcpiOsAllocate(AllocLen);
                    memcpy(&Memory24Resource->Data, &Resource->Data, CopyLen);
                    Memory24Resource->Next = list->Memory24ResourceList;
                    list->Memory24ResourceList = Memory24Resource;
                    break;

                case ACPI_RESOURCE_TYPE_MEMORY32:
                    Memory32Resource = (struct TResourceMemory32 *)AcpiOsAllocate(AllocLen);
                    memcpy(&Memory32Resource->Data, &Resource->Data, CopyLen);
                    Memory32Resource->Next = list->Memory32ResourceList;
                    list->Memory32ResourceList = Memory32Resource;
                    break;

                case ACPI_RESOURCE_TYPE_FIXED_MEMORY32:
                    FixedMemory32Resource = (struct TResourceFixedMemory32 *)AcpiOsAllocate(AllocLen);
                    memcpy(&FixedMemory32Resource->Data, &Resource->Data, CopyLen);
                    FixedMemory32Resource->Next = list->FixedMemory32ResourceList;
                    list->FixedMemory32ResourceList = FixedMemory32Resource;
                    break;

                case ACPI_RESOURCE_TYPE_ADDRESS16:
                    Address16Resource = (struct TResourceAddress16 *)AcpiOsAllocate(AllocLen);
                    memcpy(&Address16Resource->Data, &Resource->Data, CopyLen);
                    Address16Resource->Next = list->Address16ResourceList;
                    list->Address16ResourceList = Address16Resource;
                    break;

                case ACPI_RESOURCE_TYPE_ADDRESS32:
                    Address32Resource = (struct TResourceAddress32 *)AcpiOsAllocate(AllocLen);
                    memcpy(&Address32Resource->Data, &Resource->Data, CopyLen);
                    Address32Resource->Next = list->Address32ResourceList;
                    list->Address32ResourceList = Address32Resource;
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
    struct TResourceList *List;
    struct TDeviceEntry *DevEntry;
    int i;

    for (i = 0; i < MAX_DEVICE_COUNT; i++)
    {
        DevEntry = DeviceArr[i];
        if (DevEntry)
        {        
            List = &DevEntry->PossibleResourceList;
            InitResource(List);

            List = &DevEntry->CurrentResourceList;
            InitResource(List);
            
            Buffer.Length = 0x4000;
            Buffer.Pointer = TempResourceBuf;
            Status = AcpiGetCurrentResources(DevEntry->Handle, &Buffer);
            if (Status == AE_OK)
            {
                AddResource(List, Buffer.Length);

                List = &DevEntry->PossibleResourceList;
                Buffer.Length = 0x4000;
                Buffer.Pointer = TempResourceBuf;
                Status = AcpiGetPossibleResources(DevEntry->Handle, &Buffer);
                if (Status == AE_OK)
                    AddResource(List, Buffer.Length);

                HardwareArr[HardwareCount] = DevEntry;
                HardwareCount++;
            }
        }
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
    RdosRegisterUserGate(usergate_get_acpi_device, &ImplGetAcpiDevice16, &ImplGetAcpiDevice32, "Get ACPI Device");
    RdosRegisterUserGate(usergate_get_acpi_object, &ImplGetAcpiObject16, &ImplGetAcpiObject32, "Get ACPI Object");
    RdosRegisterBimodalUserGate(usergate_get_cpu_temperature, &ImplGetCpuTemperature, "Get CPU Temperature");

    RdosRegisterBimodalUserGate(usergate_test_gate, &ImplTestGate, "Test Gate");
}
