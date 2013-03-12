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
# quizh14.h
# Quiz class for H14
#
########################################################################*/

#ifndef _QUIZH14_H
#define _QUIZH14_H

#include "quiz.h"
#include "file.h"

class TQuizH14 : public TQuiz
{
public:
    TQuizH14(const char *FileName);
    ~TQuizH14();

    virtual void ImportMvsp(const char *filename, int PcaType);

    void WriteEyeResults(const char *filename);

protected:
    virtual void GetReferer(const char *referer, TPopulation *pop);
    virtual void WriteName(TFile &File);
    virtual void WriteLongName(TFile &File);
	virtual int GetPcaCount();
	virtual int GetCatCount(int Question);
	virtual int GetQuizN();

	void SetupCross();
    void SetupTexts();
    void LoadPopulations();

    TFile FDataFile;

    int FAspieEyeCount[28];
    int FAspieEyeArr[28][85];
    int FNtEyeCount[28];
    int FNtEyeArr[28][85];

};

#endif
