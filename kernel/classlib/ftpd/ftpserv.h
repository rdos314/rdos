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
# ftpserv.h
# Ftp socket server class
#
########################################################################*/

#ifndef _FTPSERV_H
#define _FTPSERV_H

#include "str.h"
#include "socket.h"
#include "langstr.h"

class TFtpSocketServer : public TSocketServer
{
public:
	TFtpSocketServer();
	~TFtpSocketServer();

	virtual void DeviceName(char *Name, int MaxLen) const;
	virtual void HandleSocket();

    void Write(char ch);
    void Write(const char *str);
    void WriteLong(long value);
    void Push();

	int VerifyUser();
	int OpenDataConnection(long IP, int port);
	void ListenForDataConnection(long *IP, int *port);
	void Quit();

	void Reply(TLangString *Msg);

	TString User;
	TString Pass;
	TString CurrDir;

	TSocket *FDataSocket;
};

#endif
