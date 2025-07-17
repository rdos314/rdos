/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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

       	        printf("%04d-%02d-%02d, %02d:%02d:%02d.%03d,  ", 
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

               printf("\n");

            }
        }        

        delete file;
    }
    return 0;
}
