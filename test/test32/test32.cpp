#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "bitdev.h"
#include "testdll.h"

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : main
#
#   Purpose....:
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void main()
{
    int InitFree = RdosGetFreeBigLocalLinear();
    int UsedMem;

    DllInit();

    UsedMem = RdosGetFreeBigLocalLinear() - InitFree;
    printf("%d\r\n", UsedMem);

}
