/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# appini.cpp
# App ini file class
#
########################################################################*/

#include <string.h>
#include "rdos.h"
#include "appini.h"

/*##########################################################################
#
#   Name       : TAppIniVar::TAppIniVar
#
#   Purpose....: Constructor for TAppIniVar
#
#   In params..: filename
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAppIniVar::TAppIniVar(const char *Name, const char *Val)
  : FName(Name),
    FVal(Val)
{
    FNextVar = 0;
}

/*##########################################################################
#
#   Name       : TAppIniVar::~TAppIniVar
#
#   Purpose....: Destructor for TAppIniVar
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAppIniVar::~TAppIniVar()
{
}

/*##########################################################################
#
#   Name       : TAppIniVar::IsMatch
#
#   Purpose....: Check for match
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAppIniVar::IsMatch(const char *Name)
{
    return FName == Name;
}

/*##########################################################################
#
#   Name       : TAppIniVar::GetName
#
#   Purpose....: Get name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TAppIniVar::GetName()
{
    return FName.GetData();
}

/*##########################################################################
#
#   Name       : TAppIniVar::GetData
#
#   Purpose....: Get value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TAppIniVar::GetData()
{
    return FVal.GetData();
}

/*##########################################################################
#
#   Name       : TAppIniVar::SetData
#
#   Purpose....: Set value
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAppIniVar::SetData(const char *Val)
{
    FVal = Val;
}

/*##########################################################################
#
#   Name       : TAppIniVar::GetSize
#
#   Purpose....: Get size of variable when printed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAppIniVar::GetSize()
{
    return FName.GetSize() + FVal.GetSize() + 3;
}

/*##########################################################################
#
#   Name       : TAppIniVar::Format
#
#   Purpose....: Format data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TAppIniVar::Format(char *buf)
{
    char *ptr = buf;

    strcpy(ptr, FName.GetData());
    ptr += FName.GetSize();

    *ptr = '=';
    ptr++;

    strcpy(ptr, FVal.GetData());
    ptr += FVal.GetSize();

    *ptr = 0xd;
    ptr++;

    *ptr = 0xa;
    ptr++;

    *ptr = 0;

    return ptr;
}

/*##########################################################################
#
#   Name       : TAppIniSection::TAppIniSection
#
#   Purpose....: Constructor for TAppIniSection
#
#   In params..: filename
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAppIniSection::TAppIniSection(const char *Name)
 : FName(Name)
{
    FVarList = 0;
    FCurrVar = 0;
    FNextSection = 0;
}

/*##########################################################################
#
#   Name       : TAppIniSection::~TAppIniSection
#
#   Purpose....: Destructor for TAppIniSection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAppIniSection::~TAppIniSection()
{
    ClearVars();
}

/*##########################################################################
#
#   Name       : TAppIniSection::ClearVars
#
#   Purpose....: Clear variables
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAppIniSection::ClearVars()
{
    TAppIniVar *var;

    FCurrVar = 0;

    while (FVarList)
    {
        var = FVarList->FNextVar;
        delete FVarList;
        FVarList = var;
    }
}

/*##########################################################################
#
#   Name       : TAppIniSection::IsMatch
#
#   Purpose....: Check for match
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAppIniSection::IsMatch(const char *Name)
{
    return FName == Name;
}

/*##########################################################################
#
#   Name       : TAppIniSection::GetSize
#
#   Purpose....: Get size of section when printed
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TAppIniSection::GetSize()
{
    int size = FName.GetSize() + 6;
    TAppIniVar *var = FVarList;

    while (var)
    {
        size += var->GetSize();
        var = var->FNextVar;
    }

    return size;
}

/*##########################################################################
#
#   Name       : TAppIniSection::Format
#
#   Purpose....: Format data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TAppIniSection::Format(char *buf)
{
    char *ptr = buf;
    TAppIniVar *var = FVarList;

    *ptr = '[';
    ptr++;

    strcpy(ptr, FName.GetData());
    ptr += FName.GetSize();

    *ptr = ']';
    ptr++;

    *ptr = 0xd;
    ptr++;

    *ptr = 0xa;
    ptr++;

    while (var)
    {
        ptr = var->Format(ptr);
        var = var->FNextVar;
    }

    *ptr = 0xd;
    ptr++;

    *ptr = 0xa;
    ptr++;

    *ptr = 0;

    return ptr;
}

/*##########################################################################
#
#   Name       : TAppIniSection::FindVar
#
#   Purpose....: Find variable
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAppIniVar *TAppIniSection::FindVar(const char *Name)
{
    TAppIniVar *var = FVarList;

    while (var)
    {
        if (var->IsMatch(Name))
            break;

        var = var->FNextVar;
    }

    return var;
}

/*##########################################################################
#
#   Name       : TAppIniSection::AddVar
#
#   Purpose....: Add variable
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAppIniSection::AddVar(const char *Name, const char *Val)
{
    TAppIniVar *ins;
    TAppIniVar *var = FindVar(Name);

    if (var)
        var->SetData(Val);
    else
    {
        var = new TAppIniVar(Name, Val);
        var->FNextVar = 0;

        if (FVarList)
        {
            ins = FVarList;

            while (ins->FNextVar)
                ins = ins->FNextVar;

            ins->FNextVar = var;
        }
        else
            FVarList = var;
    }
}

/*##########################################################################
#
#   Name       : TAppIniSection::DeleteVar
#
#   Purpose....: Delete variable
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAppIniSection::DeleteVar(const char *name)
{
    TAppIniVar *var = FVarList;
    TAppIniVar *prev = 0;

    while (var)
    {
        if (var->IsMatch(name))
        {
            if (prev)
                prev->FNextVar = var->FNextVar;
            else
                FVarList = var->FNextVar;

            delete var;
            return true;
        }

        prev = var;
        var = var->FNextVar;
    }

    return false;
}

/*##########################################################################
#
#   Name       : TAppIniSection::FindStartOfLine
#
#   Purpose....: Find start of line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TAppIniSection::FindStartOfLine(char *ptr)
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
#   Name       : TAppIniSection::CheckDelim
#
#   Purpose....: Check if character is a delimiter
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAppIniSection::CheckDelim(char ch)
{
    switch (ch)
    {
	case 0xd:
	case 0xa:
	case ' ':
	case 0x9:
		return true;
    }
    return false;
}

/*##########################################################################
#
#   Name       : TAppIniSection::Trim
#
#   Purpose....: Left and right trim string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TAppIniSection::Trim(char *str)
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
#   Name       : TAppIniSection::DecodeLine
#
#   Purpose....: Decode a single line
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAppIniSection::DecodeLine(char *ptr)
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

        AddVar(name, ptr);
    }
}

/*##########################################################################
#
#   Name       : TAppIniSection::Parse
#
#   Purpose....: Parse ini section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAppIniSection::Parse(char *ptr)
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
                DecodeLine(prev_line);

            prev_line = curr_line;
            ptr = curr_line;
        }
        else
        {
            if (prev_line)
                DecodeLine(prev_line);

            ptr = 0;
        }
    }
}

/*##########################################################################
#
#   Name       : TAppIniFile::TAppIniFile
#
#   Purpose....: Constructor for TAppIniFile
#
#   In params..: filename
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAppIniFile::TAppIniFile(const char *IniName)
  : FName(IniName)
{
    int FileHandle;
    int FileSize = 0;
    char *buf;

    FModified = false;
    FCurrSection = 0;
    FCurrVar = 0;
    FSectionList = 0;

    FileHandle = RdosOpenHandle(IniName, O_RDWR);

    if (FileHandle > 0)
        FileSize = RdosGetHandleSize(FileHandle);

    if (FileSize)
    {
        buf = new char[FileSize + 2];
        RdosReadHandle(FileHandle, buf, FileSize);
        buf[FileSize] = 0;
        buf[FileSize + 1] = 0;
        Parse(buf);
        delete buf;
    }

    if (FileHandle)
        RdosCloseHandle(FileHandle);
}

/*##########################################################################
#
#   Name       : TAppIniFile::TAppIniFile
#
#   Purpose....: Copy constructor for TAppIniFile
#
#   In params..: infile to duplicate handle on
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAppIniFile::TAppIniFile(const TAppIniFile &ini)
  : FName(ini.FName)
{
    int FileHandle;
    int FileSize = 0;
    char *buf;

    FModified = false;
    FCurrSection = 0;
    FCurrVar = 0;
    FSectionList = 0;

    FileHandle = RdosOpenHandle(ini.FName.GetData(), O_RDWR);

    if (FileHandle > 0)
        FileSize = RdosGetHandleSize(FileHandle);

    if (FileSize)
    {
        buf = new char[FileSize + 2];
        RdosReadHandle(FileHandle, buf, FileSize);
        buf[FileSize] = 0;
        buf[FileSize + 1] = 0;
        Parse(buf);
        delete buf;
    }

    if (FileHandle)
        RdosCloseHandle(FileHandle);
}

/*##########################################################################
#
#   Name       : TAppIniFile::~TAppIniFile
#
#   Purpose....: Destructor for TAppIniFile
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAppIniFile::~TAppIniFile()
{
    if (FModified)
        Update();

    ClearSections();
}

/*##########################################################################
#
#   Name       : TAppIniFile::FindSectionStart
#
#   Purpose....: Find first section in string
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TAppIniFile::FindSectionStart(char *ptr)
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
#   Name       : TAppIniFile::FindSection
#
#   Purpose....: Find section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAppIniSection *TAppIniFile::FindSection(const char *Name)
{
    TAppIniSection *sect = FSectionList;

    while (sect)
    {
        if (sect->IsMatch(Name))
            break;

        sect = sect->FNextSection;
    }

    return sect;
}

/*##########################################################################
#
#   Name       : TAppIniFile::AddSection
#
#   Purpose....: Add section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TAppIniSection *TAppIniFile::AddSection(const char *Name)
{
    TAppIniSection *ins;
    TAppIniSection *sect = FindSection(Name);

    if (!sect)
    {
        sect = new TAppIniSection(Name);
        sect->FNextSection = 0;

        if (FSectionList)
        {
            ins = FSectionList;

            while (ins->FNextSection)
                ins = ins->FNextSection;

            ins->FNextSection = sect;
        }
        else
            FSectionList = sect;
    }

    return sect;
}

/*##########################################################################
#
#   Name       : TAppIniFile::DecodeSection
#
#   Purpose....: Decode a single section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAppIniFile::DecodeSection(char *ptr)
{
    TAppIniSection *sect;
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

        sect = AddSection(name);
        sect->Parse(ptr);
    }
}

/*##########################################################################
#
#   Name       : TAppIniFile::Parse
#
#   Purpose....: Parse ini file into components
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAppIniFile::Parse(char *ptr)
{
    char *prev_sec = 0;
    char *curr_sec = 0;

    while (ptr)
    {
        curr_sec = FindSectionStart(ptr);

        if (curr_sec)
        {
            *curr_sec = 0;
            curr_sec++;

            if (prev_sec)
                DecodeSection(prev_sec);

            prev_sec = curr_sec;
            ptr = curr_sec;
        }
        else
        {
            if (prev_sec)
                DecodeSection(prev_sec);

            ptr = 0;
        }
    }
}

/*##########################################################################
#
#   Name       : TAppIniFile::Update
#
#   Purpose....: Write ini-file from in-memory contents
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAppIniFile::Update()
{
    int handle;
    TAppIniSection *sect;
    int size;
    int orgsize;
    char *buf;
    char *ptr;

    handle = RdosOpenHandle(FName.GetData(), O_RDWR);
    if (handle <= 0)
        handle = RdosOpenHandle(FName.GetData(), O_CREAT | O_RDWR);

    if (handle > 0)
    {
        orgsize = RdosGetHandleSize(handle);
        RdosSetHandlePos(handle, 0);

        size = 0;
        sect = FSectionList;

        while (sect)
        {
            size += sect->GetSize();
            sect = sect->FNextSection;
        }

        buf = new char[size + 2];

        ptr = buf;
        sect = FSectionList;

        while (sect)
        {
            ptr = sect->Format(ptr);
            sect = sect->FNextSection;
        }

        RdosWriteHandle(handle, buf, size);

        delete buf;

        if (orgsize > size)
            RdosSetHandleSize(handle, size);

        RdosCloseHandle(handle);
    }

    FModified = false;
}

/*##########################################################################
#
#   Name       : TAppIniFile::GotoSection
#
#   Purpose....: Goto section in ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAppIniFile::GotoSection(const char *name)
{
    FCurrSection = FindSection(name);
    FSection = name;
    FCurrVar = 0;

    if (FCurrSection)
    	return true;
    else
        return false;
}

/*##########################################################################
#
#   Name       : TAppIniFile::DeleteSection
#
#   Purpose....: Delete current section in ini-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAppIniFile::DeleteSection(const char *name)
{
    TAppIniSection *sect = FSectionList;
    TAppIniSection *prev = 0;

    while (sect)
    {
        if (sect->IsMatch(name))
        {
            if (prev)
                prev->FNextSection = sect->FNextSection;
            else
                FSectionList = sect->FNextSection;

            if (sect == FCurrSection)
                FCurrSection = 0;

            delete sect;
            FModified = true;
            return true;
        }

        prev = sect;
        sect = sect->FNextSection;
    }

    return false;
}

/*##########################################################################
#
#   Name       : TAppIniFile::ReadVar
#
#   Purpose....: Read variable in current section
#
#   In params..: var, buffer, maxsize
#   Out params.: *
#   Returns....: size read
#
##########################################################################*/
bool TAppIniFile::ReadVar(const char *var, char *str, int maxsize)
{
    TAppIniVar *varobj = 0;

    if (FCurrSection)
        varobj = FCurrSection->FindVar(var);

    if (varobj)
    {
        strncpy(str, varobj->GetData(), maxsize);
        return true;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TAppIniFile::WriteVar
#
#   Purpose....: Write variable in current section
#
#   In params..: var, buffer, maxsize
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAppIniFile::WriteVar(const char *var, const char *str)
{
    TAppIniVar *varobj = 0;

    if (!FCurrSection)
        FCurrSection = AddSection(FSection.GetData());

    if (FCurrSection)
    {
        varobj = FCurrSection->FindVar(var);

        if (varobj)
            varobj->SetData(str);
        else
            FCurrSection->AddVar(var, str);

        FModified = true;
        return true;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TAppIniFile::DeleteVar
#
#   Purpose....: Delete variable in current section
#
#   In params..: var
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAppIniFile::DeleteVar(const char *var)
{
    bool ok;

    if (FCurrSection)
        ok = FCurrSection->DeleteVar(var);
    else
        ok = false;

    if (ok)
        FModified = true;

    return ok;
}

/*##########################################################################
#
#   Name       : TAppIniFile::ClearSections
#
#   Purpose....: Clear sections
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TAppIniFile::ClearSections()
{
    TAppIniSection *sect;

    FCurrSection = 0;
	
    while (FSectionList)
    {
        sect = FSectionList->FNextSection;
        delete FSectionList;
        FSectionList = sect;
    }
}

/*##########################################################################
#
#   Name       : TAppIniFile::GotoFirstVar
#
#   Purpose....: Goto first ini-var in current section
#
#   In params..: var
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAppIniFile::GotoFirstVar()
{
    if (FCurrSection)
        FCurrVar = FCurrSection->FVarList;
    else
        FCurrVar = 0;

    if (FCurrVar)
        return true;
    else
        return false;
}

/*##########################################################################
#
#   Name       : TAppIniFile::GotoNextVar
#
#   Purpose....: Goto next ini-var in current section
#
#   In params..: var
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAppIniFile::GotoNextVar()
{
    if (FCurrSection && FCurrVar)
        FCurrVar = FCurrVar->FNextVar;
    else
        FCurrVar = 0;

    if (FCurrVar)
        return true;
    else
        return false;
}

/*##########################################################################
#
#   Name       : TAppIniFile::GetCurrVar
#
#   Purpose....: Get current variable
#
#   In params..: var
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TAppIniFile::GetCurrVar(char *var, int maxsize)
{
    if (FCurrVar)
    {
        strncpy(var, FCurrVar->GetName(), maxsize);
        return true;
    }
    else
        return false;
}
