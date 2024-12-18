/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2008, Leif Ekblad
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
# dnamut.cpp
# DNA mutator base class
#
########################################################################*/

#include <string.h>

#include "dnamut.h"
#include "rand.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TDnaMutator::TDnaMutator
#
#   Purpose....: Constructor for TDnaMutator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDnaMutator::TDnaMutator(int size, long double rate)
{
	if (rate > 1.0)
		rate = 1.0;

	if (rate < 0.0)
		rate = 0.0;

	FRate = (long)(1000000 * rate) + 1;
}

/*##########################################################################
#
#   Name       : TDnaMutator::~TDnaMutator
#
#   Purpose....: Destructor for TDnaMutator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDnaMutator::~TDnaMutator()
{
}

/*##########################################################################
#
#   Name       : TDnaMutator::Mutate
#
#   Purpose....: Mutate sequence
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaMutator::Mutate(char *seq, int size)
{
	int len;
	int i;
	char *baseptr;

	baseptr = seq;

	if (size > FSize)
		len = FSize;
	else
		len = size;

	for (i = 0; i < len; i++)
	{
		if (Random(1000000) < FRate)
			*baseptr = MutateBase(i, *baseptr);

		baseptr++;
	}
}

/*##########################################################################
#
#   Name       : TDnaMutator::MutateBase
#
#   Purpose....: Mutate a base
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char TDnaMutator::MutateBase(int index, char base)
{
	base += (char)Random(3);
	if (base >= 4)
		base -= 4;

	return base;
}

