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
# interact.h
# User interaction class
#
########################################################################*/

#ifndef _INTERACT_H
#define _INTERACT_H

#include "strlist.h"
#include "keyboard.h"
#include "sigdev.h"

class TInteract
{
public:
    TInteract(TKeyboardDevice *Keyboard);
    TInteract(const TInteract &source);
    virtual ~TInteract();

    virtual void DisplayPrompt() = 0;
    virtual void Run() = 0;

    void SetEchoOn();
    void SetEchoOff();
    bool IsEchoOn();

    TKeyboardDevice *GetKeyboard();

    void Write(char ch);
    void Write(const char *str);

    void WriteError(char ch);
    void WriteError(const char *str);

    int Read(char *str, int maxsize);
    int ReadCmd(char *str, int maxsize);

    int ReadCon(char *str, int maxsize);

protected:
    TString FormatTime(TDateTime &time);
    TString FormatLongDate(TDateTime &date);

    bool FEcho;
    int FBatHandle;

    TStringList FHistory;
    TKeyboardDevice *FKeyboard;

};

#endif
