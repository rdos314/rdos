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
# acpi.cpp
# ACPI command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "cmdhelp.h"
#include "lang.h"
#include "acpi.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TAcpiFactory::TAcpiFactory
#
#   Purpose....: Constructor for TAcpiFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAcpiFactory::TAcpiFactory()
  : TCommandFactory("ACPI")
{
}

/*##########################################################################
#
#   Name       : TAcpiFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TAcpiFactory::Create(TSession *session, const char *param)
{
    return new TAcpiCommand(session, param);
}

/*##########################################################################
#
#   Name       : TAcpiCommand::TAcpiCommand
#
#   Purpose....: Constructor for TAcpiCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAcpiCommand::TAcpiCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_ACPI);
}

/*##########################################################################
#
#   Name       : TAcpiCommand::ShowDevices
#
#   Purpose....: Show devices
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAcpiCommand::ShowDevices()
{
    int ok;
    char AcpiName[128];
    int DevNr;
    int ObjNr;

    for (DevNr = 0; DevNr < 0x1000; DevNr++)
    {
        ok = RdosGetAcpiObject(DevNr, AcpiName);
        if (ok)
        {
            Write(AcpiName);

            for (ObjNr = 0; ObjNr < 0x1000; ObjNr++)
            {
                ok = RdosGetAcpiMethod(DevNr, ObjNr, AcpiName);
                if (ok)
                {
                    if (!ObjNr)
                        Write(" (");
                    else
                        Write(", ");

                    Write(AcpiName);           
                }
                else
                    break;
            }

            if (ObjNr)
                Write(")");            

            Write("\r\n");
        }
        else
            break;
    }
}

/*##########################################################################
#
#   Name       : TAcpiCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAcpiCommand::Execute(char *param)
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
