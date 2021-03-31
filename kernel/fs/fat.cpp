#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#define FALSE 0
#define TRUE !FALSE

static int handle = 0;

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

    handle = ServGetVfsHandle();

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
            printf(ptr);
            printf("\r\n");

            ptr = argv[1];
            printf(ptr);
            printf("\r\n");

            ptr = argv[2];
            printf(ptr);
            printf("\r\n");

            break;

        case 4:
            ptr = argv[0];
            printf(ptr);
            printf("\r\n");

            ptr = argv[1];
            printf(ptr);
            printf("\r\n");

            ptr = argv[2];
            printf(ptr);
            printf("\r\n");

            ptr = argv[3];
            printf(ptr);
            printf("\r\n");

            break;

        default:
            break;
    }
}
