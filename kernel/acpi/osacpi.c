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
# osacpi.c
# OS interface for ACPI
#
########################################################################*/

#include "rdos.h"
#include "rdosdev.h"
#include "acpi.h"
#include "acpiosxf.h"

struct TExecReq
{
    struct TExecReq *Next;
    ACPI_EXECUTE_TYPE Type;
    ACPI_OSD_EXEC_CALLBACK Function;
    void *Context;
};

struct TIntReq
{
    ACPI_OSD_HANDLER Handler;
    void *Context;
};

struct TExecReq *ExecList = 0;
int ExecThread = 0;
struct TKernelSection ExecSection;

long MapLinear;
struct TSpinlock MapLock;

char ReadBytePort(short int address);
short int ReadWordPort(short int address);
long ReadDwordPort(short int address);

void WriteBytePort(short int address, char val);
void WriteWordPort(short int address, short int val);
void WriteDwordPort(short int address, long val);

extern void LinkIrq(int Irq, void *Handler, void *Context);
#pragma aux LinkIrq parm routine [eax] [fs esi] [es edi] 

void Load();

#pragma aux ReadBytePort = \
    "in al,dx" \
    parm [dx] \
    value [al];

#pragma aux ReadWordPort = \
    "in ax,dx" \
    parm [dx] \
    value [ax];

#pragma aux ReadDwordPort = \
    "in eax,dx" \
    parm [dx] \
    value [eax];

#pragma aux WriteBytePort = \
    "out dx,al" \
    parm [dx] [al];

#pragma aux WriteWordPort = \
    "out dx,ax" \
    parm [dx] [ax];

#pragma aux WriteDwordPort = \
    "out dx,eax" \
    parm [dx] [eax];

/*##########################################################################
#
#   Name       : AcpiOsInitialize
#
##########################################################################*/
ACPI_STATUS AcpiOsInitialize()
{
    MapLinear = RdosAllocateBigGlobalLinear(0x2000);
    RdosInitSpinlock(&MapLock);

    return AE_OK;
}

/*##########################################################################
#
#   Name       : AcpiOsTerminate
#
##########################################################################*/
ACPI_STATUS AcpiOsTerminate()
{
    return AE_OK;
}

/*##########################################################################
#
#   Name       : AcpiOsPredefinedOverride
#
##########################################################################*/
ACPI_STATUS AcpiOsPredefinedOverride(const ACPI_PREDEFINED_NAMES *Obj, ACPI_STRING *NewValue)
{
    *NewValue = 0;
    return AE_OK;
}

/*##########################################################################
#
#   Name       : AcpiOsTableOverride
#
##########################################################################*/
ACPI_STATUS AcpiOsTableOverride(ACPI_TABLE_HEADER *Table, ACPI_TABLE_HEADER **NewTable)
{
    *NewTable = 0;
    return AE_OK;
}

/*##########################################################################
#
#   Name       : AcpiOsPhysicalTableOverride
#
##########################################################################*/
ACPI_STATUS AcpiOsPhysicalTableOverride(ACPI_TABLE_HEADER *ExistingTable, ACPI_PHYSICAL_ADDRESS *NewAddress, UINT32 *NewTableLength)
{
    *NewAddress = 0;
    return AE_OK;
}

/*##########################################################################
#
#   Name       : AcpiOsMapMemory
#
##########################################################################*/
void *AcpiOsMapMemory(ACPI_PHYSICAL_ADDRESS PhysicalAddress, ACPI_SIZE Length)
{
    long linear;
    long offset;
    long size;
    long ads;

    offset = PhysicalAddress & 0xFFF;
    PhysicalAddress &= 0xFFFFFFFFFFFFF000;

    size = Length + offset;
    if (size & 0xFFF)
    {
        size &= 0xFFFFF000;
        size += 0x1000;
    }

    linear = RdosAllocateBigGlobalLinear(size);
    if (linear)
    {
        ads = linear + offset;
        while (size)
        {
            RdosSetPageEntry(linear, PhysicalAddress | 0x3);
            linear += 0x1000;
            PhysicalAddress += 0x1000;
            size -= 0x1000;
        }
        return RdosLinearToPointer(ads);
    }
    else
        return 0;
}

