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
# httpfact.cpp
# HTTP Command factory base class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "httpserv.h"
#include "httpcmd.h"
#include "httpfact.h"
#include "httpget.h"

#include "path.h"

#define FALSE 0
#define TRUE !FALSE

THttpCommandFactory *THttpCommandFactory::FCmdList = 0;

/*##########################################################################
#
#   Name       : THttpCommandFactory::THttpCommandFactory
#
#   Purpose....: Constructor for command factory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCommandFactory::THttpCommandFactory(const char *name)
  : FName(name)
{
	InsertCommand();
}

/*##########################################################################
#
#   Name       : THttpCommandFactor::~THttpCommandFactor
#
#   Purpose....: Destructor for command factory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpCommandFactory::~THttpCommandFactory()
{
	RemoveCommand();
}

/*##################  THttpCommandFactory::InsertCommand  ##########################
*   Purpose....: Insert device into command list                           #
*				 Should only be done in constructor							#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
void THttpCommandFactory::InsertCommand()
{
	FList = FCmdList;
	FCmdList = this;
}

/*##################  THttpCommandFactory::RemoveCommand  ##########################
*   Purpose....: Remove device from command list                           #
*				 Should only done in destructor								#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
void THttpCommandFactory::RemoveCommand()
{
	THttpCommandFactory *ptr;
	THttpCommandFactory *prev;
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

/*##################  THttpCommandFactory::PassAll  ##########################
*   Purpose....: Pass all characters to commandline                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
int THttpCommandFactory::PassAll()
{
	 return FALSE;
}

/*##################  THttpCommandFactory::PassDir  ##########################
*   Purpose....: Pass dir characters to commandline                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
int THttpCommandFactory::PassDir()
{
	 return FALSE;
}

/*##################  THttpCommandFactory::Parse  ##########################
*   Purpose....: Parse a command line and return a command class	    	#
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
THttpCommand *THttpCommandFactory::Parse(THttpSocketServer *Server, const char *line)
{
	const char *rest;
	int size;
	 int i;
	char *com;
	char *ptr;
	 int done;
	 TString Line;
	THttpCommandFactory *factory = 0;
	THttpCommand *cmd;

	Line = TString(THttpSocketServer::LTrim(line));

	rest = Line.GetData();

	if (*rest)
	{
		size = 0;
		while (*rest && THttpSocketServer::IsFileNameChar(*rest) && !strchr("\"", *rest))
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
			if (THttpSocketServer::IsArgDelim(*rest))
				rest = THttpSocketServer::LTrim(rest);

		return factory->Create(Server, rest);

	}
	else
		 return 0;
}

/*##########################################################################
#
#   Name       : THttpSocketServerFactory::THttpSocketServerFactory
#
#   Purpose....: Socket server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
THttpSocketServerFactory::THttpSocketServerFactory()
{
	Init();
}

/*##########################################################################
#
#   Name       : THttpSocketServerFactory::THttpSocketServerFactory
#
#   Purpose....: Socket server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void THttpSocketServerFactory::Init()
{
	THttpGetFactory *get = new THttpGetFactory;
}

/*##########################################################################
#
#   Name       : THttpSocketServerFactory::GetThreadName
#
#   Purpose....: Return thread name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *THttpSocketServerFactory::GetThreadName()
{
	return "HTTP";
}

/*##########################################################################
#
#   Name       : THttpSocketServerFactory::GetStackSize
#
#   Purpose....: Return thread stack size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int THttpSocketServerFactory::GetStackSize()
{
	return 0x2000;
}

/*##########################################################################
#
#   Name       : THttpSocketServerFactory::Create
#
#   Purpose....: Create a socket server instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *THttpSocketServerFactory::Create()
{
	THttpSocketServer *server;
	server = new THttpSocketServer();
	server->OnCommand = OnCommand;

	return server;
}
