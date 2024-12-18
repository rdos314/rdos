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
# interact.cpp
# User interaction class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>

#include "interact.h"
#include "rdos.h"

#include "file.h"
#include "path.h"
#include "env.h"

#define MAX_X   79
#define MAX_Y   24
#define MAX_HISTORY 100

#define STACK_SIZE      0x2000

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TInteract::TInteract
#
#   Purpose....: TInteract constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TInteract::TInteract(TKeyboardDevice *Keyboard)
{
    FEcho = true;
    FBatHandle = 0;
    FKeyboard = Keyboard;
}

/*##########################################################################
#
#   Name       : TInteract::TInteract
#
#   Purpose....: Copy constructor for TInteract
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TInteract::TInteract(const TInteract &src)
{
    FEcho = true;
    FBatHandle = src.FBatHandle;
    FKeyboard = src.FKeyboard;
}

/*##########################################################################
#
#   Name       : TInteract::~TInteract
#
#   Purpose....: TInteract destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TInteract::~TInteract()
{
}

/*##########################################################################
#
#   Name       : TInteract::GetKeyboard
#
#   Purpose....: Get keyboard
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TKeyboardDevice *TInteract::GetKeyboard()
{
    return FKeyboard;
}

/*##########################################################################
#
#   Name       : TInteract::SetEchoOn
#
#   Purpose....: Set Echo state to on
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInteract::SetEchoOn()
{
    FEcho = true;
}

/*##########################################################################
#
#   Name       : TInteract::SetEchoOff
#
#   Purpose....: Set Echo state to off
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInteract::SetEchoOff()
{
    FEcho = false;
}

/*##########################################################################
#
#   Name       : TInteract::IsEchoOn
#
#   Purpose....: Check if echo is on
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TInteract::IsEchoOn()
{
    return FEcho;
}

/*################## TInteract::FormatTime ##########################
 *   Purpose....: Format time                                                                            #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *##########################################################################*/
TString TInteract::FormatTime(TDateTime &time)
{
    char str[40];
    sprintf(str, "%02d.%02d.%02d,%03d", time.GetHour(), time.GetMin(), time.GetSec(), time.GetMilliSec());
    return TString(str);
}

/*################## TInteract::FormatLongDate ##########################
 *   Purpose....: Format long date                                                                       #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *##########################################################################*/
TString TInteract::FormatLongDate(TDateTime &date)
{
    char str[40];
    sprintf(str, "%04d-%02d-%02d", date.GetYear(), date.GetMonth(), date.GetDay());
    return TString(str);
}

