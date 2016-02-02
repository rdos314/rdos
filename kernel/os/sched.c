/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2011, Leif Ekblad
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
# sched.c
# Scheduler device
#
########################################################################*/

#include "rdos.h"
#include "rdosdev.h"
#include "string.h"

#define MAX_THREADS     256

#define FALSE 0
#define TRUE !FALSE

struct TKernelSection ThreadSection;

struct TThread
{
    int Valid;
    int Handle;
    int ID;
};

int  NextPid = 0;
struct TThread ThreadArr[MAX_THREADS];

extern void InitScheduler();
    
/*##########################################################################
#
#   Name       : ThreadCreated
#
##########################################################################*/
#pragma aux ThreadCreated "*" rdosdev parm routine [eax] value [eax]
int ThreadCreated(int handle)
{
    int i;
    int pid;

    RdosEnterKernelSection(&ThreadSection);    

    NextPid++;
    pid = NextPid;

    for (i = 0; i < MAX_THREADS; i++)
    {
        if (!ThreadArr[i].Valid)
        {
            ThreadArr[i].Valid = TRUE;
            ThreadArr[i].Handle = handle;
            ThreadArr[i].ID = pid;
            break;
        }
    }

    RdosLeaveKernelSection(&ThreadSection);    

    return pid;
}
    
/*##########################################################################
#
#   Name       : ThreadTerminated
#
##########################################################################*/
#pragma aux ThreadTerminated "*" rdosdev parm routine [eax]
void ThreadTerminated(int handle)
{
    int i;

    RdosEnterKernelSection(&ThreadSection);    

    for (i = 0; i < MAX_THREADS; i++)
    {
        if (ThreadArr[i].Valid && ThreadArr[i].Handle == handle) 
        {
            ThreadArr[i].Valid = FALSE;
            break;
        }
    }

    RdosLeaveKernelSection(&ThreadSection);    
}
    
/*##########################################################################
#
#   Name       : Scheduler thread
#
##########################################################################*/
#pragma aux SchedulerThread "*" rdosdev parm routine [es edi]
void __far SchedulerThread(void *param)
{
    for (;;)
    {
        RdosWaitMilli(250);
    }
}

/*##########################################################################
#
#   Name       : InitThreadList
#
#   Purpose....: Init thread lists
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void InitThreadList()
{
    int i;

    for (i = 0; i < MAX_THREADS; i++)
        ThreadArr[i].Valid = FALSE;
        
    RdosInitKernelSection(&ThreadSection);
}

/*##########################################################################
#
#   Name       : InitTasking
#
#   Purpose....: Init tasking callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux InitTasking "*" rdosdev parm routine
void __far InitTasking()
{
    RdosCreateKernelThread(5, 0x1000, &SchedulerThread, "Scheduler", 0);
} 

/*##########################################################################
#
#   Name       : main
#
#   Purpose....: Initialization
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main()
{
    InitScheduler();
    InitThreadList();
    RdosHookInitTasking(&InitTasking);
}
