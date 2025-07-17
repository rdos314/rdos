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
# httpd.cpp
# HTTP server application for RDOS
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "rdos.h"
#include "sockobj.h"
#include "httpfact.h"
#include "httpcust.h"

#define FALSE 0
#define TRUE !FALSE


/*##################  Authorize ##########################
*   Purpose....: Authorize                                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int Authorize(THttpSocketServer *server, const char *user, const char *passw)
{
    return TRUE;
}


/*##################  WriteCommand ##########################
*   Purpose....: Write command echo                                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void WriteCommand(THttpSocketServer *server, const char *str)
{
        printf(str);
}

/*##################  main ##########################
*   Purpose....: Program entry-point                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void cdecl main()
{
        THttpSocketServerFactory *Factory = new THttpSocketServerFactory(80, 50, 0x4000);
        TWait *Wait = new TWait;

        Factory->OnCommand = WriteCommand;
        Factory->OnAuthorize = Authorize;
        Factory->RootDir = "d:\\wwwroot";
        Wait->Add(Factory);
        for (;;)
                Wait->WaitForever();
}

