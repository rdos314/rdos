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
# copy.h
# Copy command class
#
########################################################################*/

#ifndef _COPY_H
#define _COPY_H

#include "cmd.h"
#include "cmdfact.h"
#include "direntry.h"

class TCopyFactory : public TCommandFactory
{
public:
	TCopyFactory();
	virtual TCommand *Create(const char *param);

protected:
};

class TCopyCommand : public TCommand
{
public:
	TCopyCommand(const char *param);

	virtual int Execute(char *param);

protected:
	virtual int IsArgDelim(char ch);
	virtual int OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg);
	void InitOptions();
    int AddSrc(TArg *arg);

	int CopyFile(TString &Src, TString &Dest);
	int AppendFile(TString &Src, TString &Dest);

	int CopyFiles();
	int AppendFiles();

	TDirList FSrcFiles;
	TPathName *FDest;

	int FOptY;

};

#endif
