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
# mwait.cpp
# Waitable device class
#
########################################################################*/

#include "mwait.h"

#include <rdos.h>

/*##########################################################################
#
#   Name       : TWaitObj::TWaitObj
#
#   Purpose....: Constructor for TWaitObj                                      
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitObj::TWaitObj()
{
    Init();
}

/*##########################################################################
#
#   Name       : TWaitObj::~TWaitObj
#
#   Purpose....: Destructor for TDevice                                   
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitObj::~TWaitObj()
{
    if (FWait)
        delete FWait;
}

/*##########################################################################
#
#   Name       : TWaitObj::Init
#
#   Purpose....: Init method for class
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWaitObj::Init()
{
    FWait = 0;
}

/*##########################################################################
#
#   Name       : TWaitObj::CreateWait
#
#   Purpose....: Create a local wait object
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWaitObj::CreateWait()
{       
    if (!FWait)
    {
        FWait = new TWait;
        FWait->Add(this);
    }
}

/*##########################################################################
#
#   Name       : TWaitObj::Remove
#
#   Purpose....: Remove wait
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWaitObj::Remove(TWait *Wait)
{
    RdosRemoveWait(Wait->GetHandle(), (int)this);
}

/*##########################################################################
#
#   Name       : TWaitObj::WaitForever
#
#   Purpose....: Wait forever
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitObj *TWaitObj::WaitForever()
{       
    if (!FWait)
        CreateWait();

    if (FWait)
        return FWait->WaitForever();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TWaitObj::WaitTimeout
#
#   Purpose....: Wait timeout
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitObj *TWaitObj::WaitTimeout(int MilliSec)
{       
    if (!FWait)
        CreateWait();

    if (FWait)
        return FWait->WaitTimeout(MilliSec);
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TWaitObj::WaitUntil
#
#   Purpose....: Wait until
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitObj *TWaitObj::WaitUntil(TDateTime &time)
{       
    if (!FWait)
        CreateWait();

    if (FWait)
        return FWait->WaitUntil(time);
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TWait::TWait
#
#   Purpose....: Constructor for TWait                                    
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWait::TWait()
 : FListSection("Wait.List")
{
    FHandle = RdosCreateWait();
    FWaitList = 0;
}

/*##########################################################################
#
#   Name       : TWait::~TWait
#
#   Purpose....: Destructor for TWait                                     
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWait::~TWait()
{
    TWaitList *ptr;

    while (FWaitList)
    {
        ptr = FWaitList->List;
        FWaitList->WaitDev->Remove(this);
        delete FWaitList;
        FWaitList = ptr;
    }

    RdosCloseWait(FHandle);
}

/*##########################################################################
#
#   Name       : TWait::GetHandle
#
#   Purpose....: Get wait handle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TWait::GetHandle()
{
    return FHandle;
}

/*##########################################################################
#
#   Name       : TWait::Add
#
#   Purpose....: Add a waitable object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWait::Add(TWaitObj *dev)
{
    TWaitList *entry = new TWaitList;
    
    dev->Add(this);

    FListSection.Enter();
    entry->WaitDev = dev;
    entry->List = FWaitList;
    FWaitList = entry;
    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TWait::Remove
#
#   Purpose....: Remove a waitable object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWait::Remove(TWaitObj *dev)
{
    TWaitList *ptr;
    TWaitList *prev;
        
    FListSection.Enter();   

    prev = 0;
    ptr = FWaitList;
    while (ptr && ptr->WaitDev != dev)
    {
        prev = ptr;
        ptr = ptr->List;
    }

    if (ptr->WaitDev == dev)
    {
        dev->Remove(this);

        if (prev == 0)
            FWaitList = FWaitList->List;
        else
            prev->List = ptr->List;

        delete ptr;
    }
    
    FListSection.Leave();
}

/*##########################################################################
#
#   Name       : TWait::Check
#
#   Purpose....: Check if signalled, and return signalled object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitObj *TWait::Check()
{
    return (TWaitObj *)RdosCheckWait(FHandle);
}

/*##########################################################################
#
#   Name       : TWait::WaitForever
#
#   Purpose....: Wait forever for object(s), and return signalled object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitObj *TWait::WaitForever()
{
    TWaitObj *Wait;

    Wait = (TWaitObj *)RdosWaitForever(FHandle);
    if (Wait)
        Wait->SignalNewData();

    return Wait;
}

/*##########################################################################
#
#   Name       : TWait::WaitTimeout
#
#   Purpose....: Wait with timeout for object(s), and return signalled object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitObj *TWait::WaitTimeout(int MilliSec)
{
    TWaitObj *Wait;

    Wait = (TWaitObj *)RdosWaitTimeout(FHandle, MilliSec);
    if (Wait)
        Wait->SignalNewData();

    return Wait;
}

/*##########################################################################
#
#   Name       : TWait::WaitUntil
#
#   Purpose....: Wait until for object(s), and return signalled object
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TWaitObj *TWait::WaitUntil(TDateTime &time)
{
    TWaitObj *Wait;

    Wait = (TWaitObj *)RdosWaitUntilTimeout(FHandle, time.GetMsb(), time.GetLsb());
    if (Wait)
        Wait->SignalNewData();

    return Wait;
}

/*##########################################################################
#
#   Name       : TWait::Abort
#
#   Purpose....: Abort wait from another thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TWait::Abort()
{
    RdosStopWait(FHandle);
}
