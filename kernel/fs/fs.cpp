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
#   Name       : TFs::Parse
#
#   Purpose....: Parse pathname
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct DirEntry *TFs::Parse(TDir *dir, char *path)
{
    int index;
    struct DirEntry *entry;

    path = dir->Parse(path, &index);

    if (path)
    {
        switch (index)
        {
            case DIR_SELF:
                if (path[0] == 0)
                    return 0;
                else
                    return Parse(dir, path);

            case DIR_PARENT:
                return 0;

            default:
                if (path[0] == 0)
                    return dir->Get(index);
                else
                    return 0;
        }
    }

    return 0;
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
            Parser.Advance();
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
    TDir *dir = GetStartDir(node);
    struct DirEntry *entry = Parse(dir, path);

    if (entry)
        return entry->Attrib;
    else
        return -1;
}
