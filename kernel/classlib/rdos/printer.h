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
# printer.h
# Printer device class
#
########################################################################*/

#ifndef _PRINTER_H
#define _PRINTER_H

#include "waitdev.h"
#include "bitdev.h"

class TPrinterDevice : public TWaitDevice
{
public:
    TPrinterDevice(const char *IniSection, int Port);
    TPrinterDevice(int Port);
    ~TPrinterDevice();

    virtual void DeviceName(char *Name, int MaxLen) const;

    virtual int IsOnline() const;

    virtual int IsJammed();
    virtual int IsPaperLow();
    virtual int IsPaperEnd();
    virtual int IsPrintHeadLifted();
    virtual int HasPaperInPresenter();

    virtual void PrintTest();

    TBitmapGraphicDevice *CreateBitmap(int Height);
    void PrintBitmap(TBitmapGraphicDevice *bitmap);

protected:
    TPrinterDevice(const char *IniSection);
    TPrinterDevice();

	virtual void SignalNewData();
	virtual void Add(TWait *Wait);

private:
    void Init(int Port);

    int FHandle;
    int FPort;

};

#endif

