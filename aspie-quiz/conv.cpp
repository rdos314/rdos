/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
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
# conv.cpp
# Convert exported quiz to binary files
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "file.h"

void Conv1();
void Conv2();
void Conv3();
void ConvNd();
void Conv5();
void Conv6();
void Conv7();
void Conv8();
void Conv9();
void ConvR1();
void ConvR2();
void ConvR3();
void ConvR4();
void ConvR5();
void ConvR6();
void ConvR7();
void ConvS1();
void ConvS2();
void ConvS3();
void ConvS4();
void ConvS5();
void ConvS6();
void ConvS7();
void ConvS8();
void ConvS9();
void ConvS10();
void ConvS11();
void ConvS12();
void ConvN1();
void ConvN2();
void ConvN3();
void ConvN4();
void ConvFI();
void ConvF1();
void ConvF2();
void ConvF3();
void ConvF4();
void ConvF5();
void ConvF6();
void ConvF7();
void ConvF8();
void ConvF9();
void ConvF10();
void ConvF11();
void ConvF12();
void ConvF13();
void ConvF14();
void ConvF15();

void ConvH4();
void ConvH5();
void ConvH6();
void ConvH7();
void ConvH8();

#define MAX_QUESTIONS 400

struct TValArr
{
    int Gender;
    int BirthYear;
    int Count;
    char Quiz[MAX_QUESTIONS];
};

int MaxSize;
int ValueCount;
TValArr *ValArr = 0;

int AsArr[MAX_QUESTIONS];
int NtArr[MAX_QUESTIONS];
int AsCount;
int NtCount;
int ReverseArr[MAX_QUESTIONS];

char Suffix[16];

TFile *PcaFile = 0;

