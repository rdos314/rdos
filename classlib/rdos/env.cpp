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
# env.cpp
# Environment handling
#
########################################################################*/

#include <string.h>
#include "rdos.h"
#include "env.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TEnvVar::TEnvVar
#
#   Purpose....: Constructor for TEnvVar
#
#   In params..: Var
#				 Val
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TEnvVar::TEnvVar(const char *var, const char *val)
{
	int size;

	size = strlen(var) + 1;
	FName = new char[size];
	memcpy(FName, var, size);

	size = strlen(val) + 1;
	FValue = new char[size];
	memcpy(FValue, val, size);
	
	Next = 0;
}

/*##########################################################################
#
#   Name       : TEnvVar::~TEnvVar
#
#   Purpose....: Destructor for TEnvVar
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TEnvVar::~TEnvVar()
{
	if (FName)
		delete FName;

	if (FValue)
		delete FValue;
}

/*##########################################################################
#
#   Name       : TEnvVar::GetName
#
#   Purpose....: Get var name
#
#   In params..: *
#   Out params.: *
#   Returns....: Name
#
##########################################################################*/
const char *TEnvVar::GetName()
{
	return FName;
}

/*##########################################################################
#
#   Name       : TEnvVar::GetValue
#
#   Purpose....: Get var value
#
#   In params..: *
#   Out params.: *
#   Returns....: Value
#
##########################################################################*/
const char *TEnvVar::GetValue()
{
	return FValue;
}

/*##########################################################################
#
#   Name       : TEnv::TEnv
#
#   Purpose....: Constructor for TEnv
#
#   In params..: Handle		environment handle
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TEnv::TEnv(int handle)
{
	FHandle = handle;
	FVarList = 0;
	FCurrent = 0;
}

/*##########################################################################
#
#   Name       : TEnv::~TEnv
#
#   Purpose....: Destructor for TEnv
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TEnv::~TEnv()
{
	Free();

	if (FHandle)
		RdosCloseEnv(FHandle);
}

/*##########################################################################
#
#   Name       : TEnv::Free
#
#   Purpose....: Free var list
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TEnv::Free()
{
	TEnvVar *Next;

	while (FVarList)
	{
		Next = FVarList->Next;
		delete FVarList;
		FVarList = Next;
	}
	FVarList = 0;
}

/*##########################################################################
#
#   Name       : TEnv::OpenSysEnv
#
#   Purpose....: Construct a sys env object
#
#   In params..: *
#   Out params.: *
#   Returns....: sys env object 
#
##########################################################################*/
TEnv *TEnv::OpenSysEnv()
{
	int handle;

	handle = RdosOpenSysEnv();
	if (handle)
		return new TEnv(handle);
	else
		return 0;
}

/*##########################################################################
#
#   Name       : TEnv::OpenProcessEnv
#
#   Purpose....: Construct a process env object
#
#   In params..: *
#   Out params.: *
#   Returns....: process env object 
#
##########################################################################*/
TEnv *TEnv::OpenProcessEnv()
{
	int handle;

	handle = RdosOpenProcessEnv();
	if (handle)
		return new TEnv(handle);
	else
		return 0;
}

/*##########################################################################
#
#   Name       : TEnv::Add
#
#   Purpose....: Add a new variable
#
#   In params..: var
#				 val
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TEnv::Add(const char *Name, const char *Value)
{
	if (FHandle)
		RdosAddEnvVar(FHandle, Name, Value);
}

/*##########################################################################
#
#   Name       : TEnv::Delete
#
#   Purpose....: Delete a variable
#
#   In params..: var
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TEnv::Delete(const char *Name)
{
	if (FHandle)
		RdosDeleteEnvVar(FHandle, Name);
}

/*##########################################################################
#
#   Name       : TEnv::Find
#
#   Purpose....: Find variable & return value
#
#   In params..: var
#				 val
#   Out params.: *
#   Returns....: TRUE if found
#
##########################################################################*/
int TEnv::Find(const char *Name, char *Value)
{
	*Value = 0;

	if (FHandle)
		if (RdosFindEnvVar(FHandle, Name, Value))
			return TRUE;
	return FALSE;
}

/*##########################################################################
#
#   Name       : TEnv::Cache
#
#   Purpose....: Cache var contents for goto first / next
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TEnv::Cache()
{
	char *Buf;
	char *ptr;
	char *VarPtr;
	char *DataPtr;
	TEnvVar *var;

	Free();

	Buf = new char[0x4000];

	ptr = Buf;
	*ptr = 0;
	*(ptr+1) = 0;

	if (FHandle)
		RdosGetEnvData(FHandle, Buf);

	while (*ptr)
	{
		VarPtr = ptr;

		while (*ptr != '=')
			ptr++;

		*ptr = 0;
		ptr++;

		DataPtr = ptr;

		while (*ptr)
			ptr++;

		var = new TEnvVar(VarPtr, DataPtr);
		var->Next = FVarList;
		FVarList = var;

		ptr++;
	}
	delete Buf;
}

/*##########################################################################
#
#   Name       : TEnv::GotoFirst
#
#   Purpose....: Goto first env var
#
#   In params..: *
#   Out params.: *
#   Returns....: Env var
#
##########################################################################*/
TEnvVar *TEnv::GotoFirst()
{
	Cache();
	FCurrent = FVarList;
	return FCurrent;
}

/*##########################################################################
#
#   Name       : TEnv::GotoNext
#
#   Purpose....: Goto next env var
#
#   In params..: *
#   Out params.: *
#   Returns....: Env var
#
##########################################################################*/
TEnvVar *TEnv::GotoNext()
{
	if (FCurrent)
		FCurrent = FCurrent->Next;

	return FCurrent;
}
