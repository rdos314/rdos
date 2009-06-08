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
# showpart.cpp
# Show partition command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "idedisc.h"
#include "showpart.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TShowPartitionFactory::TShowPartitionFactory
#
#   Purpose....: Constructor for TShowPartitionFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TShowPartitionFactory::TShowPartitionFactory()
  : TCommandFactory("PART")
{
}

/*##########################################################################
#
#   Name       : TShowPartitionFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TShowPartitionFactory::Create(TSession *session, const char *param)
{
        return new TShowPartitionCommand(session, param);
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::TShowPartitionCommand
#
#   Purpose....: Constructor for TShowPartitionCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TShowPartitionCommand::TShowPartitionCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
        FHelpScreen.Load(TEXT_CMDHELP_SHOWPART);
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TShowPartitionCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
        switch(ch)
        {
                case 'D':
                        return OptScanBool(optstr, bool, strarg, &FOptD);
        }
        OptError(optstr);
        return E_Useage;
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::InitOptions()
{
        FOptD = 0;
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowEntry
#
#   Purpose....: Show entry table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::ShowEntry(int Nr, TPartition *Entry)
{
        const char *Name;
        int Typ;
        double TotalSpace;
        double FreeSpace;
        int Drive;
        char DriveStr[4];
        char str[100];

        if (Entry)
        {
                Name = Entry->GetPartName();
                Typ = Entry->GetType();
                TotalSpace = Entry->GetTotalSpace();

                if (Entry->Size)
                {
                        if (Entry->IsFs() && Entry->GetDrive())
                                Drive = Entry->GetDrive()->GetDriveNr();
                        else
                                Drive = 0;

                        if (Drive)
                        {
                            DriveStr[0] = 'A' + (char)Drive;
                            DriveStr[1] = ':';
                            DriveStr[2] = 0;
                              
                            FreeSpace = Entry->GetFreeSpace();

                sprintf(str,
                                                "%d: %s %02hX %08lX-%08lX %8s %15.3f MB %15.3f MB\r\n",
                                                Nr,
                                                DriveStr,
                                                Typ,
                                                Entry->Start,
                                                Entry->Start + Entry->Size - 1,
                                                Name,
                                                TotalSpace,
                                                FreeSpace);
                        }
                        else
                                sprintf(str,
                                                "%d: -- %02hX %08lX-%08lX %8s %15.3f MB\r\n",
                                                Nr,
                                                Typ,
                                                Entry->Start,
                                                Entry->Start + Entry->Size - 1,
                                                Name,
                                                TotalSpace);
                        Write(str);
                }
                else
                {
                        FMsg.printf(TEXT_SHOWPART_FREE_ENTRY, Nr);
                        Write(FMsg.GetData());
                }
        }
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowTreeTable
#
#   Purpose....: Show tree table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::ShowTreeTable(TPartitionTable *Part)
{
        int i;
        TPartition *Entry;
        double TotalSpace;
        char str[100];

        TotalSpace = Part->GetTotalSpace();

        sprintf(str, "\r\n%08lX-%08lX %15.3f MB\r\n",
                                Part->Start,
                                Part->Start + Part->Size - 1,
                                TotalSpace);

        Write(str);

        FMsg.Load(TEXT_SHOWPART_HEADER);
        Write(FMsg.GetData());

        for (i = 0; i < 4; i++)
                ShowEntry(i, Part->PartArr[i]);

        for (i = 0; i < 4; i++)
        {
                Entry = Part->PartArr[i];
                if (Entry)
                        if (Entry->IsTable())
                                ShowTreeTable((TPartitionTable *)Entry);
        }
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowTree
#
#   Purpose....: Show tree
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::ShowTree(TDiscPartition *Part)
{
        FMsg.printf(TEXT_SHOWPART_DISC_SHORT, Part->GetDisc()->GetDiscNr());
        Write(FMsg.GetData());

        if (Part->PartRoot)
                ShowTreeTable(Part->PartRoot);
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::ShowTable
#
#   Purpose....: Show table
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TShowPartitionCommand::ShowTable(TDiscPartition *Part)
{
        int i;
        TDisc *Disc;

        Disc = Part->GetDisc();

        FMsg.printf(TEXT_SHOWPART_DISC_LONG, Disc->GetDiscNr(), Disc->GetTotalSectors(), Disc->GetSectorsPerCyl(), Disc->GetHeads());
        Write(FMsg.GetData());

        FMsg.Load(TEXT_SHOWPART_HEADER);
        Write(FMsg.GetData());

        for (i = 0; i < Part->PartCount; i++)
                ShowEntry(i, Part->PartArr[i]);
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::Show
#
#   Purpose....: Show result
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TShowPartitionCommand::Show(TDisc *Disc)
{
        TDiscPartition *DiscPart;

        if (Disc->IsValid())
        {
                DiscPart = new TDiscPartition(Disc);
                if (FOptD)
                        ShowTree(DiscPart);
                else
                        ShowTable(DiscPart);
                delete DiscPart;
                return TRUE;
        }
        return FALSE;
}

/*##########################################################################
#
#   Name       : TShowPartitionCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TShowPartitionCommand::Execute(char *param)
{
        int DiscNr;
        TDisc *Disc;

        InitOptions();

        if (LeadOptions(&param, 0) != E_None)
                return 1;

        /* if no parameters, show all */
        if (*param == 0)
        {
                for (DiscNr = 0; DiscNr < 4; DiscNr++)
                {
                        Disc = new TIdeDisc(DiscNr);
                        if (Disc->IsValid())
                                Show(Disc);
                        delete Disc;
                }
                return 0;
        }

        if (sscanf(param, "%d", &DiscNr) == 1)
        {
                Disc = new TIdeDisc(DiscNr);
                if (!Show(Disc))
                {
                        FMsg.printf(TEXT_SHOWPART_DISC_ERROR, DiscNr);
                        Write(FMsg.GetData());
                }
        }
        else
        {
                ErrorSyntax(0);
                return 1;
        }

        return 0;
}