/*##################  WriteOne ##########################
*   Purpose....: Write one entry                                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteOne(struct TValArr *entry)
{
    int i;
    int val;
    char str[12];
    
    for (i = 0; i < entry->Count; i++)
    {
        val = entry->Quiz[i];

        if (val > 0)
            val--;

        if (i == entry->Count - 1)            
            sprintf(str, "%d\r\n", val);
        else
            sprintf(str, "%d,", val);

        PcaFile->Write(str);
    }  
}

/*##################  WriteRev ##########################
*   Purpose....: Write rev (group) entry                                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteRev(struct TValArr *entry)
{
    int i;
    int val;
    char str[12];
    
    for (i = 0; i < entry->Count; i++)
    {
        val = entry->Quiz[i];

        if (val > 0)
        {
            if (ReverseArr[i])
                val = 3 - val;
            else
                val--;
        }

        if (i == entry->Count - 1)            
            sprintf(str, "%d\r\n", val);
        else
            sprintf(str, "%d,", val);

        PcaFile->Write(str);
    }  
}

/*##################  WriteAllPca ##########################
*   Purpose....: Write PCA, whole population                                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteAllPca()
{
    char str[80];
    int i;

    printf("All PCA\r\n");

    strcpy(str, "pca\\all");
    strcat(str, Suffix);
    strcat(str, ".csv");

    PcaFile = new TFile(str, 0);
    
    for (i = 0; i < ValueCount; i++)
        WriteOne(&ValArr[i]);

    delete PcaFile;
    PcaFile = 0;
}

/*##################  WriteMalePca ##########################
*   Purpose....: Write PCA, male population                                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteMalePca()
{
    char str[80];
    int i;

    printf("Male PCA\r\n");

    strcpy(str, "pca\\male");
    strcat(str, Suffix);
    strcat(str, ".csv");

    PcaFile = new TFile(str, 0);
    
    for (i = 0; i < ValueCount; i++)
        if (ValArr[i].Gender == 1)
            WriteOne(&ValArr[i]);

    delete PcaFile;
    PcaFile = 0;
}

/*##################  WriteFemalePca ##########################
*   Purpose....: Write PCA, female population                                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteFemalePca()
{
    char str[80];
    int i;

    printf("Female PCA\r\n");

    strcpy(str, "pca\\fem");
    strcat(str, Suffix);
    strcat(str, ".csv");

    PcaFile = new TFile(str, 0);
    
    for (i = 0; i < ValueCount; i++)
        if (ValArr[i].Gender == 2)
            WriteOne(&ValArr[i]);

    delete PcaFile;
    PcaFile = 0;
}

/*##################  CalcReverse ##########################
*   Purpose....: Calc reversed questions                                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void CalcReverse()
{
    int i;

    for (i = 0; i < MAX_QUESTIONS; i++)
    {
        if (AsArr[i] * NtCount > NtArr[i] * AsCount)
            ReverseArr[i] = FALSE;
        else
            ReverseArr[i] = TRUE;
    }
}

/*##################  WriteGroupPca ##########################
*   Purpose....: Write group PCA, whole population                                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteGroupPca()
{
    char str[80];
    int i;

    printf("Group PCA\r\n");

    CalcReverse();

    strcpy(str, "pca\\grp");
    strcat(str, Suffix);
    strcat(str, ".csv");

    PcaFile = new TFile(str, 0);
    
    for (i = 0; i < ValueCount; i++)
        WriteRev(&ValArr[i]);

    delete PcaFile;
    PcaFile = 0;
}

/*##################  OpenPca ##########################
*   Purpose....: Open PCA                                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void OpenPca(const char *str)
{
    int i;

    strcpy(Suffix, str);

    if (ValArr)
        delete ValArr;
    ValArr = 0;
    ValueCount = 0;

    AsCount = 0;
    NtCount = 0;
    
    for (i = 0; i < MAX_QUESTIONS; i++)
    {
        AsArr[i] = 0;
        NtArr[i] = 0;
    }
}

/*##################  ClosePca ##########################
*   Purpose....: Close PCA                                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void ClosePca()
{
    WriteAllPca();
    WriteMalePca();
    WriteFemalePca();
    WriteGroupPca();

    if (ValArr)
        delete ValArr;
    ValArr = 0;
    ValueCount = 0;
}

/*##################  AddPca ##########################
*   Purpose....: Write PCA                                                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void AddPca(int Gender, int BirthYear, int ScoreDiff, char *ScoreArr, int Count)
{
    int val;
    int i;
    TValArr *NewArr;

    if (ValArr == 0)
    {
         MaxSize = 8;
         ValArr = new TValArr[MaxSize];
    }

    if (ValueCount >= MaxSize)
    {
        MaxSize = 3 * MaxSize / 2;
        NewArr = new TValArr[MaxSize];

        for (i = 0; i < ValueCount; i++)
            NewArr[i] = ValArr[i];

        delete ValArr;
        ValArr = NewArr;
    }

    ValArr[ValueCount].Gender = Gender;
    ValArr[ValueCount].BirthYear = BirthYear;
    ValArr[ValueCount].Count = Count;

    for (i = 0; i < Count; i++)
    {
        val = ScoreArr[i];
        ValArr[ValueCount].Quiz[i] = val;
    }

    if (ScoreDiff >= 35)
    {
        AsCount++;
        
        for (i = 0; i < Count; i++)
        {
            val = ScoreArr[i];
            if (val == 3)
                (AsArr[i])++;
        }
    }

    if (ScoreDiff <= -35)
    {
        NtCount++;
    
        for (i = 0; i < Count; i++)
        {
            val = ScoreArr[i];
            if (val == 3)
                (NtArr[i]++);
        }
    }

    ValueCount++;
}

/*##################  main ##########################
*   Purpose....: Program entry-point                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int main(int argc, char **argv)
{
/*    Conv1();
    Conv2();
    Conv3();
    ConvNd();
    Conv5();
    Conv6();
    Conv7();
    Conv8();
    Conv9();
    ConvR1();
    ConvR2();
    ConvR3();
    ConvR4();
    ConvR5();
    ConvR6();
    ConvR7();
    ConvS1();
    ConvS2();
    ConvS3();
    ConvS4();
    ConvS5();
    ConvS6();
    ConvS7();
    ConvS8();
    ConvS9();
    ConvS10();
    ConvS11();
    ConvS12();
    ConvN1();
    ConvN2();
    ConvN3();
    ConvN4(); 
    ConvFI();
    ConvF1();
    ConvF2();
    ConvF3();
    ConvF4();
    ConvF5();
    ConvF6();
    ConvF7();
    ConvF8();
    ConvF9();
    ConvF10();
    ConvF11();
    ConvF12();
    ConvF13();
    ConvF14();
    ConvF15();

    ConvH4();
    ConvH5();
    ConvH6();
    ConvH7();
*/


    ConvH8();
    
    return 0;
}
