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
# dir.cpp
# Directory entry class
#
########################################################################*/

#include <stdio.h>
#include <rdos.h>
#include <serv.h>
#include "dir.h"

/*##########################################################################
#
#   Name       : TDirEntry::TDirEntry
#
#   Purpose....: Dir entry contructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry::TDirEntry()
{
    FileName[0] = 0;
    Time = 0;
    Attrib = 0;
}

/*##########################################################################
#
#   Name       : TDirEntry::~TDirEntry
#
#   Purpose....: Dir entry destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDirEntry::~TDirEntry()
{
}

/*##########################################################################
#
#   Name       : TDir::TDir
#
#   Purpose....: Dir contructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir::TDir()
{
    DirCount = 0;
    DirArr = 0;
}

/*##########################################################################
#
#   Name       : TDir::~TDir
#
#   Purpose....: Dir destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDir::~TDir()
{
}

/*##########################################################################
#
#   Name       : TDir::IsDir
#
#   Purpose....: Check if directory entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TDir::IsDir()
{
    return true;
}

/*##########################################################################
#
#   Name       : TFile::TFile
#
#   Purpose....: File contructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile::TFile()
{
    Size = 0;
}

/*##########################################################################
#
#   Name       : TFile::~TFile
#
#   Purpose....: File destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile::~TFile()
{
}

/*##########################################################################
#
#   Name       : TFile::IsDir
#
#   Purpose....: Check if directory entry
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TFile::IsDir()
{
    return false;
}
