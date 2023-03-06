#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "str.h"

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
    int probe = 3;
    char temp[20];
    char str[80];
    TString dummyMsg;

    sprintf(temp, "$B%02d", probe);
    sprintf(str, "%s", temp);

    dummyMsg.printf("%s", temp);
}
