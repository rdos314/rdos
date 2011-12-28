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
# pci.cpp
# PCI command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "cmdhelp.h"
#include "lang.h"
#include "pci.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TPciFactory::TPciFactory
#
#   Purpose....: Constructor for TPciFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPciFactory::TPciFactory()
  : TCommandFactory("PCI")
{
}

/*##########################################################################
#
#   Name       : TPciFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TPciFactory::Create(TSession *session, const char *param)
{
    return new TPciCommand(session, param);
}

/*##########################################################################
#
#   Name       : TPciCommand::TPciCommand
#
#   Purpose....: Constructor for TPciCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPciCommand::TPciCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_PCI);
}

/*##########################################################################
#
#   Name       : TPciCommand::ShowDevices
#
#   Purpose....: Show devices
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPciCommand::ShowDevices()
{
    int ok;
    char AcpiName[128];
    char Str[100];
    int DevNr;
    int Bus;
    int Device;
    int Function;
    int VendorID;
    int DeviceID;
    int Class;
    int SubClass;
    int Irq;

    Write("ACPI Name                     ");
    Write("Vendor/dev Class Bus Dev Func IRQ\r\n");
    
    for (DevNr = 0; DevNr < 0x1000; DevNr++)
    {
        ok = RdosGetPciDeviceName(DevNr, AcpiName);
        if (ok)
        {
            while (strlen(AcpiName) < 30)
                strcat(AcpiName, " ");
            Write(AcpiName);
        
            RdosGetPciDeviceInfo(DevNr, &Bus, &Device, &Function);
            RdosGetPciDeviceVendor(DevNr, &VendorID, &DeviceID);
            RdosGetPciDeviceClass(DevNr, &Class, &SubClass);            
            Irq = RdosGetPciDeviceIrq(DevNr);
            
            sprintf(Str, "%04hX %04hX  %02d%02d   %03d %03d %03d  %03d\r\n", VendorID, DeviceID, Class, SubClass, Bus, Device, Function, Irq);
            Write(Str);
        }
        else
            break;
    }
}

/*##########################################################################
#
#   Name       : TPciCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TPciCommand::Execute(char *param)
{
    long AcpiStatus;
    int error;
    char SubSystem[80];
    char Str[100];

    if (LeadOptions(&param, 0) != E_None)
        return 1;

    AcpiStatus = RdosGetAcpiStatus();

    if (AcpiStatus == 0)
        ShowDevices();
    else
    {
        if (AcpiStatus == -1)
            Write("No ACPI device-driver loaded");
        else
        {
            error = AcpiStatus & 0xFFFF;
            switch (AcpiStatus & 0xFFFF0000)
            {
                case 0:
                    strcpy(SubSystem, "InitializeSubsystem");
                    break;

                case 0x10000:
                    strcpy(SubSystem, "InitializeTables");
                    break;

                case 0x20000:
                    strcpy(SubSystem, "LoadTables");
                    break;

                case 0x30000:
                    strcpy(SubSystem, "EnableSubsystem");
                    break;

                case 0x40000:
                    strcpy(SubSystem, "InitializeObjects");
                    break;
            }
            sprintf(Str, "Error %d during %s", error, SubSystem);
            Write(Str);                                 
        }
    }
    return 0;
}
