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
# ftpserv.cpp
# FTP socket server class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "file.h"
#include "strlist.h"
#include "socket.h"
#include "ftpserv.h"
#include "ftplang.h"
#include "ftpcmd.h"
#include "ftpfact.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TFtpSocketServer::IsEmpty
#
#   Purpose....: Return true if string is 0 or contains only spaces
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::IsEmpty(const char *s)
{
	if (s)
	{
		while(*s)
		{
			s++;
			if (!isspace(*s))
				return FALSE;
		}
	}
	return TRUE;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::IsArgDelim
#
#   Purpose....: Check for argument delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::IsArgDelim(char ch)
{
	return isspace(ch) || iscntrl(ch) || strchr(",;=", ch);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::IsFileNameChar
#
#   Purpose....: Is filename char
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::IsFileNameChar(char c)
{
	return !(c <= ' ' || c == 0x7f || strchr(".\"/\\[]:|<>+=;,", c));
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::LTrimsp
#
#   Purpose....: Trim of leading spaces
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TFtpSocketServer::LTrimsp(const char *str)
{
	while (*str && isspace(*str))
		str++;
	return str;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::LTrim
#
#   Purpose....: Remove leading "spaces"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TFtpSocketServer::LTrim(const char *str)
{
	while (*str)
	{
		if (IsArgDelim(*str))
			str++;
		else
			break;
	}
	return str;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::RTrim
#
#   Purpose....: Remove trailing "spaces"
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::RTrim(char *str)
{
	char *p;

	p = strchr(str, 0);
	p--;

	while (p >= str && IsArgDelim(*p))
		p--;

	p[1] = 0;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Unquote
#
#   Purpose....: Unquote to new string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TFtpSocketServer::Unquote(const char *str, const char *end)
{
	char *h, *newStr;
	const char *q;
	int len;

	newStr = new char[end - str + 1];
	h = newStr;

	while ((q = strpbrk(str, "\"")) != 0 && q < end)
	{
		memcpy(h, str, len = q++ - str);
		h += len;
		if ((str = strchr(q, q[-1])) == 0 || str >= end)
		{
			str = q;
			break;
		}

		memcpy(h, q, len = str++ - q);
		h += len;
	}

	memcpy(h, str, len = end - str);
	h[len] = 0;
	return newStr;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::MatchToken
#
#   Purpose....: Match token at begining of line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::MatchToken(char **Xp, const char *word, int len)
{
	char *p;
	char *q;

	p = *Xp;
	if (strncmpi(p, word, len) == 0)
	{
		p += len;
		if (*p)
		{
			q = (char *)LTrim(p);
			if (q == p)
				return FALSE;
			p = q;
		}
		*Xp = p;
		return TRUE;
	}

	return FALSE;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::TFtpSocketServer
#
#   Purpose....: Socket server constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpSocketServer::TFtpSocketServer(TFtpUser *UserList)
{
	FUserList = UserList;
	CurrDir = "/";
	FDataSocket = 0;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::~TFtpSocketServer
#
#   Purpose....: Socket server destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpSocketServer::~TFtpSocketServer()
{
    if (FDataSocket)
        delete FDataSocket;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::DeviceName
#
#   Purpose....: Device name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::DeviceName(char *Name, int MaxLen) const
{
	strncpy(Name,"FTP",MaxLen);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Reply
#
#   Purpose....: Reply to socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::Reply(TLangString *msg)
{
	 msg->Write(FSocket);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::VerifyUser
#
#   Purpose....: Verify a valid user is logged in
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::VerifyUser()
{
	TFtpUser *user;

	user = FUserList;

	while (user)
	{
		if (user->UserName == User && user->Password == Pass)
		{
			RootDir = user->RootDir;
			return TRUE;
		}
		user = user->FNext;
	}
	return FALSE;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::OpenDataConnection
#
#   Purpose....: Open data connection to client
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::OpenDataConnection(long IP, int port)
{
	if (IP == FSocket->GetRemoteIP())
	{
		if (FDataSocket)
			delete FDataSocket;

		FDataSocket = new TSocket(FWait, IP, port, 6000, 0x2000);

		if (FDataSocket->WaitForConnection(6000))
			return TRUE;
		else
		{
			delete FDataSocket;
			FDataSocket = 0;
		}
	}
	return FALSE;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::ListenForDataConnection
#
#   Purpose....: Listen for data connection from client
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::ListenForDataConnection(long *IP, int *port)
{
	*IP = FSocket->GetLocalIP();

	if (FDataSocket)
		delete FDataSocket;

	FDataSocket = new TSocket(FWait, FSocket->GetRemoteIP(), 0, 6000, 0x2000);
	*port = FDataSocket->GetLocalPort();
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Write
#
#   Purpose....: Write character to data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::Write(char ch)
{
	char str[2];

	str[0] = ch;
	str[1] = 0;

	if (FDataSocket && FDataSocket->IsOpen())
		FDataSocket->Write(str, 1);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Write
#
#   Purpose....: Write string to data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::Write(const char *str)
{
	int size = strlen(str);

	if (FDataSocket && FDataSocket->IsOpen())
		FDataSocket->Write(str, size);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Write
#
#   Purpose....: Write buffer to data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::Write(const char *buf, int size)
{
	if (FDataSocket && FDataSocket->IsOpen())
		FDataSocket->Write(buf, size);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::WriteLong
#
#   Purpose....: Write number to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::WriteLong(long value)
{
	char str[4];
	int tmp;
	int use = FALSE;

	tmp = value / 1000000000;
	if (tmp)
	{
		use = TRUE;
		sprintf(str, "%2d", tmp);
	}
	else
		strcpy(str, "  ");
	Write(str);
	Write(" ");
	value = value % 1000000000;

	tmp = value / 1000000;
	if (use)
		sprintf(str, "%03d", tmp);
	else
	{
		if (tmp)
		{
			use = TRUE;
			sprintf(str, "%3d", tmp);
		}
		else
			strcpy(str, "   ");
	}
	Write(str);
	Write(" ");
	value = value % 1000000;

	tmp = value / 1000;
	if (use)
		sprintf(str, "%03d", tmp);
	else
	{
		if (tmp)
		{
			use = TRUE;
			sprintf(str, "%3d", tmp);
		}
		else
			strcpy(str, "   ");
	}
	Write(str);
	Write(" ");
	value = value % 1000;

	tmp = value;
	if (use)
		sprintf(str, "%03d", tmp);
	else
		sprintf(str, "%3d", tmp);
	Write(str);
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Push
#
#   Purpose....: Push data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::Push()
{
	if (FDataSocket)
	{
		delete FDataSocket;
		FDataSocket = 0;
	}
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::IsOpen
#
#   Purpose....: Check if data socket is open
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::IsOpen()
{
	return FDataSocket && FDataSocket->IsOpen();
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Read
#
#   Purpose....: Read buffer from data socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServer::Read(char *buf, int size)
{
	if (FDataSocket)
		return FDataSocket->Read(buf, size);
	else
		return 0;
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::Quit
#
#   Purpose....: Quit session
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::Quit()
{
    FSocket->Close();
}

/*##########################################################################
#
#   Name       : TFtpSocketServer::HandleSocket
#
#   Purpose....: Handle socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServer::HandleSocket()
{
	int Major;
	int Minor;
	int Release;
	TLangString msg;
	TCommand *cmd;

	int count;
	char Buf[513];

	if (FSocket->WaitForConnection(6000))
	{

		RdosGetVersion(&Major, &Minor, &Release);
		msg.printf(220, Major, Minor, Release);
		msg.Write(FSocket);

		while (FSocket->IsOpen())
		{
			count = FSocket->Read(Buf, 512);
			Buf[count] = 0;

			if (count == 0)
				break;

			printf(Buf);

			cmd = TCommandFactory::Parse(this, Buf);

			if (cmd)
				cmd->Run();
			else
			{
				msg.Load(502);
				msg.Write(FSocket);
			}
		}
	}
}
