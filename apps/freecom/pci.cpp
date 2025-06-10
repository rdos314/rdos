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
    int Handle;
    char AcpiName[128];
    char Str[100];
    int Device;
    int Function;
    int VendorID;
    int DeviceID;
    int Interface;
    int Class;
    int SubClass;
    int i;
    int Irq;
    int Msi = 0;
    int MsiX = 0;
    bool Used;

    Write("ACPI Name                     ");
    Write("Vendor/dev Class    Dev Func  Interrupt\r\n");

    for (Device = 0; Device < 32; Device++)
    {
        for (Function = 0; Function < 8; Function++)
        {
            Handle = RdosGetPciHandle(0, Bus, Device, Function);
            if (Handle)
            {
                if (!RdosGetPciDeviceName(Handle, AcpiName, 127))
                    AcpiName[0] = 0;

                while (strlen(AcpiName) < 30)
                    strcat(AcpiName, " ");

                Write(AcpiName);

                Class = RdosReadPciConfigByte(Handle, 11);
                SubClass = RdosReadPciConfigByte(Handle, 10);
                Interface = RdosReadPciConfigByte(Handle, 9);
                VendorID = RdosReadPciConfigWord(Handle, 0);
                DeviceID = RdosReadPciConfigWord(Handle, 2);

                Used = RdosIsPciHandleLocked(Handle);
                Msi = RdosGetPciHandleMsi(Handle);
                MsiX = RdosGetPciHandleMsiX(Handle);

                sprintf(Str, "%04hX %04hX  %02hX%02hX%02hX  %4d %4d  ", VendorID, DeviceID, Class, SubClass, Interface, Device, Function);
                Write(Str);

                Str[0] = 0;

                if (Used)
                {
                    if (Msi)
                    {
                        Irq = RdosGetPciHandleIrq(Handle, 0);
                        if (Msi == 1)
                        {
                            sprintf(Str, "MSI    %02hX", Irq);
                            Write(Str);
                        }
                        else
                        {
                            sprintf(Str, "MSI    %02hX-%02hX", Irq, Irq + Msi - 1);
                            Write(Str);
                        }
                    }
                    else
                    {
                        if (MsiX)
                        {
                            if (MsiX == 1)
                            {
                                Irq = RdosGetPciHandleIrq(Handle, 0);
                                sprintf(Str, "MSI-X  %02hX", Irq);
                                Write(Str);
                            }
                            else
                            {
                                sprintf(Str, "MSI-X  ");
                                Write(Str);

                                for (i = 0; i < MsiX; i++)
                                {
                                    Irq = RdosGetPciHandleIrq(Handle, i);
                                    if (i == MsiX - 1)
                                        sprintf(Str, "%02hX", Irq);
                                    else
                                        sprintf(Str, "%02hX, ", Irq);
                                    Write(Str);
                                }
                            }
                        }
                        else
                        {
                            Irq = RdosGetPciHandleIrq(Handle, 0);
                            if (Irq)
                            {
                                sprintf(Str, "IRQ    %02hX", Irq);
                                Write(Str);
                            }
                        }
                    }
                }
                else
                {
                    if (Msi)
                    {
                        sprintf(Str, "MSI");
                        if (MsiX)
                            strcat(Str, "/MSI-X");
                    }
                    else
                    {
                        if (MsiX)
                            sprintf(Str, "MSI-X");
                        else
                        {
                            Irq = RdosGetPciHandleIrq(Handle, 0);
                            if (Irq)
                                sprintf(Str, "IRQ    %02hX", Irq);
                        }
                    }
                    Write(Str);
                }

                Write("\r\n");
            }
        }
    }
    Write("\r\n");
}

/*##########################################################################
#
#   Name       : TPciCommand::PrintBus
#
#   Purpose....: Print bus
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TPciCommand::PrintBus(int index)
{
    unsigned char bus, dev, func;
    char Str[80];

    if (RdosGetPciBus(0, index, &bus, &dev, &func))
    {
        if (!bus && !dev && !func)
        {
            sprintf(Str, "Bus %d \r\n", index);
            Write(Str);
        }
        else
        {
            sprintf(Str, "Bus %d (Bus: %d, Device: %d, Function: %d)\r\n", index, bus, dev, func);
            Write(Str);
        }

        PrintBusDevices(index);
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
    int i;
    int bus;

    if (LeadOptions(&param, 0) != E_None)
        return 1;

    if (sscanf(param, "%d", &bus) == 1)
        PrintBus(bus);
    else
    {
        for (i = 0; i < 256; i++)
            PrintBus(i);
    }

    return 0;
}