/*##########################################################################
#
#   Name       : AcpiOsUnmapMemory
#
##########################################################################*/
void AcpiOsUnmapMemory(void *LogicalAddress, ACPI_SIZE Length)
{
    long linear;
    long offset;
    long size;
    long base;

    linear = RdosPointerToOffset(LogicalAddress);

    offset = linear & 0xFFF;
    linear &= 0xFFFFF000;

    size = Length + offset;
    if (size & 0xFFF)
    {
        size &= 0xFFFFF000;
        size += 0x1000;
    }

    base = linear;

    while (size)
    {
        RdosSetPageEntry(linear, 0);
        linear += 0x1000;
        size -= 0x1000;
    }

    RdosFreeLinear(linear, size);
}

/*##########################################################################
#
#   Name       : AcpiOsGetPhysicalAddress
#
##########################################################################*/
ACPI_STATUS AcpiOsGetPhysicalAddress(void *LogicalAddress, ACPI_PHYSICAL_ADDRESS *PhysicalAddress)
{
    long linear;
    long offset;

    linear = RdosPointerToOffset(LogicalAddress);

    offset = linear & 0xFFF;
    linear &= 0xFFFFF000;

    *PhysicalAddress = RdosGetPageEntry(linear) + offset;

    return AE_OK;
}

/*##########################################################################
#
#   Name       : AcpiOsAllocate
#
##########################################################################*/
void *AcpiOsAllocate(ACPI_SIZE Size)
{
    long linear;
    char *ptr;

    if (Size > 0x100000)
        return 0;
    
    if (Size < 0x1000)
    {
        linear = RdosAllocateSmallGlobalLinear(Size);
        ptr = (char *)RdosLinearToPointer(linear);
    }
    else
        ptr = (char *)RdosAllocateBigGlobalMem(Size);

    memset(ptr, 0, Size);
    return ptr;
}

/*##########################################################################
#
#   Name       : AcpiOsFree
#
##########################################################################*/
void AcpiOsFree(void *Memory)
{
    int linear;

    int sel = RdosPointerToSelector(Memory);    

    if (Memory == 0)
        return;
    
    if (sel == 0x20)
    {
        linear = RdosPointerToOffset(Memory);
        RdosFreeLinear(linear, 0);  // small linear won't require a size!
    }
    else
        RdosFreeMem(sel);
}

/*##########################################################################
#
#   Name       : AcpiOsGetThreadId
#
##########################################################################*/
ACPI_THREAD_ID AcpiOsGetThreadId()
{
    return RdosGetThreadHandle();
}

/*##########################################################################
#
#   Name       : AcpiOsExecute
#
##########################################################################*/
ACPI_STATUS AcpiOsExecute(ACPI_EXECUTE_TYPE Type, ACPI_OSD_EXEC_CALLBACK Function, void *Context)
{
    struct TExecReq *req = (struct TExecReq *)malloc(sizeof(struct TExecReq));
    struct TExecReq *ptr;
    int HasThread = ExecThread;

    if (HasThread)
        RdosEnterKernelSection(&ExecSection);

    req->Next = 0;
    req->Type = Type;
    req->Function = Function;
    req->Context = Context;

    if (ExecList)
    {
        ptr = ExecList;

        while (ptr->Next)
            ptr = ptr->Next;

        ptr->Next = req;
    }
    else
        ExecList = req;

    if (HasThread)
    {
        RdosLeaveKernelSection(&ExecSection);
        RdosSignal(ExecThread);
    }

    return AE_OK;
}

/*##########################################################################
#
#   Name       : AcpiOsCreateLock
#
##########################################################################*/
ACPI_STATUS AcpiOsCreateLock(ACPI_SPINLOCK *OutHandle)
{
    *OutHandle = (ACPI_SPINLOCK)malloc(sizeof(struct TSpinlock));
    RdosInitSpinlock(*OutHandle);
    return AE_OK;
}

/*##########################################################################
#
#   Name       : AcpiOsDeleteLock
#
##########################################################################*/
void AcpiOsDeleteLock(ACPI_SPINLOCK Handle)
{
    free(Handle);
}

/*##########################################################################
#
#   Name       : AcpiOsAcquireLock
#
##########################################################################*/
ACPI_CPU_FLAGS AcpiOsAcquireLock(ACPI_SPINLOCK Handle)
{
    return RdosRequestSpinlock(Handle);
}

/*##########################################################################
#
#   Name       : AcpiOsReleaseLock
#
##########################################################################*/
void AcpiOsReleaseLock(ACPI_SPINLOCK Handle, ACPI_CPU_FLAGS Flags)
{
    RdosReleaseSpinlock(Handle, Flags);
}

