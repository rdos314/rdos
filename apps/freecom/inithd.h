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
# inithd.h
# Init harddrive command class
#
########################################################################*/

#ifndef _INITHD_H
#define _INITHD_H

#include "cmd.h"
#include "cmdfact.h"
#include "disc.h"

class TInitHdFactory : public TCommandFactory
{
public:
	TInitHdFactory();
	virtual TCommand *Create(TSession *session, const char *param);

protected:
};

class TInitHdCommand : public TCommand
{
public:
	TInitHdCommand(TSession *session, const char *param);
	virtual ~TInitHdCommand();

	virtual int Execute(char *param);	

protected:
    void InitOptions();
	virtual int OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg);

    void LoadBootLoader(TDisc *Disc);
	void WriteBootSector(TDisc *Disc, int IdeDisc);
    void UpdateBootSector(TDisc *Disc, int IdeDisc);
	void WriteBootLoader(TDisc *Disc);

    int FLoaderSectors;
	int FOptR;
    int FOptI;
    int FOptD;
	char *FBootLoader;
	int FLoaderSize;
};

#endif
