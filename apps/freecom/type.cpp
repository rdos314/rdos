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
# type.cpp
# Type command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "type.h"
#include "rdos.h"
#include "path.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TTypeFactory::TTypeFactory
#
#   Purpose....: Constructor for TTypeFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTypeFactory::TTypeFactory()
  : TCommandFactory("TYPE")
{
}

/*##########################################################################
#
#   Name       : TTypeFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TTypeFactory::Create(const char *param)
{
	return new TTypeCommand(param);
}

/*##########################################################################
#
#   Name       : TTypeCommand::TTypeCommand
#
#   Purpose....: Constructor for TTypeCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTypeCommand::TTypeCommand(const char *param)
  : TCommand(param)
{
	FHelpScreen.Load(TEXT_CMDHELP_TYPE);
}

/*##########################################################################
#
#   Name       : TTypeCommand::Show
#
#   Purpose....: Show
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TTypeCommand::Show(TPathName &PathName)
{
	TFile file = PathName.OpenFile();
    char buf[0x1001];
    int size;

    if (file.IsOpen())
    {
        for (;;)
        {
            size = file.Read(buf, 0x1000);
            if (size == 0)
                break;
            else
            {
                buf[size] = 0;
                Write(buf); 
            }
        }
    }
    Write("\r\n");
}

/*##########################################################################
#
#   Name       : TTypeCommand::Show
#
#   Purpose....: Show
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTypeCommand::Show(TArg *arg)
{
	int count;
	TDir *dir;
	TDirEntry entry;

	count = 0;
	dir = new TDir(arg->FName);
	entry = dir->GotoFirst();
	while (entry.Valid)
	{
		if (!(entry.Attribute & FILE_ATTRIBUTE_DIRECTORY))
		{
		    Show(entry.PathName);
			count++;
		}
		entry = dir->GotoNext();
	}

	if (count == 0)
	{
		FMsg.printf(TEXT_ERROR_SFILE_NOT_FOUND, dir->FSearchString.GetData());
		Write(FMsg.GetData());
		delete dir;
		return FALSE;
	}

	delete dir;
	return TRUE;
}

/*##########################################################################
#
#   Name       : TTypeCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTypeCommand::Execute(char *param)
{
	TArg *arg;
	int HasSrc = FALSE;
	const char *ptr;

	if (!ScanCmdLine(param, 0))
		return 1;

	arg = FArgList;

	while (arg)
	{
		if (LeadOptions(&arg->ptr, 0) != E_None)
			return 1;
		else
		{
		    if (!Show(arg))
		        return 1;
		        
			arg = arg->FList;
		}
	}

	return 0;
}
