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
# exec.h
# Execute external command class
#
########################################################################*/

#ifndef _EXEC_H
#define _EXEC_H

#include "cmd.h"
#include "path.h"

class TExecCommand : public TCommand
{
public:
	TExecCommand(TSession *session, const char *line);

	virtual int Execute(char *param);
	int IsValid();

protected:
	int CheckExt(const char *path, const char *ext);
	int CheckAllExt(const char *name);
	int CheckPath(const char *path, const char *name);
	int CheckPathExt(char *path, const char *name);

    int FDetach;
    int FValid;
	TString FProgName;
	TPathName FFullPath;
};

#endif
