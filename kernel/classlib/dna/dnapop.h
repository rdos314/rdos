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
# dnapop.h
# Population class
#
########################################################################*/

#ifndef _DNAPOP_H
#define _DNAPOP_H

#include "dnamut.h"
#include "dnaind.h"
#include "dnaeval.h"
#include "dnapair.h"

class TDnaPopulation
{
public:
	TDnaPopulation(TDnaMutator *Mutator, int CrossOverRate, int SeqSize);
	~TDnaPopulation();

    void Create(int Size);
	void Pairbond();
	void CreateChildren();

    void WriteScores(TDnaEvaluator *eval);
    void WritePairs(TDnaEvaluator *eval);
 
protected:
    void FreeIndArr(TDnaIndividual **IndArr, int Size);
    void FreePairArr(TDnaPair **PairArr, int Size);
    int GetMatchScore(TDnaIndividual *ind1, TDnaIndividual *ind2);

    TDnaMutator *FMutator;
    int FCrossOverRate;   
    int FSeqSize;
    int *FMateScoreArr;

    int FSize;
	TDnaIndividual **FIndArr;

	int FPairs;
	TDnaPair **FPairArr;

};

#endif
