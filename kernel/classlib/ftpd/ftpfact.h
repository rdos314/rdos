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
# ftpfact.h
# FTP Command factory base class
#
########################################################################*/

#ifndef _FTPFACT_H
#define _FTPFACT_H

#include "ftpcmd.h"
#include "ftpacc.h"

class TFtpSocketServer;

class TFtpCommandFactory
{
friend class THelpCommand;

public:
	 TFtpCommandFactory(const char *name);
	virtual ~TFtpCommandFactory();

	static TFtpCommand *Parse(TFtpSocketServer *Server, const char *line);

protected:
	virtual TFtpCommand *Create(TFtpSocketServer *Server, const char *param) = 0;
	virtual int PassAll();
	 virtual int PassDir();

	void InsertCommand();
	void RemoveCommand();

	static TFtpCommandFactory *FCmdList;
	TFtpCommandFactory *FList;
	TString FName;
};

class TFtpSocketServerFactory : public TSocketServerFactory
{
public:
    TFtpSocketServerFactory::TFtpSocketServerFactory(const char *Language);
	 TFtpSocketServerFactory::TFtpSocketServerFactory();

	 void AddUser(const char *User, const char *Passw, const char *RootDir);

	virtual char *GetThreadName();
	virtual int GetStackSize();
	virtual TSocketServer *Create();

	void (*OnCommand)(TFtpSocketServer *server, const char *str);

protected:
	void Init();

	TFtpUser *FList;
};

#endif
