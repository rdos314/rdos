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
# cmdfact.cpp
# Command factory base class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "ftpserv.h"
#include "ftpcmd.h"
#include "ftpfact.h"
#include "ftpuser.h"
#include "ftppass.h"
#include "ftppwd.h"
#include "ftpsyst.h"
#include "ftppasv.h"
#include "ftpport.h"
#include "ftplist.h"
#include "ftpcwd.h"
#include "ftpcdup.h"
#include "ftptype.h"
#include "ftpretr.h"
#include "ftpstor.h"
#include "ftpmdtm.h"
#include "ftpdele.h"
#include "ftpmkd.h"
#include "ftprmd.h"
#include "ftpquit.h"

#include "path.h"

#define FALSE 0
#define TRUE !FALSE

TFtpCommandFactory *TFtpCommandFactory::FCmdList = 0;

/*##########################################################################
#
#   Name       : TFtpCommandFactory::TFtpCommandFactory
#
#   Purpose....: Constructor for command factory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommandFactory::TFtpCommandFactory(const char *name)
  : FName(name)
{
        InsertCommand();
}

/*##########################################################################
#
#   Name       : TFtpCommandFactor::~TFtpCommandFactor
#
#   Purpose....: Destructor for command factory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpCommandFactory::~TFtpCommandFactory()
{
        RemoveCommand();
}

/*##################  TFtpCommandFactory::InsertCommand  ##########################
*   Purpose....: Insert device into command list                           #
*                                Should only be done in constructor                                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
void TFtpCommandFactory::InsertCommand()
{
        FList = FCmdList;
        FCmdList = this;
}

/*##################  TFtpCommandFactory::RemoveCommand  ##########################
*   Purpose....: Remove device from command list                           #
*                                Should only done in destructor                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
void TFtpCommandFactory::RemoveCommand()
{
        TFtpCommandFactory *ptr;
        TFtpCommandFactory *prev;
        prev = 0;

        ptr = FCmdList;
        while ((ptr != 0) && (ptr != this))
         {
                prev = ptr;
                ptr = ptr->FList;
         }
        if (prev == 0)
                FCmdList = FCmdList->FList;
        else
                prev->FList = ptr->FList;
}

/*##################  TFtpCommandFactory::PassAll  ##########################
*   Purpose....: Pass all characters to commandline                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
int TFtpCommandFactory::PassAll()
{
         return FALSE;
}

/*##################  TFtpCommandFactory::PassDir  ##########################
*   Purpose....: Pass dir characters to commandline                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
int TFtpCommandFactory::PassDir()
{
         return FALSE;
}

/*##################  TFtpCommandFactory::Parse  ##########################
*   Purpose....: Parse a command line and return a command class                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-09-02 le                                                #
*##########################################################################*/
TFtpCommand *TFtpCommandFactory::Parse(TFtpSocketServer *Server, const char *line)
{
        const char *rest;
        int size;
         int i;
        char *com;
        char *ptr;
         int done;
         TString Line;
        TFtpCommandFactory *factory = 0;

        Line = TString(TFtpSocketServer::LTrim(line));

        rest = Line.GetData();

        if (*rest)
        {
                size = 0;
                while (*rest && TFtpSocketServer::IsFileNameChar(*rest) && !strchr("\"", *rest))
                {
                        size++;
                        rest++;
                }

                if (*rest && strchr("\"", *rest))
                        size = 0;

                if (size)
                {
                        com = new char[size + 1];

                        rest = Line.GetData();
                        ptr = com;

                        for (i = 0; i < size; i++)
                        {
                                *ptr = toupper(*rest);
                                ptr++;
                                rest++;
                        }
                        *ptr = 0;

                        factory = FCmdList;
                        while (factory)
                        {
                                if (!strcmp(factory->FName.GetData(), com))
                                        break;

                                factory = factory->FList;
                        }

                        delete com;
                }
        }

        if (factory)
        {
                done = factory->PassAll();

                if (!done && factory->PassDir())
                        done = *rest == '/' || *rest == '.' || *rest == ':';

                if (!done)
                        done = (!*rest || *rest == '/');

                if (!done)
                        if (TFtpSocketServer::IsArgDelim(*rest))
                                rest = TFtpSocketServer::LTrim(rest);

                return factory->Create(Server, rest);

        }
        else
                 return 0;
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::TFtpSocketServerFactory
#
#   Purpose....: Socket server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpSocketServerFactory::TFtpSocketServerFactory(int Port, int MaxConnections, int BufferSize)
  : TSocketServerFactory("FTPD", Port, MaxConnections, BufferSize)
{
        Init(false);
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::TFtpSocketServerFactory
#
#   Purpose....: Socket server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpSocketServerFactory::TFtpSocketServerFactory(int Port, int MaxConnections, int BufferSize, const char *Language)
  : TSocketServerFactory("FTPD", Port, MaxConnections, BufferSize)
{
    TFtpLangString::SetLanguage(Language);
    Init(false);
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::TFtpSocketServerFactory
#
#   Purpose....: Socket server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpSocketServerFactory::TFtpSocketServerFactory(int Port, int MaxConnections, int BufferSize, bool ReadOnly)
  : TSocketServerFactory("FTPD", Port, MaxConnections, BufferSize)
{
    Init(ReadOnly);
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::~TFtpSocketServerFactory
#
#   Purpose....: Socket server factory destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFtpSocketServerFactory::~TFtpSocketServerFactory()
{
    delete user;
    delete pass;
    delete pwd;
    delete syst;
    delete pasv;
    delete port;
    delete list;
    delete cwd;
    delete cdup;
    delete type;
    delete retr;
    delete quit;

    if (stor)
        delete stor;

    if (mdtm)
        delete mdtm;

    if (dele)
        delete dele;

    if (mkd)
        delete mkd;

    if (rmd)
        delete rmd;
}        

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::TFtpSocketServerFactory
#
#   Purpose....: Socket server factory constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServerFactory::Init(bool ReadOnly)
{
    user = new TFtpUserFactory;
    pass = new TFtpPassFactory;
    pwd = new TFtpPwdFactory;
    syst = new TFtpSystFactory;
    pasv = new TFtpPasvFactory;
    port = new TFtpPortFactory;
    list = new TFtpListFactory;
    cwd = new TFtpCwdFactory;
    cdup = new TFtpCdupFactory;
    type = new TFtpTypeFactory;
    retr = new TFtpRetrFactory;
    quit = new TFtpQuitFactory;

    if (ReadOnly)
    {
        stor = 0;
        mdtm = 0;
        dele = 0;
        mkd = 0;
        rmd = 0;
    }
    else
    {
        stor = new TFtpStorFactory;
        mdtm = new TFtpMdtmFactory;
        dele = new TFtpDeleFactory;
        mkd = new TFtpMkdFactory;
        rmd = new TFtpRmdFactory;
    }

    FList = 0;
    FMyIp = 0;
    FLocalPort = 0;
    OnCommand = 0;
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::Create
#
#   Purpose....: Create a socket server instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *TFtpSocketServerFactory::Create(TTcpSocket *Socket)
{
    TFtpSocketServer *server;
    server = new TFtpSocketServer(FList, "FTP", 0x2000, Socket);
    server->FLocalPort = FLocalPort;
    server->OnCommand = OnCommand;
    server->FMyIp = FMyIp;

    return server;
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::AddUser
#
#   Purpose....: Create a socket server instance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServerFactory::AddUser(const char *User, const char *Passw, const char *RootDir)
{
    TFtpUser *user = new TFtpUser(User, Passw, RootDir);

    user->FNext = FList;
    FList = user;
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::SetMyIp
#
#   Purpose....: Set IP-address
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServerFactory::SetMyIp(long Ip)
{
    FMyIp = Ip;
}

/*##########################################################################
#
#   Name       : TFtpSocketServerFactory::SetDataPort
#
#   Purpose....: Set default data port
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFtpSocketServerFactory::SetDataPort(int Port)
{
    FLocalPort = Port;
}
