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
# ymodem.h
# Ymodem class
#
########################################################################*/

#ifndef _YMODEM_H
#define _YMODEM_H

#include "serial.h"
#include "file.h"

class TYModem
{
public:
    TYModem(TSerialDevice *Serial);

    int SendFile(const char *FileName);
    int SendFile(TFile *File);

    int RecFile(const char *FileName);
    int RecFile(TFile *File);

	void (*OnHeader)(TYModem *ymodem, char Header);

protected:
	void NotifyHeader(char header);
    int SendStartup();
	int SendPacket(char *Buffer, int Size);
    int RecType();
	int RecStartup();
    int RecPacket(char *Buffer, int *Size);

    TSerialDevice *FSerial;
    int FPacketNr;
    char FNCG;    
	char FPacketType;
    int FCrcTable[256];
};

#endif

