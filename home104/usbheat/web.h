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
# web.h
# Heat pump class
#
########################################################################*/

#ifndef WEB_H
#define WEB_H

#include "httpfact.h"

void InitWeb();

class THeatHttpServerFactory : public THttpSocketServerFactory
{
public:
    THeatHttpServerFactory(int Port, int MaxConnections, int BufferSize);
    ~THeatHttpServerFactory();

    virtual TSocketServer *Create(TTcpSocket *Socket);

protected:
};

class THeatHttpServer : public THttpSocketServer
{
public:
    THeatHttpServer(const char *Name, int StackSize, TTcpSocket *Socket);
    ~THeatHttpServer();
};

class THeatJsonDirFactory : public THttpCustomDirFactory
{
public:
    THeatJsonDirFactory(const char *ReqName);
    virtual ~THeatJsonDirFactory();

    virtual THttpCustomPage *Create(THttpCommand *cmd);
};

class THeatJsonPage : public THttpCustomPage
{
public:
    THeatJsonPage(THttpCommand *Cmd);
    virtual ~THeatJsonPage();

protected:
    virtual void Get(const char *MatchName, const char *UrlName, THttpParam *Param);
    virtual void Post(const char *MatchName, const char *UrlName, THttpParam *Param);
    virtual void Post(const char *Var, const char *Val);
};

#endif
