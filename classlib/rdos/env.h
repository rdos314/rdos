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
# env.h
# Environment handling
#
########################################################################*/

#ifndef _ENVC_H
#define _ENVC_H

class TEnvVar
{
friend class TEnv;
public:
    TEnvVar(const char *Name, const char *Value);
    ~TEnvVar();

    const char *GetName();
    const char *GetValue();

protected:
    char *FName;
    char *FValue;
    TEnvVar *Next;
};

class TEnv
{
friend class TEnvVar;
public:
    TEnv(int handle);
    ~TEnv();

	static TEnv *OpenSysEnv();
	static TEnv *OpenProcessEnv();

    void Add(const char *Name, const char *Value);
    void Delete(const char *Name);
    int Find(const char *Name, char *Value);

    TEnvVar *GotoFirst();
    TEnvVar *GotoNext();

protected:
	void Free();
	void Cache();

	int FHandle;
    TEnvVar *FVarList;
    TEnvVar *FCurrent;    
};

#endif

