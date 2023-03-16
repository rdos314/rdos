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
#include "str.h"
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
    Head = PathName;
    Next = Head;
    Dir = StartDir;
    if (Dir)
        Dir->LockDir();
    CurrEntry = 0;

    Process();
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
    if (Dir && CurrEntry)
        Dir->UnlockEntry(CurrEntry);

    if (Dir)
        Dir->UnlockDir();
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
    if (CurrEntry)
        return true;
    else
        return IsCurr || IsParent;
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
    if (CurrEntry)
    {
        if (CurrEntry->Attrib & FILE_ATTRIBUTE_DIRECTORY)
            return true;
        else
            return false;
    }
    else
        return IsCurr || IsParent;
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
    return IsCurr;
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
    return IsParent;
}

/*##########################################################################
#
#   Name       : TParser::GetEntry
#
#   Purpose....: Get current dir entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
struct DirEntry *TParser::GetEntry()
{
    return CurrEntry;
}

/*##########################################################################
#
#   Name       : TParser::GetDir
#
#   Purpose....: Get current dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir *TParser::GetDir()
{
    return Dir;
}

/*##########################################################################
#
#   Name       : TParser::GetFile
#
#   Purpose....: Get current file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TParser::GetFile()
{
    if (CurrEntry)
    {
        if (CurrEntry->Attrib & FILE_ATTRIBUTE_DIRECTORY)
            return 0;
        else
            return Dir->LockFileLink(CurrIndex);
    }
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TParser::Process
#
#   Purpose....: Process next path part
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TParser::Process()
{
    bool sep = false;

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

    if (Dir && CurrEntry)
        Dir->UnlockEntry(CurrEntry);

    CurrIndex = -1;
    CurrEntry = 0;
    IsCurr = false;
    IsParent = false;

    if (Dir && Head[0])
    {
        if (!strcmp(Head, "."))
            IsCurr = true;

        if (!strcmp(Head, ".."))
            IsParent = true;

        if (!IsCurr & !IsParent)
        {
            CurrIndex = Dir->Find(Head);
            if (CurrIndex >= 0)
                CurrEntry = Dir->LockEntry(CurrIndex);
        }
    }
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
    bool isdir;
    TDir *newdir = 0;

    if (IsCurrDir())
    {
        newdir = Dir;
        newdir->LockDir();
    }
    else if (IsParentDir())
    {
        newdir = Dir->GetParentDir();
        if (newdir)
            newdir->LockDir();
    }
    else
    {
        if (CurrEntry)
        {
            if (CurrEntry->Attrib & FILE_ATTRIBUTE_DIRECTORY)
                isdir = true;
            else
                isdir = false;
        }
        else
            isdir = false;

        if (isdir)
            newdir = Dir->LockDirLink(CurrIndex);
    }

    Dir->UnlockDir();
    Dir = newdir;

    if (Dir)
    {
        Head = Next;
        Next = Head;

        Process();
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
    int i;

    Server = server;

    CurrDirCount = 0;
    MaxDirCount = 4;
    DirArr = new TDir*[MaxDirCount];

    for (i = 0; i < MaxDirCount; i++)
        DirArr[i] = 0;

    CurrFileCount = 0;
    MaxFileCount = 4;
    FileArr = new TFile*[MaxFileCount];

    for (i = 0; i < MaxFileCount; i++)
        FileArr[i] = 0;
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
    int i;

    for (i = 0; i < MaxDirCount; i++)
        if (DirArr[i])
            delete DirArr[i];

    delete DirArr;

    for (i = 0; i < MaxFileCount; i++)
        if (FileArr[i])
            delete FileArr[i];

    delete FileArr;
}

/*##########################################################################
#
#   Name       : TFs::GrowDir
#
#   Purpose....: Grow dir array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::GrowDir()
{
    int i;
    int Size = 2 * MaxDirCount;
    TDir **NewArr;

    NewArr = new TDir*[Size];

    for (i = 0; i < MaxDirCount; i++)
        NewArr[i] = DirArr[i];

    for (i = MaxDirCount; i < Size; i++)
        NewArr[i] = 0;

    delete DirArr;
    DirArr = NewArr;
    MaxDirCount = Size;
}

/*##########################################################################
#
#   Name       : TFs::Add
#
#   Purpose....: Add directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::Add(TDir *dir)
{
    int i;
    bool found = false;

    if (CurrDirCount == MaxDirCount)
        GrowDir();

    for (i = CurrDirCount; i < MaxDirCount && !found; i++)
    {
        if (DirArr[i] == 0)
        {
            DirArr[i] = dir;
            dir->Entry = i;
            found = true;
        }
    }


    for (i = 0; i < CurrDirCount && !found; i++)
    {
        if (DirArr[i] == 0)
        {
            DirArr[i] = dir;
            dir->Entry = i;
            found = true;
        }
    }

    if (found)
        CurrDirCount++;
}

/*##########################################################################
#
#   Name       : TFs::Remove
#
#   Purpose....: Remove directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::Remove(TDir *dir)
{
    if (DirArr[dir->Entry] == dir)
    {
        DirArr[dir->Entry] = 0;
        CurrDirCount--;
    }
}

/*##########################################################################
#
#   Name       : TFs::GrowFile
#
#   Purpose....: Grow file array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::GrowFile()
{
    int i;
    int Size = 2 * MaxFileCount;
    TFile **NewArr;

    NewArr = new TFile*[Size];

    for (i = 0; i < MaxFileCount; i++)
        NewArr[i] = FileArr[i];

    for (i = MaxFileCount; i < Size; i++)
        NewArr[i] = 0;

    delete FileArr;
    FileArr = NewArr;
    MaxFileCount = Size;
}

/*##########################################################################
#
#   Name       : TFs::Add
#
#   Purpose....: Add file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::Add(TFile *file)
{
    int i;
    int handle;
    bool found = false;

    if (CurrFileCount == MaxFileCount)
        GrowFile();

    for (i = CurrFileCount; i < MaxFileCount && !found; i++)
    {
        if (FileArr[i] == 0)
        {
            FileArr[i] = file;
            handle = i;
            found = true;
        }
    }


    for (i = 0; i < CurrFileCount && !found; i++)
    {
        if (FileArr[i] == 0)
        {
            FileArr[i] = file;
            handle = i;
            found = true;
        }
    }

    if (found)
    {
        file->Setup(Server->GetHandle(), handle);
        CurrFileCount++;
    }
}

/*##########################################################################
#
#   Name       : TFs::Remove
#
#   Purpose....: Remove file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::Remove(TFile *file)
{
    int handle = file->GetServHandle();

    if (FileArr[handle] == file)
    {
        FileArr[handle] = 0;
        CurrFileCount--;
    }
}

/*##########################################################################
#
#   Name       : TFs::ReadDirLink
#
#   Purpose....: Read dir link
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::ReadDirLink(TDir *dir, int index)
{
    struct DirEntry *entry;
    TDir *newdir;
    TFile *file;
    long long inode;

    entry = dir->LockEntry(index);
    inode = entry->Inode;
    dir->UnlockEntry(entry);

    if (entry->Attrib & FILE_ATTRIBUTE_DIRECTORY)
    {
        newdir = CacheDir(dir, index, inode);

        Add(newdir);
        dir->SetDirLink(index, newdir);
    }
    else
    {
        file = OpenFile(dir, index, inode);

        Add(file);
        dir->SetFileLink(index, file);
    }
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
TDir *TFs::GetStartDir(int rel)
{
    TDir *dir;

    if (CurrDirCount == 0)
    {
        DirArr[0] = CacheRootDir();
        CurrDirCount = 1;
    }

    if (rel >= 0 && rel < MaxDirCount)
        dir = DirArr[rel];
    else
        dir = 0;

    if (!dir)
        dir = DirArr[0];

    return dir;
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
struct TShareHeader *TFs::GetDir(int rel, char *path, int *count)
{
    TDir *dir;
    TParser Parser(GetStartDir(rel), path);

    while (!Parser.IsDone())
    {
        if (Parser.IsDir())
            Parser.Advance();
        else
            return 0;
    }

    dir = Parser.GetDir();

    if (dir)
    {
        *count = dir->GetCount();
        return dir->Share();
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
int TFs::GetDirEntryAttrib(int rel, char *path)
{
    TParser Parser(GetStartDir(rel), path);
    struct DirEntry *entry;

    while (!Parser.IsLast())
    {
        if (Parser.IsDir())
            Parser.Advance();
        else
            return -1;
    }

    entry = Parser.GetEntry();

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

/*##########################################################################
#
#   Name       : TFs::LockRelDir
#
#   Purpose....: Lock rel dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFs::LockRelDir(int rel, char *path)
{
    TDir *dir;
    TParser Parser(GetStartDir(rel), path);

    while (!Parser.IsDone())
    {
        if (Parser.IsDir())
            Parser.Advance();
        else
            return 0;
    }

    dir = Parser.GetDir();

    if (dir)
    {
        dir->LockDir();
        return dir->Entry;
    }
    else
        return -1;
}

/*##########################################################################
#
#   Name       : TFs::CloneRelDir
#
#   Purpose....: Clone rel dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::CloneRelDir(int rel)
{
    TDir *dir = GetStartDir(rel);

    if (dir)
        dir->LockDir();
}

/*##########################################################################
#
#   Name       : TFs::UnlockRelDir
#
#   Purpose....: Unlock rel dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::UnlockRelDir(int rel)
{
    TDir *dir = GetStartDir(rel);

    if (dir)
        dir->UnlockDir();
}

/*##########################################################################
#
#   Name       : TFs::GetRelDir
#
#   Purpose....: Get rel dir
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFs::GetRelDir(int rel, char *path)
{
    TString str;
    long long inode;
    int index;
    struct DirEntry *entry;
    TDir *dir = GetStartDir(rel);

    while (dir)
    {
        inode = dir->GetInode();
        dir = dir->GetParentDir();
        if (dir)
        {
            index = dir->Find(inode);
            if (index >= 0)
            {
                entry = dir->LockEntry(index);
                if (entry)
                {
                    if (str.GetSize())
                        str = TString(entry->PathName) + "/" + str;
                    else
                        str = TString(entry->PathName);
                }
                dir->UnlockEntry(entry);
            }
        }
    }

    strcpy(path, str.GetData());
    return strlen(path) + 1;
}

/*##########################################################################
#
#   Name       : TFs::OpenFile
#
#   Purpose....: Open file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFs::OpenFile(int rel, char *path)
{
    TParser Parser(GetStartDir(rel), path);
    TFile *file;

    while (!Parser.IsLast())
    {
        if (Parser.IsDir())
            Parser.Advance();
        else
            return -1;
    }

    file = Parser.GetFile();

    if (file)
    {
        printf("Open %d <%s>\r\n", file->GetServHandle(), path);
        return file->GetServHandle();
    }
    else
        return -1;
}

/*##########################################################################
#
#   Name       : TFs::GetFile
#
#   Purpose....: Get file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TFs::GetFile(int handle)
{
    if (handle >= 0 && handle < MaxFileCount)
        return FileArr[handle];
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TFs::GetFileAttrib
#
#   Purpose....: Get file attribute
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFs::GetFileAttrib(int handle)
{
    TFile *file = GetFile(handle);

    if (file)
        return file->GetAttrib();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TFs::GetFileHandle
#
#   Purpose....: Get file kernel handle
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFs::GetFileHandle(int handle)
{
    TFile *file = GetFile(handle);

    if (file)
        return file->GetKernelHandle();
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TFs::ReqFile
#
#   Purpose....: Req file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFs::ReqFile(int handle, long long pos, int size, int src)
{
    TFile *file = GetFile(handle);

    if (file)
        return file->ReqFile(pos, size, src, GetBytesPerSector());
    else
        return 0;
}

/*##########################################################################
#
#   Name       : TFs::CloseFile
#
#   Purpose....: Close file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::CloseFile(int handle)
{
    TFile *file;
    int i;

    if (handle >= 0 && handle < MaxFileCount)
    {
        file = FileArr[handle];
        if (file)
        {
            CurrFileCount--;
            for (i = handle; i < CurrFileCount; i++)
                FileArr[i] = FileArr[i+1];

            FileArr[CurrFileCount] = 0;
            delete file;
        }
    }
}
