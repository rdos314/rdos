#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "serial.h"
#include "section.h"
#include "file.h"
#include "rdos.h"
#include "rdoslog.h"

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
    TRdosLog log("Test");

    log.Setup("d:/rdoslog", 50, 0x10000);
    log.Write(0, "Label", "Some text");

//    RdosTestGate("");
}
