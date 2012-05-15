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
#include <stdio.h>

#include "rdos.h"
#include "rdosdev.h"

extern void InitGates();

#define FALSE   0
#define TRUE    !FALSE

struct TIniVar
{
    int Index;
    int Deleted;
    char *Name;
    char *Val;

    struct TIniVar *FNextVar;
};

struct TIniSection
{
    int Index;
    int Deleted;
    char *Name;
    struct TIniVar *FVarList;
    struct TIniSection *FNextSection;
};

struct TIni
{
    int Modified;
    int Users;
    int BaseSize;
    int BufSize;
    int SectionCount;
    int VarCount;
    int MaxBufSize;
    int MaxSectionCount;
    int MaxVarCount;
    struct TIniSection *FSectionList;
    struct TKernelSection Section;
    struct TIni *FNextIni;
    char Drive;
    char Access;
    int FileSel;
    char *Data;
    char Name[1];
};

struct TIniHandle
{
    struct THandleHeader Header;
    struct TIni *Ini;
    char *SectionName;
};

static int OldSel;
static int SysIniRead = FALSE;
static char SysIniName[256];
struct TKernelSection IniSection;
struct TIni *IniList = 0;

/*##########################################################################
#
#   Name       : GrowIni
#
#   Purpose....: Grow ini file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void GrowIni(struct TIni *Ini, int BufSize, int SectionCount, int VarCount)
{
    long OldBase;
    long NewBase;
    long limit;
    int OldSize;
    int NewSize;
    int i;
    int j;
    int offset;
    long Pos;
    int SrcBaseSize;
    int DestBaseSize;
    long SrcVarPos;
    long DestVarPos;
    struct TIni *SrcIni;
    struct TIni *DestIni;
    struct TIniSection *SrcSect;
    struct TIniSection *DestSect;
    struct TIniSection *sect;
    struct TIniVar *var;
    struct TIniVar *SrcVar;
    struct TIniVar *DestVar;
    int sel = RdosPointerToSelector(Ini);

    SrcBaseSize = Ini->BaseSize + Ini->MaxBufSize;

    RdosGetSelectorBaseSize(sel, &OldBase, &limit);

    OldSize = limit + 1;

    DestBaseSize = Ini->BaseSize + BufSize;

    NewSize = DestBaseSize + SectionCount * sizeof(struct TIniSection);
    NewSize += VarCount * sizeof(struct TIniVar);

    NewBase = RdosAllocateSmallGlobalLinear(NewSize);

    RdosCreateDataSelector32(sel, NewBase, NewSize);    
    RdosCreateDataSelector32(OldSel, OldBase, OldSize);    
    RdosReloadSelector(sel);

    SrcIni = (struct TIni*)RdosSelectorToPointer(OldSel);
    DestIni = (struct TIni*)RdosSelectorToPointer(sel);

    memcpy(DestIni, SrcIni, SrcBaseSize);

    DestIni->MaxBufSize = BufSize;
    DestIni->MaxSectionCount = SectionCount;
    DestIni->MaxVarCount = VarCount;

    SrcVarPos = SrcBaseSize + SrcIni->MaxSectionCount * sizeof(struct TIniSection);
    DestVarPos = DestBaseSize + SectionCount * sizeof(struct TIniSection);

    if (SrcIni->FSectionList)
    {
        offset = RdosPointerToOffset(SrcIni->FSectionList);
        sect = (struct TIniSection*)RdosSelectorOffsetToPointer(OldSel, offset);            
        j = sect->Index;

        Pos = DestBaseSize + j * sizeof(struct TIniSection); 
        sect = (struct TIniSection*)RdosSelectorOffsetToPointer(sel, Pos);
        DestIni->FSectionList = sect;
    }            

    for (i = 0; i < SrcIni->SectionCount; i++)
    {
        Pos = SrcBaseSize + i * sizeof(struct TIniSection); 
        SrcSect = (struct TIniSection*)RdosSelectorOffsetToPointer(OldSel, Pos);

        Pos = DestBaseSize + i * sizeof(struct TIniSection); 
        DestSect = (struct TIniSection*)RdosSelectorOffsetToPointer(sel, Pos);
        *DestSect = *SrcSect;

        if (SrcSect->FNextSection)
        {
            offset = RdosPointerToOffset(SrcSect->FNextSection);
            sect = (struct TIniSection*)RdosSelectorOffsetToPointer(OldSel, offset);            
            j = sect->Index;

            Pos = DestBaseSize + j * sizeof(struct TIniSection); 
            sect = (struct TIniSection*)RdosSelectorOffsetToPointer(sel, Pos);
            DestSect->FNextSection = sect;
        }            

        if (SrcSect->FVarList)
        {
            offset = RdosPointerToOffset(SrcSect->FVarList);
            var = (struct TIniVar*)RdosSelectorOffsetToPointer(OldSel, offset);            
            j = var->Index;

            Pos = j * sizeof(struct TIniVar); 
            var = (struct TIniVar*)RdosSelectorOffsetToPointer(sel, DestVarPos + Pos);
            DestSect->FVarList = var;
        }            
    }
    
    for (i = 0; i < SrcIni->VarCount; i++)
    {
        Pos = i * sizeof(struct TIniVar); 
        SrcVar = (struct TIniVar*)RdosSelectorOffsetToPointer(OldSel, SrcVarPos + Pos);
        DestVar = (struct TIniVar*)RdosSelectorOffsetToPointer(sel, DestVarPos + Pos);
        *DestVar = *SrcVar;

        if (SrcVar->FNextVar)
        {
            offset = RdosPointerToOffset(SrcVar->FNextVar);
            var = (struct TIniVar*)RdosSelectorOffsetToPointer(OldSel, offset);
            j = var->Index;

            Pos = j * sizeof(struct TIniVar); 
            var = (struct TIniVar*)RdosSelectorOffsetToPointer(sel, DestVarPos + Pos);
            DestVar->FNextVar = var;
        }            
    }
    RdosFreeLinear(OldBase, OldSize);
}

/*##########################################################################
#
#   Name       : CheckDelim
#
#   Purpose....: Check if character is a delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int CheckDelim(char ch)
{
    switch (ch)
    {
        case 0xd:
        case 0xa:
        case ' ':
        case 0x9:
            return TRUE;
    }
    return FALSE;
}

/*##########################################################################
#
#   Name       : Trim
#
#   Purpose....: Left and right trim string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *Trim(char *str)
{
    int len;
    char *ptr;

    while (*str == ' ' || *str == 0x9)
        str++;

    ptr = str;
    len = strlen(ptr);

    while (len)
    {
        len--;
        if (CheckDelim(ptr[len]))
            ptr[len] = 0;
        else
            break;
    }        

    return str;
}

/*##########################################################################
#
#   Name       : AddVar
#
#   Purpose....: Add single variable
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void AddVar(struct TIni *Ini, struct TIniSection *IniSect, char *name, char *val)
{
    int pos;
    char *base;
    struct TIniVar *IniVar;
    struct TIniVar *var;

    if (Ini->VarCount == Ini->MaxVarCount)
        GrowIni(Ini, Ini->MaxBufSize, Ini->MaxSectionCount, 3 * (Ini->VarCount + 1) / 2); 

    pos = Ini->BaseSize + Ini->MaxBufSize;
    pos += Ini->MaxSectionCount * sizeof(struct TIniSection);
    pos += Ini->VarCount * sizeof(struct TIniVar);
    base = (char *)Ini;
    
    IniVar = (struct TIniVar *)(base + pos);
    IniVar->Index = Ini->VarCount;
    IniVar->Deleted = FALSE;
    IniVar->Name = name;
    IniVar->Val = val;
    IniVar->FNextVar = 0;
    
    Ini->VarCount++;

    if (IniSect->FVarList)
    {
        var = IniSect->FVarList;

        while (var->FNextVar)
            var = var->FNextVar;

        var->FNextVar = IniVar;
    }
    else
        IniSect->FVarList = IniVar;    
}

/*##########################################################################
#
#   Name       : FindStartOfLine
#
#   Purpose....: Find start of line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *FindStartOfLine(char *ptr)
{
    while (*ptr && *ptr != 0xd && *ptr != 0xa)
        ptr++;

    while (*ptr == 0xd || *ptr == 0xa)
        ptr++;

    if (*ptr)
        return ptr;
    else
        return 0;    
}

/*##########################################################################
#
#   Name       : DecodeLine
#
#   Purpose....: Decode a single line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DecodeLine(struct TIni *Ini, struct TIniSection *IniSect, char *ptr)
{
    char *name = ptr;

    while (*ptr && *ptr != '=')
        ptr++;

    if (*ptr == '=')
    {
        *ptr = 0;
        ptr++;

        name = Trim(name);
        ptr = Trim(ptr);

        AddVar(Ini, IniSect, name, ptr);
    }
}

/*##########################################################################
#
#   Name       : ParseSection
#
#   Purpose....: Parse ini section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ParseSection(struct TIni *Ini, struct TIniSection *IniSect, char *ptr)
{
    char *prev_line = 0;
    char *curr_line = 0;

    while (ptr)
    {
        curr_line = FindStartOfLine(ptr);

        if (curr_line)
        {
            curr_line--;
            *curr_line = 0;
            curr_line++;

            if (prev_line)
                DecodeLine(Ini, IniSect, prev_line);

            prev_line = curr_line;
            ptr = curr_line;
        }
        else
        {
            if (prev_line)
                DecodeLine(Ini, IniSect, prev_line);

            ptr = 0;
        }
    }
}

/*##########################################################################
#
#   Name       : FindSection
#
#   Purpose....: Find first section in string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *FindSection(char *ptr)
{
    while (*ptr)
    {
        while (*ptr == 0xd || *ptr == 0xa)
            ptr++;
            
        if (*ptr == '[')
            return ptr;
        else
        {
            while (*ptr && *ptr != 0xd && *ptr != 0xa)
                ptr++;
        }
    }
    return 0;
}

/*##########################################################################
#
#   Name       : AddSection
#
#   Purpose....: Add a single section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct TIniSection *AddSection(struct TIni *Ini, char *name, char *ptr)
{
    int pos;
    char *base;
    struct TIniSection *IniSect;
    struct TIniSection *sect;

    if (Ini->SectionCount == Ini->MaxSectionCount)
        GrowIni(Ini, Ini->MaxBufSize, 3 * (Ini->SectionCount + 1) / 2, Ini->MaxVarCount); 

    pos = Ini->BaseSize + Ini->MaxBufSize;
    pos += Ini->SectionCount * sizeof(struct TIniSection);
    base = (char *)Ini;
    
    IniSect = (struct TIniSection *)(base + pos);

    IniSect->Index = Ini->SectionCount;
    IniSect->Deleted = FALSE;
    IniSect->FVarList = 0;
    IniSect->FNextSection = 0;
    IniSect->Name = name;

    if (Ini->FSectionList)
    {
        sect = Ini->FSectionList;

        while (sect->FNextSection)
            sect = sect->FNextSection;

        sect->FNextSection = IniSect;
    }
    else
        Ini->FSectionList = IniSect;    
   
    Ini->SectionCount++;

    if (ptr)
        ParseSection(Ini, IniSect, ptr);

    return IniSect;
}    

/*##########################################################################
#
#   Name       : DecodeSection
#
#   Purpose....: Decode a single section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void DecodeSection(struct TIni *Ini, char *ptr)
{
    char *name = ptr;
    
    while (*ptr)
    {
        if (*ptr == 0 || *ptr == 0xd || *ptr == 0xa)
            break;

        if (*ptr == ']')
            break;

        ptr++;
    }

    if (*ptr == ']')
    {
        *ptr = 0;
        ptr++;

        AddSection(Ini, name, ptr);
    }    
}

/*##########################################################################
#
#   Name       : ParseIni
#
#   Purpose....: Parse ini file into components
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ParseIni(struct TIni *Ini)
{
    char *prev_sec = 0;
    char *curr_sec = 0;
    char *ptr = Ini->Data;

    while (ptr)
    {
        curr_sec = FindSection(ptr);

        if (curr_sec)
        {
            *curr_sec = 0;
            curr_sec++;

            if (prev_sec)
                DecodeSection(Ini, prev_sec);

            prev_sec = curr_sec;
            ptr = curr_sec;
        }
        else
        {
            if (prev_sec)
                DecodeSection(Ini, prev_sec);

            ptr = 0;
        }
    }
}

/*##########################################################################
#
#   Name       : FindString
#
#   Purpose....: Find string in data region
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *FindString(struct TIni *Ini, char *str)
{
    int size = Ini->BufSize;
    char *ptr = Ini->Data;
    int len;

    size--;
    ptr++;

    while (size > 0)
    {
        if (strcmp(ptr, str) == 0)
            return ptr;

        len = strlen(ptr);
        len++;

        size -= len;
        ptr += len;        
    }

    return 0;
}

/*##########################################################################
#
#   Name       : AddString
#
#   Purpose....: Add string to data region
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *AddString(struct TIni *Ini, char *str)
{
    int StrSize;
    int NewSize;
    int GrowSize;
    char *DestStr;

    DestStr = FindString(Ini, str);

    if (!DestStr)
    {
        StrSize = strlen(str) + 1;
        NewSize = Ini->BufSize + StrSize;

        if (NewSize > Ini->MaxBufSize)
        {
            GrowSize = 3 * (NewSize + 1) / 2;
            GrowIni(Ini, GrowSize, Ini->MaxSectionCount, Ini->MaxVarCount); 
        }

        DestStr = (char *)Ini;
        DestStr += Ini->BaseSize + Ini->BufSize;
        strcpy(DestStr, str);
        Ini->BufSize += StrSize;
    }
    return DestStr;    
}    

/*##########################################################################
#
#   Name       : FindIniSel
#
#   Purpose....: Find ini sel
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct TIni *FindIniSel(int FileSel)
{
    struct TIni *Ini = IniList;

    while (Ini)
    {
        if (Ini->FileSel == FileSel)
            break;

        Ini = Ini->FNextIni;
    }

    return Ini;
}

/*##########################################################################
#
#   Name       : FindIniName
#
#   Purpose....: Find ini by filename
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct TIni *FindIniName(const char *FileName)
{
    struct TIni *Ini = IniList;

    while (Ini)
    {
        if (strcmp(Ini->Name, FileName) == 0)
            break;

        Ini = Ini->FNextIni;
    }

    return Ini;
}

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
struct TIni *CreateIniSel(char *FileName)
{
    struct TIni *Ini = 0;
    int sel;
    int NameSize;
    int BaseSize = 0;
    long FileSize = 0;
    int Size;
    char Access;
    char Drive;
    int FileSel = 0;
    int FileHandle = RdosOpenFile(FileName, 0);

    if (FileHandle)
        RdosGetFileInfo(FileHandle, &Access, &Drive, &FileSel);

    RdosEnterKernelSection(&IniSection);

    if (FileSel)
        Ini = FindIniSel(FileSel);
    else
        Ini = FindIniName(FileName);

    if (!Ini)
    {
        if (FileSel)
            FileSize = RdosGetFileSize(FileHandle);

        NameSize = strlen(FileName) + 1;
        BaseSize = NameSize + sizeof(struct TIni) - 1;

        Size = FileSize + BaseSize + 1;
    
        sel = RdosAllocateSmallGlobalSelector(Size);
        Ini = (struct TIni*)RdosSelectorToPointer(sel);
        strcpy(Ini->Name, FileName);
    
        Ini->Data = &Ini->Name[NameSize];
        if (FileSize)
            RdosReadFile(FileHandle, Ini->Data, FileSize);
        
        Ini->Data[FileSize] = 0;

        if (FileSel)
        {
            Ini->Access = Access;
            Ini->Drive = Drive;
            Ini->FileSel = FileSel;
            RdosLockFile(Ini->FileSel);
            RdosCloseFile(FileHandle);    
        }
        else
            Ini->FileSel = 0;

        Ini->Users = 0;
        Ini->Modified = FALSE;
        Ini->FSectionList = 0;
        Ini->BaseSize = BaseSize;
        Ini->BufSize = FileSize + 1;
        Ini->SectionCount = 0;
        Ini->VarCount = 0;
        Ini->MaxBufSize = FileSize + 1;
        Ini->MaxSectionCount = 0;
        Ini->MaxVarCount = 0;
        RdosInitKernelSection(&Ini->Section);

        ParseIni(Ini);

        Ini->FNextIni = IniList;
        IniList = Ini;
    }

    Ini->Users++;

    RdosLeaveKernelSection(&IniSection);

    return Ini;
}

/*##########################################################################
#
#   Name       : WriteIni
#
#   Purpose....: Write ini-file from in-memory contents
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void WriteIni(struct TIni *Ini)
{
    int handle;
    struct TIniSection *sect;
    struct TIniVar *var;
    char str[100];
    
    if (Ini->FileSel)
        handle = RdosDuplFileInfo(Ini->Access, Ini->Drive, Ini->FileSel);
    else
        handle = RdosCreateFile(Ini->Name, FILE_ATTRIBUTE_NORMAL);

    if (handle)
    {
        RdosSetFileSize(handle, 0);

        sect = Ini->FSectionList;

        while (sect)
        {
            if (!sect->Deleted)
            {
                sprintf(str, "[%s]\r\n", sect->Name);
                RdosWriteFile(handle, str, strlen(str));

                var = sect->FVarList;

                while (var)
                {
                    if (!var->Deleted)
                    {
                        sprintf(str, "%s=%s\r\n", var->Name, var->Val);
                        RdosWriteFile(handle, str, strlen(str));
                    }
                    var = var->FNextVar;                    
                }
            }    
            sect = sect->FNextSection;        

            strcpy(str, "\r\n");
            RdosWriteFile(handle, str, strlen(str));
        }

        RdosCloseFile(handle);
    }        
    Ini->Modified = FALSE;
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
struct TIniHandle *CreateHandle(struct TIni *Ini)
{
    struct TIniHandle *IniHandle = (struct TIniHandle *)RdosAllocateHandle(INI_HANDLE, sizeof(struct TIniHandle));
    IniHandle->Header.sign = INI_HANDLE;
    IniHandle->Ini = Ini;
    IniHandle->SectionName = 0;

    return IniHandle;
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
    struct TIni *Ini;
    struct TIniHandle* IniHandle;

    Ini = CreateIniSel(FileName);
    IniHandle = CreateHandle(Ini);

    return IniHandle->Header.handle;
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
    struct TIniHandle *IniHandle = (struct TIniHandle *)RdosDerefHandle(INI_HANDLE, Handle);
    struct TIni *Ini;
    struct TIni *prev;
    struct TIni *curr;
    int sel;

    if (IniHandle)
    {
        if (IniHandle->SectionName)
        {
            sel = RdosPointerToSelector(IniHandle->SectionName);
            RdosFreeMem(sel);
        }

        RdosEnterKernelSection(&IniSection);

        Ini = IniHandle->Ini;

        if (Ini->Modified)
            WriteIni(Ini);

        RdosFreeHandle((struct THandleHeader *)IniHandle);

        if (Ini->Users == 1)
        {
            prev = 0;
            curr = IniList;
            while (curr && curr != Ini)
            {
                prev = curr;
                curr = curr->FNextIni;
            }

            if (curr)
            {
                if (prev)
                    prev->FNextIni = curr->FNextIni;
                else
                    IniList = curr->FNextIni;
            }

            if (Ini->FileSel)
                RdosUnlockFile(Ini->FileSel);
                            
            sel = RdosPointerToSelector(Ini);
            RdosFreeMem(sel);        
        }
        else
            Ini->Users--;

        RdosLeaveKernelSection(&IniSection);
    }
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
    struct TIniHandle *IniHandle = (struct TIniHandle *)RdosDerefHandle(INI_HANDLE, Handle);
    int sel;
    int size = strlen(SectionName) + 1;

    if (IniHandle)
    {
        if (IniHandle->SectionName)
        {
            sel = RdosPointerToSelector(IniHandle->SectionName);
            RdosFreeMem(sel);
        }

        sel = RdosAllocateSmallLocalSelector(size + 1);        
        IniHandle->SectionName = RdosSelectorToPointer(sel);

        strcpy(IniHandle->SectionName, SectionName);
        return TRUE;
    }    
    else
        return FALSE;
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
    struct TIniHandle *IniHandle = (struct TIniHandle *)RdosDerefHandle(INI_HANDLE, Handle);
    struct TIni *Ini;
    struct TIniSection *sect;
    struct TIniVar *var;
    int found = FALSE;

    if (IniHandle)
    {
        Ini = IniHandle->Ini;
        
        RdosEnterKernelSection(&Ini->Section);

        sect = Ini->FSectionList;

        while (sect && !found)
        {
            if (sect->Deleted)
                sect = sect->FNextSection;
            else
            {
                if (strcmp(sect->Name, SectionName) == 0)
                {
                    sect->Deleted = TRUE;
                    found = TRUE;
                }
                else
                    sect = sect->FNextSection;                    
            }
        }

        if (found)
        {
            var = sect->FVarList;

            while (var)
            {
                var->Deleted = TRUE;
                var = var->FNextVar;                    
            }            

            Ini->Modified = TRUE;
            
        }
        RdosLeaveKernelSection(&Ini->Section);
    }    
    return found;
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
#pragma aux ReadIniVar "*" rdosdev parm routine [ebx] [fs esi] [es edi] [ecx] value [eax]
int ReadIniVar(int Handle, char *VarName, char *Buf, int MaxSize)
{
    struct TIniHandle *IniHandle = (struct TIniHandle *)RdosDerefHandle(INI_HANDLE, Handle);
    struct TIni *Ini;
    struct TIniSection *sect;
    struct TIniVar *var;
    int found = FALSE;
    int size = 0;

    if (IniHandle && IniHandle->SectionName && MaxSize)
    {
        Ini = IniHandle->Ini;
        
        RdosEnterKernelSection(&Ini->Section);

        sect = Ini->FSectionList;

        while (sect && !found)
        {
            if (sect->Deleted)
                sect = sect->FNextSection;
            else
            {
                if (strcmp(IniHandle->SectionName, sect->Name) == 0)
                    found = TRUE;
                else
                    sect = sect->FNextSection;                    
            }
        }

        if (found)
        {
            found = FALSE;

            var = sect->FVarList;

            while (var && !found)
            {
                if (var->Deleted)
                    var = var->FNextVar;                    
                else
                {
                    if (strcmp(var->Name, VarName) == 0)
                        found = TRUE;
                    else
                        var = var->FNextVar;                    
                }
            }            
        }

        if (found)
        {
            size = strlen(var->Val);
            if (size >= MaxSize)
                size = MaxSize - 1;

            strncpy(Buf, var->Val, size);
            Buf[size] = 0;
        }
        RdosLeaveKernelSection(&Ini->Section);
    }    
    return found;
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
#pragma aux WriteIniVar "*" rdosdev parm routine [ebx] [fs esi] [es edi] value [eax]
int WriteIniVar(int Handle, char *VarName, char *Buf)
{
    struct TIniHandle *IniHandle = (struct TIniHandle *)RdosDerefHandle(INI_HANDLE, Handle);
    struct TIni *Ini;
    struct TIniSection *sect;
    struct TIniVar *var;
    int found = FALSE;
    char *name;
    char *val;
    char *str;

    if (IniHandle && IniHandle->SectionName)
    {
        Ini = IniHandle->Ini;
        
        RdosEnterKernelSection(&Ini->Section);
        name = AddString(Ini, VarName);
        val = AddString(Ini, Buf);

        sect = Ini->FSectionList;

        while (sect && !found)
        {
            if (strcmp(IniHandle->SectionName, sect->Name) == 0)
                found = TRUE;
            else
                sect = sect->FNextSection;                    
        }

        if (!found)
        {
            str = AddString(Ini, IniHandle->SectionName);
            sect = AddSection(Ini, str, 0);
        }

        sect->Deleted = FALSE;

        found = FALSE;

        var = sect->FVarList;

        while (var && !found)
        {
            if (strcmp(var->Name, VarName) == 0)
                found = TRUE;
            else
                var = var->FNextVar;                    
        }            

        if (found)
        {
            var->Deleted = FALSE;
            var->Val = val;
        }
        else
            AddVar(Ini, sect, name, val);

        Ini->Modified = TRUE;
        
        RdosLeaveKernelSection(&Ini->Section);

        return TRUE;
    }    
    else
        return FALSE;
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
#pragma aux DeleteIniVar "*" rdosdev parm routine [ebx] [fs esi] value [eax]
int DeleteIniVar(int Handle, char *VarName)
{
    struct TIniHandle *IniHandle = (struct TIniHandle *)RdosDerefHandle(INI_HANDLE, Handle);
    struct TIni *Ini;
    struct TIniSection *sect;
    struct TIniVar *var;
    int found = FALSE;

    if (IniHandle && IniHandle->SectionName)
    {
        Ini = IniHandle->Ini;
        
        RdosEnterKernelSection(&Ini->Section);

        sect = Ini->FSectionList;

        while (sect && !found)
        {
            if (sect->Deleted)
                sect = sect->FNextSection;
            else
            {
                if (strcmp(IniHandle->SectionName, sect->Name) == 0)
                    found = TRUE;
                else
                    sect = sect->FNextSection;                    
            }
        }

        if (found)
        {
            found = FALSE;

            var = sect->FVarList;

            while (var && !found)
            {
                if (var->Deleted)
                    var = var->FNextVar;                    
                else
                {
                    if (strcmp(var->Name, VarName) == 0)
                    {
                        var->Deleted = TRUE;
                        found = TRUE;
                    }
                    else
                        var = var->FNextVar;                    
                }
            }            
        }

        if (found)
            Ini->Modified = TRUE;
            
        RdosLeaveKernelSection(&Ini->Section);
    }    
    return found;
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
#   Name       : SyncThread
#
##########################################################################*/
#pragma aux SyncThread "*" rdosdev parm routine [es edi]
void __far SyncThread(void *param)
{
    struct TIni *Ini;
    
    for (;;)
    {
        RdosWaitMilli(1000);

        RdosEnterKernelSection(&IniSection);

        Ini = IniList;
        while (Ini)
        {
            if (Ini->Modified)
            {
                RdosEnterKernelSection(&Ini->Section);
                WriteIni(Ini);
                RdosLeaveKernelSection(&Ini->Section);
            }
            Ini = Ini->FNextIni;
        }
        RdosLeaveKernelSection(&IniSection);
    }
}

