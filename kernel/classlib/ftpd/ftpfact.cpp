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

TCommandFactory *TCommandFactory::FCmdList = 0;

/*##########################################################################
#
#   Name       : TCommandFactory::TCommandFactory
#
#   Purpose....: Constructor for command factory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommandFactory::TCommandFactory(const char *name)
  : FName(name)
{
	InsertCommand();
}

/*##########################################################################
#
#   Name       : TCommandFactor::~TCommandFactor
#
#   Purpose....: Destructor for command factory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommandFactory::~TCommandFactory()
{	
	RemoveCommand();
}

/*##################  TCommandFactory::InsertCommand  ##########################
*   Purpose....: Insert device into command list                           #
*				 Should only be done in constructor							#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
void TCommandFactory::InsertCommand()
{
	FList = FCmdList;
	FCmdList = this;
}

/*##################  TCommandFactory::RemoveCommand  ##########################
*   Purpose....: Remove device from command list                           #
*				 Should only done in destructor								#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
void TCommandFactory::RemoveCommand()
{
	TCommandFactory *ptr;
	TCommandFactory *prev;
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

/*##################  TCommandFactory::PassAll  ##########################
*   Purpose....: Pass all characters to commandline                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
int TCommandFactory::PassAll()
{
    return FALSE;
}

/*##################  TCommandFactory::PassDir  ##########################
*   Purpose....: Pass dir characters to commandline                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
int TCommandFactory::PassDir()
{
    return FALSE;
}

/*##################  TCommandFactory::Parse  ##########################
*   Purpose....: Parse a command line and return a command class	    	#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
TCommand *TCommandFactory::Parse(TFtpSocketServer *Server, const char *line)
{
	const char *rest;
	int size;
    int i;
	char *com;
	char *ptr;
    int done;
    TString Line;
	TCommandFactory *factory = 0;
	TCommand *cmd;

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

			if (!factory)
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
	TLangString::SetLanguage(Language);
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
	TUserFactory *user = new TUserFactory;
	TPassFactory *pass = new TPassFactory;
	TPwdFactory *pwd = new TPwdFactory;
	TSystFactory *syst = new TSystFactory;
	TPasvFactory *pasv = new TPasvFactory;
	TPortFactory *port = new TPortFactory;
	TListFactory *list = new TListFactory;
	TCwdFactory *cwd = new TCwdFactory;
	TCdupFactory *cdup = new TCdupFactory;
	TTypeFactory *type = new TTypeFactory;
	TRetrFactory *retr = new TRetrFactory;
	TStorFactory *stor = new TStorFactory;
	TMdtmFactory *mdtm = new TMdtmFactory;
	TDeleFactory *dele = new TDeleFactory;
	TMkdFactory *mkd = new TMkdFactory;
	TRmdFactory *rmd = new TRmdFactory;
	TQuitFactory *quit = new TQuitFactory;

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
