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
# wdasync.cpp
# WD async supplementary class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "wdasync.h"
#include "wdmsg.h"

#define FALSE 0
#define TRUE !FALSE

#define COND_CONFIG         0x1
#define COND_SECTIONS       0x2
#define COND_LIBRARIES      0x4
#define COND_ALIAS          0x8
#define COND_THREAD         0x10
#define COND_THREAD_INFO    0x20
#define COND_TRACE          0x40
#define COND_BREAK          0x80
#define COND_WATCH          0x100
#define COND_USER           0x200
#define COND_TERMINATE      0x400
#define COND_EXCEPTION      0x800
#define COND_MSG            0x1000
#define COND_STOP           0x2000
#define COND_RUNNING        0x4000

/*##########################################################################
#
#   Name       : TWdAsyncFactory::TWdAsyncFactory
#
#   Purpose....: Supplementary async factory class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdAsyncFactory::TWdAsyncFactory(TWdSocketServerFactory *factory)
 : TWdSupplFactory(factory, "Asynch")
{
}

/*##########################################################################
#
#   Name       : TWdAsyncFactory::~TWdAsyncFactory
#
#   Purpose....: Supplementary async factory class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdAsyncFactory::~TWdAsyncFactory()
{
}

/*##########################################################################
#
#   Name       : TWdAsyncFactory::Create
#
#   Purpose....: Create service
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSupplService *TWdAsyncFactory::Create(TWdSocketServer *server)
{
    return new TWdAsyncService(server);
}

/*##########################################################################
#
#   Name       : TWdAsyncService::TWdAsyncService
#
#   Purpose....: Supplementary thread service class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdAsyncService::TWdAsyncService(TWdSocketServer *Server)
 : TWdSupplService(Server)
{
}

/*##########################################################################
#
#   Name       : TWdAsyncService::~TWdAsyncService
#
#   Purpose....: Supplementary thread service class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdAsyncService::~TWdAsyncService()
{
}

/*##########################################################################
#
#   Name       : TWdAsyncService::ReqAsyncGo
#
#   Purpose....: Req run program
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdAsyncService::ReqAsyncGo()
{
    int ok;
    short int CondFlags = COND_THREAD_INFO;
    TDebug *debug = GetDebug();
    TDebugThread *curr = 0;

    if (debug)
    {
        curr = debug->GetCurrentThread();
        ok = debug->AsyncGo(250);

        if (ok)
        {
            if (debug->IsTerminated())
                CondFlags |= COND_TERMINATE;

            if (debug->HasThreadChange())
            {
                debug->ClearThreadChange();
                CondFlags |= COND_THREAD;
                curr = debug->GetCurrentThread();
                SetCurrentThread(curr);
            }

            if (debug->HasModuleChange())
            {
                debug->ClearModuleChange();
                CondFlags |= COND_LIBRARIES;
            }

            if (curr)
            {
                if (curr->HasBreakOccurred())
                    CondFlags |= COND_BREAK;

                if (curr->HasTraceOccurred())
                    CondFlags |= COND_WATCH;

                if (curr->HasFaultOccurred())
                    CondFlags |= COND_EXCEPTION;
            }                
        }
        else
            CondFlags = COND_RUNNING;
    }                   

    if (curr && ok)
    {
        PutDword(curr->Esp);
        PutWord((short int)curr->Ss);

        PutDword(curr->Eip);
        PutWord((short int)curr->Cs);

        PutWord(CondFlags);
    }
    else
        {
        PutDword(0);
        PutWord(0);    

        PutDword(0);
        PutWord(0);   

        PutWord(CondFlags);
    }
}

/*##########################################################################
#
#   Name       : TWdAsyncService::ReqProgStep
#
#   Purpose....: Req step program
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdAsyncService::ReqAsyncStep()
{
        short int CondFlags = COND_THREAD_INFO;
        TDebug *debug = GetDebug();
        TDebugThread *curr = 0;

        if (debug)
        {
        curr = debug->GetCurrentThread();
                debug->Trace();

                if (debug->IsTerminated())
                        CondFlags |= COND_TERMINATE;

                if (debug->HasThreadChange())
                {
                        debug->ClearThreadChange();
                        CondFlags |= COND_THREAD;
                        curr = debug->GetCurrentThread();
                        SetCurrentThread(curr);
                }

                if (debug->HasModuleChange())
                {
                        debug->ClearModuleChange();
                        CondFlags |= COND_LIBRARIES;
                }

                if (curr)
                {
                        if (curr->HasBreakOccurred())
                                CondFlags |= COND_BREAK;

                        if (curr->HasTraceOccurred())
                                CondFlags |= COND_TRACE;

            if (curr->HasFaultOccurred())
                CondFlags |= COND_EXCEPTION;                
        }
    }                   

    if (curr)
    {
        PutDword(curr->Esp);
        PutWord((short int)curr->Ss);

        PutDword(curr->Eip);
        PutWord((short int)curr->Cs);

        PutWord(CondFlags);
    }
    else
    {
        PutDword(0);
        PutWord(0);    

        PutDword(0);
        PutWord(0);   

        PutWord(CondFlags);
    }
}

/*##########################################################################
#
#   Name       : TWdAsyncService::ReqAsyncPoll
#
#   Purpose....: Req poll running app
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdAsyncService::ReqAsyncPoll()
{
    int ok;
    short int CondFlags = COND_THREAD_INFO;
    TDebug *debug = GetDebug();
    TDebugThread *curr = 0;

    if (debug)
    {
        ok = debug->AsyncPoll(250);

        if (ok)
        {
            if (debug->IsTerminated())
                CondFlags |= COND_TERMINATE;

            if (debug->HasThreadChange())
            {
                debug->ClearThreadChange();
                CondFlags |= COND_THREAD;
                curr = debug->GetCurrentThread();
                SetCurrentThread(curr);
            }

            if (debug->HasModuleChange())
            {
                debug->ClearModuleChange();
                CondFlags |= COND_LIBRARIES;
            }

            if (curr)
            {
                if (curr->HasBreakOccurred())
                    CondFlags |= COND_BREAK;

                if (curr->HasTraceOccurred())
                    CondFlags |= COND_WATCH;

                if (curr->HasFaultOccurred())
                    CondFlags |= COND_EXCEPTION;
            }                
        }
        else
            CondFlags = COND_RUNNING;
    }                   

    if (curr && ok)
    {
        PutDword(curr->Esp);
        PutWord((short int)curr->Ss);

        PutDword(curr->Eip);
        PutWord((short int)curr->Cs);

        PutWord(CondFlags);
    }
    else
    {
        PutDword(0);
        PutWord(0);    

        PutDword(0);
        PutWord(0);   

        PutWord(CondFlags);
    }
}

/*##########################################################################
#
#   Name       : TWdAsyncService::ReqAsyncStop
#
#   Purpose....: Req stop running thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdAsyncService::ReqAsyncStop()
{
    PutDword(0);
    PutWord(0);    

    PutDword(0);
    PutWord(0);   

    PutWord(COND_TERMINATE);
}

/*##########################################################################
#
#   Name       : TWdAsyncService::ReqError
#
#   Purpose....: Req error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdAsyncService::ReqError()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdAsyncService::NotifyMsg
#
#   Purpose....: Notify msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdAsyncService::NotifyMsg()
{
    char ch;

    ch = GetByte();

    switch (ch)
    {
        case 0:
            ReqAsyncGo();
            break;

        case 1:
            ReqAsyncStep();
            break;

        case 2:
            ReqAsyncPoll();
            break;

        case 3:
            ReqAsyncStop();
            break;

        default:
            ReqError();
            break;
    }
}
