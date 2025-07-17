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
# parttool.h
# Partition tool command class
#
########################################################################*/

#ifndef _PARTTOOL_H
#define _PARTTOOL_H

#include "cmd.h"
#include "cmdfact.h"
#include "disccmd.h"

class TPartToolFactory : public TCommandFactory
{
public:
    TPartToolFactory();
    virtual TCommand *Create(TSession *session, const char *param);

protected:
};

class TPartToolInteract : public TInteract
{
public:
    TPartToolInteract(TKeyboardDevice *Keyboard);
    ~TPartToolInteract();

    void Setup(int DiscNr);

    virtual void DisplayPrompt();
    virtual void Run();

protected:
    void RunDisc(const char *param);

    int FDiscNr;
};

class TPartToolDisc : public TVfsDiscCmd
{
public:
    TPartToolDisc(TPartToolInteract *interact, int disc, const char *cmd);
    virtual ~TPartToolDisc();

    virtual void NotifyDone();
    virtual void NotifyMsg(const char *msg);

protected:
    TPartToolInteract *FInteract;
};

class TPartToolCommand : public TCommand
{
public:
    TPartToolCommand(TSession *session, const char *param);
    ~TPartToolCommand();

    virtual int Execute(char *param);

protected:
    TPartToolInteract FInteract;
};

#endif
