/*#######################################################################
# MID
#
# mid.cpp
# Main MID DLL
#
########################################################################*/

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "rdos.h"
#include "bitdev.h"
#include "testdll.h"

/*##################  DllMain  ###############
*   Purpose....: DLL entrypoint                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: i*                                                          #
*##########################################################################*/
int __stdcall DllMain(int hDll, int reason, void *reserved)
{
    return 0;
}

/*##################  DllInit  ###############
*   Purpose....: Init DLL                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
void __export _stdcall DllInit()
{
    TBitmapGraphicDevice *dev = 0;

    dev = new TBitmapGraphicDevice(1, 640, 1000);

    if (dev)
        delete dev;

}
