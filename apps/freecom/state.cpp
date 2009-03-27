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
# state.cpp
# State command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "state.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TStateFactory::TStateFactory
#
#   Purpose....: Constructor for TStateFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStateFactory::TStateFactory()
  : TCommandFactory("STATE")
{
}

/*##########################################################################
#
#   Name       : TStateFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TStateFactory::Create(TSession *session, const char *param)
{
	return new TStateCommand(session, param);
}

/*##########################################################################
#
#   Name       : TStateCommand::TStateCommand
#
#   Purpose....: Constructor for TStateCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TStateCommand::TStateCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_STATE);
}

/*##########################################################################
#
#   Name       : TStateCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStateCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
	switch(ch)
	{
		case 'S':
			return OptScanBool(optstr, bool, strarg, &FOptS);

	    case 'F':
			return OptScanBool(optstr, bool, strarg, &FOptF);
	}
	OptError(optstr);
	return E_Useage;
}

/*##########################################################################
#
#   Name       : TStateCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStateCommand::InitOptions()
{
    FOptS = FALSE;
    FOptF = FALSE;
}

/*##########################################################################
#
#   Name       : TStateCommand::WriteOne
#
#   Purpose....: Write one
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TStateCommand::WriteOne(ThreadState *State)
{
    char str[40];
    int len;
	unsigned long temp;
	int day;
	int hour;
	int min;
	int sec;
	int milli;
	int micro;
	int started;
    int i;

	sprintf(str, "%04hX ", State->ID);
	Write(str);

	memcpy(str, State->Name, 20);
	str[20] = 0;
	len = strlen(str);

	for (i = len; i < 20; i++)
        str[i] = ' ';

	Write(str);

	day = State->MsbTime / 24;
	hour = State->MsbTime % 24;
	RdosDecodeLsbTics(State->LsbTime, &min, &sec, &milli, &micro);

	started = FALSE;
	if (day)
	{
        sprintf(str, "%3d ", day);
        Write(str);
        started = TRUE;
    }
    else
        Write("    ");

    if (hour || started)
    {
        if (started)
				sprintf(str, "%02d.", hour);
		  else
				sprintf(str, "%2d.", hour);
		  Write(str);
		  started = TRUE;
	 }
	 else
		  Write("   ");

	 if (min || started)
	 {
		  if (started)
				sprintf(str, "%02d.", min);
		  else
				sprintf(str, "%2d.", min);
		  Write(str);
		  started = TRUE;
	 }
	 else
		  Write("   ");

	 if (sec || started)
	 {
		  if (started)
				sprintf(str, "%02d,", sec);
		  else
				sprintf(str, "%2d,", sec);
		  Write(str);
		  started = TRUE;
	 }
	 else
		  Write("   ");

	 if (milli || started)
	 {
		  if (started)
				sprintf(str, "%03d ", milli);
		  else
				sprintf(str, "%3d ", milli);
		  Write(str);
		  started = TRUE;
	 }
	 else
		  Write("    ");

	 if (started)
		  sprintf(str, "%03d ", micro);
	 else
		  sprintf(str, "%3d ", micro);
	 Write(str);

	memcpy(str, State->List, 20);
	str[20] = 0;
	len = strlen(str);

	for (i = len; i < 20; i++)
		  str[i] = ' ';

	Write(str);

	sprintf(str, "%04hX:", State->Sel);
	Write(str);

	sprintf(str, "%08lX", State->Offset);
	Write(str);

	 Write("\r\n");

}

/*##########################################################################
#
#   Name       : TStateCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TStateCommand::Execute(char *param)
{
    int i;
    ThreadState state;
    short int ID;
    TArg *arg;

	InitOptions();

	if (LeadOptions(&param, 0) != E_None)
		return 1;

	if (!ScanCmdLine(param, 0))
		return 1;

	if (FArgCount == 0)
	{
        for (i = 0; i < 256; i++)
	        if (RdosGetThreadState(i, &state))
        	    WriteOne(&state);
        	        
        return 0;
    }
    else
    {
        arg = FArgList;

		while (arg)
		{
        	if (sscanf(arg->FName.GetData(), "%4hX", &ID) == 1)
            {        	
                for (i = 0; i < 256; i++)
                {
	                if (RdosGetThreadState(i, &state))
	                {
	                    if (state.ID == ID)
	                    {
	                        if (FOptF)
	                        {
								RdosSuspendAndSignalThread(ID);
								RdosWaitMilli(50);
							}
							else
							{
								if (FOptS)
								{
									RdosSuspendThread(ID);
                    		        RdosWaitMilli(50);
                    		    }
                    		}
	                        WriteOne(&state);
	                    }
	                }
	            }
	        }
			arg = arg->FList;
		}
		return 0;
	}
}

