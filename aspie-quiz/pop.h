/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
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
# pop.h
# Basic population class
#
########################################################################*/

#ifndef _POP_H
#define _POP_H

#define MAX_CATS        8

struct TValArr
{
    char Quiz[100];
};

class TPopulation
{
public:
	TPopulation(int MaxValues);
	~TPopulation();

    void Clear(int MaxValues);
	void Add(char Arr[100]);
	void Pack();

    long double GetMean(int QuestionNr);
    long double GetSd(int QuestionNr);
    
    int Count[100];
	int Sum[100];
    int ChiArr[100][MAX_CATS];

    int ValueCount;
    int MaxSize;
    TValArr *ValArr;    
};

#endif

