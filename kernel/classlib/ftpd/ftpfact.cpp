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
#include "cmdhelp.h"
#include "cmd.h"
#include "cmdfact.h"
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

	Line = TString(LTrim(line));

	rest = Line.GetData();

	if (*rest)
	{
		size = 0;
		while (*rest && IsFileNameChar(*rest) && !strchr("\"", *rest))
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
			if (IsArgDelim(*rest))
				rest = LTrim(rest);

		return factory->Create(rest);

	}
	else
	    return 0;
}
