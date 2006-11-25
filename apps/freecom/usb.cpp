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
	int minor = dev->usb_ver & 0xFF;
	int major = (dev->usb_ver >> 8) & 0xFF;

	sprintf(str, "\n\nController: %d, Device: %d\n", control, device);
	Write(str);

	sprintf(str, "\nVersion: %02hX.%02hX", major, minor);
	Write(str);

	switch (dev->class_id)
	{
		case 0:
			break;

		case -1:
			Write("\nVendor specific class");
			break;

		default:
			sprintf(str, "\nClass: %02hX", dev->class_id);
			break;
	}
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
    int size;
    TUsbDevice UsbDevice;
	TUsbConfig *UsbConfig;

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
                    }
                }
            }        
        }
    } 

    delete buf;

	return 0;
}
