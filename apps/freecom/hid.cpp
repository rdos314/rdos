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
