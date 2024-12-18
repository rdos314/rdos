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
# dnaseq.cpp
# DNA sequence class
#
########################################################################*/

#include <stdio.h>
#include <string.h>

#include "rand.h"
#include "dnaseq.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TDnaSequence::TDnaSequence
#
#   Purpose....: Constructor for TDnaSequence
#
#   In params..: Initial size
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDnaSequence::TDnaSequence(int size)
{
	 int i;

	 FSeq = new char[size];
	 FSize = size;

	 for (i = 0; i < size; i++)
		FSeq[i] = (char)Random(4);
}

/*##########################################################################
#
#   Name       : TDnaSequence::TDnaSequemce
#
#   Purpose....: Copy constructor for sequence
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDnaSequence::TDnaSequence(const TDnaSequence &src)
{
    FSize = src.FSize;

    if (src.FSeq)
    {
        FSeq = new char[FSize];
        memcpy(FSeq, src.FSeq, FSize);
    }
    else
        FSeq = 0;
}

/*##########################################################################
#
#   Name       : TDnaSequence::TDnaSequence
#
#   Purpose....: Constructor for TDnaSequence using meosis
#
#   In params..: Mother 
#                Father
#                CrossOverRate
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDnaSequence::TDnaSequence(TDnaSequence &Mother, TDnaSequence &Father, TDnaMutator *Mutator, int CrossOverRate)
{
    int size;
    TDnaSequence *seq;
	int i;

    if (Father.FSize > Mother.FSize)
        size = Father.FSize;
    else
        size = Mother.FSize;
        
	FSeq = new char[size];

	if (Random(2))
	    seq = &Mother;
	else
	    seq = &Father;

	for (i = 0; i < seq->FSize; i++)
	{
	    FSeq[i] = seq->FSeq[i];

	    if (Random(CrossOverRate) == 0)
	    {
	        if (seq == &Mother)
	            seq = &Father;
	        else
	            seq = &Mother;
	    }
	}

	FSize = seq->FSize;

    if (Mutator)
        Mutator->Mutate(FSeq, FSize);	
}

/*##########################################################################
#
#   Name       : TDnaSequence::~TDnaSequence
#
#   Purpose....: Destructor for TDnaSequence
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDnaSequence::~TDnaSequence()
{
    if (FSeq)
        delete FSeq;
}

/*##########################################################################
#
#   Name       : TDnaSequence::operator=
#
#   Purpose....: Assignment operator
#
#   In params..: src
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const TDnaSequence &TDnaSequence::operator=(const TDnaSequence &src)
{
    if (FSeq)
        delete FSeq;

    FSize = src.FSize;

    if (src.FSeq)
    {
        FSeq = new char[FSize];
        memcpy(FSeq, src.FSeq, FSize);
    }
    else
        FSeq = 0;
    
	return *this;
}

/*##########################################################################
#
#   Name       : TDnaSequence::GetSize
#
#   Purpose....: Get sequence size
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDnaSequence::GetSize() const
{
    return FSize;
}

/*##########################################################################
#
#   Name       : TDnaSequence::Mutate
#
#   Purpose....: Mutate sequence
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaSequence::Mutate(TDnaMutator *Mutator)
{
    if (Mutator)
        Mutator->Mutate(FSeq, FSize);	
}

/*##########################################################################
#
#   Name       : TDnaSequence::GetSimilarity
#
#   Purpose....: Get similarity count between sequences
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDnaSequence::GetSimilarity(TDnaSequence &other)
{
    int i;
    int size;
    int count;

    if (FSize < other.FSize)
        size = FSize;
    else
        size = other.FSize;

    count = 0;

    for (i = 0; i < size; i++)
        if (FSeq[i] == other.FSeq[i])
            count++;

    return count; 
}

/*##########################################################################
#
#   Name       : TDnaSequence::GetSimilarity
#
#   Purpose....: Get similarity count between sequences using score weighting
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TDnaSequence::GetSimilarity(TDnaSequence &other, int size)
{
    int i;
    int csize;
    int score;

    if (FSize < other.FSize)
        csize = FSize;
    else
        csize = other.FSize;

    if (csize > size)
        csize = size;

    score = 0;

    for (i = 0; i < csize; i++)
        if (FSeq[i] == other.FSeq[i])
            score++;

    return score; 
}

/*##########################################################################
#
#   Name       : TDnaSequence::GetSeqText
#
#   Purpose....: Get text version of DNA sequence
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char *TDnaSequence::GetSeqText()
{
    int i;
    char *text;
    char *inptr;
    char *outptr;

    text = new char[FSize + 1];

    inptr = FSeq;
    outptr = text;
    
    for (i = 0; i < FSize; i++)
    {
        switch (*inptr)
        {
            case DNA_A:
                *outptr = 'A';
                break;

            case DNA_C:
                *outptr = 'C';
                break;

            case DNA_G:
                *outptr = 'G';
                break;

            case DNA_T:
                *outptr = 'T';
                break;

            default:
                *outptr = ' ';
                break;
        }

        inptr++;
        outptr++;
    } 
    *outptr = 0;

	 return text;
}

/*##########################################################################
#
#   Name       : TDnaSequence::Write
#
#   Purpose....: Write sequence to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaSequence::Write()
{
    char *text;

    text = GetSeqText();
	 printf(text);
	 printf("\r\n");
	 delete text;
}

/*##########################################################################
#
#   Name       : TDnaSequence::Write
#
#   Purpose....: Write sequence to file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TDnaSequence::Write(TFile &File)
{
    char *text;

    text = GetSeqText();
    File.Write(text, strlen(text));
    delete text;
}
