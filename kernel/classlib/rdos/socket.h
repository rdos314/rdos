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
# socket.h
# Socket class
#
########################################################################*/

#ifndef _SOCKET_H
#define _SOCKET_H

#include "waitdev.h"

class TSocketServerFactory;

class TSocket : public TWaitDevice
{
public:
    TSocket(TWait *Wait, int Handle);
    TSocket(TWait *Wait, long IP, int Port, int Timeout, int BufferSize);
    ~TSocket();

    static void Listen(TSocketServerFactory *Factory, int Port, int BufferSize);

	virtual void DeviceName(char *Name, int MaxLen) const;
	virtual int IsOpen() const;

    void Push();
    int WaitForConnection(int Timeout);

	void Write(char ch);
	void Write(const char *buf, int count);
	void Write(const char *str);

	int WaitForChar(long Timeout);
	char Read();
	int Read(char *buf, int size);

protected:
	virtual void SignalNewData();

	int FHandle;
};

class TSocketServer : public TDevice
{
public:
	TSocketServer(const char *ThreadName, int Handle);
	virtual ~TSocketServer();

protected:
    TWait *FWait;
	TSocket *FSocket;
};

class TSocketServerFactory
{
public:
	virtual TSocketServer *Create(int Handle) = 0;
};

#endif

