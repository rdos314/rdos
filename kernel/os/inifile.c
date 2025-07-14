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
# inifile.c
# Ini-file interface
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "rdosdev.h"

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
    struct TIniVar *FCurrVar;
    struct TIniVar *FVarList;
    struct TIniSection *FNextSection;
};

struct TIni
{
    int Modified;
    int Users;
    int BufSize;
    int SectionCount;
    int VarCount;
    int MaxBufSize;
    int MaxSectionCount;
    int MaxVarCount;
    struct TIniSection *FSectionList;
    int DataSel;
    char *DataBuf;
    char Name[1];
};

struct TIniHandle
{
    struct THandleHeader Header;
    struct TIni *Ini;
    char *SectionName;
};

extern void InitGates();

extern void Lock();

extern void Unlock();

extern void LockIni(struct TIni *Ini);
#pragma aux LockIni parm routine [dx eax]

extern void UnlockIni(struct TIni *Ini);
#pragma aux UnlockIni parm routine [dx eax]

extern void InsertIni(struct TIni *Ini);
#pragma aux InsertIni parm routine [dx eax]

extern void RemoveIni(struct TIni *Ini);
#pragma aux RemoveIni parm routine [dx eax]

extern struct TIni *CreateIni(int Size);
#pragma aux CreateIni parm routine [ecx] value [dx eax]

extern void DeleteIni(struct TIni *Ini);
#pragma aux DeleteIni parm routine [dx eax]

extern struct TIni *GetFirstIni();
#pragma aux GetFirstIni value [dx eax]

extern struct TIni *GetNextIni(struct TIni *Ini);
#pragma aux GetNextIni parm routine [dx eax] value [dx eax]


