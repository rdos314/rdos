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
# canshow.cpp
# CAN dump analyzer app.
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>
#include "file.h"
#include "datetime.h"

#define FALSE 0
#define TRUE !FALSE

struct TCanData
{
    int TimeLSB;
    int TimeMSB;
    int Id;
    char Data[8];
    char Size;
};

/*##################  main ##########################
*   Purpose....: Program entry-point                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int main(int argc, char **argv)
{
    char FileName[256];
    TFile *file;
    TDateTime Time;
    struct TCanData CanData;
    int size = 21;
    int id;
    int cmd;
    int port;
    int module;
    int i;
    unsigned int val;
    char str[40];
    
    CanData.Size = 0;

    if (argc == 2)
    {
        strcpy(FileName, argv[1]);
            
        file = new TFile(FileName);

        while (size)
        {
            size = file->Read(&CanData, size);
            if (size)
            {

		Time = TDateTime(CanData.TimeMSB, CanData.TimeLSB);

       	        printf("%04d-%02d-%02d %02d.%02d.%02d,%03d  ", 
	                    Time.GetYear(), 
	                    Time.GetMonth(),
	                    Time.GetDay(),
	                    Time.GetHour(),
	                    Time.GetMin(),
	                    Time.GetSec(),
	                    Time.GetMilliSec());

                id = CanData.Id >> 18;

                if (id & 0x400)
                    printf("From server, ");
                else
                    printf("From device, ");
 
                cmd = id & 0x3;
                switch (cmd)
                {
                    case 0: 
                        printf("Data, ");
                        break;
 
                    case 1: 
                        printf("Port Command,");
                        break;
 
                    case 2: 
                        printf("Module Command,");
                        break;

                    case 3: 
                        printf("Invalid cmd/data,");
                        break;
                }
                
                port = (id >> 2) & 7;
                printf(", Port=%d", port);

                module = (id >> 5) & 0x1F;
                printf(", Module=%d", module);

                for (i = 0; i < CanData.Size; i++)
                {
                    printf(", ");
                    val = (unsigned int)CanData.Data[i];
                    sprintf(str, "%04hX", val);
                    str[0] = str[2];
                    str[1] = str[3];
                    str[2] = 0;
                    printf(str);
               }

               printf("\r\n");

            }
        }        

        delete file;
    }
    return 0;
}
