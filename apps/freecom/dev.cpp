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
# dev.cpp
# Device command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "cmdhelp.h"
#include "lang.h"
#include "dev.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TDeviceFactory::TDeviceFactory
#
#   Purpose....: Constructor for TDeviceFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDeviceFactory::TDeviceFactory()
  : TCommandFactory("DEV")
{
}

/*##########################################################################
#
#   Name       : TDeviceFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TDeviceFactory::Create(TSession *session, const char *param)
{
    return new TDeviceCommand(session, param);
}

/*##########################################################################
#
#   Name       : TDeviceCommand::TDeviceCommand
#
#   Purpose....: Constructor for TDeviceCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDeviceCommand::TDeviceCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_DEV);
}

/*##########################################################################
#
#   Name       : TDeviceCommand::ShowDevices
#
#   Purpose....: Show devices
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDeviceCommand::ShowDevices()
{
    int ok;
    char AcpiName[128];
    char Str[100];
    int DevNr;
    int Index;
    int Irq;
    int Share;
    int Polarity;
    int TriggerMode;
    int Start;
    int Stop;
    int AccessSize;

    for (DevNr = 0; DevNr < 0x1000; DevNr++)
    {
        ok = RdosGetAcpiDevice(DevNr, AcpiName);
        if (ok)
        {
            Write(AcpiName);

            for (Index = 0; Index < 100; Index++)
            {
                AccessSize = RdosGetAcpiDeviceIo(DevNr, Index, &Start, &Stop);
                if (AccessSize)
                {
                    sprintf(Str, "\r\n    IO: %04hX-%04hX", Start, Stop + AccessSize - 1);
                    Write(Str);
                }
                else
                    break;
            }

            for (Index = 0; Index < 100; Index++)
            {
                AccessSize = RdosGetAcpiDeviceMem(DevNr, Index, &Start, &Stop);
                if (AccessSize)
                {
                    sprintf(Str, "\r\n    Mem: %08lX-%08lX", Start, Stop + AccessSize - 1);
                    Write(Str);
                }
                else
                    break;
            }

            for (Index = 0; Index < 10; Index++)
            {
                Irq = RdosGetAcpiDeviceIrq(DevNr, Index, &Share, &Polarity, &TriggerMode);
                if (Irq >= 0)
                {
                    sprintf(Str, "\r\n    IRQ: %d, ", Irq);
                    Write(Str);

                    if (Share)
                        Write(" sharable, ");
                    else
                        Write(" exclusive, ");

                    if (TriggerMode)
                        Write(" edge ");
                    else
                    {
                        if (Polarity > 0)
                            Write(" high level ");
                        else
                            Write(" low level ");
                    }
                }
                else
                    break;
            }
            Write("\r\n\r\n");
        }
        else
            break;
    }
}

/*##########################################################################
#
#   Name       : TDeviceCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDeviceCommand::Execute(char *param)
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
