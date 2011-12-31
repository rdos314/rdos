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
# usb.h
# USB command class
#
########################################################################*/

#ifndef _USB_H
#define _USB_H

#include "cmd.h"
#include "cmdfact.h"
#include "usbpipe.h"

class TUsbFactory : public TCommandFactory
{
public:
        TUsbFactory();
        virtual TCommand *Create(TSession *session, const char *param);

protected:
};

class TUsbCommand : public TCommand
{
public:
        TUsbCommand(TSession *session, const char *param);

        virtual int Execute(char *param);

protected:
        void ShowClass(char class_id, char sub_class, char protocol, int indent);
        void ShowDevice(int control, int device, TUsbDevice *dev);
        void ShowConfig(int config, TUsbConfig *dev);
        void ShowInterface(TUsbInterface *descr);
        void ShowEndpoint(TUsbEndpoint *descr);
        void ShowDescr(TUsbDescr *descr);

};

#endif
