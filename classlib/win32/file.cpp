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
# file.cpp
# File class
#
########################################################################*/

#include <string.h>
#include "file.h"
#include "windows.h"

/*##########################################################################
#
#   Name       : TFile::TFile
#
#   Purpose....: Constructor for TFile
#
#   In params..: Filename to open
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile::TFile(const char *FileName)
{
    int len;

    len = strlen(FileName);
    FFileName = new char[len + 1];
    strcpy(FFileName, FileName);

    FHandle = CreateFile(   FileName,
                            GENERIC_READ | GENERIC_WRITE,
                            FILE_SHARE_READ | FILE_SHARE_WRITE,
                            0,
                            OPEN_EXISTING,
                            FILE_ATTRIBUTE_NORMAL,
                            0);
    if (FHandle < 0)
        FHandle = 0;
}

/*##########################################################################
#
#   Name       : TFile::TFile
#
#   Purpose....: Constructor for TFile
#
#   In params..: Filename to create
#                                File attribute
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile::TFile(const char *FileName, int Attrib)
{
    int len;

    len = strlen(FileName);
    FFileName = new char[len + 1];
    strcpy(FFileName, FileName);

    FHandle = CreateFile(   FileName,
                            GENERIC_READ | GENERIC_WRITE,
                            FILE_SHARE_READ | FILE_SHARE_WRITE,
                            0,
                            CREATE_ALWAYS,
                            FILE_ATTRIBUTE_NORMAL,
                            0);
    if (FHandle < 0)
        FHandle = 0;
}

/*##########################################################################
#
#   Name       : TFile::TFile
#
#   Purpose....: Copy constructor for TFile
#
#   In params..: file to duplicate handle on
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile::TFile(const TFile &file)
{
    int len;

    len = strlen(file.FFileName);
    FFileName = new char[len + 1];
    strcpy(FFileName, file.FFileName);

        FHandle = 0;
}

/*##########################################################################
#
#   Name       : TFile::~TFile
#
#   Purpose....: Destructor for TFile
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile::~TFile()
{
        if (FHandle)
                CloseHandle(FHandle);

    if (FFileName)
        delete FFileName;
}

/*##########################################################################
#
#   Name       : TFile::IsOpen
#
#   Purpose....: Check if file is open
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if open
#
##########################################################################*/
int TFile::IsOpen()
{
        if (FHandle)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TFile::IsDevice
#
#   Purpose....: Check if file is device
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if open and device
#
##########################################################################*/
int TFile::IsDevice()
{
        return FALSE;
}

/*##########################################################################
#
#   Name       : TFile::IsFile
#
#   Purpose....: Check if file is ordinary file
#
#   In params..: *
#   Out params.: *
#   Returns....: TRUE if open and file
#
##########################################################################*/
int TFile::IsFile()
{
        if (FHandle)
                return TRUE;
        else
                return FALSE;
}

/*##########################################################################
#
#   Name       : TFile::GetFileName
#
#   Purpose....: Get file name
#
#   In params..: *
#   Out params.: *
#   Returns....: Filename
#
##########################################################################*/
const char *TFile::GetFileName()
{
    return FFileName;
}

/*##########################################################################
#
#   Name       : TFile::GetTime
#
#   Purpose....: Get file modification time
#
#   In params..: *
#   Out params.: *
#   Returns....: File time
#
##########################################################################*/
TDateTime TFile::GetTime()
{
    WIN32_FIND_DATA wfnd;
    FILETIME *ft;
    SYSTEMTIME sft;
    HANDLE hfind;

        if (FHandle)
        {
            hfind = FindFirstFile(FFileName, &wfnd);

            if (hfind != INVALID_HANDLE_VALUE)
            {
                ft = &wfnd.ftLastWriteTime;
                FileTimeToSystemTime(ft, &sft);
                FindClose(hfind);
                return TDateTime(   sft.wYear, sft.wMonth, sft.wDay,
                                    sft.wHour, sft.wMinute, sft.wSecond, sft.wMilliseconds);
        }
        }
    return TDateTime();
}

/*##########################################################################
#
#   Name       : TFile::GetSize
#
#   Purpose....: Get file size
#
#   In params..: *
#   Out params.: *
#   Returns....: File size
#
##########################################################################*/
long TFile::GetSize()
{
        if (FHandle)
                return GetFileSize(FHandle, 0);
        else
                return 0;
}

/*##########################################################################
#
#   Name       : TFile::SetSize
#
#   Purpose....: Set file size
#
#   In params..: File size
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::SetSize(long Size)
{
}

/*##########################################################################
#
#   Name       : TFile::GetPos
#
#   Purpose....: Get file position
#
#   In params..: *
#   Out params.: *
#   Returns....: File position
#
##########################################################################*/
long TFile::GetPos()
{
        if (FHandle)
                return SetFilePointer(FHandle, 0, 0, FILE_CURRENT);
        else
                return 0;
}

/*##########################################################################
#
#   Name       : TFile::SetPos
#
#   Purpose....: Set file position
#
#   In params..: File position
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::SetPos(long Pos)
{
        if (FHandle)
                SetFilePointer(FHandle, Pos, 0, FILE_BEGIN);
}

/*##########################################################################
#
#   Name       : TFile::Read
#
#   Purpose....: Read data from file
#
#   In params..: buf, size
#   Out params.: *
#   Returns....: Bytes read
#
##########################################################################*/
int TFile::Read(void *Buf, int Size)
{
    DWORD read;

        if (FHandle)
                if (ReadFile(FHandle, Buf, Size, &read, 0))
                    return read;

        return 0;
}

/*##########################################################################
#
#   Name       : TFile::Write
#
#   Purpose....: Write data to file
#
#   In params..: buf, size
#   Out params.: *
#   Returns....: Bytes written
#
##########################################################################*/
int TFile::Write(const void *Buf, int Size)
{
    DWORD written;

        if (FHandle)
                if (WriteFile(FHandle, Buf, Size, &written, 0))
                    return written;

        return 0;
}

/*##########################################################################
#
#   Name       : TFile::Write
#
#   Purpose....: Write data to file
#
#   In params..: buf
#   Out params.: *
#   Returns....: Bytes written
#
##########################################################################*/
int TFile::Write(const char *str)
{
    DWORD written;
    int size = strlen(str);

        if (FHandle)
                if (WriteFile(FHandle, str, size, &written, 0))
                    return written;

        return 0;
}
