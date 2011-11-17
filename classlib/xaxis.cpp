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
# xaxis.cpp
# X-axis base class
#
########################################################################*/

#include "xaxis.h"

#define     FALSE	0
#define     TRUE	!FALSE

/*##########################################################################
#
#   Name       : TXAxis::TXAxis
#
#   Purpose....: Constructor for TXAxis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TXAxis::TXAxis()
{
    FMinHeight = 0;
    FAxisOffset = 0;
}

/*##########################################################################
#
#   Name       : TXAxis::~TXAxis
#
#   Purpose....: Destructor for TXAxis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TXAxis::~TXAxis()
{
}

/*##########################################################################
#
#   Name       : TXAxis::IsXAxis
#
#   Purpose....: Check if object is x-axis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TXAxis::IsXAxis()
{
	return TRUE;
}

/*##########################################################################
#
#   Name       : TXAxis::SetMinHeight
#
#   Purpose....: Set min height for axis
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TXAxis::SetMinHeight(int height)
{
    FMinHeight = height;
}

/*##########################################################################
#
#   Name       : TXAxis::SetAxisOffset
#
#   Purpose....: Set axis offset
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TXAxis::SetAxisOffset(int offset)
{
    FAxisOffset = offset;
}
