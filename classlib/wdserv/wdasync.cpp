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
            SetCurrentThread(debug->GetCurrentThread());
            
            if (debug->IsTerminated())
                CondFlags |= COND_TERMINATE;

            if (debug->HasThreadChange())
            {
                CondFlags |= COND_THREAD;
                debug->ClearThreadChange();
            }

            if (debug->HasModuleChange())
                CondFlags |= COND_LIBRARIES;

            if (debug->HasConfigChange())
            {
                debug->ClearConfigChange();
                CondFlags |= COND_CONFIG;
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
    int ok;
    short int CondFlags = COND_THREAD_INFO;
    TDebug *debug = GetDebug();
    TDebugThread *curr = 0;

    if (debug)
    {
        curr = debug->GetCurrentThread();
        ok = debug->AsyncTrace(250);

        if (ok)
        {
            SetCurrentThread(debug->GetCurrentThread());
            
            if (debug->IsTerminated())
                CondFlags |= COND_TERMINATE;

            if (debug->HasThreadChange())
            {
                CondFlags |= COND_THREAD;
                debug->ClearThreadChange();
            }

            if (debug->HasModuleChange())
                CondFlags |= COND_LIBRARIES;

            if (debug->HasConfigChange())
            {
                debug->ClearConfigChange();
                CondFlags |= COND_CONFIG;
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
            SetCurrentThread(debug->GetCurrentThread());
            
            if (debug->IsTerminated())
                CondFlags |= COND_TERMINATE;

            if (debug->HasThreadChange())
            {
                CondFlags |= COND_THREAD;
                debug->ClearThreadChange();
            }

            if (debug->HasModuleChange())
                CondFlags |= COND_LIBRARIES;

            if (debug->HasConfigChange())
            {
                debug->ClearConfigChange();
                CondFlags |= COND_CONFIG;
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
    TDebug *debug = GetDebug();

//    if (debug)
//        debug->ExitAsync();

    PutDword(0);
    PutWord(0);    

    PutDword(0);
    PutWord(0);   

    PutWord(COND_STOP);
}

/*##########################################################################
#
#   Name       : TWdAsyncService::ReqAsyncAddBreak
#
#   Purpose....: Req add breakpoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdAsyncService::ReqAsyncAddBreak()
{
    TDebug *debug = GetDebug();
    long Offset = GetDword();
    int Sel = GetWord();
    int Local = GetByte();
    int Hw;
        
    if (Local)
        Hw = TRUE;
    else
    {
        if ((Sel & 3) == 0)
            Hw = TRUE;
        else
            Hw = FALSE;
    }

    if (debug)
        debug->AddBreak(Sel, Offset, Hw);
}

/*##########################################################################
#
#   Name       : TWdAsyncService::ReqAsyncRemoveBreak
#
#   Purpose....: Req remove breakpoint
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdAsyncService::ReqAsyncRemoveBreak()
{
    TDebug *debug = GetDebug();
    long Offset = GetDword();
    int Sel = GetWord();

    if (debug)
        debug->ClearBreak(Sel, Offset);
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
            DebugLog("AsyncGo");
            ReqAsyncGo();
            break;

        case 1:
            DebugLog("AsyncStep");
            ReqAsyncStep();
            break;

        case 2:
            DebugLog("AsyncPoll");
            ReqAsyncPoll();
            break;

        case 3:
            DebugLog("AsyncStop");
            ReqAsyncStop();
            break;

        case 4:
            DebugLog("AsyncAddBreak");
            ReqAsyncAddBreak();
            break;

        case 5:
            DebugLog("AsyncRemoveBreak");
            ReqAsyncRemoveBreak();
            break;

        default:
            char str[40];
            sprintf(str, "AsyncErr: %02hX", ch);
            LogMsg(str);
            ReqError();
            break;
    }
}
