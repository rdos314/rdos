#include <rdos.h>
#include <serv.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "modbus.h"
#include "disc.h"
#include "md5.h"
#include "ini.h"

#define FALSE 0
#define TRUE !FALSE

int Prev;

/*##########################################################################
#
#   Name       : WriteSmall
#
#   Purpose....: Write small
#
##########################################################################*/
int WriteSmall(const char *msg, int base)
{
    int Curr;
    int Linear;

    Curr = RdosGetFreeSmallKernelLinear();
    Linear = Curr - base;
    printf("Small %s %d\r\n", msg, Linear);

    return Curr;
}

/*##########################################################################
#
#   Name       : WriteIni
#
#   Purpose....: Write ini
#
##########################################################################*/
void WriteIni(int val)
{
    char label[100];
    char str[40];
    TIniFile *ini;

    WriteSmall("before", Prev);

    ini = new TIniFile("c:\\run.ini");

    WriteSmall("new", Prev);

    ini->GotoSection("r1");

    WriteSmall("section", Prev);

    sprintf(label, "total_volume_p%d_n%d", 99, 1);
    sprintf(str, "%d", val);
    ini->WriteVar(label, str);
//    ini->ReadVar(label, str, 30);

    WriteSmall("write", Prev);

    delete ini;

    Prev = WriteSmall("delete", Prev);
}

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
    int total = 0;

    Prev = RdosGetFreeSmallKernelLinear();

    for (;;) 
    {
        WriteIni(total);

        total++;
        RdosWaitMilli(50);
    }

    RdosTestGate("");
}
