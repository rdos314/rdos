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
# exec.cpp
# Execute external command class
#
########################################################################*/

#include <string.h>

#include "rdos.h"
#include "exec.h"
#include "cmdhelp.h"
#include "lang.h"
#include "env.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TExecCommand::TExecCommand
#
#   Purpose....: Constructor for TExecCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TExecCommand::TExecCommand(const char *line)
{
	const char *cp;
	const char *rest;

	rest = SkipWord((char *)line);
    cp = Unquote(line, rest);

	FProgName = cp;
	FCmdLine = rest;
}

/*##########################################################################
#
#   Name       : TExecCommand::Start
#
#   Purpose....: Start program
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TExecCommand::Start(TPathName *path, const char *param)
{
	return RdosExec(path->Get().GetData(), param);
}

/*##########################################################################
#
#   Name       : TExecCommand::CheckExt
#
#   Purpose....: Check if path is valid file (with given extension)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TExecCommand::CheckExt(TPathName *path, const char *ext)
{
	TPathName pn(*path);

	pn += ext;
	if (pn.IsFile())
	{
		*path += ext;
		return TRUE;
	}
	else
		return FALSE;
}

/*##########################################################################
#
#   Name       : TExecCommand::CheckPath
#
#   Purpose....: Check if path is valid file (.exe.bat.com)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TExecCommand::CheckPath(TPathName *path)
{
	if (CheckExt(path, ".com"))
		return TRUE;

	if (CheckExt(path, ".exe"))
		return TRUE;

	if (CheckExt(path, ".bat"))
		return TRUE;

	return FALSE;
}

/*##########################################################################
#
#   Name       : TExecCommand::CheckPath
#
#   Purpose....: Check if name is a valid file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName *TExecCommand::CheckPath(const char *name)
{
	TPathName *pn;

	pn = new TPathName(name);

	if (CheckPath(pn))
		return pn;
	else
	{
		delete pn;
		return 0;
	}
}

/*##########################################################################
#
#   Name       : TExecCommand::CheckPath
#
#   Purpose....: Check if path + name is a valid file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TPathName *TExecCommand::CheckPath(const char *path, const char *name)
{
	TPathName *pn;

	pn = new TPathName(path);
	*pn += name;

	if (CheckPath(pn))
		return pn;
	else
	{
		delete pn;
		return 0;
	}
}

/*##########################################################################
#
#   Name       : TExecCommand::Load
#
#   Purpose....: Load with absolute path
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TExecCommand::Load(const char *name, char *param)
{
	TPathName *pn;
	int result;

	pn = CheckPath(name);

	if (pn)
	{
		result = Start(pn, param);
		delete pn;
		return result;
	}
	else
	{
		FMsg.printf(TEXT_ERROR_BADCOMMAND, name);
		Write(FMsg.GetData());
		return 1;
	}
}

/*##########################################################################
#
#   Name       : TExecCommand::Load
#
#   Purpose....: Load with path var
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TExecCommand::Load(char *path, const char *name, char *param)
{
	char *ptr;
	TPathName *pn = 0;
	int result;

	pn = CheckPath(name);

	while (*path && !pn)
	{
		ptr = strchr(path, ';');
		if (ptr)
		{
			*ptr = 0;
			pn = CheckPath(path, name);
			path = ptr + 1;
		}
		else
		{
			pn = CheckPath(path, name);
			break;
		}
	}

	if (pn)
	{
		result = Start(pn, param);
		delete pn;
		return result;
	}
	else
	{
		FMsg.printf(TEXT_ERROR_BADCOMMAND, name);
		Write(FMsg.GetData());
		return 1;
	}
}

/*##########################################################################
#
#   Name       : TExecCommand::Run
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TExecCommand::Execute(char *param)
{
	char *name;
	char *path;
	char *ptr;
	TEnv *env;
	int result;

	name = (char *)FProgName.GetData();
	if (strchr(name, '\\'))
		return Load(name, param);

	if (strchr(name, '/'))
		return Load(name, param);

	if (strchr(name, ':'))
		return Load(name, param);

	path = new char[512];
	env = TEnv::OpenSysEnv();
	if (env->Find("PATH", path))
	{
		result = Load(path, name, param);
		delete env;
		delete path;
		return result;
	}		
	delete env;	
	delete path;	
	return Load(name, param);
}
