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

#define VFS_FILE_SIGN 0x460000;

#define REQ_READ       1
#define REQ_FREE       2
#define REQ_CLOSE      3
#define REQ_COMPLETED  4
#define REQ_MAP        5

/*##########################################################################
#
#   Name       : ThreadStartup
#
#   Purpose....: Startup procedure for thread
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
static void ThreadStartup(void *ptr)
{
    ((TFs *)ptr)->Execute();
}

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
struct RdosDirEntry *TParser::GetEntry()
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

    FServer = server;

    FBytesPerSector = FServer->GetBytesPerSector();
    FStartSector = FServer->GetPartStartSector();
    FSectorCount = FServer->GetPartSectors();

    FSectorsPerPage = 0x1000 / FBytesPerSector;
    FOffsetSector = FStartSector % FSectorsPerPage;

    FQueueArr = 0;
    FServerActive = false;

    FCurrDirCount = 0;
    FMaxDirCount = 4;
    FDirArr = new TDir*[FMaxDirCount];

    for (i = 0; i < FMaxDirCount; i++)
        FDirArr[i] = 0;

    FCurrFileCount = 0;
    FMaxFileCount = 4;
    FFileArr = new TFile*[FMaxFileCount];

    for (i = 0; i < FMaxFileCount; i++)
        FFileArr[i] = 0;

    FCurrPendCount = 0;
    FMaxPendCount = 4;
    FPendArr = new TFileReq*[FMaxPendCount];

    for (i = 0; i < FMaxPendCount; i++)
        FPendArr[i] = 0;
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

    for (i = 0; i < FMaxDirCount; i++)
        if (FDirArr[i])
            delete FDirArr[i];

    delete FDirArr;

    for (i = 0; i < FMaxFileCount; i++)
        if (FFileArr[i])
            delete FFileArr[i];

    delete FFileArr;
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
    int Size = 2 * FMaxDirCount;
    TDir **NewArr;

    NewArr = new TDir*[Size];

    for (i = 0; i < FMaxDirCount; i++)
        NewArr[i] = FDirArr[i];

    for (i = FMaxDirCount; i < Size; i++)
        NewArr[i] = 0;

    delete FDirArr;
    FDirArr = NewArr;
    FMaxDirCount = Size;
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

    if (FCurrDirCount == FMaxDirCount)
        GrowDir();

    for (i = FCurrDirCount; i < FMaxDirCount && !found; i++)
    {
        if (FDirArr[i] == 0)
        {
            FDirArr[i] = dir;
            dir->Entry = i;
            found = true;
        }
    }


    for (i = 0; i < FCurrDirCount && !found; i++)
    {
        if (FDirArr[i] == 0)
        {
            FDirArr[i] = dir;
            dir->Entry = i;
            found = true;
        }
    }

    if (found)
        FCurrDirCount++;
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
    if (FDirArr[dir->Entry] == dir)
    {
        FDirArr[dir->Entry] = 0;
        FCurrDirCount--;
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
    int Size = 2 * FMaxFileCount;
    TFile **NewArr;

    NewArr = new TFile*[Size];

    for (i = 0; i < FMaxFileCount; i++)
        NewArr[i] = FFileArr[i];

    for (i = FMaxFileCount; i < Size; i++)
        NewArr[i] = 0;

    delete FFileArr;
    FFileArr = NewArr;
    FMaxFileCount = Size;
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
    int handle;

    handle = file->Setup(FServer->GetHandle());

    if (handle)
    {
        if (file->Index >= FCurrFileCount)
            FCurrFileCount = file->Index + 1;

        if (FCurrFileCount > FMaxFileCount)
            GrowFile();

        FFileArr[file->Index] = file;
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
    int handle = file->Handle;

    if (FFileArr[handle] == file)
    {
        FFileArr[handle] = 0;
        FCurrFileCount--;
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
    struct RdosDirEntry *entry;
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

    if (FCurrDirCount == 0)
    {
        FDirArr[0] = CacheRootDir();
        FCurrDirCount = 1;
    }

    if (rel >= 0 && rel < FMaxDirCount)
        dir = FDirArr[rel];
    else
        dir = 0;

    if (!dir)
        dir = FDirArr[0];

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
    struct RdosDirEntry *entry;

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
    struct RdosDirEntry *entry;
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
#   Name       : TFs::GrowPend
#
#   Purpose....: Grow pend array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::GrowPend()
{
    int i;
    int Size = 2 * FMaxPendCount;
    TFileReq **NewArr;

    NewArr = new TFileReq*[Size];

    for (i = 0; i < FMaxPendCount; i++)
        NewArr[i] = FPendArr[i];

    for (i = FMaxPendCount; i < Size; i++)
        NewArr[i] = 0;

    delete FPendArr;
    FPendArr = NewArr;
    FMaxPendCount = Size;
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
        if (!FServerActive)
            StartServer();

        printf("Open %d <%s>\r\n", file->Index, path);
        return file->Handle;
    }
    else
        return -1;
}

/*##########################################################################
#
#   Name       : TFs::FileHandleToIndex
#
#   Purpose....: Convert file handle to index in file arr
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TFs::FileHandleToIndex(int handle)
{
    int index = handle & 0xFFFF;
    int vfs = VFS_FILE_SIGN;
    vfs |= FServer->GetHandle() << 24;

    if (vfs == (handle & 0xFFFF0000))
        return index - 1;
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
    int index = FileHandleToIndex(handle);

    if (index >= 0 && index < FMaxFileCount)
        return FFileArr[index];
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
        return file->Handle;
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
    int index = FileHandleToIndex(handle);

    if (index >= 0 && index < FMaxFileCount)
    {
        file = FFileArr[index];
        if (file)
        {
            file->Close();

            if (file->IsClosing())
            {
                FFileArr[index] = 0;
                delete file;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TFileIo::StartFileServer
#
#   Purpose....: Start file server
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::StartServer()
{
    char ThreadName[40];
    int Handle = FServer->GetHandle();
    int Disc = ServGetVfsDisc(Handle);
    int Part = ServGetVfsPart(Handle);

    sprintf(ThreadName, "File IO %02hX.%02hX", Disc, Part);
    RdosCreateThread(ThreadStartup, ThreadName, this, 0x2000);
}

/*##########################################################################
#
#   Name       : TFs::HandleRead
#
#   Purpose....: Handle read file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::HandleRead(TFile *file, long long pos, int size)
{
    int i;
    bool delay = false;
    long long check;
    TFileReq *req;

    req = file->HandleRead(pos, size);

    if (req)
    {
        if (FCurrPendCount == FMaxPendCount)
            GrowPend();

        FPendArr[FCurrPendCount] = req;
        FCurrPendCount++;
        req->Start();
    }
}

/*##########################################################################
#
#   Name       : TFs::HandleFreeReq
#
#   Purpose....: Handle free req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::HandleFreeReq(TFile *file, int req)
{
    file->HandleFreeReq(req);

    if (file->IsClosing())
    {
        FFileArr[file->Index] = 0;
        delete file;
    }
}

/*##########################################################################
#
#   Name       : TFs::HandleCompletedReq
#
#   Purpose....: Handle completed req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::HandleCompletedReq(TFile *file, int req)
{
    int i;
    int j;
    int index = file->Index;
    TFileReq *fr = 0;

    for (i = 0; i < FCurrPendCount; i++)
    {
        if (index == FPendArr[i]->Index && req == FPendArr[i]->Req)
        {
            fr = FPendArr[i];
            FPendArr[i] = 0;
            FCurrPendCount--;

            for (j = i; j < FCurrPendCount; j++)
                FPendArr[j] = FPendArr[j+1];

            FPendArr[FCurrPendCount] = 0;
            break;
        }
    }   
 
    file->HandleCompletedReq(req);
}

/*##########################################################################
#
#   Name       : TFs::HandleMapReq
#
#   Purpose....: Handle map req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::HandleMapReq(TFile *file, int req)
{
    file->HandleMapReq(req);
}

/*##########################################################################
#
#   Name       : TFs::HandleQueue
#
#   Purpose....: Handle queue entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFs::HandleQueue(struct TFsQueueEntry *entry)
{
    int handle = entry->File;
    TFile *file = 0;

    if (entry->Op == REQ_CLOSE)
        return false;

    if (handle > 0 && handle <= FMaxFileCount)
        file = FFileArr[handle - 1];

    if (file)
    {
        switch (entry->Op)
        {
            case REQ_READ:
                HandleRead(file, entry->Par64, entry->Par32);
                break;

            case REQ_COMPLETED:
                HandleCompletedReq(file, entry->Par32);
                break;

            case REQ_MAP:
                HandleMapReq(file, entry->Par32);
                break;

            case REQ_FREE:
                HandleFreeReq(file, entry->Par32);
                break;
        }
    }

    return true;
}

/*##########################################################################
#
#   Name       : TFs::Execute
#
#   Purpose....: Execute
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFs::Execute()
{
    int index;
    struct TFsQueueEntry *entry;

    if (!FQueueArr)
    {
        FQueueArr = (struct TFsQueueEntry *)RdosAllocateMem(0x1000);

        for (index = 0; index < 256; index++)
            FQueueArr[index].Op = 0;

        ServStartVfsIoServer(FServer->GetHandle(), FQueueArr);
    }

    FServerActive = true;

    index = 0;

    for (;;)
    {
        if (FQueueArr[index].Op)
        {
            entry = &FQueueArr[index];
            if (HandleQueue(entry))
            {
                entry->Op = 0;
                index = (index + 1) % 256;
            }
            else
                break;
        }
        else
            ServWaitVfsIoServer(FServer->GetHandle(), index);
    }

    FServerActive = false;

}
