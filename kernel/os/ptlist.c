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

extern void __far InitTasking();

int MaxRows = 25;
int MaxCols = 80;
int CurrRow = 0;
int StartRow = 0;
int Suspend = FALSE;

/*##########################################################################
#
#   Name       : WriteEmpty
#
#   Purpose....: Write empty row
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void WriteEmpty()
{
    int i;

    RdosSetForeColor(7);
    RdosSetBackColor(0);

    for (i = 0; i < 80; i++)
        RdosWriteChar(' ');
}

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
void WriteOne(int Row, struct RdosThreadActionState *State)
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

    if (Row == CurrRow - StartRow)
    {
        RdosSetForeColor(0);
        RdosSetBackColor(7);

        if (Suspend)
            RdosSuspendAndSignalThread(State->ID);
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

    if (State->Action[0])
    {
        for (len = 0; len < 20 && State->Action[len]; len++)
            str[len] = State->Action[len];

        str[len] = ' ';
        len++;

        str[len] = '(';
        len++;

        i = 0;
        while (len < 20 + 12 && State->List[i])
        {
            str[len] = State->List[i];
            len++;
            i++;
        }

        str[len] = ')';
        len++;
    
        for (i = len; i < 20 + 13; i++)
            str[i] = ' ';

        str[20+13] = 0;
        RdosWriteString(str);
    }
    else
    {
        memcpy(str, State->List, 20);
        str[20] = 0;
        len = strlen(str);

        for (i = len; i < 20; i++)
            str[i] = ' ';

        RdosWriteString(str);

        if (State->Pos.Sel)
        {
            sprintf(str, "%04hX:", State->Pos.Sel);
            RdosWriteString(str);

            sprintf(str, "%08lX", State->Pos.Offset);
            RdosWriteString(str);
        }
        else
        {
            if (State->UserCount > 1)
            {
                sprintf(str, "%04hX:", State->UserCall[0].Sel);
                RdosWriteString(str);

                sprintf(str, "%08lX", State->UserCall[0].Offset);
                RdosWriteString(str);
            }
            else
                RdosWriteString("             ");
        }
    }
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
    struct RdosThreadActionState state;
    int row;
    int absrow;
    int lastrow;
    int WaitHandle = RdosCreateWait();
    int ThreadCount;
    char key[4];
    int val;

    RdosGetTextSize(&MaxRows, &MaxCols);

    RdosAddWaitForKeyboard(WaitHandle, 1);

    Suspend = FALSE;

    for (;;)
    {
        ThreadCount = RdosGetThreadCount();

        row = 0;
        for (i = 0; i < ThreadCount; i++)
        {
            if (RdosGetThreadActionState(i, &state))
            {            
                absrow = row - StartRow;
                if (absrow < MaxRows && absrow >= 0)
                {
                    lastrow = absrow;
                    WriteOne(absrow, &state);
                }
                row++;
            }
        }

        Suspend = FALSE;

        for (i = lastrow + 1; i < MaxRows; i++)
            WriteEmpty();

        RdosWaitTimeout(WaitHandle, 100);

        if (RdosPollKeyboard())
        {
            val = RdosReadKeyboard(); 
            memcpy(key, &val, 4);

            switch(key[0])
            {
                case 0:
                    switch (key[1])
                    {
                        case 72:
                            if (CurrRow > 0)
                                CurrRow--;
                            break;

                        case 80:
                            CurrRow++;
                            break;
                    }
                    break;

                case 's':
                case 'S':
                    Suspend = TRUE;
                    break;
            }
               
            if (CurrRow < MaxRows - 10)
                StartRow = 0;
            else
                StartRow = CurrRow - MaxRows + 10;
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
    return 0;
}
