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
# hid.cpp
# HID command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "cmdhelp.h"
#include "lang.h"
#include "hid.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : THidFactory::THidFactory
#
#   Purpose....: Constructor for THidFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THidFactory::THidFactory()
  : TCommandFactory("HID")
{
}

/*##########################################################################
#
#   Name       : THidFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *THidFactory::Create(TSession *session, const char *param)
{
    return new THidCommand(session, param);
}

/*##########################################################################
#
#   Name       : THidCommand::THidCommand
#
#   Purpose....: Constructor for THidCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THidCommand::THidCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_HID);
}

/*##########################################################################
#
#   Name       : THidCommand::ShowDevices
#
#   Purpose....: Show devices
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THidCommand::ShowDevices()
{
    int ok;
    char ItemName[256];
    int DevNr;
    int Controller;
    int Port;
    int ReportNr;
    int ObjNr;

    for (DevNr = 0; DevNr < 0x40; DevNr++)
    {
        ok = RdosGetHidDevice(DevNr, &Controller, &Port);
        if (ok)
        {
            sprintf(ItemName, "HID Device: %02hX.%02hX\r\n", Controller, Port);
            Write(ItemName);

            for (ObjNr = 0; ObjNr < 0x1000; ObjNr++)
            {
                ok = RdosGetHidReportItem(DevNr, ObjNr, ItemName);
                if (ok)
                {
                    Write(ItemName);
                    Write("\r\n");
                }
                else
                    break;
            }

            Write("\r\n");

            for (ReportNr = 0; ReportNr < 16; ReportNr++)
            {
                ok = RdosGetHidReportInputData(DevNr, ReportNr, 0, ItemName);
                if (!ok)
                    ok = RdosGetHidReportOutputData(DevNr, ReportNr, 0, ItemName);
                if (!ok)
                    ok = RdosGetHidReportFeatureData(DevNr, ReportNr, 0, ItemName);

                if (ok)
                {
                    sprintf(ItemName, "Report ID: %d\r\n", ReportNr);
                    Write(ItemName);

                    ok = RdosGetHidReportInputData(DevNr, ReportNr, 0, ItemName);
                    if (ok)
                    {
                        Write("Input: \r\n");

                        for (ObjNr = 0; ObjNr < 256; ObjNr++)
                        {
                            ok = RdosGetHidReportInputData(DevNr, ReportNr, ObjNr, ItemName);
                            if (ok)
                            {
                                Write(ItemName);
                                Write("\r\n");
                            }
                            else
                                break;
                        }
                    }

                    ok = RdosGetHidReportOutputData(DevNr, ReportNr, 0, ItemName);
                    if (ok)
                    {
                        Write("Output: \r\n");

                        for (ObjNr = 0; ObjNr < 256; ObjNr++)
                        {
                            ok = RdosGetHidReportOutputData(DevNr, ReportNr, ObjNr, ItemName);
                            if (ok)
                            {
                                Write(ItemName);
                                Write("\r\n");
                            }
                            else
                                break;
                        }
                    }

                    ok = RdosGetHidReportFeatureData(DevNr, ReportNr, 0, ItemName);
                    if (ok)
                    {
                        Write("Output: \r\n");

                        for (ObjNr = 0; ObjNr < 256; ObjNr++)
                        {
                            ok = RdosGetHidReportFeatureData(DevNr, ReportNr, ObjNr, ItemName);
                            if (ok)
                            {
                                Write(ItemName);
                                Write("\r\n");
                            }
                            else
                                break;
                        }
                    }
                }
            }
            Write("\r\n");
        }

    }
}

/*##########################################################################
#
#   Name       : THidCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THidCommand::Execute(char *param)
{
    if (LeadOptions(&param, 0) != E_None)
        return 1;

    ShowDevices();
    return 0;
}