/*##########################################################################
#
#   Name       : AcpiOsCreateMutex
#
##########################################################################*/
ACPI_STATUS AcpiOsCreateMutex(ACPI_MUTEX *OutHandle)
{
    *OutHandle = (ACPI_MUTEX)malloc(sizeof(struct TKernelSection));
    RdosInitKernelSection(*OutHandle);
    return AE_OK;
}

/*##########################################################################
#
#   Name       : AcpiOsDeleteMutex
#
##########################################################################*/
void AcpiOsDeleteMutex(ACPI_MUTEX Handle)
{
    free(Handle);
}

/*##########################################################################
#
#   Name       : AcpiOsAcquireMutex
#
##########################################################################*/
ACPI_STATUS AcpiOsAcquireMutex(ACPI_MUTEX Handle, UINT16 Timeout)
{
    if (Timeout == 0xFFFF)
    {
        RdosEnterKernelSection(Handle);
        return AE_OK;
    }
    else
    {
        if (RdosCondEnterKernelSection(Handle, Timeout))
            return AE_OK;
        else
            return AE_TIME;
    }
}

/*##########################################################################
#
#   Name       : AcpiOsReleaseMutex
#
##########################################################################*/
void AcpiOsReleaseMutex(ACPI_MUTEX Handle)
{
    RdosLeaveKernelSection(Handle);
}

/*##########################################################################
#
#   Name       : AcpiOsCreateSemaphore
#
##########################################################################*/
ACPI_STATUS AcpiOsCreateSemaphore(UINT32 MaxUnits, UINT32 InitUnits, ACPI_SEMAPHORE *OutHandle)
{
    struct TSemaphore *sema;
    
    sema = (struct TSemaphore *)malloc(sizeof(struct TSemaphore));
    RdosInitKernelSection(&sema->gate);
    RdosInitKernelSection(&sema->mutex);
    sema->maxval = MaxUnits;
    sema->currval = InitUnits;

    if (InitUnits == 0)
        RdosEnterKernelSection(&sema->gate);

    *OutHandle = sema;
    return AE_OK;
}

/*##########################################################################
#
#   Name       : AcpiOsDeleteSemaphore
#
##########################################################################*/
ACPI_STATUS AcpiOsDeleteSemaphore(ACPI_SEMAPHORE Handle)
{
    free(Handle);
    return AE_OK;
}

/*##########################################################################
#
#   Name       : AcpiOsWaitSemaphore
#
##########################################################################*/
ACPI_STATUS AcpiOsWaitSemaphore(ACPI_SEMAPHORE Handle, UINT32 Units, UINT16 Timeout)
{
    int ok = TRUE;

    if (Timeout == 0xFFFF)
        RdosEnterKernelSection(&Handle->gate);
    else
        ok = RdosCondEnterKernelSection(&Handle->gate, Timeout);

    if (Handle->maxval > 1)
    {
        if (ok)
        {
            RdosEnterKernelSection(&Handle->mutex);

            if (Handle->currval >= Units)
            {
                Handle->currval -= Units;

                if (Handle->currval > 0)
                    RdosLeaveKernelSection(&Handle->gate);
            }
            else
                ok = FALSE;

            RdosLeaveKernelSection(&Handle->mutex);
        }
    }

    if (ok)
        return AE_OK;
    else
        return AE_TIME;
}
    
/*##########################################################################
#
#   Name       : AcpiOsSignalSemaphore
#
##########################################################################*/
ACPI_STATUS AcpiOsSignalSemaphore(ACPI_SEMAPHORE Handle, UINT32 Units)
{
    if (Handle->maxval == 1)
        RdosLeaveKernelSection(&Handle->gate);
    else
    {
        RdosEnterKernelSection(&Handle->mutex);
        Handle->currval += Units;
        if (Handle->currval == Units)
            RdosLeaveKernelSection(&Handle->gate);
        RdosLeaveKernelSection(&Handle->mutex);
    }
    return AE_OK;
}
    
/*##########################################################################
#
#   Name       : AcpiOsSignal
#
##########################################################################*/
ACPI_STATUS AcpiOsSignal(UINT32 Function, void *Info)
{
    return AE_OK;
}
    
/*##########################################################################
#
#   Name       : AcpiOsStall
#
##########################################################################*/
void AcpiOsStall(UINT32 us)
{
    RdosWaitMicro(us);
}
    
