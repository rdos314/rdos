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
# ctlpipe.h
# USB control pipe class
#
########################################################################*/

#ifndef _CTLPIPE_H
#define _CTLPIPE_H

#include "usbpipe.h"

struct TUsbControlMsg
{
    char type;
    char req;
    short int val;
    short int index;
    short int len;
};

class TUsbControlPipe : public TUsbPipe
{
public:
    TUsbControlPipe(int Handle);
    TUsbControlPipe(int Controller, int Device, int Pipe);
    ~TUsbControlPipe();

    int Send(TUsbControlMsg *msg, int ms);
    int Write(TUsbControlMsg *msg, const char *buf, int size, int ms);
    int Read(TUsbControlMsg *msg, char *buf, int size, int ms);
};

#endif

