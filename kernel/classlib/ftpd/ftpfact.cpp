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
# cmdfact.cpp
# Command factory base class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "ftpserv.h"
#include "ftpcmd.h"
#include "ftpfact.h"
#include "ftpuser.h"
#include "ftppass.h"
#include "ftppwd.h"
#include "ftpsyst.h"
#include "ftppasv.h"
#include "ftpport.h"
#include "ftplist.h"
#include "ftpcwd.h"
#include "ftpcdup.h"
#include "ftptype.h"
#include "ftpretr.h"
#include "ftpstor.h"
#include "ftpmdtm.h"
#include "ftpdele.h"
#include "ftpmkd.h"
#include "ftprmd.h"
#include "ftpquit.h"

#include "path.h"

#define FALSE 0
#define TRUE !FALSE

TFtpCommandFactory *TFtpCommandFactory::FCmdList = 0;

/*##########################################################################
#
#   Name       : TFtpCommandFactory::TFtpCommandFactory
#
#   Purpose....: Constructor for command factory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommandFactory::TFtpCommandFactory(const char *name)
  : FName(name)
{
	InsertCommand();
}

/*##########################################################################
#
#   Name       : TFtpCommandFactor::~TFtpCommandFactor
#
#   Purpose....: Destructor for command factory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommandFactory::~TFtpCommandFactory()
{
	RemoveCommand();
}

/*##################  TFtpCommandFactory::InsertCommand  ##########################
*   Purpose....: Insert device into command list                           #
*				 Should only be done in constructor							#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
void TFtpCommandFactory::InsertCommand()
{
	FList = FCmdList;
	FCmdList = this;
}

/*##################  TFtpCommandFactory::RemoveCommand  ##########################
*   Purpose....: Remove device from command list                           #
*				 Should only done in destructor								#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
void TFtpCommandFactory::RemoveCommand()
{
	TFtpCommandFactory *ptr;
	TFtpCommandFactory *prev;
	prev = 0;

	ptr = FCmdList;
	while ((ptr != 0) && (ptr != this))
	 {
		prev = ptr;
		ptr = ptr->FList;
	 }
	if (prev == 0)
		FCmdList = FCmdList->FList;
	else
		prev->FList = ptr->FList;
}

/*##################  TFtpCommandFactory::PassAll  ##########################
*   Purpose....: Pass all characters to commandline                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
int TFtpCommandFactory::PassAll()
{
	 return FALSE;
}

/*##################  TFtpCommandFactory::PassDir  ##########################
*   Purpose....: Pass dir characters to commandline                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
int TFtpCommandFactory::PassDir()
{
	 return FALSE;
}

/*##################  TFtpCommandFactory::Parse  ##########################
*   Purpose....: Parse a command line and return a command class	    	#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
TFtpCommand *TFtpCommandFactory::Parse(TFtpSocketServer *Server, const char *line)
{
	const char *rest;
	int size;
	 int i;
	char *com;
	char *ptr;
	 int done;
	 TString Line;
	TFtpCommandFactory *factory = 0;
	TFtpCommand *cmd;

	Line = TString(TFtpSocketServer::LTrim(line));

	rest = Line.GetData();

	if (*rest)
	{
		size = 0;
		while (*rest && TFtpSocketServer::IsFileNameChar(*rest) && !strchr("\"", *rest))
		{
			size++;
			rest++;
		}

		if (*rest && strchr("\"", *rest))
			size = 0;

		if (size)
		{
			com = new char[size + 1];

			rest = Line.GetData();
			ptr = com;

			for (i = 0; i < size; i++)
			{
				*ptr = toupper(*rest);
				ptr++;
				rest++;
			}
			*ptr = 0;

			factory = FCmdList;
			while (factory)
			{
				if (!strcmp(factory->FName.GetData(), com))
					break;

				factory = factory->FList;
			}

			delete com;
		}
	}

	if (factory)
	{
		done = factory->PassAll();

		if (!done && factory->PassDir())
			done = *rest == '/' || *rest == '.' || *rest == ':';

		if (!done)
			done = (!*rest || *rest == '/');

		if (!done)
			if (TFtpSocketServer::IsArgDelim(*rest))
				rest = TFtpSocketServer::LTrim(rest);

		return factory->Create(Server, rest);

	}
	else
		 return 0;
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::TFtpSocketServerFactory
#
#   Purpose....: Socket server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpSocketServerFactory::TFtpSocketServerFactory()
{
	Init();
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::TFtpSocketServerFactory
#
#   Purpose....: Socket server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpSocketServerFactory::TFtpSocketServerFactory(const char *Language)
{
	TFtpLangString::SetLanguage(Language);
	Init();
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::TFtpSocketServerFactory
#
#   Purpose....: Socket server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServerFactory::Init()
{
	TFtpUserFactory *user = new TFtpUserFactory;
	TFtpPassFactory *pass = new TFtpPassFactory;
	TFtpPwdFactory *pwd = new TFtpPwdFactory;
	TFtpSystFactory *syst = new TFtpSystFactory;
	TFtpPasvFactory *pasv = new TFtpPasvFactory;
	TFtpPortFactory *port = new TFtpPortFactory;
	TFtpListFactory *list = new TFtpListFactory;
	TFtpCwdFactory *cwd = new TFtpCwdFactory;
	TFtpCdupFactory *cdup = new TFtpCdupFactory;
	TFtpTypeFactory *type = new TFtpTypeFactory;
	TFtpRetrFactory *retr = new TFtpRetrFactory;
	TFtpStorFactory *stor = new TFtpStorFactory;
	TFtpMdtmFactory *mdtm = new TFtpMdtmFactory;
	TFtpDeleFactory *dele = new TFtpDeleFactory;
	TFtpMkdFactory *mkd = new TFtpMkdFactory;
	TFtpRmdFactory *rmd = new TFtpRmdFactory;
	TFtpQuitFactory *quit = new TFtpQuitFactory;

	FList = 0;
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::GetThreadName
#
#   Purpose....: Return thread name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TFtpSocketServerFactory::GetThreadName()
{
	return "FTP";
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::GetStackSize
#
#   Purpose....: Return thread stack size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFtpSocketServerFactory::GetStackSize()
{
	return 0x2000;
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::Create
#
#   Purpose....: Create a socket server instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *TFtpSocketServerFactory::Create()
{
	TFtpSocketServer *server;
	server = new TFtpSocketServer(FList);
	server->OnCommand = OnCommand;

	return server;
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::AddUser
#
#   Purpose....: Create a socket server instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServerFactory::AddUser(const char *User, const char *Passw, const char *RootDir)
{
    TFtpUser *user = new TFtpUser(User, Passw, RootDir);

    user->FNext = FList;
    FList = user;
}
