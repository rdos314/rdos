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
# zap.h
# ZAP protocol translator
#
########################################################################*/

#ifndef _ZAP_H
#define _ZAP_H

#include "anabase.h"

struct TZapMsg
{
	char Adr;
	char Type;
	char MsgData[256];
};

class TZapProtocolAnalyser : public TProtocolAnalyser
{
public:
	TZapProtocolAnalyser(TFile *RawFile);
	virtual ~TZapProtocolAnalyser();
    
    virtual int GetMsg();
    virtual void ShowMsg();

protected:
    void ShowState(const char *str);
    void ShowType(char typ);
    void ShowAddress(char Adr);
    void ShowReqMsg();
    void ShowReplyMsg();
    void UpdatePump();

    TZapMsg *FZapReqMsg;
    TZapMsg *FZapReplyMsg;
};

#endif
