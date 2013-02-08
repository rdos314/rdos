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
# audio.cpp
# Audio command class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "audio.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TAudioFactory::TAudioFactory
#
#   Purpose....: Constructor for TAudioFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAudioFactory::TAudioFactory()
  : TCommandFactory("AUDIO")
{
}

/*##########################################################################
#
#   Name       : TAudioFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TAudioFactory::Create(TSession *session, const char *param)
{
	return new TAudioCommand(session, param);
}

/*##########################################################################
#
#   Name       : TAudioCommand::TAudioCommand
#
#   Purpose....: Constructor for TAudioCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAudioCommand::TAudioCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
	FHelpScreen.Load(TEXT_CMDHELP_AUDIO);
}

/*##########################################################################
#
#   Name       : TAudioCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAudioCommand::Execute(char *param)
{
    int i;
    int j;
    int k;
    int l;
    int FunctionCount;
    int CodecCount;
    int Count;
    char Info[512];
    int ConnectionList[256];
    char Type;
    char str[256];

    FunctionCount = RdosGetAudioDeviceCount();

    for (i = 0; i < FunctionCount; i++)
    {
        sprintf(str, "Audio device: %d\r\n", i);
        Write(str);
        
        CodecCount = RdosGetAudioCodecCount(i);

        for (j = 0; j < CodecCount; j++)
        {
            sprintf(str, "Codec device: %d\r\n", j);
            Write(str);
            
            for (k = 0; k < 128; k++)
            {
                Type = RdosGetAudioWidgetInfo(i, j, k, Info);
                if (Type)
                {
                    sprintf(str, "%3d: ", k); 
                    Write(str);
                    Write(Info);

                    Count = RdosGetAudioWidgetConnectionList(i, j, k, ConnectionList);

                    if (Count)
                        Write(" (");
                    for (l = 0; l < Count; l++)
                    {
                        sprintf(str, "%d", ConnectionList[l]);
                        Write(str);
                        
                        if (l == Count - 1)
                            Write(")");
                        else
                            Write(", ");
                    }

                    Write("\r\n");
                }                                
            }            
        }     
    }    
    return 0;
}
