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
# quizf14.h
# Quiz final version 14 class
#
########################################################################*/

#ifndef _QUIZF14_H
#define _QUIZF14_H

#include "quizf13.h"
#include "file.h"

class TQuizF14 : public TQuizFinal
{
public:
	 TQuizF14(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9, TQuiz *QuizS10, TQuiz *QuizS11, TQuiz *QuizS12, TQuiz *QuizN1, TQuiz *QuizN2, TQuiz *QuizN3, TQuiz *QuizN4, TQuiz *QuizFI, TQuiz *QuizF1, TQuiz *QuizF2, TQuiz *QuizF3, TQuiz *QuizF4, TQuiz *QuizF5, TQuiz *QuizF6, TQuiz *QuizF7, TQuiz *QuizF8, TQuiz *QuizF9, TQuiz *QuizF10, TQuiz *QuizF11, TQuiz *QuizF12, TQuiz *QuizF13);
	 ~TQuizF14();

	 virtual void ExportExcelCase(const char *filename, int PcaType);
	 virtual void ExportExcelGroups(const char *filename);
	 virtual void ExportExcelAspie(const char *filename);
	 virtual void ImportMvsp(const char *filename, int PcaType);

	 virtual void WriteRetest(const char *filename);
	 virtual void WriteRace(const char *filename);

private:
    virtual void GetReferer(const char *referer, TPopulation *pop);
    virtual void WriteName(TFile &File);
    virtual void WriteLongName(TFile &File);
    virtual int GetCatCount(int Question);
	virtual int GetQuizN();

	void SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1, TQuiz *QuizS2, TQuiz *QuizS3, TQuiz *QuizS4, TQuiz *QuizS5, TQuiz *QuizS6, TQuiz *QuizS7, TQuiz *QuizS8, TQuiz *QuizS9, TQuiz *QuizS10, TQuiz *QuizS11, TQuiz *QuizS12, TQuiz *QuizN1, TQuiz *QuizN2, TQuiz *QuizN3, TQuiz *QuizN4, TQuiz *QuizFI, TQuiz *QuizF1, TQuiz *QuizF2, TQuiz *QuizF3, TQuiz *QuizF4, TQuiz *QuizF5, TQuiz *QuizF6, TQuiz *QuizF7, TQuiz *QuizF8, TQuiz *QuizF9, TQuiz *QuizF10, TQuiz *QuizF11, TQuiz *QuizF12, TQuiz *QuizF13);
    void SetupTexts();
    void LoadReferers();
    void LoadPopulations();

    TFile FDataFile;
};

#endif

