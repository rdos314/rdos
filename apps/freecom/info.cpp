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
# info.cpp
# System info command class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "cmdhelp.h"
#include "lang.h"
#include "info.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TInfoFactory::TInfoFactory
#
#   Purpose....: Constructor for TInfoFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TInfoFactory::TInfoFactory()
  : TCommandFactory("INFO")
{
}

/*##########################################################################
#
#   Name       : TInfoFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TInfoFactory::Create(TSession *session, const char *param)
{
    return new TInfoCommand(session, param);
}

/*##########################################################################
#
#   Name       : TInfoCommand::TInfoCommand
#
#   Purpose....: Constructor for TInfoCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TInfoCommand::TInfoCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
    FHelpScreen.Load(TEXT_CMDHELP_INFO);
}

/*##########################################################################
#
#   Name       : TInfoCommand::~TInfoCommand
#
#   Purpose....: Destructor for TInfoCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TInfoCommand::~TInfoCommand()
{
}

/*##########################################################################
#
#   Name       : TInfoCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TInfoCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
    OptError(optstr);
    return E_Useage;
}

/*##########################################################################
#
#   Name       : TInfoCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TInfoCommand::InitOptions()
{
}

/*##########################################################################
#
#   Name       : TInfoCommand::Execute
#
#   Purpose....: Execute command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TInfoCommand::Execute(char *param)
{
    long long PhysMem;
    long Gdt;
    long Linear;
    long mb;
    long kb;
    char CpuType[80];
    char CpuVendor[80];
    int CpuVer;
    int FeatureBits;
    int Freq;
    int Entry;
    int Type;
    long long Base;
    long long Size;
    unsigned int LsbStart, MsbStart;
    unsigned int LsbEnd, MsbEnd;

    InitOptions();

    if (LeadOptions(&param, 0) != E_None)
        return 1;

    FMsg.printf(TEXT_INFO_PHYS_HEADER);
    Write(FMsg.GetData());

    Entry = 0;
    Type = -1;
    while (Type)
    {
        Type = RdosGetPhysicalEntryType(Entry);
        if (Type)
        {
            if (Type == 1)
            {
                Base = RdosGetPhysicalEntryBase(Entry);
                Size = RdosGetPhysicalEntrySize(Entry);

                LsbStart = (unsigned int)Base;
                MsbStart = (unsigned int)(Base >> 32);

                LsbEnd = (unsigned int)(Base + Size - 1);
                MsbEnd = (unsigned int)((Base + Size - 1) >> 32);

                FMsg.printf(TEXT_INFO_PHYS_ENTRY, MsbStart, LsbStart, MsbEnd, LsbEnd);
                Write(FMsg.GetData());
            }
            Entry++;
        }
    }

    if (RdosUsesPae())
    {
        if (RdosHasPhysical64())
        {
            FMsg.printf(TEXT_INFO_PAE64);
            Write(FMsg.GetData());
        }
        else
        {
            FMsg.printf(TEXT_INFO_PAE32);
            Write(FMsg.GetData());
        }
    }
    else
    {
        FMsg.printf(TEXT_INFO_PAGING32);
        Write(FMsg.GetData());
    }


    PhysMem = RdosGetFreePhysical();
    mb = (int)(PhysMem / 1024LL / 1024LL);
    kb = (int)(PhysMem - (long long)mb * 1024LL * 1024LL);
    kb = kb * 1000 / 1024;
    kb = kb * 100 / 1024;
    FMsg.printf(TEXT_INFO_PHYSICAL, mb, kb);
    Write(FMsg.GetData());

    Gdt = RdosGetFreeGdt();
    FMsg.printf(TEXT_INFO_GDT, Gdt);
    Write(FMsg.GetData());

    Linear = RdosGetFreeSmallKernelLinear();
    mb = Linear / 1024 / 1024;
    kb = Linear - mb * 1024 * 1024;
    kb = kb * 1000 / 1024;
    kb = kb * 100 / 1024;
    FMsg.printf(TEXT_INFO_SMALL_KERNEL, mb, kb);
    Write(FMsg.GetData());

    Linear = RdosGetFreeBigKernelLinear();
    mb = Linear / 1024 / 1024;
    kb = Linear - mb * 1024 * 1024;
    kb = kb * 1000 / 1024;
    kb = kb * 100 / 1024;
    FMsg.printf(TEXT_INFO_BIG_KERNEL, mb, kb);
    Write(FMsg.GetData());

    CpuVer = RdosGetCpuVersion(CpuVendor, &FeatureBits, &Freq);

    if (!strcmp(CpuVendor, "AMDisbetter!"))
        strcpy(CpuVendor, "AMD K5");

    if (!strcmp(CpuVendor, "AuthenticAMD"))
        strcpy(CpuVendor, "AMD");

    if (!strcmp(CpuVendor, "CentaurHauls"))
        strcpy(CpuVendor, "Centaur");

    if (!strcmp(CpuVendor, "CyrixInstead"))
        strcpy(CpuVendor, "Cyrix");

    if (!strcmp(CpuVendor, "GenuineIntel"))
        strcpy(CpuVendor, "Intel");

    if (!strcmp(CpuVendor, "Geode by NSC"))
        strcpy(CpuVendor, "Geode");

    if (!strcmp(CpuVendor, "NexGenDriven"))
        strcpy(CpuVendor, "NexGen");

    if (!strcmp(CpuVendor, "RiseRiseRise"))
        strcpy(CpuVendor, "Rise");

    if (!strcmp(CpuVendor, "SiS SiS SiS "))
        strcpy(CpuVendor, "SiS");

    if (!strcmp(CpuVendor, "UMC UMC UMC "))
        strcpy(CpuVendor, "UMC");

    if (!strcmp(CpuVendor, "VIA VIA VIA "))
        strcpy(CpuVendor, "VIA");

    switch (CpuVer)
    {
        case 3:
            strcpy(CpuType, "386");
            break;

        case 4:
            strcpy(CpuType, "486");
            break;

        case 5:
            strcpy(CpuType, "Pentium");
            break;

        case 6:
            strcpy(CpuType, "Pentium Pro");
            break;

        default:
            sprintf(CpuType, "%d86", CpuVer);
            break;
    }

    if (Freq)
        FMsg.printf(TEXT_INFO_CPU_FREQ, Freq, CpuType, CpuVendor);
    else
        FMsg.printf(TEXT_INFO_CPU, CpuType, CpuVendor);
    Write(FMsg.GetData());

    if (RdosHasGlobalTimer())
        FMsg.printf(TEXT_INFO_GLOBAL_TIMER);
    else
        FMsg.printf(TEXT_INFO_LOCAL_TIMER);
    Write(FMsg.GetData());

    FMsg.printf(TEXT_INFO_FEATURE);
    Write(FMsg.GetData());

    if (FeatureBits & 1)
        Write("FPU ");

    if (FeatureBits & 2)
        Write("VME ");

    if (FeatureBits & 4)
        Write("DE ");

    if (FeatureBits & 8)
        Write("PSE ");

    if (FeatureBits & 0x10)
        Write("TSC ");

    if (FeatureBits & 0x20)
        Write("MSR ");

    if (FeatureBits & 0x40)
        Write("PAE ");

    if (FeatureBits & 0x80)
        Write("MCE ");

    if (FeatureBits & 0x100)
        Write("CX8 ");

    if (FeatureBits & 0x200)
        Write("APIC ");

    if (FeatureBits & 0x800)
        Write("SEP ");

    if (FeatureBits & 0x1000)
        Write("MTRR ");

    if (FeatureBits & 0x2000)
        Write("PGE ");

    if (FeatureBits & 0x4000)
        Write("MCA ");

    if (FeatureBits & 0x8000)
        Write("CMOV ");

    if (FeatureBits & 0x10000)
        Write("PAT ");

    if (FeatureBits & 0x20000)
        Write("PSE36 ");

    if (FeatureBits & 0x40000)
        Write("PSN ");

    if (FeatureBits & 0x80000)
        Write("CLFSH ");

    if (FeatureBits & 0x200000)
        Write("DS ");

    if (FeatureBits & 0x400000)
        Write("ACPI ");

    if (FeatureBits & 0x800000)
        Write("MMX ");

    if (FeatureBits & 0x1000000)
        Write("FXSR ");

    if (FeatureBits & 0x2000000)
        Write("SSE ");

    if (FeatureBits & 0x4000000)
        Write("SSE2 ");

    if (FeatureBits & 0x8000000)
        Write("SS ");

    if (FeatureBits & 0x10000000)
        Write("HTT ");

    if (FeatureBits & 0x20000000)
        Write("TM ");

    if (FeatureBits & 0x80000000)
        Write("PBE ");

    Write("\r\n");

    return 0;
}
