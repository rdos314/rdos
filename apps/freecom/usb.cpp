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
# usb.cpp
# USB command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "cmdhelp.h"
#include "lang.h"
#include "usb.h"
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TUsbFactory::TUsbFactory
#
#   Purpose....: Constructor for TUsbFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUsbFactory::TUsbFactory()
  : TCommandFactory("USB")
{
}

/*##########################################################################
#
#   Name       : TUsbFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TUsbFactory::Create(TSession *session, const char *param)
{
        return new TUsbCommand(session, param);
}

/*##########################################################################
#
#   Name       : TUsbCommand::TUsbCommand
#
#   Purpose....: Constructor for TUsbCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TUsbCommand::TUsbCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
        FHelpScreen.Load(TEXT_CMDHELP_USB);
}

/*##########################################################################
#
#   Name       : TUsbCommand::ShowClass
#
#   Purpose....: Show class information
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbCommand::ShowClass(char class_id, char sub_class, char protocol, int indent)
{
        char str[80];

        if (indent)
        Write("    ");

        switch (class_id)
        {
                case 0:
                        break;

                case -1:
            Write("Vendor specific class\r\n");
                        break;

                default:
                        sprintf(str, "Class: %02hX\r\n", class_id);
                        Write(str);
                        break;
        }

    if (indent)
        Write("    ");

        switch (sub_class)
        {
                case 0:
                        break;

                case -1:
                        Write("Vendor specific subclass\r\n");
                        break;

                default:
                        sprintf(str, "Subclass: %02hX\r\n", sub_class);
                        Write(str);
                        break;
        }

    if (indent)
        Write("    ");

        switch (protocol)
        {
                case 0:
                        break;

                case -1:
                        Write("Vendor specific protocol\r\n");
                        break;

                default:
                        sprintf(str, "Protocol: %02hX\r\n", protocol);
                        Write(str);
                        break;
        }
}

/*##########################################################################
#
#   Name       : TUsbCommand::ShowDevice
#
#   Purpose....: Show device descriptor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbCommand::ShowDevice(int control, int port, TUsbDevice *dev)
{
    char str[100];
    int minor;
    int major;

        sprintf(str, "\r\n\r\nController: %d, Port: %d\r\n", control, port);
        Write(str);

    minor = dev->usb_ver & 0xFF;
    major = (dev->usb_ver >> 8) & 0xFF;
    sprintf(str, "USB version: %d.%02hX\r\n", major, minor);
    Write(str);

    ShowClass(dev->class_id, dev->sub_class, dev->proto, 0);

    sprintf(str, "Vendor: %04hX\r\n", dev->vendor);
    Write(str);

    minor = dev->device & 0xFF;
    major = (dev->device >> 8) & 0xFF;
    sprintf(str, "Product: %04hX %d.%02hX\r\n", dev->prod, major, minor);
    Write(str);

    sprintf(str, "Packet size: %d\r\n", dev->maxlen);
    Write(str);
}

/*##########################################################################
#
#   Name       : TUsbCommand::ShowConfig
#
#   Purpose....: Show config descriptor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbCommand::ShowConfig(int config, TUsbConfig *dev)
{
    char str[100];
    int power;

    sprintf(str, "\r\n  Configuration: %d\r\n", dev->config_id);
    Write(str);

    if (dev->interface_count > 1)
    {
        sprintf(str, "  %d interfaces\r\n", dev->interface_count);
        Write(str);
    }

    if (dev->attrib & 0x40)
        Write("  Self-powered");
    else
        Write("  Bus-powered");

    power = (unsigned char)dev->power;
    power = 2 * (power + 1);

    sprintf(str, ", %d mA\r\n", power);
    Write(str);

}

/*##########################################################################
#
#   Name       : TUsbCommand::ShowInterface
#
#   Purpose....: Show interface
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbCommand::ShowInterface(int control, int device, TUsbInterface *descr)
{
    char str[100];
//    int InterfaceId = RdosGetUsbInterface(control, device, descr->interface_id);

    sprintf(str, "\r\n    Interface #: %d\r\n", descr->interface_id);
    Write(str);

    sprintf(str, "    Alt setting: %d\r\n", descr->alt_setting);
    Write(str);

//    sprintf(str, "    Active setting: %d\r\n", InterfaceId);
//    Write(str);

    ShowClass(descr->class_id, descr->sub_class, descr->proto, 4);

}

/*##########################################################################
#
#   Name       : TUsbCommand::ShowEndpoint
#
#   Purpose....: Show endpoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbCommand::ShowEndpoint(TUsbEndpoint *descr)
{
    char str[100];
    int type;
    int size;

    sprintf(str, "\r\n    Endpoint: %d\r\n", descr->address & 0xF);
    Write(str);

    Write("    ");

    type = descr->attrib & 3;

    switch (type)
    {
        case 0:
            Write("Control");
            break;

        case 1:
            if (descr->address & 0x80)
                Write("Isochronous IN");
            else
                Write("Isochronous OUT");
            break;

        case 2:
            if (descr->address & 0x80)
                Write("Bulk IN");
            else
                Write("Bulk OUT");
            break;

        case 3:
            if (descr->address & 0x80)
                Write("Interrupt IN");
            else
                Write("Interrupt OUT");
            break;
    }

    Write("\r\n");

    size = (unsigned char)descr->maxsize;

    sprintf(str, "    Packet size %d\r\n", size);
    Write(str);

    sprintf(str, "    Interval %d\r\n", descr->interval);
    Write(str);
}

/*##########################################################################
#
#   Name       : TUsbCommand::ShowDescr
#
#   Purpose....: Show descriptor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbCommand::ShowDescr(int control, int device, TUsbDescr *descr)
{
    char str[100];

    switch (descr->type)
    {
        case 4:
            ShowInterface(control, device, (TUsbInterface *)descr);
            break;

        case 5:
            ShowEndpoint((TUsbEndpoint *)descr);
            break;

        default:
            sprintf(str, "\r\n    Unknown descriptor: %02hX\r\n", descr->type);
            Write(str);
            break;
    }
}

/*##########################################################################
#
#   Name       : TUsbCommand::Show
#
#   Purpose....: Show status
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbCommand::Show()
{
    int contr;
    int port;
    int config;
    int handle;
    char *buf;
    short int *sptr;
    char *ptr;
    int pos;
    int size;
    TUsbDevice UsbDevice;
    TUsbConfig *UsbConfig;
    TUsbDescr *descr;

    buf = new char[4096];

    for (contr = 0; contr < 256; contr++)
    {
        for (port = 0; port < 32; port++)
        {
            handle = RdosOpenUsbDevice(contr, port);
            if (handle)
            {
                size = RdosSendUsbDeviceControlMsg(handle, 0x80, 6, 0x100, 0, (char *)&UsbDevice, sizeof(TUsbDevice));
                if (size >= sizeof(TUsbDevice))
                {
                    ShowDevice(contr, port, &UsbDevice);

                    for (config = 0; config < UsbDevice.configs; config++)
                    {
                        size = RdosSendUsbDeviceControlMsg(handle, 0x80, 6, 0x200 + config, 0, buf, 8);
                        if (size == 8)
                        {
                            sptr = (short int *)(buf + 2);
                            size = *sptr;
                            size = RdosSendUsbDeviceControlMsg(handle, 0x80, 6, 0x200 + config, 0, buf, size);
                        }

                        if (size >= sizeof(TUsbConfig))
                        {
                            UsbConfig = (TUsbConfig *)buf;
                            ShowConfig(config, UsbConfig);

                            pos = 0;
                            ptr = buf;
                            descr = (TUsbDescr *)ptr;
                            ptr += descr->len;
                            pos += descr->len;

                            while (pos < size)
                            {
                                descr = (TUsbDescr *)ptr;
                                ShowDescr(contr, port, descr);
                                ptr += descr->len;
                                pos += descr->len;
                             }
                        }
                    }
                }
                RdosCloseUsbDevice(handle);

                RdosWaitMilli(250);

            }
        }
    }

    delete buf;
}

/*##########################################################################
#
#   Name       : TUsbCommand::Reset
#
#   Purpose....: Reset all ports
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TUsbCommand::Reset()
{
}

/*##########################################################################
#
#   Name       : TUsbCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TUsbCommand::Execute(char *param)
{
    TArg *arg;

    if (!ScanCmdLine(param, 0))
        return 1;

    arg = FArgList;

    if (LeadOptions(&param, 0) != E_None)
        return 1;

    if (arg)
    {
        strupr((char *)arg->FName.GetData());
        if (!strcmp(arg->FName.GetData(), "RESET"))
            Reset();
        else
            return 1;
    }
    else
        Show();

    return 0;
}
