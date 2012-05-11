/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2012, Leif Ekblad
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
# inifile.c
# Ini-file interface
#
########################################################################*/

#include <string.h>

#include "rdos.h"
#include "rdosdev.h"

#define FALSE   0
#define TRUE    !FALSE

struct TIniVar
{
    char *Name;
    char *Val;

    struct TIniVar *FNextVar;
};

struct TIniSection
{
   struct TIniVar *FVarList;
   struct TIniSection *FNextSection;
};

struct TIni
{
    int Users;
    struct TKernelSection FSection;
    struct TIniSection *FSectionList;
    char Buffer[1];
};

struct TIniHandle
{
    struct THandleHeader Header;
    int IniSel;
    long SectionLinear;
};

static int SysIniRead = FALSE;
static char SysIniName[256];

/*##########################################################################
#
#   Name       : CreateIniSel
#
#   Purpose....: Create ini selector
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int CreateIniSel(char *FileName)
{
    struct TIni *Ini;
    int sel;
    long FileSize = 0;
    int Size;
    int FileHandle = RdosOpenFile(FileName, 0);

    if (FileHandle)
        FileSize = RdosGetFileSize(FileHandle);

    Size = FileSize + sizeof(struct TIni);
    
    sel = RdosAllocateSmallGlobalSelector(Size);
    Ini = (struct TIni*)RdosSelectorToPointer(sel);

    if (FileSize)
        RdosReadFile(FileHandle, Ini->Buffer, FileSize);
    Ini->Buffer[FileSize] = 0;

    if (FileHandle)
        RdosCloseFile(FileHandle);    

    Ini->Users = 1;
    RdosInitKernelSection(&Ini->FSection);
    Ini->FSectionList = 0;

    return sel;
}

/*##########################################################################
#
#   Name       : CreateHandle
#
#   Purpose....: Create Handle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct TIniHandle *CreateHandle(int Sel)
{
    struct TIniHandle *Ini = (struct TIniHandle *)RdosAllocateHandle(INI_HANDLE, sizeof(struct TIniHandle));
    Ini->Header.sign = INI_HANDLE;
    Ini->IniSel = Sel;
    Ini->SectionLinear = 0;

    return Ini;
}

/*##########################################################################
#
#   Name       : FreeHandle
#
#   Purpose....: Free Handle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void FreeHandle(struct TIniHandle *Ini)
{
    if (Ini->SectionLinear)
        RdosFreeLinear(Ini->SectionLinear, 0);

    RdosFreeHandle((struct THandleHeader *)Ini);
}

/*##########################################################################
#
#   Name       : OpenIni
#
#   Purpose....: Open ini
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int OpenIni(char *FileName)
{
    int Sel;
    struct TIniHandle* Ini;

    Sel = CreateIniSel(FileName);
    Ini = CreateHandle(Sel);

    return Ini->Header.handle;
}

/*##########################################################################
#
#   Name       : DeleteHandle
#
#   Purpose....: Delete handle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DeleteHandle(int Handle)
{
}

/*##########################################################################
#
#   Name       : CloseIni
#
#   Purpose....: Close ini
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void CloseIni(int Handle)
{
    DeleteHandle(Handle);
}

/*##########################################################################
#
#   Name       : GotoIniSection
#
#   Purpose....: Goto ini section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GotoIniSection(int Handle, char *SectionName)
{
    return 0;
}

/*##########################################################################
#
#   Name       : RemoveIniSection
#
#   Purpose....: Remove ini section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int RemoveIniSection(int Handle, char *SectionName)
{
    return 0;
}

/*##########################################################################
#
#   Name       : ReadIniVar
#
#   Purpose....: Read ini var
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int ReadIniVar(int Handle, char *VarName, char *Buf, int MaxSize)
{
    return 0;
}

/*##########################################################################
#
#   Name       : WriteIniVar
#
#   Purpose....: Write ini var
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int WriteIniVar(int Handle, char *VarName, char *Buf, int Size)
{
    return 0;
}

/*##########################################################################
#
#   Name       : DeleteIniVar
#
#   Purpose....: Delete ini var
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int DeleteIniVar(int Handle, char *VarName)
{
    return 0;
}

/*##########################################################################
#
#   Name       : GetSysIni
#
#   Purpose....: Get sys ini filename
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GetSysIni()
{
    int handle = RdosOpenSysEnv();

    strcpy(SysIniName, "z:\system.ini");

    RdosFindEnvVar(handle, "SYSINI", SysIniName);

    RdosCloseEnv(handle);    

    SysIniRead = TRUE;
}

/*##########################################################################
#
#   Name       : ImplOpenSysIni
#
#   Purpose....: Open sys ini
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplOpenSysIni "*" rdosdev parm routine value [ebx]
int __far ImplOpenSysIni()
{
    int handle;

    if (!SysIniRead)
        GetSysIni();

    handle = OpenIni(SysIniName);

    if (handle)    
        RdosSetSuccess();
    else
        RdosSetFailure();

    return handle;
}

/*##########################################################################
#
#   Name       : ImplOpenIni16
#
#   Purpose....: Open ini, 16-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplOpenIni16 "*" rdosdev parm routine [es edi] value [ebx]
int __far ImplOpenIni16(char *FileName)
{
    int handle;
    
    RdosExtendDi();

    handle = OpenIni(FileName);

    if (handle)    
        RdosSetSuccess();
    else
        RdosSetFailure();

    return handle;
}

/*##########################################################################
#
#   Name       : ImplOpenIni32
#
#   Purpose....: Open ini, 32-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplOpenIni32 "*" rdosdev parm routine [es edi] value [ebx]
int __far ImplOpenIni32(char *FileName)
{
    int handle;
    
    handle = OpenIni(FileName);

    if (handle)    
        RdosSetSuccess();
    else
        RdosSetFailure();

    return handle;
}

/*##########################################################################
#
#   Name       : ImplCloseIni
#
#   Purpose....: Open close ini
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplCloseIni "*" rdosdev parm routine [ebx]
void __far ImplCloseIni(int handle)
{
    CloseIni(handle);
}

/*##########################################################################
#
#   Name       : ImplGotoIniSection16
#
#   Purpose....: Goto ini section, 16-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGotoIniSection16 "*" rdosdev parm routine [ebx] [es edi]
void __far ImplGotoIniSection16(int Handle, char *SectionName)
{
    RdosExtendDi();

    if (GotoIniSection(Handle, SectionName))
        RdosSetSuccess();
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : ImplGotoIniSection32
#
#   Purpose....: Goto ini section, 32-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGotoIniSection32 "*" rdosdev parm routine [ebx] [es edi]
void __far ImplGotoIniSection32(int Handle, char *SectionName)
{
    if (GotoIniSection(Handle, SectionName))
        RdosSetSuccess();
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : ImplRemoveIniSection16
#
#   Purpose....: Remove ini section, 16-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplRemoveIniSection16 "*" rdosdev parm routine [ebx] [es edi]
void __far ImplRemoveIniSection16(int Handle, char *SectionName)
{
    RdosExtendDi();

    if (RemoveIniSection(Handle, SectionName))
        RdosSetSuccess();
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : ImplRemoveIniSection32
#
#   Purpose....: Remove ini section, 32-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplRemoveIniSection32 "*" rdosdev parm routine [ebx] [es edi]
void __far ImplRemoveIniSection32(int Handle, char *SectionName)
{
    if (RemoveIniSection(Handle, SectionName))
        RdosSetSuccess();
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : ImplReadIniVar16
#
#   Purpose....: Read ini var, 16-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplReadIniVar16 "*" rdosdev parm routine [ebx] [esi] [es edi] [ecx] value [eax]
int __far ImplReadIniVar16(int Handle, long Offset, char *Buf, int MaxSize)
{
    char *VarName;
    int Size;

    RdosExtendCx();
    RdosExtendSi();
    RdosExtendDi();

    VarName = RdosSelectorOffsetToPointer(RdosGetGateDs(), Offset);

    Size = ReadIniVar(Handle, VarName, Buf, MaxSize);

    if (Size)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return Size;
}

/*##########################################################################
#
#   Name       : ImplReadIniVar32
#
#   Purpose....: Read ini var, 32-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplReadIniVar32 "*" rdosdev parm routine [ebx] [esi] [es edi] [ecx] value [eax]
int __far ImplReadIniVar32(int Handle, long Offset, char *Buf, int MaxSize)
{
    char *VarName = RdosSelectorOffsetToPointer(RdosGetGateDs(), Offset);
    int Size;

    Size = ReadIniVar(Handle, VarName, Buf, MaxSize);

    if (Size)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return Size;
}

/*##########################################################################
#
#   Name       : ImplWriteIniVar16
#
#   Purpose....: Write ini var, 16-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplWriteIniVar16 "*" rdosdev parm routine [ebx] [esi] [es edi] [ecx]
void __far ImplWriteIniVar16(int Handle, long Offset, char *Buf, int Size)
{
    char *VarName;

    RdosExtendCx();
    RdosExtendSi();
    RdosExtendDi();

    VarName = RdosSelectorOffsetToPointer(RdosGetGateDs(), Offset);

    if (WriteIniVar(Handle, VarName, Buf, Size))
        RdosSetSuccess();
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : ImplWriteIniVar32
#
#   Purpose....: Write ini var, 32-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplWriteIniVar32 "*" rdosdev parm routine [ebx] [esi] [es edi] [ecx]
void __far ImplWriteIniVar32(int Handle, long Offset, char *Buf, int Size)
{
    char *VarName;

    VarName = RdosSelectorOffsetToPointer(RdosGetGateDs(), Offset);

    if (WriteIniVar(Handle, VarName, Buf, Size))
        RdosSetSuccess();
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : ImplDeleteIniVar16
#
#   Purpose....: Delete ini var, 16-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplDeleteIniVar16 "*" rdosdev parm routine [ebx] [esi]
void __far ImplDeleteIniVar16(int Handle, long Offset)
{
    char *VarName;

    RdosExtendSi();

    VarName = RdosSelectorOffsetToPointer(RdosGetGateDs(), Offset);

    if (DeleteIniVar(Handle, VarName))
        RdosSetSuccess();
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : ImplDeleteIniVar32
#
#   Purpose....: Delete ini var, 32-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplDeleteIniVar32 "*" rdosdev parm routine [ebx] [esi]
void __far ImplDeleteIniVar32(int Handle, long Offset)
{
    char *VarName;

    VarName = RdosSelectorOffsetToPointer(RdosGetGateDs(), Offset);

    if (DeleteIniVar(Handle, VarName))
        RdosSetSuccess();
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : ImplDeleteHandle
#
#   Purpose....: Delete handles when process terminates
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplDeleteHandle "*" rdosdev parm routine [ebx]
void __far ImplDeleteHandle(int handle)
{
    DeleteHandle(handle);
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....: Initialization
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main()
{
    RdosRegisterBimodalUserGate(usergate_open_sys_ini, &ImplOpenSysIni, "Open Sys Ini");
    RdosRegisterSegUserGate(usergate_open_ini, GATE_ES_IN, &ImplOpenIni16, &ImplOpenIni32, "Open Ini");
    RdosRegisterBimodalUserGate(usergate_close_ini, &ImplCloseIni, "Close Ini");
    RdosRegisterSegUserGate(usergate_goto_ini_section, GATE_ES_IN, &ImplGotoIniSection16, &ImplGotoIniSection32, "Goto Ini Section");
    RdosRegisterSegUserGate(usergate_remove_ini_section, GATE_ES_IN, &ImplRemoveIniSection16, &ImplRemoveIniSection32, "Remove Ini Section");
    RdosRegisterSegUserGate(usergate_read_ini, GATE_DS_IN | GATE_ES_IN, &ImplReadIniVar16, &ImplReadIniVar32, "Read Ini");
    RdosRegisterSegUserGate(usergate_write_ini, GATE_DS_IN | GATE_ES_IN, &ImplWriteIniVar16, &ImplWriteIniVar32, "Write Ini");
    RdosRegisterSegUserGate(usergate_delete_ini, GATE_DS_IN, &ImplDeleteIniVar16, &ImplDeleteIniVar32, "Delete Ini");
    RdosRegisterHandle(INI_HANDLE, &ImplDeleteHandle);    
}