/*##########################################################################
#
#   Name       : AcpiOsSleep
#
##########################################################################*/
void AcpiOsSleep(UINT64 ms)
{
    unsigned long msb, lsb;
    int min, sec, milli, micro;
    int temp;
    int remain;
    
    RdosGetSysTime(&msb, &lsb);

    RdosDecodeLsbTics(lsb, &min, &sec, &milli, &micro); 

    while (ms > 1000 * 3600)
    {
        msb++;
        ms -= 1000 * 3600;
    }

    remain = ms;

    temp = remain % 1000;

    milli += temp;
    remain -= temp;

    remain = remain / 1000;
    temp = remain % 60;

    sec += temp;
    remain -= temp;

    remain = remain / 60;
    temp = remain % 60;

    min += temp;    

    lsb = RdosCodeLsbTics(min, sec, milli, micro);
    
    RdosWaitUntil(msb, lsb);
}
    
/*##########################################################################
#
#   Name       : AcpiOsGetTimer
#
##########################################################################*/
UINT64 AcpiOsGetTimer()
{
    UINT64 val;
    unsigned long msb, lsb;
    int min, sec, milli, micro;
    
    RdosGetSysTime(&msb, &lsb);
    RdosDecodeLsbTics(lsb, &min, &sec, &milli, &micro); 

    val = msb;
    val = val * 24 + min;
    val = val * 60 + sec;
    val = val * 60 + milli;
    val = val * 1000 + micro;
    
    return 10 * val;
}
    
/*##########################################################################
#
#   Name       : AcpiOsReadMemory
#
##########################################################################*/
ACPI_STATUS AcpiOsReadMemory(ACPI_PHYSICAL_ADDRESS Address, UINT64 *Value, UINT32 Width)
{
    ACPI_CPU_FLAGS flags;
    long long page;
    long offset;
    void *ptr;
    long long res = 0;

    page = Address & 0xFFFFFFFFFFFFF000;
    offset = Address & 0xFFF;

    flags = RdosRequestSpinlock(&MapLock);

    RdosSetPageEntry(MapLinear, page | 0x3);
    RdosSetPageEntry(MapLinear + 0x1000, (page + 0x1000) | 0x3);
    ptr = RdosLinearToPointer(MapLinear + offset);

    switch (Width)
    {
        case 8:
            res = *(char *)ptr;
            break;

        case 16:
            res = *(short int *)ptr;
            break;

        case 32:
            res = *(long *)ptr;
            break;

        case 64:
            res = *(long long *)ptr;
            break;
    }

    *Value = res;

    RdosReleaseSpinlock(&MapLock, flags);

    return AE_OK;
}
    
/*##########################################################################
#
#   Name       : AcpiOsWriteMemory
#
##########################################################################*/
ACPI_STATUS AcpiOsWriteMemory(ACPI_PHYSICAL_ADDRESS Address, UINT64 Value, UINT32 Width)
{
    ACPI_CPU_FLAGS flags;
    long long page;
    long offset;
    void *ptr;

    page = Address & 0xFFFFFFFFFFFFF000;
    offset = Address & 0xFFF;

    flags = RdosRequestSpinlock(&MapLock);

    RdosSetPageEntry(MapLinear, page | 0x3);
    RdosSetPageEntry(MapLinear + 0x1000, (page + 0x1000) | 0x3);
    ptr = RdosLinearToPointer(MapLinear + offset);

    switch (Width)
    {
        case 8:
            *(char *)ptr = (char)Value;
            break;

        case 16:
            *(short int *)ptr = (short int)Value;
            break;

        case 32:
            *(long *)ptr = (long)Value;
            break;

        case 64:
            *(long long *)ptr = Value;
            break;
    }

    RdosReleaseSpinlock(&MapLock, flags);

    return AE_OK;
}
    
/*##########################################################################
#
#   Name       : AcpiOsReadPort
#
##########################################################################*/
ACPI_STATUS AcpiOsReadPort(ACPI_IO_ADDRESS Address, UINT32 *Value, UINT32 Width)
{
    long res = 0;

    switch (Width)
    {
        case 8:
            res = ReadBytePort(Address);
            break;

        case 16:
            res = ReadWordPort(Address);
            break;

        case 32:
            res = ReadDwordPort(Address);
            break;
    }

    *Value = res;

    return AE_OK;
}
    
