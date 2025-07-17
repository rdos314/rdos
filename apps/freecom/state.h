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
# state.h
# State command class
#
########################################################################*/

#ifndef _STATE_H
#define _STATE_H

#include "cmd.h"
#include "cmdfact.h"
#include "rdos.h" 

class TStateFactory : public TCommandFactory
{
public:
    TStateFactory();
    virtual TCommand *Create(TSession *session, const char *param);
};

class TStateCommand : public TCommand
{
public:
    TStateCommand(TSession *session, const char *param);

    virtual int Execute(char *param);       

protected:
    void InitOptions();
    virtual int OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg);

    void WriteOne(struct RdosThreadActionState *state);
    void WriteThreads();

    void WriteOneModule(int mid, const char *Name);
    void WriteOneModule(int pid, int mid, const char *Name);
    void WriteModules();

    void WriteOneProcess(int pid, const char *Name);

    void WritePrograms();
    void WriteProgramModules(int pid);
    void WriteModuleById(int mid);
    void WriteModuleById(int pid, int mid);
    void WriteThreadById(int tid);

    void WriteProcessById(int pid);
    void WriteProcessThreads(int pid);
    void WriteProgramProcesses(int pid);

    int FOptM;
    int FOptT;
    int FOptS;
    int FOptF;
    int FOptU;

    unsigned short int IdBuf[256];
    unsigned short int TIdBuf[256];
};

#endif
