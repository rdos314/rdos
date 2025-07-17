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
# convdeb.cpp
# Convert debug log
#
########################################################################*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

#include "rdos.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  main ##########################
*   Purpose....: Program entry-point                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int main()
{
    int in_handle = RdosOpenHandle("z:\\debug.log", O_RDWR);
    int out_handle = RdosOpenHandle("z:\\debug.txt", O_CREAT | O_RDWR);
    char in_buf[2*80];
    char out_buf[80+2];
    int size;
    int i;

    size = RdosReadHandle(in_handle, in_buf, 2 * 80);
    while (size)
    {
        for (i = 0; i < 80; i++)
            out_buf[i] = in_buf[2*i];
        out_buf[80] = 0xd;
        out_buf[81] = 0xa;
        RdosWriteHandle(out_handle, out_buf, 82);
        size = RdosReadHandle(in_handle, in_buf, 2 * 80);
    }

    RdosCloseHandle(in_handle);
    RdosCloseHandle(out_handle);        
}
