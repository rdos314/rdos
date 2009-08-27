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
# refer.cpp
# Referrer class
#
########################################################################*/

#include <string.h>
#include <math.h>
#include "refer.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TReferer::TReferer
#
#   Purpose....: Constructor for TReferer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TReferer::TReferer(const char *Search, const char *Ref)
{
    int grp;

	strcpy(RefererSearch, Search);
	strcpy(RefererRef, Ref);
	Count = 0;
	AqCount = 0;
	Result = 0;
	AsResult = 0;
	NtResult = 0;
	AqResult = 0;
	Result0_59 = 0;
	Result60_99 = 0;
	Result100_139 = 0;
	Result140_200 = 0;
	ResultNt = 0;
	ResultMixed = 0;
	ResultAs = 0;
	ResultAq = 0;

	for (grp = 0; grp < 12; grp++)
	    GroupResult[grp] = 0;

	NT = FALSE;
	Aspie = FALSE;
}

/*##########################################################################
#
#   Name       : TReferer::~TReferer
#
#   Purpose....: Destructor for TReferer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TReferer::~TReferer()
{
}

/*##########################################################################
#
#   Name       : TReferer::IsMatch
#
#   Purpose....: Check for a matching referer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TReferer::IsMatch(const char *Referer)
{
    if (strstr(Referer, RefererSearch))
        return TRUE;
	else
		return FALSE;
}
