#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

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
int main(int argc, char **argv)
{
    char *ptr;

    ServTest();

    switch (argc)
    {
        case 1:
            ptr = argv[0];
            break;

        case 2:
            ptr = argv[0];
            ptr = argv[1];
            break;

        case 3:
            ptr = argv[0];
            ptr = argv[1];
            ptr = argv[2];
            break;

        default:
            break;
    }


    for (;;)
        RdosWaitMilli(100);
}
