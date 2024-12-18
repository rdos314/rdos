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
# session.h
# Session class
#
########################################################################*/

#ifndef _SESSION_H
#define _SESSION_H

#include "cmd.h"
#include "cmdfact.h"
#include "part.h"
#include "strlist.h"
#include "keyboard.h"
#include "sigdev.h"
#include "interact.h"

class TArg;

class TSession : public TInteract
{
public:
    TSession(TKeyboardDevice *Keyboard);
    TSession(const TSession &source);
    virtual ~TSession();

    virtual void DisplayPrompt();
    virtual void Run();

    void Run(const char *param);
    int Run(const char *name, TArg *ArgList);

protected:
    void WriteWelcome();

    const char *GetArg(int ArgNr);
    TString ExpandParam(const char *param);

    TString FName;
    TArg *FArgList;

    static int Count;

};

#endif
