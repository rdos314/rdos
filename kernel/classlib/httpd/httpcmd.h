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
# httpcmd.h
# Http command base class
#
########################################################################*/

#ifndef _HTTPCMD_H
#define _HTTPCMD_H

#include "file.h"
#include "path.h"
#include "httppars.h"
#include "httpserv.h"

class THttpArg
{
public:
    THttpArg(const char *name);
    ~THttpArg();

    char *ptr;

    TString FName;
	THttpArg *FList;
};

class THttpCommand : public THttpParser
{
public:
    THttpCommand(THttpSocketServer *Server);
    THttpCommand(THttpSocketServer *Server, const char *param);
	virtual ~THttpCommand();

	void Run(char *opt);
	virtual void Execute(char *param) = 0;

	static int ErrorLevel;

protected:
    void AddArg(const char *name);
    void AddArg(char *sBeg, char **sEnd);
    void Split(char *s);
    int Parse(void *arg);
    int ScanCmdLine(char *line, void *arg);

	TString FCmdLine;
	THttpCommand *FList;
	
	THttpArg *FArgList;
	int FArgCount;

	THttpSocketServer *FServer;
};

#endif
