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
# volume.cpp
# Volume command class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "volume.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TVolumeFactory::TVolumeFactory
#
#   Purpose....: Constructor for TVolumeFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVolumeFactory::TVolumeFactory()
  : TCommandFactory("VOLUME")
{
}

/*##########################################################################
#
#   Name       : TVolumeFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TVolumeFactory::Create(TSession *session, const char *param)
{
	return new TVolumeCommand(session, param);
}

/*##########################################################################
#
#   Name       : TVolumeCommand::TVolumeCommand
#
#   Purpose....: Constructor for TVolumeCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TVolumeCommand::TVolumeCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_VOLUME);
}

/*##########################################################################
#
#   Name       : TVolumeCommand::ShowVolume
#
#   Purpose....: Show current volume
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TVolumeCommand::ShowVolume()
{
    int L, R;

    RdosGetMasterVolume(&L, &R);

    if (L < 0)
    {
		FMsg.Load(TEXT_VOLUME_L_OFF);
		Write(FMsg.GetData());
    }
    else
    {
		FMsg.printf(TEXT_VOLUME_L_ON, L);
		Write(FMsg.GetData());
    }

    if (R < 0)
    {
		FMsg.Load(TEXT_VOLUME_R_OFF);
		Write(FMsg.GetData());
    }
    else
    {
		FMsg.printf(TEXT_VOLUME_R_ON, L);
		Write(FMsg.GetData());
    }    
}

/*##########################################################################
#
#   Name       : TVolumeCommand::SetVolume1
#
#   Purpose....: Set same volune for both channels
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVolumeCommand::SetVolume1()
{
	const char *str;
    TString Str;
    int Volume;

	Str = FArgList->FName;
	Str.Lower();
	str = Str.GetData();

	if (!strcmp(str, "off"))
	    Volume = -1;
    else
        Volume = atoi(str);

    RdosSetMasterVolume(Volume, Volume);

    return 0;
}

/*##########################################################################
#
#   Name       : TVolumeCommand::SetVolume2
#
#   Purpose....: Set different volune for both channels
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVolumeCommand::SetVolume2()
{
	const char *str;
    int L, R;
	TArg *arg;
    TString Str;

    arg = FArgList;
    
	Str = arg->FName;
	Str.Lower();
	str = Str.GetData();

	if (!strcmp(str, "off"))
	    L = -1;
    else
        L = atoi(str);

    arg = arg->FList;
    
	Str = arg->FName;
	Str.Lower();
	str = Str.GetData();

	if (!strcmp(str, "off"))
	    R = -1;
    else
        R = atoi(str);

    RdosSetMasterVolume(L, R);

    return 0;
}

/*##########################################################################
#
#   Name       : TVolumeCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TVolumeCommand::Execute(char *param)
{
	if (!ScanCmdLine(param, 0))
		return 1;

    switch (FArgCount)
    {
        case 0:
            ShowVolume();
            return 0;

        case 1:
            return SetVolume1();

        case 2:
            return SetVolume2();

        default:
		    FMsg.Load(TEXT_ERROR_REQ_PARAM_MISSING);
		    Write(FMsg.GetData());
		    return E_Useage;
	}
}