/*##########################################################################
#
#   Name       : InitTasking
#
#   Purpose....: Init tasking callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux InitTasking "*" rdosdev parm routine
void __far InitTasking()
{
    RdosCreateKernelThread(1, 0x1000, &SyncThread, "Ini-file sync", 0);
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
    OldSel = RdosAllocateGdt();
    
    RdosInitKernelSection(&IniSection);

    InitGates();

    RdosRegisterBimodalUserGate(usergate_open_sys_ini, &ImplOpenSysIni, "Open Sys Ini");
    RdosRegisterSegUserGate(usergate_open_ini, GATE_ES_IN, &ImplOpenIni16, &ImplOpenIni32, "Open Ini");
    RdosRegisterBimodalUserGate(usergate_close_ini, &ImplCloseIni, "Close Ini");
    RdosRegisterSegUserGate(usergate_goto_ini_section, GATE_ES_IN, &ImplGotoIniSection16, &ImplGotoIniSection32, "Goto Ini Section");
    RdosRegisterSegUserGate(usergate_remove_ini_section, GATE_ES_IN, &ImplRemoveIniSection16, &ImplRemoveIniSection32, "Remove Ini Section");
    RdosRegisterHandle(INI_HANDLE, &ImplDeleteHandle);    
    RdosHookInitTasking(&InitTasking);
}
