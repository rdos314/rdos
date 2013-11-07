/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2012, Leif Ekblad
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
# ptlist.c
# Thread list process
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "rdosdev.h"

#define FALSE   0
#define TRUE    !FALSE

extern void InitTasking();

int CurrRow = 0;
int StartRow = 0;

/*##########################################################################
#
#   Name       : WriteOne
#
#   Purpose....: Write one thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void WriteOne(int Row, ThreadState *State)
{
    char str[40];
    int len;
    int day;
    int hour;
    int min;
    int sec;
    int milli;
    int micro;
    int started;
    int i;

    if (Row == CurrRow)
    {
        RdosSetForeColor(0);
        RdosSetBackColor(7);
    }
    else
    {
        RdosSetForeColor(7);
        RdosSetBackColor(0);
    }
            
    RdosSetCursorPosition(Row, 0);

    sprintf(str, "%04hX ", State->ID);
    RdosWriteString(str);

    memcpy(str, State->Name, 20);
    str[20] = 0;
    len = strlen(str);

    for (i = len; i < 20; i++)
    str[i] = ' ';

    RdosWriteString(str);

    day = State->MsbTime / 24;
    hour = State->MsbTime % 24;
    RdosDecodeLsbTics(State->LsbTime, &min, &sec, &milli, &micro);

    started = FALSE;
    if (day)
    {
        sprintf(str, "%3d ", day);
        RdosWriteString(str);
        started = TRUE;
    }
    else
        RdosWriteString("    ");

    if (hour || started)
    {
        if (started)
            sprintf(str, "%02d.", hour);
        else
            sprintf(str, "%2d.", hour);
        RdosWriteString(str);
        started = TRUE;
    }
    else
        RdosWriteString("   ");

    if (min || started)
    {
        if (started)
            sprintf(str, "%02d.", min);
        else
            sprintf(str, "%2d.", min);
        RdosWriteString(str);
        started = TRUE;
    }
    else
        RdosWriteString("   ");

    if (sec || started)
    {
        if (started)
            sprintf(str, "%02d,", sec);
        else
            sprintf(str, "%2d,", sec);
        RdosWriteString(str);
        started = TRUE;
    }
    else
        RdosWriteString("   ");

    if (milli || started)
    {
        if (started)
            sprintf(str, "%03d ", milli);
        else
            sprintf(str, "%3d ", milli);
        RdosWriteString(str);
        started = TRUE;
    }
    else
        RdosWriteString("    ");

    if (started)
        sprintf(str, "%03d ", micro);
    else
        sprintf(str, "%3d ", micro);
    RdosWriteString(str);

    memcpy(str, State->List, 20);
    str[20] = 0;
    len = strlen(str);

    for (i = len; i < 20; i++)
        str[i] = ' ';

    RdosWriteString(str);

    if (State->Sel)
    {
        sprintf(str, "%04hX:", State->Sel);
        RdosWriteString(str);

        sprintf(str, "%08lX", State->Offset);
        RdosWriteString(str);
    }
    else
        RdosWriteString("             ");
}
    
/*##########################################################################
#
#   Name       : ProcessHandler
#
##########################################################################*/
#pragma aux ProcessHandler "*" rdosdev parm routine
void ProcessHandler()
{
    int i;
    ThreadState state;
    int row;
    int absrow;
    int WaitHandle = RdosCreateWait();
    int key;

    RdosAddWaitForKeyboard(WaitHandle, 1);

    for (;;)
    {
        row = 0;
        for (i = 0; i < 256; i++)
        {
            if (RdosGetThreadState(i, &state))
            {            
                absrow = row - StartRow;
                if (absrow < 25 && absrow >= 0)
                {
                    WriteOne(absrow, &state);
                }
                row++;
            }
        }

        RdosWaitTimeout(WaitHandle, 100);

        if (RdosPollKeyboard())
        {
            key = RdosReadKeyboard(); 
        }
    }
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
    RdosHookInitTasking(&InitTasking);
}
