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
# wdsuppl.h
# WD supplementary service base class
#
########################################################################*/

#ifndef _WDSUPPL_H
#define _WDSUPPL_H

#include "str.h"
#include "wdfact.h"
#include "wdserv.h"

class TWdSupplService;

class TWdSupplFactory
{
public:
	 TWdSupplFactory(TWdSocketServerFactory *factory, const char *Name);
	virtual ~TWdSupplFactory();

	virtual TWdSupplService *Create(TWdSocketServer *server) = 0;

    char *FName;
	TWdSupplFactory *FNext;
};

class TWdSupplService
{
public:
    TWdSupplService(TWdSocketServer *server);
	virtual ~TWdSupplService();

    virtual void NotifyMsg() = 0;

    TWdSupplService *FNext;

protected:

    char GetByte();
    short int GetWord();
    long GetDword();
    void GetString(char *str, int maxsize);

    void PutByte(char val);
    void PutWord(short int val);
    void PutDword(long val);
    void PutString(const char *str);
    void PutData(void *ptr, int size);

    TDebug *GetDebug();
    TString GetFullPathName(char *name, const char *ext);

    TWdSocketServer *FServer;
};

#endif
