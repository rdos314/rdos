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
    TRdosDefaultLog def("d:/rdoslog", 50, 0x10000, "System");
    TRdosEventLog log("d:/evlog", 50, 50, "Test");

    def.printf(0, "main", "Started, %d", 150);
    log.Write(0, "Label", "Some text");

    def.Stop();
    log.Write(0, "Label", "After stopped");

    log.DumpEvents();

//    RdosTestGate("");
}
