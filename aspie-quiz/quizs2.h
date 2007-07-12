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
# quizs2.h
# Quiz stable release 2 class
#
########################################################################*/

#ifndef _QUIZS2_H
#define _QUIZS2_H

#include "quiz.h"
#include "file.h"

class TQuizS2 : public TQuiz
{
public:
    TQuizS2(const char *FileName, TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1);
    ~TQuizS2();

    virtual void ExportExcelCase(const char *filename, int PcaType);
    virtual void ExportExcelGroups(const char *filename);
    virtual void ImportMvsp(const char *filename, int PcaType);

    virtual void WritePictureRating(const char *filename);

private:
    virtual void GetReferer(const char *referer, TPopulation *pop);
    virtual void WriteName(TFile &File);
    virtual int GetPcaCount();
    virtual int GetCatCount(int Question);
	virtual int GetQuizN();

    void DefineQuiz();
    void SetupTexts();
    void InitReferers();
    void LoadReferers();
    void LoadPopulations();
    void SetupControlGroups();
    void SetupCross(TQuiz *QuizI, TQuiz *QuizII, TQuiz *QuizIII, TQuiz *QuizNd, TQuiz *Quiz5, TQuiz *Quiz6, TQuiz *Quiz7, TQuiz *Quiz8, TQuiz *Quiz9, TQuiz *QuizR1, TQuiz *QuizR2, TQuiz *QuizR3, TQuiz *QuizR4, TQuiz *QuizR5, TQuiz *QuizR6, TQuiz *QuizR7, TQuiz *QuizS1);
    void UpdateReferer(TReferer *ref, int AsResult, int NtResult);

    TFile FDataFile;
};

#endif

