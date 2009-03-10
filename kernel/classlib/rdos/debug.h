/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2009, Leif Ekblad
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
# debug.h
# Debug classes
#
########################################################################*/

#ifndef _DEBUG_H
#define _DEBUG_H

#include "thread.h"
#include "str.h"
#include "waitdev.h"

struct TCreateProcessEvent
{
    int FileHandle;
    int Handle;
    int Process;
    int Thread;
    unsigned int ImageBase;
    unsigned int ImageSize;
    unsigned int FsLinear;
    unsigned int StartEip;
    unsigned short StartCs;
};    

struct TCreateThreadEvent
{
    int Thread;
    unsigned int FsLinear;
    unsigned int StartEip;
    unsigned short StartCs;
};

struct TLoadDllEvent
{
    int FileHandle;
    int Handle;
    unsigned int ImageBase;
    unsigned int ImageSize;
};

struct TExceptionEvent
{
    int Code;
    unsigned int Ptr;
    unsigned int Eip;
    unsigned short Cs;
};    


class TDebugThread
{
public:
    TDebugThread(TCreateProcessEvent *event);
    TDebugThread(TCreateThreadEvent *event);
    ~TDebugThread();

    TString ThreadName;
    int ThreadID;
    unsigned int FsLinear;
    unsigned int Eip;
    unsigned short Cs;

    TDebugThread *Next;
        
};

class TDebug : public TWaitDevice
{
public:
	TDebug(const char *Program, const char *Param, const char *StartDir);
	~TDebug();

	virtual void DeviceName(char *Name, int MaxLen) const;

	TDebugThread *ThreadList;

protected:
	virtual void SignalNewData();
	virtual void Add(TWait *Wait);
	virtual void Execute();

    void HandleCreateProcess(TCreateProcessEvent *event);
    void HandleTerminateProcess(int exitcode);
    void HandleCreateThread(TCreateThreadEvent *event);
    void HandleTerminateThread(int thread);
	void HandleException(TExceptionEvent *event, int thread);
    void HandleLoadDll(TLoadDllEvent *event);

    TString FProgram;
    TString FParam;
	TString FStartDir;
	int FHandle;

};

#endif

