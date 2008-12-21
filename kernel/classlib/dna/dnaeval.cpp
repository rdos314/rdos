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
#include <math.h>

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
    FSize = size;
}

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
TDnaEvaluator::TDnaEvaluator(TDnaSequence *seq)
 : FRefSeq(*seq)
{
    FSize = seq->GetSize();
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
#   Name       : TDnaEvaluator::GetSeq
#
#   Purpose....: Get reference sequence
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDnaSequence *TDnaEvaluator::GetSeq()
{
	return &FRefSeq;
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
    long double val;
    long double fscore;

	val = (long double)FRefSeq.GetSimilarity(ind->FMotherSeq);
	val = val / (long double)FSize;
	fscore = val * val;

	val = (long double)FRefSeq.GetSimilarity(ind->FFatherSeq);
	val = val / (long double)FSize;
	fscore += val * val;

	fscore = 1000.0 * sqrtl(fscore / 2.0);

	score = (int)fscore;

	if (score < 0)
		 score = 0;

	if (score > 1000)
		 score = 1000;

	 return score;
}