/*##########################################################################
#
#   Name       : TInteract::ReadCon
#
#   Purpose....: Read a string from console
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TInteract::ReadCon(char *str, int maxsize)
{
    int OrgX;
    int OrgY;
    int CurrX;
    int CurrY;
    int ExtKey;
    int State;
    int VirtKey;
    int ScanCode;
    int Count = 0;
    int CurrPos = 0;
    int i;
    int Insert = TRUE;
    TString prev;
    const char *prevstr;
    int ok;
    int GetNext = FALSE;

    if (FHistory.GotoFirst())
        prev = FHistory.Get();

    prevstr = prev.GetData();

    RdosGetConsoleCursorPosition(&OrgY, &OrgX);
    CurrX = OrgX;
    CurrY = OrgY;

    memset(str, 0, maxsize);

    for (;;)
    {
        FKeyboard->WaitForever();

        ok = FKeyboard->ReadEvent(&ExtKey, &State, &VirtKey, &ScanCode);
        if (ok)
            ok = FKeyboard->IsStdKey(ExtKey, VirtKey);

        if (ok)
        {
            switch (VirtKey)
            {
                case VK_BACK:
                    if (Count && CurrPos)
                    {
                        if (Count == CurrPos)
                        {
                            str[CurrPos - 1] = 0;

                            if (CurrX)
                                CurrX--;
                            else
                            {
                                CurrX = MAX_X;
                                CurrY--;
                            }
                            RdosSetConsoleCursorPosition(CurrY, CurrX);
                            Write(' ');
                            RdosSetConsoleCursorPosition(CurrY, CurrX);
                        }
                        else
                        {
                            for (i = CurrPos - 1; i < Count; i++)
                                str[i] = str[i + 1];

                            if (CurrX)
                                CurrX--;
                            else
                            {
                                CurrX = MAX_X;
                                CurrY--;
                            }
                            RdosSetConsoleCursorPosition(CurrY, CurrX);
                            Write(&str[CurrPos - 1]);
                            Write(' ');
                            RdosSetConsoleCursorPosition(CurrY, CurrX);
                        }
                        CurrPos--;
                        Count--;
                        str[Count] = 0;
                    }
                    break;


                case VK_INSERT:
                    Insert = !Insert;
                    break;

                case VK_DELETE:
                    if (Count && CurrPos != Count)
                    {
                        for (i = CurrPos; i < Count; i++)
                            str[i] = str[i + 1];
                        Count--;
                        str[Count] = 0;
                        Write(&str[CurrPos]);
                        Write(' ');
                        RdosSetConsoleCursorPosition(CurrY, CurrX);
                    }
                    break;

                case VK_HOME:
                    if (CurrPos)
                    {
                        CurrX = OrgX;
                        CurrY = OrgY;
                        RdosSetConsoleCursorPosition(CurrY, CurrX);
                        CurrPos = 0;
                    }
                    break;

                case VK_END:
                    if (CurrPos != Count)
                    {
                        RdosSetConsoleCursorPosition(OrgY, OrgX);
                        Write(str);
                        RdosGetConsoleCursorPosition(&CurrY, &CurrX);
                    }
                    break;

                case VK_RETURN:
                    if (Count)
                    {
                        TString s(str);

                        if (FHistory.Find(s))
                            FHistory.RemoveCurrent();

                        FHistory.AddFirst(s);
                        if (FHistory.GetSize() >= MAX_HISTORY)
                            FHistory.RemoveLast();
                    }
                    Write("\r\n");
                    return TRUE;

                case VK_ESCAPE:
                    return FALSE;


                case VK_RIGHT:
                    if (CurrPos != Count)
                    {
                        CurrPos++;
                        if (CurrX == MAX_X)
                        {
                            CurrX = 1;
                            CurrY++;
                        }
                        else
                            CurrX++;
                        RdosSetConsoleCursorPosition(CurrY, CurrX);
                        break;
                    }

                case VK_F1:
                    if (CurrPos < strlen(prevstr))
                    {
                        str[CurrPos] = prevstr[CurrPos];
                        Write(str[CurrPos]);
                        RdosGetConsoleCursorPosition(&CurrY, &CurrX);
                        CurrPos++;
                        Count = CurrPos;
                        str[Count] = 0;
                    }
                    break;

                case VK_F3:
                    memset(str, ' ', Count);
                    RdosSetConsoleCursorPosition(OrgY, OrgX);
                    Write(str);

                    strcpy(str, prevstr);
                    RdosSetConsoleCursorPosition(OrgY, OrgX);
                    Write(str);
                    RdosGetConsoleCursorPosition(&CurrY, &CurrX);
                    Count = strlen(str);
                    CurrPos = Count;
                    break;

                case VK_UP:
                    if (GetNext)
                        ok = FHistory.GotoNext();
                    else
                    {
                        ok = FHistory.GotoFirst();
                        GetNext = TRUE;
                    }

                    if (ok)
                    {
                        memset(str, ' ', Count);
                        RdosSetConsoleCursorPosition(OrgY, OrgX);
                        Write(str);

                        prev = FHistory.Get();
                        prevstr = prev.GetData();
                        strcpy(str, prevstr);
                        RdosSetConsoleCursorPosition(OrgY, OrgX);
                        Write(str);
                        RdosGetConsoleCursorPosition(&CurrY, &CurrX);
                        Count = strlen(str);
                        CurrPos = Count;
                    }
                    break;

                case VK_DOWN:
                    if (FHistory.GotoPrev())
                    {
                        memset(str, ' ', Count);
                        RdosSetConsoleCursorPosition(OrgY, OrgX);
                        Write(str);

                        prev = FHistory.Get();
                        prevstr = prev.GetData();
                        strcpy(str, prevstr);
                        RdosSetConsoleCursorPosition(OrgY, OrgX);
                        Write(str);
                        RdosGetConsoleCursorPosition(&CurrY, &CurrX);
                        Count = strlen(str);
                        CurrPos = Count;
                    }
                    break;

                case VK_LEFT:
                    if (CurrPos)
                    {
                        CurrPos--;
                        if (CurrX)
                            CurrX--;
                        else
                        {
                            CurrX = MAX_X;
                            CurrY--;
                        }
                        RdosSetConsoleCursorPosition(CurrY, CurrX);
                    }
                    break;

                default:
                    ExtKey = ExtKey & 0xFF;
                    if (ExtKey >= ' ' && Count < maxsize - 1)
                    {
                        if (Insert && CurrPos != Count)
                        {
                            for (i = Count; i > CurrPos; i--)
                                str[i] = str[i - 1];
                            Count++;
                            str[CurrPos] = (char)ExtKey;
                            Write(str[CurrPos]);
                            RdosGetConsoleCursorPosition(&CurrY, &CurrX);
                            str[Count] = 0;
                            Write(&str[CurrPos + 1]);
                            RdosSetConsoleCursorPosition(CurrY, CurrX);
                        }
                        else
                        {
                            if (CurrPos == Count)
                                Count++;
                            str[CurrPos] = (char)ExtKey;
                            Write(str[CurrPos]);
                            RdosGetConsoleCursorPosition(&CurrY, &CurrX);
                            str[Count] = 0;
                        }
                        if (CurrX == 0)
                            OrgY--;
                        CurrPos++;
                    }
                    break;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TInteract::Write
#
#   Purpose....: Write character to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInteract::Write(char ch)
{
    write(1, &ch, 1);
}

/*##########################################################################
#
#   Name       : TInteract::Write
#
#   Purpose....: Write string to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInteract::Write(const char *str)
{
    write(1, str, strlen(str));
}

/*##########################################################################
#
#   Name       : TInteract::WriteError
#
#   Purpose....: Write character to standard error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInteract::WriteError(char ch)
{
    write(2, &ch, 1);
}

/*##########################################################################
#
#   Name       : TInteract::WriteError
#
#   Purpose....: Write string to standard error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInteract::WriteError(const char *str)
{
    write(2, str, strlen(str));
}

/*##########################################################################
#
#   Name       : TInteract::ReadCmd
#
#   Purpose....: Read a string from cmd input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TInteract::ReadCmd(char *str, int maxsize)
{
    char ch;
    int i;

    if (FBatHandle)
    {
        for (i = 0; i < maxsize; i++)
        {
            ch = 0;
            read(FBatHandle, &ch, 1);

            if (ch == 0 || ch == 0xa)
            {
                *str = 0;
                break;
            }
            else
            {
                *str = ch;
                str++;
            }
        }
        *str = 0;
        return TRUE;
    }
    else
        return ReadCon(str, maxsize);
}

/*##########################################################################
#
#   Name       : TInteract::Read
#
#   Purpose....: Read a string from standard input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TInteract::Read(char *str, int maxsize)
{
    return read(0, str, maxsize);
}
