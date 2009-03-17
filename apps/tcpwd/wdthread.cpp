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
    TDebug *Debug = GetDebug();
    
    id = GetDword();

    if (Debug)
        id = Debug->GetNextThread(id);
    else
        id = 0;

    PutDword(id);
    PutByte(0);    
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
    _asm int 3
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
    _asm int 3
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
    _asm int 3
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
