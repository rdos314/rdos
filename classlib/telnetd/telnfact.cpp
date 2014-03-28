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
# telnfact.cpp
# TELNET Command factory base class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "env.h"
#include "telnserv.h"
#include "telnfact.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TTelnetSocketServerFactory::TTelnetSocketServerFactory
#
#   Purpose....: Socket server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTelnetSocketServerFactory::TTelnetSocketServerFactory(int Port, int MaxConnections, int BufferSize)
  : TSocketServerFactory(Port, MaxConnections, BufferSize)
{
    OnCommand = 0;
}

/*##########################################################################
#
#   Name       : TTelnetSocketServerFactory::~TTelnetSocketServerFactory
#
#   Purpose....: Socket server factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TTelnetSocketServerFactory::~TTelnetSocketServerFactory()
{
}

/*##########################################################################
#
#   Name       : TTelnetSocketServerFactory::Create
#
#   Purpose....: Create a socket server instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *TTelnetSocketServerFactory::Create(TTcpSocket *Socket)
{
    TTelnetSocketServer *server = 0;
    int ok;

    ok = CheckFile("command", ".exe");
    if (!ok)
        ok = CheckFile("command", ".com");

    if (ok)
    {
        server = new TTelnetSocketServer("TELNET", 0x2000, Socket);
        server->OnCommand = OnCommand;
    }

    return server;
}

/*##########################################################################
#
#   Name       : TTelnetSocketServerFactory::CheckFileExt
#
#   Purpose....: Check if path is valid file (with given extension)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTelnetSocketServerFactory::CheckFileExt(const char *path, const char *ext)
{
    FFullPath = TString(path);
    FFullPath += ext;

    if (FFullPath.IsFile())
        return TRUE;
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TTelnetSocketServerFactory::CheckFileExt
#
#   Purpose....: Check if path + name is a valid file (with given extension)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTelnetSocketServerFactory::CheckFileExt(const char *path, const char *name, const char *ext)
{
    TPathName pn(path);
    pn += name;

    return CheckFileExt(pn.Get().GetData(), ext);
}

/*##########################################################################
#
#   Name       : TTelnetSocketServerFactory::CheckPathFileExt
#
#   Purpose....: Find file through with path env var
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTelnetSocketServerFactory::CheckPathFileExt(char *path, const char *name, const char *ext)
{
    char *ptr;

    if (CheckFileExt(name, ext))
        return TRUE;

    while (*path)
    {
        ptr = strchr(path, ';');
        if (ptr)
        {
            *ptr = 0;
            if (CheckFileExt(path, name, ext))
                return TRUE;

            path = ptr + 1;
        }
        else
            return CheckFileExt(path, name, ext);
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : TTelnetSocketServerFactory::CheckFile
#
#   Purpose....: Check if file is executable
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTelnetSocketServerFactory::CheckFile(char *name, const char *ext)
{
    char *path;
    TEnv *env;
    int ok;
        
    if (strchr(name, '\\'))
        if (CheckFileExt(name, ext))
            return TRUE;

    if (strchr(name, '/'))
        if (CheckFileExt(name, ext))
            return TRUE;

    if (strchr(name, ':'))
        if (CheckFileExt(name, ext))
            return TRUE;

    path = new char[512];
    env = TEnv::OpenSysEnv();
    if (env->Find("PATH", path))
    {
        ok = CheckPathFileExt(path, name, ext);
        delete env;
        delete path;
        if (ok)
            return TRUE;
    }
    else
    {
        delete env;
        delete path;
    }

    return CheckFileExt(name, ext);
}
