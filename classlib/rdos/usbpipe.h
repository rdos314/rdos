/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# usbpipe.h
# Usbpipe class
#
########################################################################*/

#ifndef _USBPIPE_H
#define _USBPIPE_H

#include "waitdev.h"

struct TUsbDescr
{
    unsigned char len;
    char type;
};

struct TUsbDevice
{
    char len;
    char type;
    short int usb_ver;
    char class_id;
    char sub_class;
    char proto;
    char maxlen;
    short int vendor;
    short int prod;
    short int device;
    char man;
    char prodid;
	char num;
    char configs;
};
    
struct TUsbConfig
{
    char len;
    char type;
    short int size;
    char interface_count;
    char config_id;
    char config_str_id;
    char attrib;
    char power;
};

struct TUsbInterface
{
	char len;
	char type;
	char interface_id;
	char alt_setting;
	char endpoint_count;
	char class_id;
	char sub_class;
	char proto;
	char str_id;
};

struct TUsbEndpoint
{
	char len;
	char type;
	char address;
	char attrib;
	short int maxsize;
	char interval;
};

class TUsbPipe : public TWaitDevice
{
public:
    TUsbPipe(int Handle);
    TUsbPipe(int Controller, int Device, int Pipe);
    ~TUsbPipe();

	virtual void DeviceName(char *Name, int MaxLen) const;

protected:
	virtual void SignalNewData();
	virtual void Add(TWait *Wait);

    void Lock();
    void Unlock();
    
    void WriteControl(const char *buf, int size);
	void ReqData(char *buf, int size);
	void WriteData(const char *buf, int size);
	int GetDataSize();
	void ReqStatus();
	void WriteStatus();
	int IsTransDone();
	int WasTransOk();

	int FHandle;
};

#endif

