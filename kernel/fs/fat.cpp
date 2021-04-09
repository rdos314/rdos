#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "discreq.h"

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
    long long sectors;
    int id;

    ServTest();

    sectors = TDiscReq::GetPartSectors();
    printf("Sectors: %lld\r\n", sectors);

    TDiscReq req;

    req.Add(121, 16);
    req.Add(131, 8);
    req.Start();

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
