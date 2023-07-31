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
# quiz.cpp
# Basic quiz class
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <math.h>

#define MAX_IN_ROW 4096

#include "quiz.h"
#include "file.h"

static double r2pi = sqrt(2.0 * 3.14159265358979323846);

/*##########################################################################
#
#   Name       : TQuizItem::TQuizItem
#
#   Purpose....: Constructor for TQuizItem
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizItem::TQuizItem()
{
    Text = "NO TEXT";
    MyGroup = 0;
    Reverse = false;
}

/*##########################################################################
#
#   Name       : TQuizItem::~TQuizItem
#
#   Purpose....: Destructor for TQuizItem
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizItem::~TQuizItem()
{
}

/*##########################################################################
#
#   Name       : TQuiz::TQuiz
#
#   Purpose....: Constructor for TQuiz
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuiz::TQuiz(int Questions)
{
    int i;

    N = Questions;

    ItemArr = new TQuizItem*[N];

    for (i = 0; i < N; i++)
        ItemArr[i] = new TQuizItem;

    ValueCount = 0;
    ValueSize = 0;
    ValueArr = 0;

    GroupValArr = 0;
    GroupValCount = 0;

    Init();

    CalcProbArr(28.4, 28.0);
}

/*##########################################################################
#
#   Name       : TQuiz::~TQuiz
#
#   Purpose....: Destructor for TQuiz
#
#   In params..: Filename to load quiz from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuiz::~TQuiz()
{
    int i;

    for (i = 0; i < N; i++)
        delete ItemArr[i];

    delete ItemArr;

    for (i = 0; i < ValueCount; i++)
        delete ValueArr[i];

    if (ValueArr)
        delete ValueArr;

    if (GroupValArr)
        delete GroupValArr;
}

/*##########################################################################
#
#   Name       : TQuiz::Init
#
#   Purpose....: Init
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuiz::Init()
{
    int i;
    int g;
    int g1, g2;

    for (g = 0; g < MAX_GROUP_COUNT; g++)
    {
        Group[g].PosName = "NO NAME";
        Group[g].NegName = "NO NAME";
    }

    Group[GROUP_ASPIE_TALENT].PosName = "Aspie ability";
    Group[GROUP_ASPIE_TALENT].NegName = "Aspie ability problem";

    Group[GROUP_NT_TALENT].PosName = "NT ability problem";
    Group[GROUP_NT_TALENT].NegName = "NT ability";

    Group[GROUP_ASPIE_RELATION].PosName = "Aspie relationship";
    Group[GROUP_ASPIE_RELATION].NegName = "Aspie relationship problem";

    Group[GROUP_ASPIE_SOCIAL].PosName = "Aspie social";
    Group[GROUP_ASPIE_SOCIAL].NegName = "Aspie social problem";

    Group[GROUP_NT_SOCIAL].PosName = "NT social problem";
    Group[GROUP_NT_SOCIAL].NegName = "NT social";

    Group[GROUP_ASPIE_NVC].PosName = "Aspie communication";
    Group[GROUP_ASPIE_NVC].NegName = "Aspie communication problem";

    Group[GROUP_NT_NVC].PosName = "NT communication problem";
    Group[GROUP_NT_NVC].NegName = "NT communication";

    Group[GROUP_NT_RELATION].PosName = "NT relationship problem";
    Group[GROUP_NT_RELATION].NegName = "NT relationship";

    Group[GROUP_ASPIE_SENSORY].PosName = "Aspie sensory";
    Group[GROUP_ASPIE_SENSORY].NegName = "Aspie sensory problem";

    Group[GROUP_NT_SENSORY].PosName = "NT sensory problem";
    Group[GROUP_NT_SENSORY].NegName = "NT sensory";

    Group[GROUP_MIXED].PosName = "Aspie mixed";
    Group[GROUP_MIXED].NegName = "NT mixed";

    for (g1 = 0; g1 < MAX_GROUP_COUNT; g1++)
    {
        for (g2 = 0; g2 < MAX_GROUP_COUNT; g2++)
        {
            GroupCorr[g1][g2].Corr = 0;
            GroupCorr[g1][g2].Count = 0;
        }
    }

    for (g = 0; g < MAX_GROUP_COUNT; g++)
    {
        Group[g].Mean = 0;
        Group[g].Sd = 0;
    }
}

/*##################  TQuiz::CalcNorm ##########################
*   Purpose....: Calculate normal distribution                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
double TQuiz::CalcNorm(double x, double u, double sd, double scale)
{
    double temp;

    temp = (x - u) / sd;
    temp = -0.5 * temp * temp;
    temp = exp(temp);
    temp = temp * scale;

    return temp;
}

/*##################  TQuiz::CalcProbArr ##########################
*   Purpose....: Calculate ND & NT probability                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::CalcProbArr(double u, double sd)
{
    int i;
    double ndp[201];
    double ntp[201];
    double sum;
    double val;
    double x;
    double scale = 1.0 / sd / r2pi;

    sum = 0.0;
    for (i = 0; i < 201; i++)
    {
        x = (double)i;
        val = CalcNorm(x, 100 + u, sd, scale);
        sum += val;
        ndp[i] = sum;
    }

    sum = 0.0;
    for (i = 200; i >= 0; i--)
    {
        x = (double)i;
        val = CalcNorm(x, 100 - u, sd, scale);
        sum += val;
        ntp[i] = sum;
    }

    for (i = 0; i < 201; i++)
    {
        sum = ndp[i] + ntp[i];
        ProbArr[i] = ndp[i] / sum;
    }
}

/*##################  TQuiz::GetCatCount ##########################
*   Purpose....: Return number of categories for question                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuiz::GetCatCount(int Question)
{
    return 3;
}

/*##################  TQuiz::GetQuizN ##########################
*   Purpose....: Return number of questions in the quiz (not counting fictive questions)                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuiz::GetQuizN()
{
    return N;
}

/*##################  TQuiz::WriteNoAnswerStats ##########################
*   Purpose....: Write unanswered item stats                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteNoAnswerStats(const char *filename)
{
}

/*##################  TQuiz::WriteFieldHeader ##########################
*   Purpose....: Write field header for table                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteFieldHeader(TFile &File, int RelWidth)
{
    char str[80];

    sprintf(str, "\n<td width=\"%d%%\" colspan=2 valign=top>\n", RelWidth);
    File.Write(str);

    File.Write("<p>\n");
    File.Write("<b>\n");
}

/*##################  TQuiz::WriteCenteredFieldHeader ##########################
*   Purpose....: Write centered field header for table                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteCenteredFieldHeader(TFile &File, int RelWidth)
{
    char str[80];

    sprintf(str, "\n<td width=\"%d%%\" colspan=2 valign=top>\n", RelWidth);
    File.Write(str);

    File.Write("<p align=\"center\">\n");
    File.Write("<b>\n");
}

/*##################  TQuiz::WriteRightFieldHeader ##########################
*   Purpose....: Write right-aligned field header for table                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteRightFieldHeader(TFile &File, int RelWidth)
{
    char str[80];

    sprintf(str, "\n<td width=\"%d%%\" colspan=2 valign=top>\n", RelWidth);
    File.Write(str);

    File.Write("<p align=\"right\">\n");
    File.Write("<b>\n");
}

/*##################  TQuiz::WriteFieldFooter ##########################
*   Purpose....: Write field footer for table                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteFieldFooter(TFile &File)
{
    File.Write("\n</b>\n");
    File.Write("</p>\n");

    File.Write("</td>\n");
}

/*##################  TQuiz::WriteSumaryTable ##########################
*   Purpose....: Write sumary table                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteSumaryTable(const char *filename, int OnlyMixed)
{
    int i;
    int j;
    char str[80];
    int ival;
    TFile file(filename, 0);

    file.Write("<table border=3 cellspacing=0 cellpadding=0>");

    j = 0;
    
    for (i = 0; i < N; i++)
    {
        if (j % 10 == 0)
        {
            file.Write("<tr style='height:24.75pt'>");

            WriteCenteredFieldHeader(file, 5);
            file.Write("#");
            WriteFieldFooter(file);

            WriteCenteredFieldHeader(file, 40);
            file.Write(" ");
            WriteFieldFooter(file);

            file.Write("</tr>");
        }

        j++;
            
        file.Write("<tr style='height:24.75pt'>");

        WriteCenteredFieldHeader(file, 5);
        sprintf(str, "%d", i + 1);
        file.Write(str);
        WriteFieldFooter(file);

        WriteCenteredFieldHeader(file, 40);
        file.Write(ItemArr[i]->Text);
        WriteFieldFooter(file);

        file.Write("</tr>");
    }

    file.Write("</table>");    
}

/*##################  TQuiz::WriteGroupCorrTable ##########################
*   Purpose....: Write group correlation table                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteGroupCorrTable(const char *filename)
{
}

/*##################  TQuiz::WriteIntercorr ##########################
*   Purpose....: Write intercorrelation report for quiz                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::WriteIntercorr(const char *filename)
{
}

/*##################  AddRow ##########################
*   Purpose....: Add a row                                                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuiz::AddRow(TQuizRow *Row)
{
    int val;
    int i;
    TQuizRow **NewArr;

    printf("%d Score: %d\r\n", Row->ID, Row->Score);

    if (ValueArr == 0)
    {
        ValueSize = 8;
        ValueArr = new TQuizRow*[ValueSize];
    }

    if (ValueCount >= ValueSize)
    {
        ValueSize = 3 * ValueSize / 2;
        NewArr = new TQuizRow*[ValueSize];

        for (i = 0; i < ValueCount; i++)
            NewArr[i] = ValueArr[i];

        delete ValueArr;
        ValueArr = NewArr;
    }

    Row->P = ProbArr[Row->Score];

    ValueArr[ValueCount] = Row;
    ValueCount++;
}