static int OldSel;
static int SysIniRead = FALSE;
static char SysIniName[256];

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
    int i;
    int j;
    int offset;
    long Pos;
    long SrcVarPos;
    long DestVarPos;
    struct TIniSection *SrcSect;
    struct TIniSection *DestSect;
    struct TIniSection *sect;
    struct TIniVar *var;
    struct TIniVar *SrcVar;
    struct TIniVar *DestVar;

    long NewBase;
    int NewSize;
    long OldBase;
    long OldSize;
    int oldsel;
    int newsel;
    char *SrcBuf;
    char *DestBuf;

    OldSize = Ini->MaxBufSize;
    OldSize += Ini->MaxSectionCount * sizeof(struct TIniSection);
    OldSize += Ini->MaxVarCount * sizeof(struct TIniVar);

    NewSize = BufSize;
    NewSize += SectionCount * sizeof(struct TIniSection);
    NewSize += VarCount * sizeof(struct TIniVar);

    oldsel = Ini->DataSel;

    NewBase = RdosAllocateSmallGlobalLinear(NewSize);
    newsel = RdosAllocateGdt();
    RdosCreateDataSelector32(newsel, NewBase, NewSize);

    RdosGetSelectorBaseSize(oldsel, &OldBase, &OldSize);

    SrcBuf = (char *)RdosSelectorToPointer(oldsel);
    DestBuf = (char *)RdosLinearToPointer(NewBase);

    memcpy(DestBuf, SrcBuf, OldSize);

    SrcVarPos = Ini->MaxBufSize + Ini->MaxSectionCount * sizeof(struct TIniSection);
    DestVarPos = BufSize + SectionCount * sizeof(struct TIniSection);

    if (Ini->FSectionList)
    {
        offset = RdosPointerToOffset(Ini->FSectionList);
        sect = (struct TIniSection*)RdosSelectorOffsetToPointer(oldsel, offset);
        j = sect->Index;

        Pos = BufSize + j * sizeof(struct TIniSection);
        sect = (struct TIniSection*)RdosSelectorOffsetToPointer(newsel, Pos);
        Ini->FSectionList = sect;
    }

    for (i = 0; i < Ini->SectionCount; i++)
    {
        Pos = Ini->MaxBufSize + i * sizeof(struct TIniSection);
        SrcSect = (struct TIniSection*)RdosSelectorOffsetToPointer(oldsel, Pos);

        Pos = BufSize + i * sizeof(struct TIniSection);
        DestSect = (struct TIniSection*)RdosSelectorOffsetToPointer(newsel, Pos);
        *DestSect = *SrcSect;

        offset = RdosPointerToOffset(SrcSect->Name);
        DestSect->Name = (char *)RdosSelectorOffsetToPointer(newsel, offset);

        if (SrcSect->FNextSection)
        {
            offset = RdosPointerToOffset(SrcSect->FNextSection);
            sect = (struct TIniSection*)RdosSelectorOffsetToPointer(oldsel, offset);
            j = sect->Index;

            Pos = BufSize + j * sizeof(struct TIniSection);
            sect = (struct TIniSection*)RdosSelectorOffsetToPointer(newsel, Pos);
            DestSect->FNextSection = sect;
        }

        if (SrcSect->FVarList)
        {
            offset = RdosPointerToOffset(SrcSect->FVarList);
            var = (struct TIniVar*)RdosSelectorOffsetToPointer(oldsel, offset);
            j = var->Index;

            Pos = j * sizeof(struct TIniVar);
            var = (struct TIniVar*)RdosSelectorOffsetToPointer(newsel, DestVarPos + Pos);
            DestSect->FVarList = var;
        }
    }

    for (i = 0; i < Ini->VarCount; i++)
    {
        Pos = i * sizeof(struct TIniVar);
        SrcVar = (struct TIniVar*)RdosSelectorOffsetToPointer(oldsel, SrcVarPos + Pos);
        DestVar = (struct TIniVar*)RdosSelectorOffsetToPointer(newsel, DestVarPos + Pos);
        *DestVar = *SrcVar;

        offset = RdosPointerToOffset(SrcVar->Name);
        DestVar->Name = (char *)RdosSelectorOffsetToPointer(newsel, offset);

        offset = RdosPointerToOffset(SrcVar->Val);
        DestVar->Val = (char *)RdosSelectorOffsetToPointer(newsel, offset);

        if (SrcVar->FNextVar)
        {
            offset = RdosPointerToOffset(SrcVar->FNextVar);
            var = (struct TIniVar*)RdosSelectorOffsetToPointer(oldsel, offset);
            j = var->Index;

            Pos = j * sizeof(struct TIniVar);
            var = (struct TIniVar*)RdosSelectorOffsetToPointer(newsel, DestVarPos + Pos);
            DestVar->FNextVar = var;
        }
    }

    Ini->DataSel = newsel;
    Ini->DataBuf = (char *)RdosSelectorOffsetToPointer(newsel, 0);
    Ini->MaxBufSize = BufSize;
    Ini->MaxSectionCount = SectionCount;
    Ini->MaxVarCount = VarCount;
    RdosFreeMem(oldsel);
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
    struct TIniVar *IniVar;
    struct TIniVar *var;
    int offset;

    if (Ini->VarCount == Ini->MaxVarCount)
        GrowIni(Ini, Ini->MaxBufSize, Ini->MaxSectionCount, 3 * (Ini->VarCount + 1) / 2);

    offset = RdosPointerToOffset(name);
    name = (char *)RdosSelectorOffsetToPointer(Ini->DataSel, offset);

    offset = RdosPointerToOffset(val);
    val = (char *)RdosSelectorOffsetToPointer(Ini->DataSel, offset);

    offset = RdosPointerToOffset(IniSect);
    IniSect = (struct TIniSection *)RdosSelectorOffsetToPointer(Ini->DataSel, offset);

    pos = Ini->MaxBufSize;
    pos += Ini->MaxSectionCount * sizeof(struct TIniSection);
    pos += Ini->VarCount * sizeof(struct TIniVar);

    IniVar = (struct TIniVar *)(Ini->DataBuf + pos);
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
    char *ptr = Ini->DataBuf;
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

        DestStr = Ini->DataBuf;
        DestStr += Ini->BufSize;
        strcpy(DestStr, str);
        Ini->BufSize += StrSize;
    }
    return DestStr;
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
void DecodeLine(struct TIni *Ini, int SectionIndex, char *ptr)
{
    char *name = ptr;
    int offset;
    struct TIniSection *IniSect;

    while (*ptr && *ptr != '=')
        ptr++;

    if (*ptr == '=')
    {
        *ptr = 0;
        ptr++;

        name = Trim(name);
        ptr = Trim(ptr);

        name = AddString(Ini, name);
        ptr = AddString(Ini, ptr);

        offset = Ini->MaxBufSize + SectionIndex * sizeof(struct TIniSection);
        IniSect = (struct TIniSection*)RdosSelectorOffsetToPointer(Ini->DataSel, offset);

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
void ParseSection(struct TIni *Ini, int SectionIndex, char *ptr)
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
                DecodeLine(Ini, SectionIndex, prev_line);

            prev_line = curr_line;
            ptr = curr_line;
        }
        else
        {
            if (prev_line)
                DecodeLine(Ini, SectionIndex, prev_line);

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
    struct TIniSection *IniSect;
    struct TIniSection *sect;
    int offset;

    if (Ini->SectionCount == Ini->MaxSectionCount)
    {
        GrowIni(Ini, Ini->MaxBufSize, 3 * (Ini->SectionCount + 1) / 2, Ini->MaxVarCount);

        offset = RdosPointerToOffset(name);
        name = (char *)RdosSelectorOffsetToPointer(Ini->DataSel, offset);
    }

    pos = Ini->MaxBufSize;
    pos += Ini->SectionCount * sizeof(struct TIniSection);

    IniSect = (struct TIniSection *)(Ini->DataBuf + pos);

    IniSect->Index = Ini->SectionCount;
    IniSect->Deleted = FALSE;
    IniSect->FVarList = 0;
    IniSect->FCurrVar = 0;
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
        ParseSection(Ini, IniSect->Index, ptr);

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

        name = AddString(Ini, name);
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
void ParseIni(struct TIni *Ini, char *ptr)
{
    char *prev_sec = 0;
    char *curr_sec = 0;

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
    struct TIni *Ini;

    Ini = GetFirstIni();

    while (Ini)
    {
        if (strcmp(Ini->Name, FileName) == 0)
            break;

        Ini = GetNextIni(Ini);
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
    char *buf;
    int NameSize;
    long FileSize = 0;
    int Size;
    int sel;
    int DriveNr;
    char Path[260];
    int FileHandle;

    if (FileName[1] == ':')
        strcpy(Path, FileName);
    else
    {
        DriveNr = RdosGetCurDrive();
        Path[0] = (char)DriveNr + 'A';
        Path[1] = ':';

        if (FileName[0] == '\\' || FileName[0] == '/')
            strcpy(&Path[2], FileName);
        else
        {
            Path[2] = '/';
            RdosGetCurDir(DriveNr, &Path[3]);
            if (Path[3] != 0)
                strcat(Path, "/");
            strcat(Path, FileName);
        }
    }

    Lock();

    Ini = FindIniName(Path);

    if (!Ini)
    {

        FileHandle = RdosOpenFile(Path, 0);

        if (FileHandle)
            FileSize = RdosGetFileSize(FileHandle);

        NameSize = strlen(Path) + 1;
        Size = NameSize + sizeof(struct TIni);

        Ini = CreateIni(Size);
        strcpy(Ini->Name, Path);

        Ini->DataSel = RdosAllocateSmallGlobalSelector(1);
        Ini->DataBuf = (char *)RdosSelectorOffsetToPointer(Ini->DataSel, 0);

        Ini->Users = 0;
        Ini->Modified = FALSE;
        Ini->FSectionList = 0;
        Ini->BufSize = 1;
        Ini->SectionCount = 0;
        Ini->VarCount = 0;
        Ini->MaxBufSize = 1;
        Ini->MaxSectionCount = 0;
        Ini->MaxVarCount = 0;

        if (FileSize)
        {
            buf = RdosAllocateSmallGlobalMem(FileSize + 2);
            RdosReadFile(FileHandle, buf, FileSize);
            buf[FileSize] = 0;
            buf[FileSize + 1] = 0;
            ParseIni(Ini, buf);
            sel = RdosPointerToSelector(buf);
            RdosFreeMem(sel);
        }

        if (FileHandle)
            RdosCloseFile(FileHandle);

        InsertIni(Ini);
    }

    Ini->Users++;

    Unlock();

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

    LockIni(Ini);

    handle = RdosOpenFile(Ini->Name, 0);
    if (handle)
        RdosSetFileSize(handle, 0);
    else
        handle = RdosCreateFile(Ini->Name, 0);

    if (handle)
    {
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

    UnlockIni(Ini);
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
#   Name       : DupIni
#
#   Purpose....: Duplicate ini
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int DupIni(int Handle)
{
    struct TIniHandle *IniHandle = (struct TIniHandle *)RdosDerefHandle(INI_HANDLE, Handle);
    struct TIni *Ini;

    if (IniHandle)
    {
        Ini = IniHandle->Ini;

        Lock();
        Ini->Users++;
        Unlock();

        IniHandle = CreateHandle(Ini);

        return IniHandle->Header.handle;
    }
    else
        return 0;
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
    int sel;

    if (IniHandle)
    {
        Ini = IniHandle->Ini;

        LockIni(Ini);

        if (IniHandle->SectionName)
            sel = RdosPointerToSelector(IniHandle->SectionName);
        else
            sel = 0;

        RdosFreeHandle((struct THandleHeader *)IniHandle);

        UnlockIni(Ini);

        RdosWaitMilli(10);

        LockIni(Ini);

        if (sel)
            RdosFreeMem(sel);

        UnlockIni(Ini);

        Lock();

        if (Ini->Modified)
            WriteIni(Ini);

        if (Ini->Users == 1)
        {
            RemoveIni(Ini);
            RdosFreeMem(Ini->DataSel);
            DeleteIni(Ini);
        }
        else
            Ini->Users--;

        Unlock();
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

        sel = RdosAllocateSmallGlobalSelector(size + 1);
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

        LockIni(Ini);

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

        UnlockIni(Ini);

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

        LockIni(Ini);

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

        UnlockIni(Ini);

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

        LockIni(Ini);

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

        UnlockIni(Ini);

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

        LockIni(Ini);

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

                        if (var == sect->FCurrVar)
                            sect->FCurrVar = 0;
                    }
                    else
                        var = var->FNextVar;
                }
            }
        }

        if (found)
            Ini->Modified = TRUE;

        UnlockIni(Ini);

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
#   Name       : ImplDupIni
#
#   Purpose....: Duplicate ini handle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplDupIni "*" rdosdev parm routine [ebx] value [ebx]
int __far ImplDupIni(int InHandle)
{
    int OutHandle;

    OutHandle = DupIni(InHandle);

    if (OutHandle)
        RdosSetSuccess();
    else
        RdosSetFailure();

    return OutHandle;
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
#   Name       : ImplGetFirstVar
#
#   Purpose....: Goto first var
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGotoFirstVar "*" rdosdev parm routine [ebx]
void __far ImplGotoFirstVar(int handle)
{
    struct TIniHandle *IniHandle = (struct TIniHandle *)RdosDerefHandle(INI_HANDLE, handle);
    struct TIni *Ini;
    struct TIniSection *sect;
    struct TIniVar *var;
    int found = FALSE;

    if (IniHandle && IniHandle->SectionName)
    {
        Ini = IniHandle->Ini;

        LockIni(Ini);

        sect = Ini->FSectionList;

        while (sect && !found)
        {
            if (strcmp(IniHandle->SectionName, sect->Name) == 0)
                found = TRUE;
            else
                sect = sect->FNextSection;
        }

        if (found)
        {
            var = sect->FVarList;

            while (var)
            {
                if (var->Deleted)
                    var = var->FNextVar;
                else
                    break;
            }

            sect->FCurrVar = var;

            if (!var)
                found = FALSE;
        }

        UnlockIni(Ini);

    }

    if (found)
        RdosSetSuccess();
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : ImplGetNextVar
#
#   Purpose....: Goto next var
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGotoNextVar "*" rdosdev parm routine [ebx]
void __far ImplGotoNextVar(int handle)
{
    struct TIniHandle *IniHandle = (struct TIniHandle *)RdosDerefHandle(INI_HANDLE, handle);
    struct TIni *Ini;
    struct TIniSection *sect;
    struct TIniVar *var;
    int found = FALSE;

    if (IniHandle && IniHandle->SectionName)
    {
        Ini = IniHandle->Ini;

        LockIni(Ini);

        sect = Ini->FSectionList;

        while (sect && !found)
        {
            if (strcmp(IniHandle->SectionName, sect->Name) == 0)
                found = TRUE;
            else
                sect = sect->FNextSection;
        }

        if (found)
        {
            var = sect->FCurrVar;

            if (var)
                var = var->FNextVar;

            while (var)
            {
                if (var->Deleted)
                    var = var->FNextVar;
                else
                    break;
            }

            sect->FCurrVar = var;

            if (!var)
                found = FALSE;
        }

        UnlockIni(Ini);

    }

    if (found)
        RdosSetSuccess();
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : GetCurrVar
#
#   Purpose....: Get current var
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int GetCurrVar(int Handle, char *VarName, int MaxSize)
{
    struct TIniHandle *IniHandle = (struct TIniHandle *)RdosDerefHandle(INI_HANDLE, Handle);
    struct TIni *Ini;
    struct TIniSection *sect;
    struct TIniVar *var;
    int found = FALSE;
    int size;

    if (IniHandle && IniHandle->SectionName)
    {
        Ini = IniHandle->Ini;

        LockIni(Ini);

        sect = Ini->FSectionList;

        while (sect && !found)
        {
            if (strcmp(IniHandle->SectionName, sect->Name) == 0)
                found = TRUE;
            else
                sect = sect->FNextSection;
        }

        if (found)
        {
            var = sect->FCurrVar;
            if (var)
            {
                size = strlen(var->Name);
                if (size >= MaxSize)
                    size = MaxSize - 1;

                strncpy(VarName, var->Name, size);
                VarName[size] = 0;
            }
            else
                found = FALSE;
        }

        UnlockIni(Ini);

    }

    return found;
}

/*##########################################################################
#
#   Name       : ImplGetCurrVar
#
#   Purpose....: Get current inivar, 16-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetCurrVar16 "*" rdosdev parm routine [ebx] [es edi] [ecx]
void __far ImplGetCurrVar16(int handle, char *var, int maxsize)
{
    int ok;

    RdosExtendCx();
    RdosExtendDi();

    ok = GetCurrVar(handle, var, maxsize);

    if (ok)
        RdosSetSuccess();
    else
        RdosSetFailure();
}

/*##########################################################################
#
#   Name       : ImplGetCurrVar32
#
#   Purpose....: Get current var, 32-bit version
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
#pragma aux ImplGetCurrVar32 "*" rdosdev parm routine [ebx] [es edi] [ecx]
void __far ImplGetCurrVar32(int handle, char *var, int maxsize)
{
    int ok;

    ok = GetCurrVar(handle, var, maxsize);

    if (ok)
        RdosSetSuccess();
    else
        RdosSetFailure();
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

        Lock();

        Ini = GetFirstIni();
        while (Ini)
        {
            if (Ini->Modified)
                WriteIni(Ini);

            Ini = GetNextIni(Ini);
        }

        Unlock();
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

    InitGates();

    RdosRegisterBimodalUserGate(usergate_open_sys_ini, (__rdos_gate_callback *)&ImplOpenSysIni, "Open Sys Ini");
    RdosRegisterSegUserGate(usergate_open_ini, GATE_ES_IN, (__rdos_gate_callback *)&ImplOpenIni16, (__rdos_gate_callback *)&ImplOpenIni32, "Open Ini");
    RdosRegisterBimodalUserGate(usergate_dup_ini, (__rdos_gate_callback *)&ImplDupIni, "Dup Ini");
    RdosRegisterBimodalUserGate(usergate_close_ini, (__rdos_gate_callback *)&ImplCloseIni, "Close Ini");
    RdosRegisterSegUserGate(usergate_goto_ini_section, GATE_ES_IN, (__rdos_gate_callback *)&ImplGotoIniSection16, (__rdos_gate_callback *)&ImplGotoIniSection32, "Goto Ini Section");
    RdosRegisterSegUserGate(usergate_remove_ini_section, GATE_ES_IN, (__rdos_gate_callback *)&ImplRemoveIniSection16, (__rdos_gate_callback *)&ImplRemoveIniSection32, "Remove Ini Section");
    RdosRegisterBimodalUserGate(usergate_goto_first_inivar, (__rdos_gate_callback *)&ImplGotoFirstVar, "Goto First Inivar");
    RdosRegisterBimodalUserGate(usergate_goto_next_inivar, (__rdos_gate_callback *)&ImplGotoNextVar, "Goto Next Inivar");
    RdosRegisterSegUserGate(usergate_get_curr_inivar, GATE_ES_IN, (__rdos_gate_callback *)&ImplGetCurrVar16, (__rdos_gate_callback *)&ImplGetCurrVar32, "Get Current Inivar");
    RdosRegisterHandle(INI_HANDLE, &ImplDeleteHandle);
    RdosHookInitTasking(&InitTasking);
    return 0;
}
