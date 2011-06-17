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

struct TExecReq *ExecList = 0;

/*##########################################################################
#
#   Name       : AcpiOsInitialize
#
##########################################################################*/
ACPI_STATUS AcpiOsInitialize()
{
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
    return AE_OK;
}

/*##########################################################################
#
#   Name       : AcpiOsTableOverride
#
##########################################################################*/
ACPI_STATUS AcpiOsTableOverride(ACPI_TABLE_HEADER *Table, ACPI_TABLE_HEADER **NewTable)
{
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

    linear = RdosAllocateBigGlobalLinear(Length);
    if (linear)
    {
        RdosSetPhysicalPage(linear, PhysicalAddress);
        return RdosLinearToPointer(linear);
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

    linear = RdosPointerToOffset(LogicalAddress);
    RdosFreeLinear(linear, Length);
}

/*##########################################################################
#
#   Name       : AcpiOsGetPhysicalAddress
#
##########################################################################*/
ACPI_STATUS AcpiOsGetPhysicalAddress(void *LogicalAddress, ACPI_PHYSICAL_ADDRESS *PhysicalAddress)
{
    long linear;

    linear = RdosPointerToOffset(LogicalAddress);
    *PhysicalAddress = RdosGetPhysicalPage(linear);

    return AE_OK;
}

/*##########################################################################
#
#   Name       : AcpiOsAllocate
#
##########################################################################*/
void *AcpiOsAllocate(ACPI_SIZE Size)
{
    return RdosAllocateSmallGlobalMem(Size);
}

/*##########################################################################
#
#   Name       : AcpiOsFree
#
##########################################################################*/
void AcpiOsFree(void *Memory)
{
    int sel = RdosPointerToSelector(Memory);    
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

    return AE_OK;
}
