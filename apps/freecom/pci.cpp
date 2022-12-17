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
#   Name       : TPciCommand::PrintBusDevices
#
#   Purpose....: Print bus devices
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPciCommand::PrintBusDevices(int Bus)
{
    int ok;
    char AcpiName[128];
    char Str[100];
    int Device;
    int Function;
    int VendorID;
    int DeviceID;
    int Class;
    int SubClass;
    int Irq;

    Write("ACPI Name                     ");
    Write("Vendor/dev Class  Dev Func  IRQ\r\n");

    for (Device = 0; Device < 32; Device++)
    {
        for (Function = 0; Function < 8; Function++)
        {
            if (RdosGetPciDeviceVendor(Bus, Device, Function, &VendorID, &DeviceID))
            {
                if (!RdosGetPciDeviceName(Bus, Device, Function, AcpiName))
                    AcpiName[0] = 0;

                while (strlen(AcpiName) < 30)
                    strcat(AcpiName, " ");

                Write(AcpiName);

                RdosGetPciClass(Bus, Device, Function, &Class, &SubClass);
                Irq = RdosGetPciIrq(Bus, Device, Function);

                sprintf(Str, "%04hX %04hX  %02hX%02hX  %4d %4d  ", VendorID, DeviceID, Class, SubClass, Device, Function);
                Write(Str);

                if (Irq)
                    sprintf(Str, "%3d\r\n", Irq);
                else
                    strcpy(Str, "   \r\n");
                Write(Str);
            }
        }
    }
    Write("\r\n");
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
    int i;
    int bus, dev, func;
    char Str[80];

    if (LeadOptions(&param, 0) != E_None)
        return 1;

    for (i = 0; i < 256; i++)
    {
        if (RdosGetPciBus(i, &bus, &dev, &func))
        {
            sprintf(Str, "Bus %d (Bus: %d, Device: %d, Function: %d)\r\n", i, bus, dev, func);
            Write(Str);

            PrintBusDevices(i);
        }
    }

    return 0;
}
