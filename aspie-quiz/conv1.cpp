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
# Convert exported quiz to binary file
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "pop.h"
#include "file.h"
#include "quizdb.h"
#include "conv.h"

#define MAX_IN_ROW      0x1000

static TFile quizfile("bin\\quiz1.bin", 0);


/*##################  HandleRow ##########################
 *   Purpose....: Handle a row                                                                   #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-11-20 le                                                #
 *##########################################################################*/
static void HandleRow(TQuizRow *Row)
{
    quizfile.Write(Row, sizeof(TQuizRow));
    printf("I: %d Now: %d Before: %d\r\n", Row->ID, Row->ResultNow, Row->ResultBefore);
}

/*##################  CalcScore ##########################
 *   Purpose....: Calculate score                                                                #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-11-20 le                                                #
 *##########################################################################*/
static void CalcScore(TQuizRow *Row)
{
    int nsum = 0;
    int fsum = 0;
    int i;
    int grp;
    int dx;
    int val;
    int w;
    int sum;
    int totsum;

    for (i = 0; i < 100; i++)
    {
        if (Row->Now[i] && Row->Before[i])
        {
            nsum += Row->Now[i];
            fsum += Row->Before[i];
        }
        else
        {
            if (Row->Now[i])
            {
                nsum += Row->Now[i];
                fsum += Row->Now[i];
            }

            if (Row->Before[i])
            {
                nsum += Row->Before[i];
                fsum += Row->Before[i];
            }
        }
    }

    Row->ResultNow = nsum;
    Row->ResultBefore = fsum;

    for (grp = 0; grp < 14; grp++)
    {
        sum = 0;
        totsum = 0;

        for (i = 0; i < 100; i++)
        {
            val = Row->Now[i];
            if (Row->Before[i] > val)
                val = Row->Before[i];

            w = Gw[i][grp];

            if (w < 0)
            {
                w = -w;
                val = 2 - val;
            }

            sum += val * w;
            totsum += 2 * w;
        }

        if (totsum)
            Row->GroupResult[grp] = 100 * sum / totsum;
        else
            Row->GroupResult[grp] = 0;
    }
}

/*##################  ProcessRow ##########################
 *   Purpose....: Process row                                                                    #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-11-20 le                                                #
 *##########################################################################*/
static void ProcessRow(char *str)
{
    char *valstr;
    char *ptr;
    int fieldno;
    int i;
    int year, month, day;
    int hour, min, sec;
    TDateTime *time;
    TQuizRow Row;

    for (fieldno = 0; fieldno < 207; fieldno++)
    {
        valstr = str;
        ptr = strstr(str, ";");
        if (ptr)
        {
            *ptr = 0;
            str = ptr + 1;

            switch (fieldno)
            {
                case 0:
                    Row.ID = atol(valstr);
                    break;

                case 1:
                    sscanf(valstr+1, "%04d-%02d-%02d %02d:%02d:%02d",
                            &year, &month, &day,
                            &hour, &min, &sec);

                    time = new TDateTime(year, month, day, hour, min, sec);
                    Row.LsbTime = time->GetLsb();
                    Row.MsbTime = time->GetMsb();
                    delete time;
                    break;

                case 2:
                    Row.Diagnos = atoi(valstr);
                    break;

                case 3:
                    Row.Age = atoi(valstr);
                    break;

                case 4:
                    Row.Gender = atoi(valstr);
                    break;

                case 5:
                    Row.ResultNow = atoi(valstr);
                    break;

                case 6:
                    Row.ResultBefore = atoi(valstr);
                    break;

                default:
                    i = fieldno - 7;
                    if (i >= 100)
                        Row.Now[i - 100] = atoi(valstr);
                    else
                        Row.Before[i] = atoi(valstr);
                    break;
            }                    
        }
    }

    CalcScore(&Row);
    HandleRow(&Row);
}

/*##################  Conv1 ##########################
 *   Purpose....: Convert quiz1                                                            #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-11-20 le                                                #
 *##########################################################################*/
void Conv1()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("raw\\aspie-quiz.csv");
    char *ptr;

    size = infile.Read(buf, MAX_IN_ROW);
    buf[size] = 0;
    ptr = strchr(buf, 0xd);
    if (ptr)
        *ptr = 0;       

    pos += strlen(buf) + 1;
    infile.SetPos(pos);

    while (size = infile.Read(buf, MAX_IN_ROW))
    {
        buf[size] = 0;
        ptr = strchr(buf, 0xd);
        if (ptr)
            *ptr = 0;   

        pos += strlen(buf) + 1;
        infile.SetPos(pos);

        if (ptr)
            ProcessRow(buf);
    }
}

