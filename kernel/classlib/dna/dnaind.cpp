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
# dnaind.cpp
# DNA individual class
#
########################################################################*/

#include <stdio.h>
#include <string.h>

#include "rand.h"
#include "dnaind.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TDnaIndividual::TDnaIndividual
#
#   Purpose....: Constructor for TDnaIndividual
#
#   In params..: Initial size
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDnaIndividual::TDnaIndividual(int size)
 : FMotherSeq(size),
	FFatherSeq(size)
{
}

/*##########################################################################
#
#   Name       : TDnaIndividual::TDnaIndividual
#
#   Purpose....: Constructor for TDnaIndividual
#
#   In params..: Initial size
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDnaIndividual::TDnaIndividual(TDnaSequence *seq)
 :  FMotherSeq(*seq),
    FFatherSeq(*seq)
{
}

/*##########################################################################
#
#   Name       : TDnaIndividual::TDnaIndividual
#
#   Purpose....: Constructor for TDnaIndividual
#
#   In params..: Mother
#                Father
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDnaIndividual::TDnaIndividual(TDnaIndividual &Mother, TDnaIndividual &Father, TDnaMutator *Mutator, int CrossOverRate)
 : FMotherSeq(Mother.FMotherSeq, Mother.FFatherSeq, Mutator, CrossOverRate),
	FFatherSeq(Father.FMotherSeq, Father.FFatherSeq, Mutator, CrossOverRate)
{
}

/*##########################################################################
#
#   Name       : TDnaIndividual::~TDnaIndividual
#
#   Purpose....: Destructor for TDnaIndividual
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDnaIndividual::~TDnaIndividual()
{
}

/*##########################################################################
#
#   Name       : TDnaIndividual::Write
#
#   Purpose....: Write sequences
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaIndividual::Write()
{
	printf("Mother: ");
	FMotherSeq.Write();
	printf("Father: ");
	FFatherSeq.Write();
}

