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
# httpfact.h
# HTTP Command factory base class
#
########################################################################*/

#ifndef _HTTPFACT_H
#define _HTTPFACT_H

#include "httpcmd.h"

class THttpSocketServer;

class THttpCommandFactory
{
public:
	THttpCommandFactory(const char *name);
	virtual ~THttpCommandFactory();

	static THttpCommand *Parse(THttpSocketServer *Server, const char *line);

protected:
	virtual THttpCommand *Create(THttpSocketServer *Server, const char *param) = 0;
	virtual int PassAll();
	virtual int PassDir();

	void InsertCommand();
	void RemoveCommand();

	static THttpCommandFactory *FCmdList;
	THttpCommandFactory *FList;
	TString FName;
};

class THttpSocketServerFactory : public TSocketServerFactory
{
public:
	THttpSocketServerFactory::THttpSocketServerFactory();

	virtual char *GetThreadName();
	virtual int GetStackSize();
	virtual TSocketServer *Create();

	void (*OnCommand)(THttpSocketServer *server, const char *str);

protected:
	void Init();
};

#endif
