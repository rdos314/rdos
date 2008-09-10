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

#include "dnaseq.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TDnaSequence::TDnaSequence
#
#   Purpose....: Constructor for TDnaSequence
#
#   In params..: Population
#                Initial size
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TDnaSequence::TDnaSequence(TDnaPopulation *pop, int size)
{
	 FPop = pop;
    FSeq = new char[size];
    FSize = size;
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

    return outptr;                    
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
