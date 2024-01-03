#include <rdos.h>
#include <serv.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include "sslint.h"

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
int main()
{
    TSslServer *Server;
        
    Server = new TSslServer;

    for (;;)
        Server->WaitForMsg();

}
