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
# section.cpp
# Critical section class
#
########################################################################*/

#include <string.h>
#include "section.h"

#define     FALSE   0
#define     TRUE    !FALSE

/*##########################################################################
#
#   Name       : TSection::TSection
#
#   Purpose....: Constructor for TSection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSection::TSection(const char *Name)
{
    strncpy(FName, Name, 32);
    FName[32] = 0;

    RdosInitFutex(&Futex, FName);
}

/*##########################################################################
#
#   Name       : TSection::~TSection
#
#   Purpose....: Destructor for TSection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSection::~TSection()
{
    RdosResetFutex(&Futex);
}

/*##########################################################################
#
#   Name       : TSection::EnterSection
#
#   Purpose....: Enter critical section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSection::Enter() const
{
    RdosEnterFutex(&Futex);
}

/*##########################################################################
#
#   Name       : TSection::LeaveSection
#
#   Purpose....: Leave critical section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSection::Leave() const
{
    RdosLeaveFutex(&Futex);
}
