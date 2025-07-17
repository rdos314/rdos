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
# dir.cpp
# Dir command class
#
########################################################################*/

#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "cmdhelp.h"
#include "lang.h"
#include "dir.h"
#include "rdos.h"
#include "path.h"

#define FALSE 0
#define TRUE !FALSE

#define DEFAULT_SORT_ORDER "NG"

/*##########################################################################
#
#   Name       : TDirFactory::TDirFactory
#
#   Purpose....: Constructor for TDirFactory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirFactory::TDirFactory()
  : TCommandFactory("DIR")
{
}

/*##########################################################################
#
#   Name       : TDirFactory::Create
#
#   Purpose....: Create a command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TCommand *TDirFactory::Create(TSession *session, const char *param)
{
        return new TDirCommand(session, param);
}

/*##########################################################################
#
#   Name       : TDirCommand::TDirCommand
#
#   Purpose....: Constructor for TDirCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirCommand::TDirCommand(TSession *session, const char *param)
  : TCommand(session, param)
{
        FHelpScreen.Load(TEXT_CMDHELP_DIR);
}

/*##########################################################################
#
#   Name       : TDirCommand::~TDirCommand
#
#   Purpose....: Destructor for TDirCommand
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirCommand::~TDirCommand()
{
}

/*##########################################################################
#
#   Name       : TDirCommand::InitOptions
#
#   Purpose....: Init options
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::InitOptions()
{
    FRequired = 0;
    FIgnored = FILE_ATTRIBUTE_HIDDEN | FILE_ATTRIBUTE_SYSTEM;
    FOptDirFirst = TRUE;
    FOptDirLast = FALSE;
        FOptS = FALSE;
        FOptP = FALSE;
        FOptW = FALSE;
        FOptB = FALSE;
        FOptL = FALSE;
}

/*##########################################################################
#
#   Name       : TDirCommand::ScanAttr
#
#   Purpose....: Scan attribute option
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirCommand::ScanAttr(const char *p)
{
        int attr;
        int done = FALSE;

        FRequired = 0;
        FIgnored = 0;

        if (p && *p)
        {
                p--;
                while (!done)
                {
                        switch (toupper(*++p))
                        {
                                case 'R':
                                        attr = FILE_ATTRIBUTE_READONLY;
                                        break;

                                case 'A':
                                        attr = FILE_ATTRIBUTE_ARCHIVE;
                                        break;

                                case 'D':
                                        attr = FILE_ATTRIBUTE_DIRECTORY;
                                        break;

                                case 'H':
                                        attr = FILE_ATTRIBUTE_HIDDEN;
                                        break;

                                case 'S':
                                        attr = FILE_ATTRIBUTE_SYSTEM;
                                        break;

                                case 0:
                                        done = TRUE;
                                        break;

                                default:
                                        OptError(p);
                                        return E_Useage;
                        }

                        if (!done)
                        {
                                switch (p[-1])
                                {
                                        case '-':
                                                FIgnored |= attr;
                                                break;

                                        default:
                                                FRequired |= attr;
                                                break;
                                }
                        }
                }
        }

        return E_None;
}

/*##########################################################################
#
#   Name       : TDirCommand::ScanOrder
#
#   Purpose....: Scan order option
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirCommand::ScanOrder(const char *p)
{
        int inverse;
        int changed;

        if (!p || !*p)
                p = DEFAULT_SORT_ORDER;

    FFileList.ClearSort();
    FDirList.ClearSort();

    FOptDirFirst = FALSE;
    FOptDirLast = FALSE;

        if (p && *p)
        {
                while (*p)
                {
                        inverse = p[-1] == '-';
                        changed = FALSE;

                        switch (toupper(*p))
                        {
                                case '-':
                                        break;

                                case 'S':
                                    if (inverse)
                                    {
                                    FFileList.AddReverseSortBySize();
                                    FDirList.AddReverseSortBySize();
                                }
                                else
                                    {
                                    FFileList.AddSortBySize();
                                    FDirList.AddSortBySize();
                                }
                                        break;

                                case 'D':
                                    if (inverse)
                                    {
                                    FFileList.AddReverseSortByTime();
                                    FDirList.AddReverseSortByTime();
                                }
                                else
                                    {
                                    FFileList.AddSortByTime();
                                    FDirList.AddSortByTime();
                                }
                                        break;

                                case 'N':
                                    if (inverse)
                                    {
                                    FFileList.AddReverseSortByName();
                                    FDirList.AddReverseSortByName();
                                }
                                else
                                    {
                                    FFileList.AddSortByName();
                                    FDirList.AddSortByName();
                                }
                                        break;

                                case 'E':
                                    if (inverse)
                                    {
                                    FFileList.AddReverseSortByExt();
                                    FDirList.AddReverseSortByExt();
                                }
                                else
                                    {
                                    FFileList.AddSortByExt();
                                    FDirList.AddSortByExt();
                                }
                                        break;

                                case 'G':
                                    if (inverse)
                                    {
                                        FOptDirLast = TRUE;
                                        FOptDirFirst = FALSE;
                                    }
                                    else
                                    {
                                        FOptDirFirst = TRUE;
                                        FOptDirLast = FALSE;
                                    }
                                        break;

                                case 'U':
                    FFileList.ClearSort();
                    FDirList.ClearSort();
                    FOptDirFirst = FALSE;
                    FOptDirLast = FALSE;
                                        break;

                                default:
                                        OptError(p);
                                        return E_Useage;
                        }
                        p++;
                }
        }

        return E_None;
}

/*##########################################################################
#
#   Name       : TDirCommand::OptScan
#
#   Purpose....: Opt scan callback
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirCommand::OptScan(const char *optstr, int ch, int bool, const char *strarg, void * const arg)
{
        switch (ch)
        {
                case 'S':
                        return OptScanBool(optstr, bool, strarg, &FOptS);

                case 'P':
                        return OptScanBool(optstr, bool, strarg, &FOptP);

                case 'W':
                        return OptScanBool(optstr, bool, strarg, &FOptW);

                case 'B':
                        return OptScanBool(optstr, bool, strarg, &FOptB);

                case 'O':
                        if (!bool)
                                return ScanOrder(strarg);
                        break;

                case 'A':
                        if (!bool)
                                return ScanAttr(strarg);
                        break;

                case 'L':
                        return OptScanBool(optstr, bool, strarg, &FOptL);

                case 0:
                        switch (*optstr)
                        {
                                case 'A':
                                case 'a':
                                        if (!bool && strarg == 0)
                                                return ScanAttr(optstr + 1);
                                        break;

                                case 'O':
                                case 'o':
                                        if (!bool && strarg == 0)
                                                return ScanOrder(optstr + 1);
                                        break;
                        }
        }
        OptError(optstr);
        return E_Useage;
}

/*##########################################################################
#
#   Name       : TDirCommand::WriteHeader
#
#   Purpose....: Write directory header
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::WriteHeader(TString &str)
{
        TPathName path(str);
        FDrive = path.GetDrive();
        TPathName search(FDrive, "/*");
        TDirList dir;
        TDirEntry entry;
        const char *ep;

        FCurrentRow = 0;

        dir.SetRequiredAttributes(8);
        dir.SetIgnoredAttributes(0);
        dir.Add(search);

        FMsg.printf(TEXT_DIR_HDR_VOLUME, FDrive + 'A');
        Write(FMsg.GetData());

        if (dir.GotoFirst())
        {
                entry = dir.Get();
                ep = entry.Get().EntryName.GetData();
                FMsg.printf(TEXT_DIR_HDR_VOLUME_STRING, ep);
                Write(FMsg.GetData());
        }
        else
        {
                FMsg.Load(TEXT_DIR_HDR_VOLUME_NONE);
                Write(FMsg.GetData());
        }
        FCurrentRow++;

        FMsg.printf(TEXT_DIR_DIRECTORY_WITH_SPACE, path.GetFullPathName().GetData());
        Write(FMsg.GetData());
        FCurrentRow += 3;
}

/*##########################################################################
#
#   Name       : TDirCommand::WriteFooter
#
#   Purpose....: Write directory footer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::WriteFooter()
{
    long FreeUnits;
    long TotalUnits;
    int BytesPerUnit;
    long long FreeSpace;

    WriteLongLong(FFileList.GetSize());
        FMsg.Load(TEXT_DIR_FTR_FILES);
        Write(FMsg.GetData());

        WriteLongLong(FTotalSize);
        FMsg.Load(TEXT_DIR_FTR_BYTES);
        Write(FMsg.GetData());

    WriteLongLong(FDirList.GetSize());
        FMsg.Load(TEXT_DIR_FTR_DIRS);
        Write(FMsg.GetData());

    FreeSpace = RdosGetVfsDriveFree(FDrive);
    if (FreeSpace > 0)
    {
        WriteLongLong(FreeSpace * 512);
        FMsg.Load(TEXT_DIR_FTR_BYTES_FREE);
        Write(FMsg.GetData());
    }
    else
    {
        FreeUnits = 0;
        RdosGetDriveInfo(FDrive, &FreeUnits, &BytesPerUnit, &TotalUnits);
        WriteLong(FreeUnits * BytesPerUnit);
        FMsg.Load(TEXT_DIR_FTR_BYTES_FREE);
        Write(FMsg.GetData());
    }
}

/*##########################################################################
#
#   Name       : TDirCommand::WriteDetailed
#
#   Purpose....: Write detailed listing entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::WriteDetailed(const TDirEntryData &entry)
{
        char str[31];
        int size;
        int i;

        size = entry.EntryName.GetSize();
        strncpy(str, entry.EntryName.GetData(), 30);

        if (size < 30)
        {
                str[size] = ' ';
                for (i = size + 1; i < 30; i++)
                        str[i] = 'ú';
        }
        str[30] = 0;

        Write(str);

        if (entry.Attribute & FILE_ATTRIBUTE_DIRECTORY)
        {
                FDirCount++;
                Write("<DIR>         ");
        }
        else
        {
                FFileCount++;
                FTotalSize += entry.FileSize;
                WriteLongLong(entry.FileSize);
        }

        Write("  ");

        sprintf(str, "%04d-%02d-%02d %02d.%02d.%02d,%03d",
                                        entry.ModifyTime.GetYear(),
                                        entry.ModifyTime.GetMonth(),
                                        entry.ModifyTime.GetDay(),
                                        entry.ModifyTime.GetHour(),
                                        entry.ModifyTime.GetMin(),
                                        entry.ModifyTime.GetSec(),
                                        entry.ModifyTime.GetMilliSec());
        Write(str);
        Write("\r\n");

        FCurrentRow++;

        if (FOptP && (FCurrentRow == 23))
        {
                FCurrentRow = 0;
                FMsg.Load(TEXT_MSG_PAUSE);
                Write(FMsg.GetData());
                RdosReadKeyboard();
                Write("\r\n");
        }

}

/*##########################################################################
#
#   Name       : TDirCommand::WriteWide
#
#   Purpose....: Write wide listing entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::WriteWide(const TDirEntryData &entry)
{
        int size;
        int i;

        if (FCurrentCol + FWidth >= 80)
        {
                FCurrentRow++;
                FCurrentCol = 0;
                Write("\r\n");
        }

        if (entry.Attribute & FILE_ATTRIBUTE_DIRECTORY)
        {
                FDirCount++;
                size = entry.EntryName.GetSize() + 3;
                Write("[");
                Write(entry.EntryName.GetData());
                Write("] ");
        }
        else
        {
                FFileCount++;
                FTotalSize += entry.FileSize;
                size = entry.EntryName.GetSize() + 1;
                Write(entry.EntryName.GetData());
                Write(" ");
        }

        for (i = size; i < FWidth; i++)
                Write(" ");

        FCurrentCol += FWidth;

        if (FOptP && FCurrentCol == 0 && FCurrentRow == 23)
        {
                FCurrentRow = 0;
                FMsg.Load(TEXT_MSG_PAUSE);
                Write(FMsg.GetData());
                RdosReadKeyboard();
                Write("\r\n");
        }
}

/*##########################################################################
#
#   Name       : TDirCommand::WriteDetailed
#
#   Purpose....: Write detailed listing
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::WriteDetailed()
{
        int ok;

    if (FOptDirFirst)
    {
        ok = FDirList.GotoFirst();
        while (ok)
        {
            WriteDetailed(FDirList.Get().Get());
            ok = FDirList.GotoNext();
        }
    }

    ok = FFileList.GotoFirst();
    while (ok)
    {
        WriteDetailed(FFileList.Get().Get());
        ok = FFileList.GotoNext();
    }

    if (FOptDirLast)
    {
        ok = FDirList.GotoFirst();
        while (ok)
        {
            WriteDetailed(FDirList.Get().Get());
            ok = FDirList.GotoNext();
        }
    }
}

/*##########################################################################
#
#   Name       : TDirCommand::WriteWide
#
#   Purpose....: Write wide listing
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::WriteWide()
{
        int size;
        int ok;

        FCurrentCol = 0;
        FWidth = 1;

    ok = FDirList.GotoFirst();
    while (ok)
    {
                size = FDirList.Get().GetEntryName().GetSize();
            size += 2;

                if (size > FWidth)
                        FWidth = size;

        ok = FDirList.GotoNext();
        }

    ok = FFileList.GotoFirst();
    while (ok)
    {
                size = FFileList.Get().GetEntryName().GetSize();
        if (FFileList.Get().GetAttribute() & FILE_ATTRIBUTE_DIRECTORY)
                        size += 2;

                if (size > FWidth)
                        FWidth = size;

        ok = FFileList.GotoNext();
        }

        FWidth += 2;

    if (FOptDirFirst)
    {
        ok = FDirList.GotoFirst();
        while (ok)
        {
            WriteWide(FDirList.Get().Get());
            ok = FDirList.GotoNext();
        }
    }

    ok = FFileList.GotoFirst();
    while (ok)
    {
        WriteWide(FFileList.Get().Get());
        ok = FFileList.GotoNext();
    }

    if (FOptDirLast)
    {
        ok = FDirList.GotoFirst();
        while (ok)
        {
            WriteWide(FDirList.Get().Get());
            ok = FDirList.GotoNext();
        }
    }
}

/*##########################################################################
#
#   Name       : TDirCommand::Add
#
#   Purpose....: Add files for argument
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDirCommand::Add(TString &path)
{
    if (FOptDirLast || FOptDirFirst)
    {
        FDirList.Add(path);
        FFileList.Add(path);
    }
    else
        FFileList.Add(path);
}

/*##########################################################################
#
#   Name       : TDirCommand::Execute
#
#   Purpose....: Run command
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDirCommand::Execute(char *param)
{
    TArg *arg;
    TString all("*");

    InitOptions();

    if (!ScanCmdLine(param, 0))
        return 1;

    FFileCount = 0;
    FDirCount = 0;
    FTotalSize = 0;

    arg = FArgList;

    if (FOptDirFirst || FOptDirLast)
    {
        FFileList.SetRequiredAttributes(FRequired & (~FILE_ATTRIBUTE_DIRECTORY));
        FFileList.SetIgnoredAttributes(FIgnored | FILE_ATTRIBUTE_DIRECTORY);
        FDirList.SetRequiredAttributes(FRequired | FILE_ATTRIBUTE_DIRECTORY);
        FDirList.SetIgnoredAttributes(FIgnored & (~FILE_ATTRIBUTE_DIRECTORY));
    }
    else
    {
        FFileList.SetRequiredAttributes(FRequired);
        FFileList.SetIgnoredAttributes(FIgnored);
    }

    if (arg)
    {
        WriteHeader(arg->FName);
        while (arg)
        {
            Add(arg->FName);
            arg = arg->FList;
        }
    }
    else
    {
        WriteHeader(all);
        Add(all);
    }

    FFileList.RemoveDuplicates();
    FDirList.RemoveDuplicates();

    FFileList.Sort();
    FDirList.Sort();

    if (FOptW)
        WriteWide();
    else
        WriteDetailed();

    WriteFooter();

    return 0;
}
