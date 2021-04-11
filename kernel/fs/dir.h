/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-20019, Leif Ekblad
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
# discserv.h
# Disc server class
#
########################################################################*/

#ifndef _DIR_H
#define _DIR_H

#define MAX_FILE_NAME_SIZE  260

class TDirEntry
{
public:
    TDirEntry();
    ~TDirEntry();

    virtual bool IsDir() = 0;

    char FileName[MAX_FILE_NAME_SIZE];
    long long Time;
    int Attrib;
};

class TDir : public TDirEntry
{
public:
    TDir();
    ~TDir();

    virtual bool IsDir();

    int DirCount;
    TDirEntry **DirArr;
};

class TFile : public TDirEntry
{
public:
    TFile();
    ~TFile();

    virtual bool IsDir();

    long long Size;
};

#endif

