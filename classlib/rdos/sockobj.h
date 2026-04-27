/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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

    bool WaitForData(long Timeout);

    virtual bool IsIdle() = 0;
    virtual int GetSize() = 0;
    virtual int GetWriteSpace() = 0;
    virtual void Write(const char *buf, int count) = 0;
    virtual void Write(const char *str) = 0;
    virtual int Read(char *buf, int size) = 0;

protected:
    TSocket(const char *DeviceName);
    virtual void SignalNewData();
};

class TTcpSocket : public TSocket
{
public:
    TTcpSocket(int Handle);
    TTcpSocket(long IP, int Port, int Timeout, int BufferSize);
    TTcpSocket(long IP, int LocalPort, int RemotePort, int Timeout, int BufferSize);
    virtual ~TTcpSocket();

    virtual bool IsOpen();
    virtual void NotifyClose();

    virtual long GetRemoteIP() const;
    virtual int GetRemotePort() const;
    virtual int GetLocalPort() const;

    virtual void Push();
    virtual void Write(char ch);
    virtual char Read();
    virtual bool WaitForConnection(int Timeout);

    virtual bool IsIdle();
    virtual int GetSize();
    virtual int GetWriteSpace();
    virtual void Write(const char *buf, int count);
    virtual void Write(const char *str);
    virtual int Read(char *buf, int size);

protected:
    TTcpSocket(const char *DeviceName);

    virtual void Add(TWait *Wait);

private:
    int FHandle;
};

class TUdpSocket : public TSocket
{
public:
    TUdpSocket(long IP, int LocalPort, int RemotePort);
    virtual ~TUdpSocket();

    virtual void NotifyClose();

    virtual long GetRemoteIP() const;
    virtual int GetRemotePort() const;
    virtual int GetLocalPort() const;

    virtual bool IsIdle();
    virtual int GetSize();
    virtual int GetWriteSpace();
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

class TSslSocket : public TTcpSocket
{
public:
    TSslSocket(int Handle);
    TSslSocket(long IP, int Port, int Timeout, int BufferSize);
    TSslSocket(long IP, int LocalPort, int RemotePort, int Timeout, int BufferSize);
    virtual ~TSslSocket();

    virtual bool IsOpen();
    virtual void NotifyClose();

    virtual long GetRemoteIP() const;
    virtual int GetRemotePort() const;
    virtual int GetLocalPort() const;

    virtual void Push();
    virtual void Write(char ch);
    virtual char Read();
    virtual bool WaitForConnection(int Timeout);

    virtual bool IsIdle();
    virtual int GetSize();
    virtual int GetWriteSpace();
    virtual void Write(const char *buf, int count);
    virtual void Write(const char *str);
    virtual int Read(char *buf, int size);

    int GetCertificate(char *buf, int size);

protected:
    int CreateSession();
    virtual void Add(TWait *Wait);

private:
    int FHandle;
    int FSession;
    bool FWaitDone;
};

class TSocketServer : public TThread
{
friend class TSocketServerFactory;
public:
    TSocketServer(const char *Name, int StackSize, TTcpSocket *Socket);
    virtual ~TSocketServer();

    long GetRemoteIP();

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
    TSocketServerFactory(const char *DeviceName, int Port, int MaxConnections, int BufferSize);
    virtual ~TSocketServerFactory();

    virtual TSocketServer *Create(TTcpSocket *Socket) = 0;
    void CloseAllSockets();
    int GetConnectionCount();

protected:
    TSocketServerFactory(const char *DeviceName);

    void Cleanup();
    void Insert(TSocketServer *server);

    virtual void SignalNewData();
    virtual void Add(TWait *Wait);

    TSocketServer *FList;
    int FServerCount;

private:
    int FListenHandle;
};

class TSslSocketServerFactory : public TSocketServerFactory
{
public:
    TSslSocketServerFactory(const char *DeviceName, int Port, int MaxConnections, int BufferSize);
    virtual ~TSslSocketServerFactory();

    void SetCertificate(const char *CertFileName, const char *PrivateKeyFileName, const char *ChainFileName);

protected:
    virtual void SignalNewData();
    virtual void Add(TWait *Wait);

private:
    int FListenHandle;
};

class TUdpSocketListner : public TWaitDevice
{
public:
    TUdpSocketListner(const char *DeviceName, int Port, int MaxBufferedMessages);
    virtual ~TUdpSocketListner();

    bool WaitForMsg(long Timeout);
    bool WaitForMsg();
    bool HasMsg();

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