/*##########################################################################
#
#   Name       : AcpiOsWritePort
#
##########################################################################*/
ACPI_STATUS AcpiOsWritePort(ACPI_IO_ADDRESS Address, UINT32 Value, UINT32 Width)
{
    switch (Width)
    {
        case 8:
            WriteBytePort(Address, (char)Value);
            break;

        case 16:
            WriteWordPort(Address, (short int)Value);
            break;

        case 32:
            WriteDwordPort(Address, Value);
            break;
    }

    return AE_OK;
}
    
/*##########################################################################
#
#   Name       : AcpiOsReadPciConfiguration
#
##########################################################################*/
ACPI_STATUS AcpiOsReadPciConfiguration(ACPI_PCI_ID *PciId, UINT32 Reg, UINT64 *Value, UINT32 Width)
{
    UINT64 res = 0;

    switch (Width)
    {
        case 8:
            res = RdosReadPciByte(PciId->Bus, PciId->Device, PciId->Function, Reg);
            break;

        case 16:
            res = RdosReadPciWord(PciId->Bus, PciId->Device, PciId->Function, Reg);
            break;

        case 32:
            res = RdosReadPciDword(PciId->Bus, PciId->Device, PciId->Function, Reg);
            break;
    }

    *Value = res;

    return AE_OK;
}
    
/*##########################################################################
#
#   Name       : AcpiOsWritePciConfiguration
#
##########################################################################*/
ACPI_STATUS AcpiOsWritePciConfiguration(ACPI_PCI_ID *PciId, UINT32 Reg, UINT64 Value, UINT32 Width)
{
    switch (Width)
    {
        case 8:
            RdosWritePciByte(PciId->Bus, PciId->Device, PciId->Function, Reg, (char)Value);
            break;

        case 16:
            RdosWritePciWord(PciId->Bus, PciId->Device, PciId->Function, Reg, (short int)Value);
            break;

        case 32:
            RdosWritePciDword(PciId->Bus, PciId->Device, PciId->Function, Reg, Value);
            break;
    }

    return AE_OK;
}
    
/*##########################################################################
#
#   Name       : AcpiOsPrintf
#
##########################################################################*/
void ACPI_INTERNAL_VAR_XFACE AcpiOsPrintf(const char *Format,  ...)
{
}
    
/*##########################################################################
#
#   Name       : AcpiOsVprintf
#
##########################################################################*/
void AcpiOsVprintf(const char *Format, va_list Args)
{
}
    
/*##########################################################################
#
#   Name       : IrqStart
#
##########################################################################*/
#pragma aux IrqStart "*" rdosdev parm routine [fs esi] [es edi]
void IrqStart(ACPI_OSD_HANDLER Handler, void *Context)
{
    (*Handler)(Context);
}
    
/*##########################################################################
#
#   Name       : AcpiOsInstallInterruptHandler
#
##########################################################################*/
ACPI_STATUS AcpiOsInstallInterruptHandler(UINT32 Level, ACPI_OSD_HANDLER Handler, void *Context)
{
    LinkIrq(Level, Handler, Context);
    return AE_OK;
}
    
/*##########################################################################
#
#   Name       : AcpiOsRemoveInterruptHandler
#
##########################################################################*/
ACPI_STATUS AcpiOsRemoveInterruptHandler(UINT32 Level, ACPI_OSD_HANDLER Handler)
{
    return AE_OK;
}
    
/*##########################################################################
#
#   Name       : AcpiThread
#
##########################################################################*/
#pragma aux AcpiThread "*" rdosdev parm routine [es edi]
void __far AcpiThread(void *param)
{
    struct TExecReq *exec;

    ExecThread = RdosGetThreadHandle();

    for (;;)
    {
        for (;;)
        {
            exec = 0;
            RdosEnterKernelSection(&ExecSection);
            if (ExecList)
            {
                exec = ExecList;
                ExecList = ExecList->Next;
            }
            RdosLeaveKernelSection(&ExecSection);

            if (exec)
            {
                (*exec->Function)(exec->Context);
                free(exec);
            }
            else
                break;
            
        }
        RdosWaitForSignal();
//        RdosWaitMilli(100);
    }
}

    /*##########################################################################
#
#   Name       : AcpiWaitEventsComplete
#
##########################################################################*/
void AcpiOsWaitEventsComplete()
{
    while (ExecList)
        RdosWaitMilli(100);
}
    
/*##########################################################################
#
#   Name       : InitOsAcpi
#
##########################################################################*/
void InitOsAcpi()
{
    RdosInitKernelSection(&ExecSection);
    RdosCreateKernelThread(5, 0x1000, &AcpiThread, "Acpi Exec", 0);
}
