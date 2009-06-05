/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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

