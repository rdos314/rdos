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
# cmdfact.h
# Command factory base class
#
########################################################################*/

#ifndef _CMDFACT_H
#define _CMDFACT_H

#include "cmd.h"
#include "cmdout.h"

class TCommand;

class TCommandFactory
{
friend class THelpCommand;
public:
    TCommandFactory(const char *name);
    virtual ~TCommandFactory();

    static void Run(TCommandOutput *out, const char *line);

protected:
    static const char *FindArg(int no);
    static char *SkipWord(char *p);
    static TCommand *Parse(TCommandOutput *out, const char *line);

    virtual TCommand *Create(TCommandOutput *out, const char *param) = 0;
    virtual int PassAll();
    virtual int PassDir();
	
    void InsertCommand();
    void RemoveCommand();

    static TCommandFactory *FCmdList;

    TCommandFactory *FList;
    TString FName;
};

#endif
