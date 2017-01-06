/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2017, Leif Ekblad
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
# Convert solar raw-data to OpenOffice format
#
########################################################################*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "file.h"

#define FALSE 0
#define TRUE !FALSE

#define MAX_IN_ROW      0x1000

/*##################  ProcessRow ##########################
*   Purpose....: Process row                                                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 17-01-06 le                                                #
*##########################################################################*/
static void ProcessRow(char *str)
{
    char *valstr;
    char *ptr;
    int fieldno;
    int i;
    int year, month, day;
    int hour, min, sec;
    int mant;
    int exp;
    int dec;
    long double val;
    char formstr[10];

    ptr = str;
    for (fieldno = 0; ptr; fieldno++)
    {
        valstr = str;
        ptr = strstr(str, ";");
        if (ptr)
            *ptr = 0;

        str = ptr + 1;

        switch (fieldno)
        {
            case 0:
                sscanf(valstr, "%04d-%02d-%02d",
                        &year, &month, &day);
                printf("%04d-%02d-%02d;", year, month, day);
                break;

            case 1:
                sscanf(valstr, "%02d:%02d:%02d",
                        &hour, &min, &sec);
                printf("%02d:%02d:%02d", hour, min, sec);
                break;

            default:
                sscanf(valstr, "%de%d", &mant, &exp);

                val = (long double)mant;

                if (exp >= 0)
                    dec = 0;
                else
                    dec = -exp;

                while (exp > 0)
                {
                    val = val * 10.0;
                    exp--;
                }
    
                while (exp < 0)
                {
                    val = val / 10.0;
                    exp++;
                }

                sprintf(formstr, ";x1.%dLf", dec);
                formstr[1] = '%';
                
                printf(formstr, val);
                break;

        }                    
    }
    printf("\n");
}

/*################## main ##########################
*   Purpose....: main proc                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 17-01-06 le                                                #
*##########################################################################*/
void main()
{
    char buf[MAX_IN_ROW];
    int size;
    long pos = 0;
    TFile infile("2016.csv");
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

