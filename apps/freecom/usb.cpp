/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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

#include "ctlpipe.h"

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
void TUsbCommand::ShowDevice(int control, int device, TUsbDevice *dev)
{
	char str[100];
	int minor;
	int major;

	sprintf(str, "\r\n\r\nController: %d, Device: %d\r\n", control, device);
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
void TUsbCommand::ShowInterface(TUsbInterface *descr)
{
	char str[100];

	sprintf(str, "\r\n    Interface: %d\r\n", descr->interface_id);
	Write(str);

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
void TUsbCommand::ShowDescr(TUsbDescr *descr)
{
	char str[100];

	switch (descr->type)
	{
		case 4:
			ShowInterface((TUsbInterface *)descr);
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
    int contr;
    int device;
    int config;
	char *buf;
	char *ptr;
    int pos;
    int size;
    TUsbDevice UsbDevice;
	TUsbConfig *UsbConfig;
	TUsbDescr *descr;

	if (LeadOptions(&param, 0) != E_None)
		return 1;

	buf = new char[4096];
    
    for (contr = 0; contr < 256; contr++)
    {
        for (device = 1; device < 128; device++)
        {
            size = RdosGetUsbDevice(contr, device, &UsbDevice, sizeof(TUsbDevice));
            if (size >= sizeof(TUsbDevice))
            {
                ShowDevice(contr, device, &UsbDevice);

                for (config = 0; config < UsbDevice.configs; config++)
                {
					size = RdosGetUsbConfig(contr, device, config, buf, 4096);
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
							ShowDescr(descr);
							ptr += descr->len;
							pos += descr->len;
						}
					}
				}

				Write("Start read\r\n");

				char buf[256];
				int ok;
				int size;
				TUsbControlPipe *pipe = new TUsbControlPipe(contr, device, 0);
				TUsbControlMsg msg;
				msg.type = 0x80;
				msg.req = 6;
				msg.val = 0x200;
				msg.index = 0;
				ok = pipe->Read(&msg, buf, 8, 2000);
				if (ok)
				{
					Write("First ok\r\n");
					size = 0;
					memcpy(&size, &buf[2], 2);
					ok = pipe->Read(&msg, buf, size, 2000);
					if (ok)
						Write("Second ok\r\n");
				}

				delete pipe;
			}
		}
	}

	delete buf;

	return 0;
}
