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
# del.cpp
# Delete command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "del.h"
#include "rdos.h"
#include "path.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TDelFactory::TDelFactory
#
#   Purpose....: Constructor for TDelFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDelFactory::TDelFactory()
  : TCommandFactory("DEL")
{
}

/*##########################################################################
#
#   Name       : TDelFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TDelFactory::Create(const char *param)
{
	return new TDelCommand(param);
}

/*##########################################################################
#
#   Name       : TEraseFactory::TEraseFactory
#
#   Purpose....: Constructor for TEraseFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TEraseFactory::TEraseFactory()
  : TCommandFactory("ERASE")
{
}

/*##########################################################################
#
#   Name       : TEraseFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TEraseFactory::Create(const char *param)
{
	return new TDelCommand(param);
}

/*##########################################################################
#
#   Name       : TDelCommand::TDelCommand
#
#   Purpose....: Constructor for TDelCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDelCommand::TDelCommand(const char *param)
  : TCommand(param)
{
	FHelpScreen.Load(TEXT_CMDHELP_COPY);
}

/*##########################################################################
#
#   Name       : TDelCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDelCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
	switch(ch)
	{
		case 'V':
			return OptScanBool(optstr, bool, strarg, &FOptV);

		case 'P':
			return OptScanBool(optstr, bool, strarg, &FOptP);
	}
	OptError(optstr);
	return E_Useage;
}

/*##########################################################################
#
#   Name       : TDelCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDelCommand::InitOptions()
{
	FOptV = FALSE;
	FOptP = FALSE;
}

/*##########################################################################
#
#   Name       : TDelCommand::Del
#
#   Purpose....: Delete file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDelCommand::Del(TPathName &path)
{
	if (FOptP)
	{
		switch (FMsg.UserPrompt(PROMPT_DELETE_FILE, path.Get().GetData()))
		{
			case 4:
				FBreak = TRUE;
				return FALSE;

			case 3:
				FOptP = FALSE;
				break;

			case 1:
				break;

			default:
				return FALSE;
		}
	}
    
	if (!FOptP)
	{
        FMsg.printf(TEXT_DELETE_FILE, path.Get().GetData());
		Write(FMsg.GetData());
	}

    if (path.DeleteFile())
        return TRUE;
    else
    {
	    FMsg.printf(TEXT_ERROR_DIRFCT_FAILED, "DEL", path.Get().GetData());
		Write(FMsg.GetData());
    	return FALSE;
    }
}

/*##########################################################################
#
#   Name       : TDelCommand::Del
#
#   Purpose....: Delete files in argument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDelCommand::Del(TArg *arg)
{
	int count;
	TDir *dir;
	TDirEntry entry;
	TPathName path(arg->FName);

	if (path.IsDir() && !FOptP)
	{
		if (FMsg.UserPrompt(PROMPT_DELETE_ALL, arg->FName.GetData()) != 1)
			return 0;
	}

	count = 0;
	dir = new TDir(arg->FName);
	entry = dir->GotoFirst();
	while (entry.Valid && !FBreak)
	{
		if (!(entry.Attribute & FILE_ATTRIBUTE_DIRECTORY))
		{
		    if (Del(entry.PathName))
				count++;
		}
		entry = dir->GotoNext();
	}

	if (!FBreak && count == 0)
	{
		FMsg.printf(TEXT_ERROR_SFILE_NOT_FOUND, dir->FSearchString.GetData());
		Write(FMsg.GetData());
		delete dir;
		return FALSE;
	}

	delete dir;
	return count;

}

/*##########################################################################
#
#   Name       : TDelCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDelCommand::Execute(char *param)
{
	TArg *arg;
	const char *ptr;
	int count;
	int total;

	InitOptions();

	if (!ScanCmdLine(param, 0))
		return 1;

	arg = FArgList;
	total = 0;
	FBreak = FALSE;

	while (arg && !FBreak)
	{
		if (LeadOptions(&arg->ptr, 0) != E_None)
			return 1;
		else
		{
			count = Del(arg);
			if (count)
				total += count;
			else
				return 1;

			arg = arg->FList;
		}
	}

	if (total)
	{
		ShowCount(TEXT_MSG_DEL_CNT_FILES, total);
		return 0;
	}
	else
	{
		FMsg.Load(TEXT_ERROR_REQ_PARAM_MISSING);
		Write(FMsg.GetData());
		return E_Useage;
	}
}
