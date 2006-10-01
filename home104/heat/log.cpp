/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2006, Leif Ekblad
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
# log.h
# Log class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "log.h"
#include "section.h"

static TSection FSection;

/*##########################################################################
#
#   Name       : TLog::TLog
#
#   Purpose....: Log constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLog::TLog(const char *RootDir)
{
    strcpy(FRootDir, RootDir);
    strlwr(FRootDir);

    CreateRootDir();
}

/*##########################################################################
#
#   Name       : TLog::TLog
#
#   Purpose....: Log destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TLog::~TLog()
{
}

/*##########################################################################
#
#   Name       : TLog::DeviceName
#
#   Purpose....: Device name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLog::DeviceName(char *Name, int Size) const
{
	strcpy(Name, "LOG");
}

/*##########################################################################
#
#   Name       : TLog::GetDayFile
#
#   Purpose....: Create/open a day-file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TLog::GetDayFile(int year, int month, int day, int hour, int min, const char *name, void *init, int size)
{
    char str[20];
    char filename[256];
    TFile *file;
    int i, j;
	int filesize;

	FSection.Enter();

	sprintf(str, "%d", year);
	strcpy(filename, FRootDir);
	strcat(filename, "\\");
	strcat(filename, str);

	if (!RdosSetCurDir(filename))
		RdosMakeDir(filename);

	sprintf(str, "%d\\%d", year, month);
	strcpy(filename, FRootDir);
	strcat(filename, "\\");
	strcat(filename, str);

	if (!RdosSetCurDir(filename))
		RdosMakeDir(filename);

	sprintf(str, "%d\\%d\\%d", year, month, day);

	strcpy(filename, FRootDir);
	strcat(filename, "\\");
	strcat(filename, str);

	if (!RdosSetCurDir(filename))
		RdosMakeDir(filename);

	strcat(filename, "\\");
	strcat(filename, name);

	file = new TFile(filename);
	if (!file->IsOpen())
	{
		delete file;
		file = new TFile(filename, 0);
	}

	if (file->IsOpen())
	{
		for (i = 0; i < hour; i++)
			for (j = 0; j < 60; j++)
				file->Write(init, size);

		for (j = 0; j < min; j++)
			file->Write(init, size);
	}

	FSection.Leave();

	return file;
}

/*##########################################################################
#
#   Name       : TLog::CreateRootDir
#
#   Purpose....: Create root directory
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TLog::CreateRootDir()
{
    FSection.Enter();

    if (!RdosSetCurDir(FRootDir))
        RdosMakeDir(FRootDir);
        
    FSection.Leave();
}
