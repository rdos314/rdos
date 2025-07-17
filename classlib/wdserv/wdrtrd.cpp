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
# wdrtrd.cpp
# WD non-blocking thread supplementary class
#
########################################################################*/

#include <ctype.h>
#include <stdio.h>
#include <string.h>

#include "rdos.h"
#include "wdrtrd.h"
#include "wdmsg.h"

#define FALSE 0
#define TRUE !FALSE

#define THD_WAIT        2
#define THD_SIGNAL      3
#define THD_KEYBOARD    4
#define THD_BLOCKED     5
#define THD_RUN         6
#define THD_DEBUG       7

#define INFO_TYPE_NONE       0
#define INFO_TYPE_NAME       1
#define INFO_TYPE_STATE      2
#define INFO_TYPE_CS_EIP     3
#define INFO_TYPE_EXTRA      4

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
#   Name       : TWdRunThreadFactory::TWdRunThreadFactory
#
#   Purpose....: Supplementary thread factory class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdRunThreadFactory::TWdRunThreadFactory(TWdSocketServerFactory *factory)
 : TWdSupplFactory(factory, "RunThread")
{
}

/*##########################################################################
#
#   Name       : TWdRunThreadFactory::~TWdRunThreadFactory
#
#   Purpose....: Supplementary thread factory class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdRunThreadFactory::~TWdRunThreadFactory()
{
}

/*##########################################################################
#
#   Name       : TWdRunThreadFactory::Create
#
#   Purpose....: Create service
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdSupplService *TWdRunThreadFactory::Create(TWdSocketServer *server)
{
    return new TWdRunThreadService(server);
}

/*##########################################################################
#
#   Name       : TWdRunThreadService::TWdRunThreadService
#
#   Purpose....: Supplementary thread service class constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdRunThreadService::TWdRunThreadService(TWdSocketServer *Server)
 : TWdSupplService(Server)
{
}

/*##########################################################################
#
#   Name       : TWdRunThreadService::~TWdRunThreadService
#
#   Purpose....: Supplementary thread service class destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWdRunThreadService::~TWdRunThreadService()
{
}

/*##########################################################################
#
#   Name       : TWdRunThreadService::ReqInfo
#
#   Purpose....: Req info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdRunThreadService::ReqInfo()
{ 
    int row = GetWord();

    switch (row)
    {
        case 0:
            PutByte(INFO_TYPE_NAME);
            PutWord(25);
            PutString("ID   Name");
            return;

        case 1:
            PutByte(INFO_TYPE_EXTRA);
            PutWord(21);
            PutString("                Time");
            return;

        case 2:
            PutByte(INFO_TYPE_STATE);
            PutWord(10);
            PutString("State");
            return;

        case 3:
            PutByte(INFO_TYPE_CS_EIP);
            PutWord(15);            
            PutString("cs:eip");
            return;
    }
    PutByte(INFO_TYPE_NONE);
    PutWord(0);
    PutString("");
}

/*##########################################################################
#
#   Name       : TWdRunThreadService::ReqGetNext
#
#   Purpose....: Req get next thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdRunThreadService::ReqGetNext()
{
    int ThreadID;
    TDebugThread *t;
    char IdStr[10];
    TString NameStr;
    TDebug *Debug = GetDebug();
    
    ThreadID = GetDword();

    if (Debug)
    {
        PutDword(Debug->GetNextThread(ThreadID));
        sprintf(IdStr, "%04hX", ThreadID);
        t = Debug->LockThread(ThreadID);

        if (t)
            NameStr = TString(IdStr) + " " + t->ThreadName;
        else
            NameStr = TString(IdStr);
        
        PutString(NameStr.GetData());
        Debug->UnlockThread();
    }
    else
    {
        PutDword(0);
        PutString("");
    }
}

/*##########################################################################
#
#   Name       : TWdRunThreadService::ReqGetRuntime
#
#   Purpose....: Req get runtime info about thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdRunThreadService::ReqGetRuntime()
{
    int id;
    char list = THD_BLOCKED;
    int ok;
    int i;
    RdosThreadState State;
    char fullstr[50];
    char tempstr[10];
    int day;
    int hour;
    int min;
    int sec;
    int milli;
    int micro;
    int started;
    int CurrentThreads = RdosGetThreadCount();
    TDebug *Debug = GetDebug();
    
    id = GetDword();

    ok = FALSE;
    
    for (i = 0; i < CurrentThreads && !ok; i++)
    {
        RdosGetThreadState(i, &State);
        if (State.ID == id)
            ok = TRUE;
    }

    if (ok)
    {
        if (strstr(State.List, "Ready"))
            list = THD_RUN;

        if (strstr(State.List, "Run"))
            list = THD_RUN;
                
        if (strstr(State.List, "Debug"))
            list = THD_DEBUG;
                
        if (strstr(State.List, "Wait"))
            list = THD_WAIT;

        if (strstr(State.List, "Signal"))
            list = THD_SIGNAL;

        if (strstr(State.List, "Keyboard"))
            list = THD_KEYBOARD;

        PutByte(list);
        PutWord(State.Sel);
        PutDword(State.Offset);

        day = State.MsbTime / 24;
        hour = State.MsbTime % 24;
        RdosDecodeLsbTics(State.LsbTime, &min, &sec, &milli, &micro);

        started = FALSE;
        if (day)
        {
            sprintf(fullstr, "%3d ", day);
            started = TRUE;
        }
        else
            strcpy(fullstr, "    ");

        if (hour || started)
        {
            if (started)
                sprintf(tempstr, "%02d.", hour);
            else
                sprintf(tempstr, "%2d.", hour);
            strcat(fullstr, tempstr);
            started = TRUE;
        }
        else
            strcat(fullstr, "   ");

        if (min || started)
        {
            if (started)
                sprintf(tempstr, "%02d.", min);
            else
                sprintf(tempstr, "%2d.", min);
            strcat(fullstr, tempstr);
            started = TRUE;
        }
        else
            strcat(fullstr, "   ");

        if (sec || started)
        {
            if (started)
               sprintf(tempstr, "%02d,", sec);
            else
               sprintf(tempstr, "%2d,", sec);
            strcat(fullstr, tempstr);
            started = TRUE;
        }
        else
            strcat(fullstr, "   ");

        if (milli || started)
        {
            if (started)
                sprintf(tempstr, "%03d ", milli);
            else
                sprintf(tempstr, "%3d ", milli);
            strcat(fullstr, tempstr);
            started = TRUE;
        }
        else
            strcat(fullstr, "    ");

        if (started)
            sprintf(tempstr, "%03d", micro);
        else 
            sprintf(tempstr, "%3d", micro);
        strcat(fullstr, tempstr);

        PutString(fullstr);
    }
    else
    {
        PutByte(0);
        PutWord(0);
        PutDword(0);
        PutString("");
    }
}

/*##########################################################################
#
#   Name       : TWdRunThreadService::ReqPoll
#
#   Purpose....: Req poll execution state (new threads & modules)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdRunThreadService::ReqPoll()
{
    short int CondFlags = 0;
    TDebug *Debug = GetDebug();
    TDebugThread *curr = 0;

    if (Debug)
    {
        if (Debug->IsTerminated())
            CondFlags |= COND_TERMINATE;

        if (Debug->HasThreadChange())
        {
            CondFlags |= COND_THREAD;
            Debug->ClearThreadChange();
        }

        if (Debug->HasModuleChange())
            CondFlags |= COND_LIBRARIES;
    }
    PutWord(CondFlags);
}

/*##########################################################################
#
#   Name       : TWdRunThreadService::ReqSet
#
#   Purpose....: Req set current thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdRunThreadService::ReqSet()
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
            {
                Debug->SetCurrentThread(newid);
                t = Debug->GetCurrentThread();        
                SetCurrentThread(t);
            }
        }
    }

    PutDword(status);
    PutDword(oldid);
}

/*##########################################################################
#
#   Name       : TWdRunThreadService::ReqGetName
#
#   Purpose....: Req get name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdRunThreadService::ReqGetName()
{
    int ThreadID;
    TDebugThread *t;
    TDebug *Debug = GetDebug();
    char str[100];

    ThreadID = GetDword();

    if (ThreadID)
    {
        if (Debug)
        {
            t = Debug->LockThread(ThreadID);

            if (t)
            {
                sprintf(str, "%04hX %s", ThreadID, t->ThreadName.GetData());
                PutString(str);
            }

            Debug->UnlockThread();
        }
    }
    else
        PutString("Name");
}

/*##########################################################################
#
#   Name       : TWdRunThreadService::ReqStop
#
#   Purpose....: Req stop a thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdRunThreadService::ReqStop()
{
    int id;
    TDebug *Debug = GetDebug();
    
    id = GetDword();

    RdosSuspendThread(id);
}

/*##########################################################################
#
#   Name       : TWdRunThreadService::ReqSignalStop
#
#   Purpose....: Req signal & stop a thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdRunThreadService::ReqSignalStop()
{
    int id;
    TDebug *Debug = GetDebug();
    
    id = GetDword();

    RdosSuspendAndSignalThread(id);
}

/*##########################################################################
#
#   Name       : TWdRunThreadService::ReqError
#
#   Purpose....: Req error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdRunThreadService::ReqError()
{
}

/*##########################################################################
#
#   Name       : TWdRunThreadService::NotifyMsg
#
#   Purpose....: Notify msg
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWdRunThreadService::NotifyMsg()
{
    char ch;

    ch = GetByte();

    switch (ch)
    {
        case 0:
            DebugLog("TrInfo");
            ReqInfo();
            break;

        case 1:
            DebugLog("TrNext");
            ReqGetNext();
            break;

        case 2:
            DebugLog("TrRuntime");
            ReqGetRuntime();
            break;

        case 3:
            DebugLog("TrPoll");
            ReqPoll();
            break;

        case 4:
            DebugLog("TrSet");
            ReqSet();
            break;

        case 5:
            DebugLog("TrName");
            ReqGetName();
            break;

        case 6:
            DebugLog("TrStop");
            ReqStop();
            break;

        case 7:
            DebugLog("TrSignalStop");
            ReqSignalStop();
            break;

        default:
            char str[40];
            sprintf(str, "ThreadErr: %02hX", ch);
            LogMsg(str);
            ReqError();
            break;
    }
}
