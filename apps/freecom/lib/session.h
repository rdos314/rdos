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

#include "file.h"
#include "cmdfact.h"
#include "part.h"
#include "strlist.h"
#include "keyboard.h"

class TSession
{
public:
    TSession();
    ~TSession();

    void Run();
    
    void Write(char ch);
    void Write(const char *str);

    void WriteError(char ch);
    void WriteError(const char *str);

    void WriteLong(long Value);

    char Read();
    int Read(char *str, int maxsize);
    int ReadCmd(char *str, int maxsize);

    void DisplayPrompt();
    int ReadCon(char *str, int maxsize);

    void SetCmdFile(TFile *File);
    void SetInputFile(TFile *File);
    void SetOutputFile(TFile *File);
    void SetErrorFile(TFile *File);

	TFile *GetCmdFile();
    TFile *GetInputFile();
    TFile *GetOutputFile();
    TFile *GetErrorFile();

protected:
    void WriteWelcome();
    TString FormatTime(TDateTime &time);
    TString FormatLongDate(TDateTime &date);

    TFile *FCmdFile;
    TFile *FInputFile;
    TFile *FOutputFile;
    TFile *FErrorFile;

    static Count;
    static TStringList *History;
    static TKeyboardDevice *Keyboard;

};

#endif
