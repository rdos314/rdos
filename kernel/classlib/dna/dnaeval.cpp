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
# dnaeval.cpp
# DNA evaluator base class
#
########################################################################*/

#include <string.h>

#include "dnaeval.h"
#include "rand.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TDnaEvaluator::TDnaEvaluator
#
#   Purpose....: Constructor for TDnaEvaluator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDnaEvaluator::TDnaEvaluator(int size)
 : FRefSeq(size)
{
}

/*##########################################################################
#
#   Name       : TDnaEvaluator::~TDnaEvaluator
#
#   Purpose....: Destructor for TDnaEvaluator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDnaEvaluator::~TDnaEvaluator()
{
}

/*##########################################################################
#
#   Name       : TDnaEvaluator::Score
#
#   Purpose....: Score individual
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDnaEvaluator::Score(TDnaIndividual *ind)
{
    int score;

	 score = FRefSeq.GetSimilarity(ind->FMotherSeq);
	 score += FRefSeq.GetSimilarity(ind->FFatherSeq);

    return score;
}
