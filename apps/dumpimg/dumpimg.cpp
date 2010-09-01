/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2010, Leif Ekblad
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
# dumpimg.cpp
# Dump RDOS image
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "rdosimg.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  main ##########################
*   Purpose....: Program entry-point                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int main(int argc, char **argv)
{
    char FileName[256];
    TRdosImage img;
    TRdosObject *obj;
    TString info;

    if (argc == 2)
    {
        strcpy(FileName, argv[1]);
        strcat(FileName, ".bin");
            
        img.AddImage(FileName);

        obj = img.FObjectList;

        while (obj)
        {
            info = obj->GetInfo();
            printf(info.GetData());
            printf("\r\n");

            obj = obj->FLink;            
        }
    }
    else
        printf("usage: dumpimg image base name\r\n");        
}

