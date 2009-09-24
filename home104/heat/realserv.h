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
# realserv.h
# Real-time data socket server class
#
########################################################################*/

#ifndef _REALSERV_H
#define _REALSERV_H

#include "str.h"
#include "cotserv.h"
#include "sigdev.h"
#include "heatdata.h"

class TReadtimeSocketServerFactory;

class TRealtimeSocketServer : public TCotexSocketServer
{
friend class TRealtimeSocketServerFactory;
public:
	 TRealtimeSocketServer(TRealtimeSocketServerFactory *fact, const char *Name, int StackSize, TSocket *Socket);
	~TRealtimeSocketServer();

protected:
	void SendData(THeatData *data);

	virtual void HandleSocket();

    TSignalDevice FSignal;
    THeatData FHeatData;
    int FNewData;

    TRealtimeSocketServerFactory *FFactory;
	TRealtimeSocketServer *FNext;	
};

class TRealtimeSocketServerFactory : public TSocketServerFactory
{
friend class TRealtimeSocketServer;
public:
    TRealtimeSocketServerFactory(int Port, int MaxConnections, int BufferSize);
	~TRealtimeSocketServerFactory();

	virtual TSocketServer *Create(TSocket *Socket);

	void SendData(THeatData *data);

protected:
    void InsertServer(TRealtimeSocketServer *server);
    void RemoveServer(TRealtimeSocketServer *server);

    TSection FServerSection;
    TRealtimeSocketServer *FServerList;

};

#endif
