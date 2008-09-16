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
# dnapop.cpp
# DNA population
#
########################################################################*/

#include <string.h>
#include <stdio.h>
#include <math.h>

#include "dnapop.h"
#include "rand.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TDnaPopulation::TDnaPopulation
#
#   Purpose....: Constructor for TDnaPopulation
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDnaPopulation::TDnaPopulation(TDnaMutator *Mutator, int CrossOverRate, int SeqSize)
{
    FMutator = Mutator;
    FCrossOverRate = CrossOverRate;
    FSeqSize = SeqSize;    

    FSize = 0;
    FIndArr = 0;

    FPairs = 0;
    FPairArr = 0;
}

/*##########################################################################
#
#   Name       : TDnaPopulation::~TDnaPopulation
#
#   Purpose....: Destructor for TDnaPopulation
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDnaPopulation::~TDnaPopulation()
{
    if (FIndArr)
    {
        FreeIndArr(FIndArr, FSize);
        delete FIndArr;
    }

    if (FPairArr)
    {
        FreePairArr(FPairArr, FPairs);
        delete FPairArr;
    }

    if (FMateScoreArr)
        delete FMateScoreArr;
}

/*##########################################################################
#
#   Name       : TDnaPopulation::FreeIndArr
#
#   Purpose....: Free individual array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaPopulation::FreeIndArr(TDnaIndividual **IndArr, int Size)
{
    int i;

    for (i = 0; i < Size; i++)
    {
        if (IndArr[i])
            delete IndArr[i];

        IndArr[i] = 0;
    }
}

/*##########################################################################
#
#   Name       : TDnaPopulation::FreePairArr
#
#   Purpose....: Free pair array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaPopulation::FreePairArr(TDnaPair **PairArr, int Size)
{
    int i;

    for (i = 0; i < Size; i++)
    {
        if (PairArr[i])
            delete PairArr[i];

        PairArr[i] = 0;
    }
}

/*##########################################################################
#
#   Name       : TDnaPopulation::CreateRandom
#
#   Purpose....: Create an initial population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaPopulation::CreateRandom(int size)
{
	 int i;

	 if (FIndArr)
	 {
		  FreeIndArr(FIndArr, FSize);
		  delete FIndArr;
	 }

	 FSize = size;
	 FIndArr = new TDnaIndividual* [FSize];

	 for (i = 0; i < size; i++)
		  FIndArr[i] = new TDnaIndividual(FSeqSize);

	 if (FMateScoreArr)
		  delete FMateScoreArr;

	FMateScoreArr = new int[FSeqSize];

	for (i = 0; i < FSeqSize; i++)
		FMateScoreArr[i] = FSeqSize - i;
}

/*##########################################################################
#
#   Name       : TDnaPopulation::CreateUniform
#
#   Purpose....: Create an initial population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaPopulation::CreateUniform(TDnaSequence *seq, int size)
{
	 int i;

	 if (FIndArr)
	 {
		  FreeIndArr(FIndArr, FSize);
		  delete FIndArr;
	 }

	 FSize = size;
	 FIndArr = new TDnaIndividual* [FSize];
	 FSeqSize = seq->GetSize();

	 for (i = 0; i < size; i++)
		  FIndArr[i] = new TDnaIndividual(seq);

	 if (FMateScoreArr)
		  delete FMateScoreArr;

	FMateScoreArr = new int[FSeqSize];

	for (i = 0; i < FSeqSize; i++)
		FMateScoreArr[i] = FSeqSize - i;
}

/*##########################################################################
#
#   Name       : TDnaPopulation::GetMatchScore
#
#   Purpose....: Get a match score (0..1000) of the probability of a match
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDnaPopulation::GetMatchScore(TDnaIndividual *ind1, TDnaIndividual *ind2)
{
	int score;
	long double val;
	long double size;
	long double fscore;


	val = (long double)ind1->FMotherSeq.GetSimilarity(ind2->FMotherSeq, FMateScoreArr);
	val = val / (long double)FSize;
	fscore = val * val;

	val = (long double)ind1->FMotherSeq.GetSimilarity(ind2->FFatherSeq, FMateScoreArr);
	val = val / (long double)FSize;
	fscore += val * val;

	val = (long double)ind1->FFatherSeq.GetSimilarity(ind2->FMotherSeq, FMateScoreArr);
	val = val / (long double)FSize;
	fscore += val * val;

	val = (long double)ind1->FFatherSeq.GetSimilarity(ind2->FFatherSeq, FMateScoreArr);
	val = val / (long double)FSize;
	fscore += val * val;

	fscore = 1000.0 * sqrtl(fscore);
	fscore = fscore / (long double)FSize;

	score = (int)fscore;

	if (score <= 0)
		score = 1;

	if (score > 1000)
		score = 1000;

	return score;
}

/*##########################################################################
#
#   Name       : TDnaPopulation::Pairbond
#
#   Purpose....: Create pair-bonds
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaPopulation::Pairbond(int Width)
{
	 int *Paired;
	 int i;
	 int j;
	 int p;
	 int score;
	 int ok;

	 if (FPairArr)
	 {
		  FreePairArr(FPairArr, FPairs);
		  delete FPairArr;
	 }

	Paired = new int[FSize];

	 for (i = 0; i < FSize; i++)
		  Paired[i] = FALSE;

	 FPairs = FSize * 80 / 100 / 2;
	 FPairArr = new TDnaPair* [FPairs];

	 for (p = 0; p < FPairs; p++)
	 {
		  ok = FALSE;

		  while (!ok)
		  {
				i = Random(FSize);
				j = Random(FSize);

				if (i != j && !Paired[i] && !Paired[j])
				{
					 score = GetMatchScore(FIndArr[i], FIndArr[j]);
					 score = (1000 - score) / Width;
					 if (Random(score) == 0)
					 {
						  ok = TRUE;
						  FPairArr[p] = new TDnaPair(FIndArr[i], FIndArr[j]);

						  Paired[i] = TRUE;
						  Paired[j] = TRUE;
				}
				}
        }            
    }

    delete Paired;            
}

/*##########################################################################
#
#   Name       : TDnaPopulation::CreateChildren
#
#   Purpose....: Create children
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaPopulation::CreateChildren(TDnaEvaluator *eval, int Width)
{
	 TDnaIndividual **ChildArr;
	 TDnaIndividual *child;
	 int NewSize;
	 int c;
	 int p;
	 int ok;
	 int score;

	 NewSize = FSize;
	 ChildArr = new TDnaIndividual* [NewSize];

	 for (c = 0; c < NewSize; c++)
	 {
		  ok = FALSE;

		  while (!ok)
		  {
				p = Random(FPairs);
				child = FPairArr[p]->CreateChild(FMutator, FCrossOverRate);
				score = eval->Score(child);

			score = (1000 - score) / Width;

			if (Random(score) == 0)
			{
				ok = TRUE;
				ChildArr[c] = child;
			}
			else
				delete child;
		}
	}

	if (FIndArr)
	{
		FreeIndArr(FIndArr, FSize);
		delete FIndArr;
	}

	if (FPairArr)
	{
		FreePairArr(FPairArr, FPairs);
		delete FPairArr;
	}

	FSize = NewSize;
	FIndArr = ChildArr;
	FPairArr = 0;
}

/*##########################################################################
#
#   Name       : TDnaPopulation::WriteScores
#
#   Purpose....: Write scores for individuals in the population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaPopulation::WriteScores(TDnaEvaluator *eval)
{
    int i;
	int score;

	for (i = 0; i < FSize; i++)
	{
		if (FIndArr[i])
		{
			score = eval->Score(FIndArr[i]);
			printf("%d\n", score);
		}
	}
}

/*##########################################################################
#
#   Name       : TDnaPopulation::WritePairDetails
#
#   Purpose....: Write detailed pair info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaPopulation::WritePairDetails(TDnaEvaluator *eval)
{
    int i;
    int score1;
    int score2;
    int match;

    for (i = 0; i < FPairs; i++)
    {
        if (FPairArr[i])
        {
            score1 = eval->Score(FPairArr[i]->Mate1);
            score2 = eval->Score(FPairArr[i]->Mate2);
            match = GetMatchScore(FPairArr[i]->Mate1, FPairArr[i]->Mate2);

            printf("m1 = %d, m2 = %d; fit = %d\n", score1, score2, match);
        }
    }
}

/*##########################################################################
#
#   Name       : TDnaPopulation::WritePairSumary
#
#   Purpose....: Write short pair info
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaPopulation::WritePairSumary(TDnaEvaluator *eval)
{
    int i;
    int score1;
    int score2;
    int match;
    int count;

    count = 0;
    score1 = 0;
    score2 = 0;
    match = 0;

    for (i = 0; i < FPairs; i++)
    {
        if (FPairArr[i])
        {
            count++;
            score1 += eval->Score(FPairArr[i]->Mate1);
            score2 += eval->Score(FPairArr[i]->Mate2);
            match += GetMatchScore(FPairArr[i]->Mate1, FPairArr[i]->Mate2);
        }
    }
    score1 = score1 / count;
    score2 = score2 / count;
    match = match / count;

    printf("m1 = %d, m2 = %d; fit = %d\n", score1, score2, match);
}
