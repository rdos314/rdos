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
#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

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

	FHandle = RdosOpenFile(FileName, 0);
}

/*##########################################################################
#
#   Name       : TFile::TFile
#
#   Purpose....: Constructor for TFile
#
#   In params..: Filename to create
#				 File attribute
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

	FHandle = RdosCreateFile(FileName, Attrib);
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

	if (file.FHandle)
		FHandle = RdosDuplFile(file.FHandle);
	else
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
		RdosCloseFile(FHandle);

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
	if (FHandle)
		return RdosIsDevice(FHandle);
	else
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
		return !RdosIsDevice(FHandle);
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
		return RdosGetFileSize(FHandle);
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
	if (FHandle)
		RdosSetFileSize(FHandle, Size);
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
		return RdosGetFilePos(FHandle);
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
		RdosSetFilePos(FHandle, Pos);
}

/*##########################################################################
#
#   Name       : TFile::GetTime
#
#   Purpose....: Get file time & date
#
#   In params..: File time
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDateTime TFile::GetTime()
{
	unsigned long msb, lsb;

	if (FHandle)
	{
		RdosGetFileTime(FHandle, &msb, &lsb);
		return TDateTime(msb, lsb);
	}

	return TDateTime();
}

/*##########################################################################
#
#   Name       : TFile::SetTime
#
#   Purpose....: Set file time & date
#
#   In params..: File time
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFile::SetTime(const TDateTime &time)
{
	long msb, lsb;

	if (FHandle)
	{
		msb = time.GetMsb();
		lsb = time.GetLsb();
		RdosSetFileTime(FHandle, msb, lsb);
	}
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
	if (FHandle)
		return RdosReadFile(FHandle, Buf, Size);
	else
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
	if (FHandle)
		return RdosWriteFile(FHandle, Buf, Size);
	else
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
	if (FHandle)
		return RdosWriteFile(FHandle, str, strlen(str));
	else
		return 0;
}
