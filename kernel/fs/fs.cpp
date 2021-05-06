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
# fs.cpp
# Fs base class
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <rdos.h>
#include <serv.h>
#include "fs.h"

/*##########################################################################
#
#   Name       : TParser::TParser
#
#   Purpose....: Parser constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TParser::TParser(TDir *StartDir, char *PathName)
{
    bool sep = false;

    Head = PathName;
    Next = Head;

    while (*Next && !sep)
    {
        if (*Next == '/' || *Next == '\\')
            sep = true;
        else
            Next++;
    }

    if (sep)
    {
        *Next = 0;
        Next++;
    }

    Dir = StartDir;
}

/*##########################################################################
#
#   Name       : TParser::~TParser
#
#   Purpose....: Parser constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TParser::~TParser()
{
}

/*##########################################################################
#
#   Name       : TParser::IsDone
#
#   Purpose....: Check if done
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TParser::IsDone()
{
    if (Dir == 0)
        return true;

    if (*Head == 0)
        return true;

    return false;
}

/*##########################################################################
#
#   Name       : TParser::IsLast
#
#   Purpose....: Check if at last path compoonent
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TParser::IsLast()
{
    if (Dir == 0)
        return true;

    if (*Next == 0)
        return true;

    return false;
}

/*##########################################################################
#
#   Name       : TParser::IsValid
#
#   Purpose....: Check if valid entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TParser::IsValid()
{
    int index;
    struct DirEntry *entry;

    if (Dir)
    {
        if (!strcmp(Head, "."))
            return true;

        if (!strcmp(Head, ".."))
            return true;

        index = Dir->Find(Head);
        if (index >= 0)
            return true;
    }
    return false;
}

/*##########################################################################
#
#   Name       : TParser::IsDir
#
#   Purpose....: Check if directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TParser::IsDir()
{
    int index;
    struct DirEntry *entry;

    if (Dir)
    {
        if (!strcmp(Head, "."))
            return true;

        if (!strcmp(Head, ".."))
            return true;

        index = Dir->Find(Head);
        if (index >= 0)
        {
            entry = Dir->Get(index);
            if (entry->Attrib & FILE_ATTRIBUTE_DIRECTORY)
                return true;
        }
    }
    return false;
}

/*##########################################################################
#
#   Name       : TParser::IsCurrDir
#
#   Purpose....: Check if current directory "."
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TParser::IsCurrDir()
{
    if (Dir)
    {
        if (!strcmp(Head, "."))
            return true;
        else
            return false;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TParser::IsParentDir
#
#   Purpose....: Check if parent directory ".."
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TParser::IsParentDir()
{
    if (Dir)
    {
        if (!strcmp(Head, ".."))
            return true;
        else
            return false;
    }
    else
        return false;
}

/*##########################################################################
#
#   Name       : TParser::Get
#
#   Purpose....: Get current dir entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct DirEntry *TParser::Get()
{
    int index;
    struct DirEntry *entry;

    if (Dir)
    {
        if (!strcmp(Head, "."))
            return 0;

        if (!strcmp(Head, ".."))
            return 0;

        index = Dir->Find(Head);
        if (index >= 0)
            return Dir->Get(index);
    }

    return 0;
}

/*##########################################################################
#
#   Name       : TParser::Advance
#
#   Purpose....: Parser advance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TParser::Advance()
{
    bool sep = false;

    Head = Next;
    Next = Head;

    while (*Next && !sep)
    {
        if (*Next == '/' || *Next == '\\')
            sep = true;
        else
            Next++;
    }

    if (sep)
    {
        *Next = 0;
        Next++;
    }
}

/*##########################################################################
#
#   Name       : TFs::TFs
#
#   Purpose....: FS contructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFs::TFs(TDiscServer *server)
{
    Server = server;
    Root = 0;
}

/*##########################################################################
#
#   Name       : TFs::~TFs
#
#   Purpose....: FS destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFs::~TFs()
{
    if (Root)
        delete Root;
}

/*##########################################################################
#
#   Name       : TFs::GetStartDir
#
#   Purpose....: Get start dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir *TFs::GetStartDir(int node)
{
    TDir *dir;

    if (!Root)
        Root = CacheRootDir();

    dir = Root;

    return dir;
}

/*##########################################################################
#
#   Name       : TFs::Advance
#
#   Purpose....: Advance path
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::Advance(TParser *Parser)
{
    struct DirEntry *entry;    
    bool isdir;

    if (Parser->IsCurrDir())
        Parser->Advance();
    else if (Parser->IsParentDir())
    {
        Parser->Advance();
    }
    else
    {
        entry = Parser->Get();

        if (entry)
        {
            if (entry->Attrib & FILE_ATTRIBUTE_DIRECTORY)
                isdir = true;
            else
                isdir = false;
        }
        else
            isdir = false;

        if (isdir)
        {
            Parser->Dir = CacheDir(Parser->Dir, entry->Inode);
            if (Parser->Dir)
                Parser->Advance();
        }  
    }
}

/*##########################################################################
#
#   Name       : TFs::GetDir
#
#   Purpose....: Get dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct TShareHeader *TFs::GetDir(int node, char *path, int *count)
{
    TParser Parser(GetStartDir(node), path);

    while (!Parser.IsDone())
    {
        if (Parser.IsDir())
            Advance(&Parser);
        else
            return 0;
    }

    if (Parser.Dir)
    {
        *count = Parser.Dir->GetCount();
        return Parser.Dir->Share();
    }
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TFs::GetDirEntryAttrib
#
#   Purpose....: Get dir entry attrib
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFs::GetDirEntryAttrib(int node, char *path)
{
    TParser Parser(GetStartDir(node), path);
    struct DirEntry *entry;

    while (!Parser.IsLast())
    {
        if (Parser.IsDir())
            Advance(&Parser);
        else
            return -1;
    }

    entry = Parser.Get();    

    if (entry)
        return entry->Attrib;
    else
    {
        if (Parser.IsCurrDir() || Parser.IsParentDir())
            return FILE_ATTRIBUTE_DIRECTORY;
        else
            return -1;
    }
}
