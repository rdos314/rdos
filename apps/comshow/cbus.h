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
# cbus.h
# CBUS protocol translator
#
########################################################################*/

#ifndef _CBUS_H
#define _CBUS_H

#include "anabase.h"

struct TCbusMsg
{
	char Adr;
	char MessCode;
	char MsgData[128];
};

class TCbusProtocolAnalyser : public TProtocolAnalyser
{
public:
	TCbusProtocolAnalyser(TFile *RawFile, int MaxSize);
	virtual ~TCbusProtocolAnalyser();
    
    virtual int GetMsg();
    virtual void ShowMsg();

protected:
    void ShowDefault(TCbusMsg *Msg);
    void ShowCbusPumpReqText();
    void ShowCbusPumpReplyText();
    void ShowAddress(char Adr);
    void ShowCode(char Code);
    void UpdatePump();
    void ShowPumpMsg(char ToAdr, char FromAdr, char MessCode, const char *MsgData);

    TCbusMsg *FCbusReqMsg;
    TCbusMsg *FCbusReplyMsg;
};

#endif
