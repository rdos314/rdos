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
# netana.h
# Network protocol translator
#
########################################################################*/

#ifndef _NETANA_H
#define _NETANA_H

#include "anabase.h"

struct TLogHeader
{
	short int Size;
	char Type;
	long LsbTime;
	long MsbTime;
};

class TNetProtocolAnalyser : public TProtocolAnalyser
{
public:
	TNetProtocolAnalyser(TFile *RawFile);
	virtual ~TNetProtocolAnalyser();
    
    virtual int GetMsg();
    virtual void ShowMsg();

protected:
	void ShowNetAddress(const char *Adress);
	void ShowIpData(unsigned char Protocol, const char *Msg, int Size);
	void ShowIcmp(const char *Msg, int Size);
	void ShowUdp(const char *Msg, int Size);
	void ShowTcp(const char *Msg, int Size);
    void ShowSmp(const char *Msg, int Size);
    void ShowArp(const char *Msg, int Size);
    void ShowIp(const char *Msg, int Size);
    void ShowNet(const char *Msg, int Size);
    void ShowUnknown(int DataType, const char *Msg, int Size);    
	void ShowDataMsg(const char *Msg, int Size);
	void ShowAll(const char *Msg, int Size);

	TLogHeader FHdr;

};

#endif
