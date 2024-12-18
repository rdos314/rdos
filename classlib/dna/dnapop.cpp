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

}

/*##########################################################################
#
#   Name       : TDnaPopulation::Split
#
#   Purpose....: Split population in two parts
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDnaPopulation *TDnaPopulation::Split(int size)
{
    int i;
    int base;
    TDnaPopulation *pop;
    TDnaIndividual **NewIndArr;

    if (FPairArr)
    {
        FreePairArr(FPairArr, FPairs);
        delete FPairArr;
    }

    if (size > FSize)
        size = FSize;

    base = FSize - size;

    pop = new TDnaPopulation(FMutator, FCrossOverRate, FSeqSize);
    
    pop->FSize = size;
    pop->FIndArr = new TDnaIndividual* [size];

    NewIndArr = new TDnaIndividual* [base];

    for (i = 0; i < base; i++)
        NewIndArr[i] = FIndArr[i];

    for (i = 0; i < size; i++)
        pop->FIndArr[i] = FIndArr[base + i];

    delete FIndArr;
    FIndArr = NewIndArr;        
    FSize = base;

    return pop;
}

/*##########################################################################
#
#   Name       : TDnaPopulation::Merge
#
#   Purpose....: Merge 2 populations into one
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaPopulation::Merge(TDnaPopulation *pop)
{
    int i;
    TDnaIndividual **NewIndArr;
    int size;

    if (FPairArr)
    {
        FreePairArr(FPairArr, FPairs);
        delete FPairArr;
    }

    size = FSize + pop->FSize;
    
    NewIndArr = new TDnaIndividual* [size];

    for (i = 0; i < FSize; i++)
        NewIndArr[i] = FIndArr[i];

    for (i = 0; i < pop->FSize; i++)
        NewIndArr[FSize + i] = pop->FIndArr[i];

    delete FIndArr;
    FIndArr = NewIndArr;        
    FSize = size;

    delete pop->FIndArr;
    pop->FIndArr = 0;

    delete pop;
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
}

/*##########################################################################
#
#   Name       : TDnaPopulation::Set
#
#   Purpose....: Set DNA mutator
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaPopulation::Set(TDnaMutator *Mutator)
{
    FMutator = Mutator;
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
    long double fscore;
    long double divi;

    divi = (long double)FSeqSize / 4.0;

    val = (long double)ind1->FMotherSeq.GetSimilarity(ind2->FMotherSeq, FSeqSize / 4);
    val = val / divi;
    fscore = val * val;

    val = (long double)ind1->FMotherSeq.GetSimilarity(ind2->FFatherSeq, FSeqSize / 4);
    val = val / divi;
    fscore += val * val;

    val = (long double)ind1->FFatherSeq.GetSimilarity(ind2->FMotherSeq, FSeqSize / 4);
    val = val / divi;
    fscore += val * val;

    val = (long double)ind1->FFatherSeq.GetSimilarity(ind2->FFatherSeq, FSeqSize / 4);
    val = val / divi;
    fscore += val * val;

    fscore = 500.0 * sqrt(fscore);

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
void TDnaPopulation::Pairbond(int tries)
{
    int *Paired;
    int i;
    int j;
    int k;
    int max;
    int p;
    int score;

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
        for (i = p; i < FSize; i++)
            if (!Paired[i])
                break;

        Paired[i] = TRUE; 

        max = 0;
        j = p;

        for (;;)
        {
            k = Random(FSize);

            if (!Paired[k])
            {
                score = GetMatchScore(FIndArr[i], FIndArr[k]);
                if (score > max)
                {
                    score = max;
                    j = k;

                    if (Random(tries) == 0)
                        break;
                }
            }
        }

        Paired[j] = TRUE;   
        FPairArr[p] = new TDnaPair(FIndArr[i], FIndArr[j]);
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
void TDnaPopulation::CreateChildren()
{
    TDnaIndividual **ChildArr;
    int NewSize;
    int c;
    int p;
    int *IndArr;
    int pc;

    NewSize = FSize;
    ChildArr = new TDnaIndividual* [NewSize];

    c = 0;
    pc = FPairs;

     IndArr = new int[FPairs];

     for (p = 0; p < FPairs; p++)
          IndArr[p] = p;

     while (c < NewSize)
     {
        ChildArr[c] = FPairArr[IndArr[0]]->CreateChild(FMutator, FCrossOverRate);
        c++;

        for (p = 0; p < pc / 2 && c < NewSize; p++)
        {
            
            if (Random(2))
            {
                IndArr[p] = IndArr[2 * p];
                ChildArr[c] = FPairArr[IndArr[p]]->CreateChild(FMutator, FCrossOverRate);
            }
            else                
            {
                IndArr[p] = IndArr[2 * p + 1];
                ChildArr[c] = FPairArr[IndArr[p]]->CreateChild(FMutator, FCrossOverRate);
            }
            c++;
        }

        pc = pc / 2;
    }        

    delete IndArr;

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
#   Name       : TDnaPopulation::CreateChildren
#
#   Purpose....: Create children
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaPopulation::CreateChildren(TDnaEvaluator *eval)
{
    TDnaIndividual **ChildArr;
    int NewSize;
    int c;
    int p;
    int score1;
    int score2;
    int val;
    int *IndArr;
    int pc;
    int ind;

    NewSize = FSize;
    ChildArr = new TDnaIndividual* [NewSize];

    c = 0;
    pc = FPairs;

     IndArr = new int[FPairs];

     for (p = 0; p < FPairs; p++)
          IndArr[p] = p;

     while (c < NewSize)
     {
        ChildArr[c] = FPairArr[IndArr[0]]->CreateChild(FMutator, FCrossOverRate);
        c++;

          for (p = 0; p < pc / 2 && c < NewSize; p++)
        {
            ind = IndArr[2 * p];
            score1 = 0;
                val = eval->Score(FPairArr[ind]->Mate1);
                score1 = val * val;
                val = eval->Score(FPairArr[ind]->Mate2);
                score1 += val * val;

                ind = IndArr[2 * p + 1];
                score2 = 0;
                val = eval->Score(FPairArr[ind]->Mate1);
                score2 = val * val;
            val = eval->Score(FPairArr[ind]->Mate2);
            score2 += val * val;
            
            if (score1 > score2)
            {
                IndArr[p] = IndArr[2 * p];
                ChildArr[c] = FPairArr[IndArr[p]]->CreateChild(FMutator, FCrossOverRate);
            }
            else                
            {
                IndArr[p] = IndArr[2 * p + 1];
                ChildArr[c] = FPairArr[IndArr[p]]->CreateChild(FMutator, FCrossOverRate);
            }
            c++;
        }

        pc = pc / 2;
    }        

    delete IndArr;

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
#   Name       : TDnaPopulation::ExportRaw
#
#   Purpose....: Export raw sequences
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaPopulation::ExportRaw(const char *filename)
{
    TFile file(filename, 0);
    int i;
    TDnaIndividual *ind;
    char str[40];

    for (i = 0; i < FSize; i++)
    {
        ind = FIndArr[i];
        if (ind)
        {
            sprintf(str, "M%05d: ", i);
            file.Write(str);
            ind->FMotherSeq.Write(file);
            file.Write("\r\n");

            sprintf(str, "F%05d: ", i);
            file.Write(str);
            ind->FFatherSeq.Write(file);
            file.Write("\r\n");
        }
    }
}

/*##########################################################################
#
#   Name       : TDnaPopulation::ExportQuiz
#
#   Purpose....: Export a quiz for PCA
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaPopulation::ExportQuiz(const char *filename, TDnaSequence *ref, TDnaSequence *ref1, TDnaSequence *ref2)
{
    TFile file(filename, 0);
    int i;
    TDnaIndividual *ind;
    int j;
    int k;
    char str[40];
    char *fseq;
    char *mseq;
     char *rseq;
     char *rseq1;
     char *rseq2;
     int score;
     int score1;
    int score2;
    long double mean;
    long double *SdArr;
    int sum;
    long double val;
    long double rsum;
    int count;
    int RefArr[150];
    long double maxsd;

    SdArr = new long double[FSeqSize];

    for (i = 0; i < FSeqSize; i++)
    {
        sum = 0;
        count = 0;

        for (j = 0; j < FSize; j++)
        {
            ind = FIndArr[j];
            if (ind)
            {
                sum += ind->FFatherSeq.FSeq[i];
                sum += ind->FMotherSeq.FSeq[i];
                count++;
            }
        }

        mean = (long double)sum / (long double)(2 * count);

        rsum = 0;

        for (j = 0; j < FSize; j++)
        {
            ind = FIndArr[j];
            if (ind)
            {
                val = (long double)ind->FFatherSeq.FSeq[i] - mean;
                rsum += val * val;
                
                val = (long double)ind->FMotherSeq.FSeq[i] - mean;
                rsum += val * val;
            }
        }
        SdArr[i] = sqrt(rsum / ((long double)2 * count - 1));
    }

    for (i = 0; i < 150; i++)
    {
        maxsd = 0;

        for (j = 0; j < FSeqSize; j++)
        {
            if (SdArr[j] > maxsd)
            {
                maxsd = SdArr[j];
                k = j;
            }
        }

        SdArr[k] = 0;
        RefArr[i] = k;        
    }


     file.Write("\"\", \"\", ");
     for (j = 0; j < 150; j++)
     {
          sprintf(str, "\"#%d\"", j + 1);
          file.Write(str);
          if (j != FSeqSize - 1)
                file.Write(", ");
     }
     file.Write("\r\n");

    for (i = 0; i < FSize; i++)
    {
        ind = FIndArr[i];
        if (ind)
        {
            sprintf(str, "\"%d\", ", i + 1);
            file.Write(str);
            file.Write(str);

            rseq = ref->FSeq;
            rseq1 = ref1->FSeq;
            rseq2 = ref2->FSeq;
            fseq = ind->FFatherSeq.FSeq;
            mseq = ind->FMotherSeq.FSeq;

            for (j = 0; j < 150; j++)
            {
                k = RefArr[j];
    
                score1 = 0;
                score2 = 0;

                if (fseq[k] == rseq1[k])
                    score1++;
                
                if (mseq[k] == rseq1[k])
                    score1++;

                if (fseq[k] == rseq2[k])
                    score2++;                
                
                if (mseq[k] == rseq2[k])
                    score2++;                

                if (score1 && score2)
                {
                    if (rseq1[k] == rseq2[k])
                        score = score1;
                    else
                    {
                        if (rseq2[k] == rseq[k])
                            score = 2 - score2;
                        else
                            score = score2;                        
                    }
                }
                else
                    score = score1 + score2;

                score = fseq[k] + mseq[k];
                
                sprintf(str, "\"%d\"", score); 
                file.Write(str);
                if (j != 149)
                    file.Write(", ");
                    
            }

            file.Write("\r\n");
        }
    }

    delete SdArr;
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
