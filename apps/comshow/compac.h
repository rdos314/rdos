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
# compac.h
# Compac protocol translator
#
########################################################################*/

#ifndef _COMPAC_H
#define _COMPAC_H

#include "anabase.h"

struct TCompacMsg
{
	char Adr;
	char Mode;
	char Lockout;
	char PollType;
	char MsgData[256];
};

class TCompacProtocolAnalyser : public TProtocolAnalyser
{
public:
	TCompacProtocolAnalyser(TFile *RawFile, int MaxSize);
	virtual ~TCompacProtocolAnalyser();
    
    virtual int GetMsg();
    virtual void ShowMsg();

protected:
    char CalcLrc(const char *str, int size);
    void ShowPump(int Pump);
    void ShowPrePay(int PrePay);
    void ShowLockout(char Lockout);
	void ShowPollType(char PollType);
	void ShowNozzle(char Nozzle);
    void ShowStatus(char Status);
    const char *ShowFID(const char *str);
	void ShowMasterMsg(int Pump, int PrePay, char Lockout, char PollType, const char *MsgData);
	void ShowSlaveMsg(int Pump, int PrePay, char Nozzle, char Status,  char Lockout, const char *MsgData);

    TCompacMsg *FCompacReqMsg;
    TCompacMsg *FCompacReplyMsg;
};

#endif
