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
# mount.h
# Mount file onto a new drive command class
#
########################################################################*/

#ifndef _MOUNT_H
#define _MOUNT_H

#include "cmd.h"
#include "cmdfact.h"

class TMountFactory : public TCommandFactory
{
public:
	TMountFactory();
	virtual TCommand *Create(TSession *session, const char *param);
};

class TMountCommand : public TCommand
{
public:
	TMountCommand(TSession *session, const char *param);
	virtual ~TMountCommand();

	virtual int Execute(char *param);	

protected:
	virtual int OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg);
    void InitOptions();

    int Mount(TString filename);

    TDrive *FDrive;
	int FOptD;
};

#endif
