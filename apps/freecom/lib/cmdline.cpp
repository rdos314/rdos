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
# cmdline.cpp
# Command line class
#
########################################################################*/

#include "cmdhelp.h"
#include "cmdline.h"
#include "cmdfact.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TCommandLine::TCommandLine
#
#   Purpose....: Constructor for command line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommandLine::TCommandLine(const char *line)
{	
    TCommand *cmd;
    char *ptr;
    TString str;
    char ch;
    char *p;
  
//    cmd = TCommandFactory::Parse(line);
//    InsertLast(cmd);

    ptr = line;

    while (*ptr)
    {
        ch = *ptr;

        switch (ch)
        {
            case '"':
            case '\'':
                p = strchr(ptr, ch);
                if (p == 0)
                {
                    str.Append(ptr);
                    ptr = ptr + strlen(ptr) - 1;
                }
                else
                {
                    while (p >= ptr)
                    {
                        str.Append(*ptr);
                        ptr++;
                    }
                }
                break;

            case '<':
                ptr = RedirInput(str, ptr);
                str = "";
                break;

            case '>':
                if (*(ptr+1) == '>')
                    RedirAppend(str, ptr + 1);
                else
                    RedirOutput(str, ptr);
                return;

            case '|':
                ptr = Pipe(str, ptr);
                str = "";
                break;                

            default:
                str.Append(ptr);
                ptr++;
                break;
        }
    }

    Add(str);
}

/*##########################################################################
#
#   Name       : TCommandLine::~TCommandLine
#
#   Purpose....: Destructor for command line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommandLine::~TCommandLine()
{	
    TCommand *cmd;
    TCommand *next;

    cmd = FList;

    while (cmd)
    {
        next = cmd->FList;
        delete cmd;
        cmd = next;
    }
}

/*##########################################################################
#
#   Name       : TCommandLine::InsertLast
#
#   Purpose....: Insert command last
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TCommandLine::InsertLast(TCommand *cmd)
{
    TCommand *curr;
    
    cmd->FList = 0;
    curr = FList;
   
    if (curr)
    {
        while (curr->FList)
            curr = curr->FList;

        curr->FList = cmd;
    }
    else
        FList = cmd;
}

/*##########################################################################
#
#   Name       : TCommandLine::Run
#
#   Purpose....: Run command line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TCommandLine::Run()
{	
    TCommand *cmd;
    int result = 0;
    TFile *PrevInput = GetInputFile();
    TFile *PrevOutput = GetOutputFile();
    TFile *PrevError = GetErrorFile();

    cmd = FList;

    while (cmd && result == 0)
    {
        result = cmd->Run();
        cmd = cmd->FList;

        SetInputFile(PrevInput);
        SetOutputFile(PrevOutput);
        SetErrorFile(PrevError);
    }
    Write("\r\n");
    return result;
}
