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
# rwsect.cpp
# Critical read-write section class
#
########################################################################*/

#include "rwsect.h"
#include "rdos.h"

#define     FALSE	0
#define     TRUE	!FALSE

/*##########################################################################
#
#   Name       : TReadWriteSection::TReadWriteSection
#
#   Purpose....: Constructor for TReadWriteSection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TReadWriteSection::TReadWriteSection()
{
    FHandle = RdosCreateReadWriteSection();
}

/*##########################################################################
#
#   Name       : TReadWriteSection::~TReadWriteSection
#
#   Purpose....: Destructor for TReadWriteSection
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TReadWriteSection::~TReadWriteSection()
{
    RdosDeleteReadWriteSection(FHandle);
}

/*##########################################################################
#
#   Name       : TReadWriteSection::EnterRead
#
#   Purpose....: Enter critical section as reader
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TReadWriteSection::EnterRead() const
{
    RdosEnterReadSection(FHandle);
}

/*##########################################################################
#
#   Name       : TReadWriteSection::LeaveRead
#
#   Purpose....: Leave critical section as reader
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TReadWriteSection::LeaveRead() const
{
    RdosLeaveReadSection(FHandle);
}

/*##########################################################################
#
#   Name       : TReadWriteSection::EnterWrite
#
#   Purpose....: Enter critical section as writer. Only a single thread
#                can enter the section as a writer, and only if there are
#                no readers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TReadWriteSection::EnterWrite() const
{
    RdosEnterWriteSection(FHandle);
}

/*##########################################################################
#
#   Name       : TReadWriteSection::LeaveWrite
#
#   Purpose....: Leave critical section as writer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TReadWriteSection::LeaveWrite() const
{
    RdosLeaveWriteSection(FHandle);
}
