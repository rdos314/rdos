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
# path.cpp
# Path command class
#
########################################################################*/

#include <string.h>

#include "cmdhelp.h"
#include "lang.h"
#include "copy.h"
#include "rdos.h"
#include "path.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TCopyFactory::TCopyFactory
#
#   Purpose....: Constructor for TCopyFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCopyFactory::TCopyFactory()
  : TCommandFactory("COPY")
{
}

/*##########################################################################
#
#   Name       : TCopyFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TCopyFactory::Create(const char *param)
{
	return new TCopyCommand(param);
}

/*##########################################################################
#
#   Name       : TCopyCommand::TCopyCommand
#
#   Purpose....: Constructor for TCopyCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCopyCommand::TCopyCommand(const char *param)
  : TCommand(param)
{
	FHelpScreen.Load(TEXT_CMDHELP_COPY);
}

/*##########################################################################
#
#   Name       : TCopyCommand::IsArgDelim
#
#   Purpose....: Check for argument delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCopyCommand::IsArgDelim(char ch)
{
	if (ch == '+')
		return TRUE;
	else
		return TCommand::IsArgDelim(ch);
}

/*##########################################################################
#
#   Name       : TCopyCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCopyCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
	switch(ch)
	{
		case 'Y':
			return OptScanBool(optstr, bool, strarg, &FOptY);
	}
	OptError(optstr);
	return E_Useage;
}

/*##########################################################################
#
#   Name       : TCopyCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCopyCommand::InitOptions()
{
	FOptY = FALSE;
}

/*##########################################################################
#
#   Name       : TCopyCommand::CopyFile
#
#   Purpose....: Copy file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCopyCommand::CopyFile(TString &Src, TString &Dest)
{
	char ch;
	TPathName src(Src);
	TPathName dest(Dest);
	TString fullsrc(src.GetFullPathName());
	TString fulldest(dest.GetFullPathName());

	fullsrc.Upper();
	fulldest.Upper();

	if (!strcmp(fullsrc.GetData(), fulldest.GetData()))
	{
		FMsg.printf(TEXT_ERROR_SELFCOPY, Dest.GetData());
		Write(FMsg.GetData());
		return 1;
	}

	if (dest.IsFile() && !FOptY)
	{
		ch = FMsg.UserPrompt(PROMPT_OVERWRITE_FILE, Dest.GetData());
		switch (ch)
		{
			case 3:	/* All */
				FOptY = TRUE;

			case 1: /* Yes */
				break;

			case 2:	/* No */
				return 0;

			default:	/* Quit */
				return 1;
		}		
	}


	Write(Src.GetData());
	Write(" => ");
	Write(Dest.GetData());
	Write("\r\n");

	if (src.CopyFile(dest))
		return 0;
	else
	{
		FMsg.Load(TEXT_ERROR_COPY);
		Write(FMsg.GetData());
		return 1;
	}
}

/*##########################################################################
#
#   Name       : TCopyCommand::AppendFile
#
#   Purpose....: Append file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCopyCommand::AppendFile(TString &Src, TString &Dest)
{
	TPathName src(Src);
	TPathName dest(Dest);
	TString fullsrc(src.GetFullPathName());
	TString fulldest(dest.GetFullPathName());

	fullsrc.Upper();
	fulldest.Upper();

	if (!strcmp(fullsrc.GetData(), fulldest.GetData()))
		return 0;

	Write(Src.GetData());
	Write(" =>> ");
	Write(Dest.GetData());
	Write("\r\n");

	if (src.AppendFile(dest))
		return 0;
	else
	{
		FMsg.Load(TEXT_ERROR_COPY);
		Write(FMsg.GetData());
		return 1;
	}
}

/*##########################################################################
#
#   Name       : TCopyCommand::CopyFiles
#
#   Purpose....: Copy files
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCopyCommand::CopyFiles()
{
	TDirEntry *entry;
	int result;

	entry = FSrcFiles.GotoFirst();
	while (entry)
	{
		TPathName path(*FDest);
		path += entry->EntryName;
		result = CopyFile(entry->PathName.Get(), path.Get());
		if (result)
			return result;
		entry = FSrcFiles.GotoNext();
	}

	return 0;
}

/*##########################################################################
#
#   Name       : TCopyCommand::AppendFiles
#
#   Purpose....: Append files
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCopyCommand::AppendFiles()
{
	TDirEntry *entry;
	TString file;

	entry = FSrcFiles.GotoFirst();
	file = entry->PathName.Get();

	if (entry)
	{
		CopyFile(entry->PathName.Get(), FDest->Get());
		entry = FSrcFiles.GotoNext();
		while (entry)
		{
			AppendFile(entry->PathName.Get(), FDest->Get());
			entry = FSrcFiles.GotoNext();
		}
	}
	return 0;
}

/*##########################################################################
#
#   Name       : TCopyCommand::AddSrc
#
#   Purpose....: Add source files
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCopyCommand::AddSrc(TArg *arg)
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
			count++;
			FSrcFiles.Add(entry);
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
#   Name       : TCopyCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCopyCommand::Execute(char *param)
{
	TArg *arg;
	int HasSrc = FALSE;
	const char *ptr;

	FDest = 0;

	InitOptions();

	if (!ScanCmdLine(param, 0))
		return 1;

	arg = FArgList;

	while (arg)
	{
		if (LeadOptions(&arg->ptr, 0) != E_None)
			return 1;
		else
		{
			if (arg->FList)
			{
				if (AddSrc(arg))
					HasSrc = TRUE;
				else
					return 1;
			}
			else
			{
				if (HasSrc)
				{
					ptr = arg->FName.GetData();
					if (strlen(ptr) == 2 && *(ptr+1) == ':')
						FDest = new TPathName(arg->FName + ".");
					else
						FDest = new TPathName(arg->FName);
				}
				else
				{
					if (AddSrc(arg))
						FDest = new TPathName(".");
					else
						return 1;
				}
			}

			arg = arg->FList;
		}
	}

	if (FDest)
	{
		if (FDest->IsDir())
			return CopyFiles();
		else
			return AppendFiles();
	}

	return 0;
}
