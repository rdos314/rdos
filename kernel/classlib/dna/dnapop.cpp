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

#include "dnapop.h"

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
#   Name       : TDnaPopulation::Create
#
#   Purpose....: Create an initial population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaPopulation::Create(int size)
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
            printf("%d\r\n", score);
        }
    }
}
