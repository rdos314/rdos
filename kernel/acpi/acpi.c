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

#include "malloc.h"

extern void InitOsAcpi();

ACPI_STATUS Status;

#pragma aux ImplTestGate "*" rdosdev parm routine [es edi]


ACPI_STATUS AddDevice(ACPI_HANDLE Object, UINT32 Nesting, void *Context, void **ReturnVal)
{
    RdosWriteString("Obj\r\n");
    return AE_OK;
}

void __far ImplTestGate(const char *msg)
{
    char str[128];

    sprintf(str, "Status: %d\r\n", Status);
    RdosWriteString(str);

    if (Status == 0)
        AcpiGetDevices(0, AddDevice, 0, 0);
}

#pragma aux InitTasking "*" rdosdev parm routine

void __far InitTasking()
{
    InitOsAcpi();

    if (Status == 0)
        Status = AcpiLoadTables();

    if (Status == 0)
        Status = AcpiEnableSubsystem(ACPI_FULL_INITIALIZATION);

    if (Status == 0)
        Status = AcpiInitializeObjects(ACPI_FULL_INITIALIZATION);

    RdosRegisterUserGate(usergate_test_gate, &ImplTestGate, "Test Gate");
} 

int main()
{
    Status = AcpiInitializeSubsystem();
    if (Status == 0)   
        Status = AcpiInitializeTables(0, 0, 0);

    RdosHookInitTasking(&InitTasking);
}

