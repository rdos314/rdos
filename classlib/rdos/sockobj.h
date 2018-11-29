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
# sockobj.h
# Socket class
#
########################################################################*/

#ifndef _SOCKOBJ_H
#define _SOCKOBJ_H

#include "str.h"
#include "waitdev.h"

void IpToString(char *str, int Ip);
int StringToIp(const char *str);

class TSocketServerFactory;

class TSocket : public TWaitDevice
{
public:
    virtual ~TSocket();

    static long GetLocalIP();
        
    virtual long GetRemoteIP() const = 0;
    virtual int GetRemotePort() const = 0;
    virtual int GetLocalPort() const = 0;

    int WaitForData(long Timeout);

    virtual int IsIdle() = 0;
    virtual int GetSize() = 0;
    virtual void Write(const char *buf, int count) = 0;
    virtual void Write(const char *str) = 0;
    virtual int Read(char *buf, int size) = 0;

protected:
    virtual void SignalNewData();
};

class TTcpSocket : public TSocket
{
public:
    TTcpSocket(int Handle);
    TTcpSocket(long IP, int Port, int Timeout, int BufferSize);
    TTcpSocket(long IP, int LocalPort, int RemotePort, int Timeout, int BufferSize);
    ~TTcpSocket();

    virtual void DeviceName(char *Name, int MaxLen) const;
    virtual int IsOpen();
    virtual void NotifyClose();
        
    virtual long GetRemoteIP() const;
    virtual int GetRemotePort() const;
    virtual int GetLocalPort() const;

    void Push();
    void Write(char ch);
    char Read();
    int WaitForConnection(int Timeout);

    virtual int IsIdle();
    virtual int GetSize();
    virtual void Write(const char *buf, int count);
    virtual void Write(const char *str);
    virtual int Read(char *buf, int size);

protected:
    virtual void Add(TWait *Wait);

    int FHandle;
};

class TUdpSocket : public TSocket
{
public:
    TUdpSocket(long IP, int LocalPort, int RemotePort);
    ~TUdpSocket();

    virtual void DeviceName(char *Name, int MaxLen) const;
    virtual void NotifyClose();
        
    virtual long GetRemoteIP() const;
    virtual int GetRemotePort() const;
    virtual int GetLocalPort() const;

    virtual int IsIdle();
    virtual int GetSize();
    virtual void Write(const char *buf, int count);
    virtual void Write(const char *str);
    virtual int Read(char *buf, int size);

protected:
    virtual void Add(TWait *Wait);

    int FHandle;
    int FLocalPort;
    long FRemoteIp;
    int FRemotePort;
};


class TSocketServer : public TThread
{
friend class TSocketServerFactory;
public:
    TSocketServer(const char *Name, int StackSize, TTcpSocket *Socket);
    virtual ~TSocketServer();

    char FRemoteIp[30];
    
protected:
    virtual void HandleSocket() = 0;
    virtual void NotifyStarted();
    virtual void NotifyStopped();
    virtual void Execute();
    
    TSocketServer *FNext;
    TTcpSocket *FSocket;
};

class TSocketServerFactory : public TWaitDevice
{
public:
    TSocketServerFactory(int Port, int MaxConnections, int BufferSize);
    ~TSocketServerFactory();

    virtual TSocketServer *Create(TTcpSocket *Socket) = 0;
    void CloseAllSockets();

protected:
    void Cleanup();
    void Insert(TSocketServer *server);
    
    virtual void SignalNewData();
    virtual void Add(TWait *Wait);

    TSocketServer *FList;
    int FListenHandle;
};

class TUdpSocketListner : public TWaitDevice
{
public:
    TUdpSocketListner(int Port, int MaxBufferedMessages);
    virtual ~TUdpSocketListner();

    int WaitForMsg(long Timeout);
    int WaitForMsg();
    int HasMsg();

    long GetIP();
    int GetPort();
    int GetMsgSize();
    int GetMsg(char *buf, int size);    
    void ClearMsg();
    
protected:
    virtual void SignalNewData();
    virtual void Add(TWait *Wait);

    int FHandle;
};

#endif

