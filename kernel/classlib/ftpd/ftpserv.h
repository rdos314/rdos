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
#include "ftplang.h"
#include "ftpacc.h"

enum InternalErrorCodes
{
	E_None = 0,
	E_Useage = 1,
	E_Other = 2,
	E_CBreak = 3,
	E_NoMem,
	E_CorruptMemory,
	E_NoOption,
	E_Exit,
	E_Ignore,			/* Error that can be ignored */
	E_Empty,
	E_Syntax,
	E_Range,				/* Numbers out of range */
	E_NoItems,
	E_Help,		/* Help screen */
	E_User		/* MUST be the last one */
};

class TFtpSocketServer : public TSocketServer
{
public:
	TFtpSocketServer(TFtpUser *UserList);
	~TFtpSocketServer();

	virtual void DeviceName(char *Name, int MaxLen) const;
	virtual void HandleSocket();

    void Write(char ch);
    void Write(const char *str);
    void Write(const char *buf, int size);
    void WriteLong(long value);
    void Push();

	int IsOpen();
	int Read(char *buf, int size);

	int VerifyUser();
	int OpenDataConnection(long IP, int port);
	void ListenForDataConnection(long *IP, int *port);
	void Quit();

	void Reply(TLangString *Msg);

	void (*OnCommand)(TFtpSocketServer *server, const char *str);

    static int IsEmpty(const char *s);
    static int IsArgDelim(char ch);
    static int IsFileNameChar(char c);
    static const char *LTrimsp(const char *str);
    static const char *LTrim(const char *str);
    static void RTrim(char *str);
    static char *Unquote(const char *str, const char *end);
    static int MatchToken(char **Xp, const char *word, int len);

	TString User;
	TString Pass;
	TString CurrDir;
	TString RootDir;

	TSocket *FDataSocket;
	TFtpUser *FUserList;
};

#endif
