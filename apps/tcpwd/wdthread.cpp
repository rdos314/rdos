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
# wdthread.cpp
# WD thread supplementary class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "wdthread.h"
#include "wdmsg.h"

#define FALSE 0
#define TRUE !FALSE

#define THD_WAIT        2
#define THD_SIGNAL      3
#define THD_KEYBOARD    4
#define THD_BLOCKED     5
#define THD_RUN         6

/*##########################################################################
#
#   Name       : TWdThreadFactory::TWdThreadFactory
#
#   Purpose....: Supplementary thread factory class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdThreadFactory::TWdThreadFactory(TWdSocketServerFactory *factory)
 : TWdSupplFactory(factory, "Threads")
{
}

/*##########################################################################
#
#   Name       : TWdThreadFactory::~TWdThreadFactory
#
#   Purpose....: Supplementary thread factory class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdThreadFactory::~TWdThreadFactory()
{
}

/*##########################################################################
#
#   Name       : TWdThreadFactory::Create
#
#   Purpose....: Create service
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSupplService *TWdThreadFactory::Create(TWdSocketServer *server)
{
    return new TWdThreadService(server);
}

/*##########################################################################
#
#   Name       : TWdThreadService::TWdThreadService
#
#   Purpose....: Supplementary thread service class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdThreadService::TWdThreadService(TWdSocketServer *Server)
 : TWdSupplService(Server)
{
}

/*##########################################################################
#
#   Name       : TWdThreadService::~TWdThreadService
#
#   Purpose....: Supplementary thread service class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdThreadService::~TWdThreadService()
{
}

/*##########################################################################
#
#   Name       : TWdThreadService::ReqGetNext
#
#   Purpose....: Req get next thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdThreadService::ReqGetNext()
{
    int id;
    char list = 0;
    int ok;
    int i;
    ThreadState state;
    TDebug *Debug = GetDebug();
    
    id = GetDword();

    if (Debug)
        id = Debug->GetNextThread(id);
    else
        id = 0;

    if (id)
    {

        ok = FALSE;
    
        for (i = 0; i < 256 && !ok; i++)
        {
            RdosGetThreadState(i, &state);
            if (state.ID == id)
                ok = TRUE;
        }

        if (ok)
        {
            list = THD_BLOCKED;

            if (strstr(state.List, "Ready"))
                list = THD_RUN;

            if (strstr(state.List, "Run"))
                list = THD_RUN;
                
            if (strstr(state.List, "Debug"))
                list = 0;
                
            if (strstr(state.List, "Wait"))
                list = THD_WAIT;

            if (strstr(state.List, "Signal"))
                list = THD_SIGNAL;

            if (strstr(state.List, "Keyboard"))
                list = THD_KEYBOARD;
        }
    }
    
    PutDword(id);
    PutByte(list);
}

/*##########################################################################
#
#   Name       : TWdThreadService::ReqSet
#
#   Purpose....: Req set current thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdThreadService::ReqSet()
{
    TDebugThread *t;
    int oldid = 0;
    int newid = 0;
    int status = MSG_NO_THREAD;
    TDebug *Debug = GetDebug();

    if (Debug)
    {
        t = Debug->GetCurrentThread();
        if (t)
        {
            oldid = t->ThreadID;
            newid = GetDword();
            status = 0;

            if (newid)
                Debug->SetCurrentThread(newid);
        }
    }

    PutDword(status);
    PutDword(oldid);
}

/*##########################################################################
#
#   Name       : TWdThreadService::ReqFreeze
#
#   Purpose....: Req freeze 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdThreadService::ReqFreeze()
{
//    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdThreadService::ReqThaw
#
#   Purpose....: Req thaw
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdThreadService::ReqThaw()
{
//    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdThreadService::ReqGetExtra
#
#   Purpose....: Req get extra
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdThreadService::ReqGetExtra()
{
    int ThreadID;
    TDebugThread *t;
    TDebug *Debug = GetDebug();

    ThreadID = GetDword();

    if (ThreadID)
    {
        if (Debug)
        {
            t = Debug->LockThread(ThreadID);

            if (t)
                PutString(t->ThreadName.GetData());

            Debug->UnlockThread();
        }
    }
    else
        PutString("Thread header");
}

/*##########################################################################
#
#   Name       : TWdThreadService::ReqError
#
#   Purpose....: Req error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdThreadService::ReqError()
{
    _asm int 3
}

/*##########################################################################
#
#   Name       : TWdThreadService::NotifyMsg
#
#   Purpose....: Notify msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdThreadService::NotifyMsg()
{
    char ch;

    ch = GetByte();

    switch (ch)
    {
        case 0:
            ReqGetNext();
            break;

        case 1:
            ReqSet();
            break;

        case 2:
                        ReqFreeze();
            break;

        case 3:
            ReqThaw();
            break;

        case 4:
            ReqGetExtra();
            break;

        default:
            ReqError();
            break;
    }
}
