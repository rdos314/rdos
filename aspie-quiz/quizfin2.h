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
# quizfin2.h
# Quiz class for final version 2
#
########################################################################*/

#ifndef _QUIZFIN2_H
#define _QUIZFIN2_H

#include "quiz.h"
#include "file.h"

class TQuizFinal2 : public TQuiz
{
public:
    TQuizFinal2(const char *FileName);
    ~TQuizFinal2();

    virtual void ExportExcelAspieItems(const char *filename);
    virtual void ExportExcelNtItems(const char *filename);

    virtual void ExportExcelCase(const char *filename, int PcaType);
    virtual void ExportExcelGroups(const char *filename);
    virtual void ExportExcelAspie(const char *filename);
    virtual void ImportMvsp(const char *filename, int PcaType);
    virtual void WriteRace(const char *filename);

protected:
    virtual void GetReferer(const char *referer, TPopulation *pop);
    virtual void WriteName(TFile &File);
    virtual void WriteLongName(TFile &File);
	virtual int GetPcaCount();
	virtual int GetCatCount(int Question);
	virtual int GetQuizN();

	void InitReferers();
	void SetupControlGroups();
	void SetupCross();
    void SetupTexts();
    void LoadReferers();
    void LoadPopulations();

    TFile FDataFile;

};

#endif
