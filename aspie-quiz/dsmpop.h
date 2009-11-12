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
# dsmpop.h
# Basic DSM-population class
#
########################################################################*/

#ifndef _DSMPOP_H
#define _DSMPOP_H

#define MAX_GLOBAL_QUESTIONS   2000

struct TDsmElem
{
    int Increment;
    int ValueCount;
    int MaxSize;
    char *DataArr;
};

class TDsmPopulation
{
public:
    TDsmPopulation();
	~TDsmPopulation();

	void AddNo(int globalid, char score);
	void AddSelf(int globalid, char score);
	void AddDx(int globalid, char score);
	void Add(int cat, int globalid, char score);

    void Correlate();
    void Sort();

    long double Corr[MAX_GLOBAL_QUESTIONS];
	int IndArr[MAX_GLOBAL_QUESTIONS];

    TDsmElem NoCat[MAX_GLOBAL_QUESTIONS];
    TDsmElem SelfCat[MAX_GLOBAL_QUESTIONS];
    TDsmElem DxCat[MAX_GLOBAL_QUESTIONS];
};

#endif

