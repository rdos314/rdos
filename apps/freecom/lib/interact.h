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
