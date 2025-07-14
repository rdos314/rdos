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
# ftpfact.h
# FTP Command factory base class
#
########################################################################*/

#ifndef _FTPFACT_H
#define _FTPFACT_H

#include "ftpcmd.h"
#include "ftpacc.h"

class TFtpSocketServer;

class TFtpCommandFactory
{
friend class THelpCommand;

public:
	 TFtpCommandFactory(const char *name);
	virtual ~TFtpCommandFactory();

	static TFtpCommand *Parse(TFtpSocketServer *Server, const char *line);

protected:
	virtual TFtpCommand *Create(TFtpSocketServer *Server, const char *param) = 0;
	virtual int PassAll();
	 virtual int PassDir();

	void InsertCommand();
	void RemoveCommand();

	static TFtpCommandFactory *FCmdList;
	TFtpCommandFactory *FList;
	TString FName;
};

class TFtpSocketServerFactory : public TSocketServerFactory
{
public:
    TFtpSocketServerFactory(int Port, int MaxConnections, int BufferSize, bool ReadOnly);
    TFtpSocketServerFactory(int Port, int MaxConnections, int BufferSize, const char *Language);
    TFtpSocketServerFactory(int Port, int MaxConnections, int BufferSize);
    ~TFtpSocketServerFactory();

    void AddUser(const char *User, const char *Passw, const char *RootDir);
    void SetDataPort(int DataPort);

    void SetMyIp(long Ip);

    virtual TSocketServer *Create(TTcpSocket *Socket);

    void (*OnCommand)(TFtpSocketServer *server, const char *str);

protected:
    void Init(bool ReadOnly);

    TFtpCommandFactory *user;
    TFtpCommandFactory *pass;
    TFtpCommandFactory *pwd;
    TFtpCommandFactory *syst;
    TFtpCommandFactory *pasv;
    TFtpCommandFactory *port;
    TFtpCommandFactory *list;
    TFtpCommandFactory *cwd;
    TFtpCommandFactory *cdup;
    TFtpCommandFactory *type;
    TFtpCommandFactory *retr;
    TFtpCommandFactory *stor;
    TFtpCommandFactory *mdtm;
    TFtpCommandFactory *dele;
    TFtpCommandFactory *mkd;
    TFtpCommandFactory *rmd;
    TFtpCommandFactory *quit;

    TFtpUser *FList;

    long FMyIp;
    int FLocalPort;
};

#endif
