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
# com.cpp
# Com info command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "com.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TComFactory::TComFactory
#
#   Purpose....: Constructor for TComFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TComFactory::TComFactory()
  : TCommandFactory("COM")
{
}

/*##########################################################################
#
#   Name       : TComFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TComFactory::Create(TSession *session, const char *param)
{
    return new TComCommand(session, param);
}

/*##########################################################################
#
#   Name       : TComCommand::TComCommand
#
#   Purpose....: Constructor for TComCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TComCommand::TComCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_COM);
}

/*##########################################################################
#
#   Name       : TComCommand::~TComCommand
#
#   Purpose....: Destructor for TComCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TComCommand::~TComCommand()
{
}

/*##########################################################################
#
#   Name       : TComCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TComCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
    OptError(optstr);
    return E_Useage;
}

/*##########################################################################
#
#   Name       : TComCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TComCommand::InitOptions()
{
}

/*##########################################################################
#
#   Name       : TComCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TComCommand::Execute(char *param)
{
    const int KNOWN_COUNT = 3;
    char txt[256];
    int moduleNr;

    int numPorts = RdosGetMaxComPort();

    for (int i = 0; i < numPorts; i++)
    {
        int portNr;
        int irq;
        int base;
        int baud;
        int typ;
        int vendor;
        int product;

        if (RdosCheckCanSerialPort(i, &moduleNr, &portNr))
            sprintf(txt, "Com%d: Module: %d, Port: %d\r\n", i + 1, moduleNr, portNr);
        else
        {
            if (RdosGetStdComPar(i, &irq, &base, &baud))
                sprintf(txt, "Com%d: IRQ: %d, Base: %04hX, Maxbaud: %d\r\n", i + 1, irq, base, baud);
            else
            {
                if (RdosGetUsbComPar(i, &typ))
                {
                    switch (typ)
                    {
                        case 0x101:
                            sprintf(txt, "Com%d: USB FTDI SIO serialport\r\n", i + 1);
                            break;

                        case 0x102:
                            sprintf(txt, "Com%d: USB FTDI FT232AM serialport\r\n", i + 1);
                            break;

                        case 0x103:
                            sprintf(txt, "Com%d: USB FTDI FT232BM serialport\r\n", i + 1);
                            break;

                        case 0x104:
                            sprintf(txt, "Com%d: USB FTDI FT2232C serialport\r\n", i + 1);
                            break;

                        case 0x201:
                            sprintf(txt, "Com%d: USB PL 01 serialport\r\n", i + 1);
                            break;

                        case 0x202:
                            sprintf(txt, "Com%d: USB PL HX serialport\r\n", i + 1);
                            break;

                        case 0x301:
                            sprintf(txt, "Com%d: USB MCT Sitecom serialport\r\n", i + 1);
                            break;

                        case 0x302:
                            sprintf(txt, "Com%d: USB MCT Belkin serialport\r\n", i + 1);
                            break;

                        default:
                            sprintf(txt, "Com%d: USB serialport, Type: %04hX\r\n", i + 1, typ);
                            break;
                    }
                }
                else
                {
                    if (RdosGetUsbCdcComPar(i, &vendor, &product))
                        sprintf(txt, "Com%d: USB CDC, Vendor: %04hX, Product: %04hX\r\n", i + 1, vendor, product);
                    else
                    {
                        if (RdosGetUsbBusPar(i))
                            sprintf(txt, "Com%d: USB serial bus\r\n", i + 1);
                        else
                            sprintf(txt, "Com%d: Unknown type\r\n", i + 1);
                    }
                 }
            }
        }
        Write(txt);
    }

    return 0;
}
