/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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
    SocketId = 0;
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

/*##########################################################################
#
#   Name       : TTelnetSocketServerFactory::StartShell
#
#   Purpose....: Start new shell
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TTelnetSocketServerFactory::StartShell(const char *param)
{
    TPathName StartupDir;
    int ThreadId;
    int Handle;

    Handle = RdosSpawn(FFullPath.Get().GetData(), param, StartupDir.Get().GetData(), 0, &ThreadId);
    if (Handle)
        return TRUE;
    else
        return FALSE;
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
    int i;
    int IpcHandle;
    char IpcName[80];

    ok = CheckFile("command", ".exe");
    if (!ok)
        ok = CheckFile("command", ".com");

    if (ok)
    {
        sprintf(IpcName, "TELNET.%d", SocketId);
        SocketId++;

        ok = StartShell(IpcName);
    }

    if (ok)
    {
        for (i = 0; i < 100; i++)
        {
            RdosWaitMilli(100);
            IpcHandle = RdosGetLocalMailslot(IpcName);

            if (IpcHandle)
                break;
        }

        server = new TTelnetSocketServer("TELNET", 0x2000, Socket, IpcHandle);
        server->OnCommand = OnCommand;
    }

    return server;
}
