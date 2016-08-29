#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <string.h>
#include "rdos.h"

extern "C" void WriterThread(void *Data)
{
    char *str = (char *)Data;
    char var[40];
    char valstr[40];
    int handle;
    int val;

    strcpy(var, "Entry");
    strcat(var, str);

    for (;;)
    {
        RdosWaitMilli(RdosGetRandom(20));
        handle = RdosOpenIni("z:\\test.ini");
        RdosGotoIniSection(handle, "TEST");
        if (!RdosReadIni(handle, var, valstr, 40))
            strcpy(valstr, "0");
        val = atoi(valstr);
        val++;
        sprintf(valstr, "%d", val);
        RdosWriteIni(handle, var, valstr);
        RdosCloseIni(handle);
    }
}

void main()
{
    int handle;
    char str[40];
    char name[40];
    int i;

    handle = RdosOpenIni("z:\\test.ini");
    RdosGotoIniSection(handle, "TEST");
    RdosWriteIni(handle, "Entry1", "1");
    RdosWriteIni(handle, "Entry2", "2");
    RdosGotoIniSection(handle, "SYS");
    RdosWriteIni(handle, "Entry3", "3");
    RdosGotoIniSection(handle, "TEST");
    RdosWriteIni(handle, "Entry4", "4");
    RdosDeleteIni(handle, "Entry1");
    RdosCloseIni(handle);

    handle = RdosOpenIni("z:\\test.ini");
    RdosGotoIniSection(handle, "TEST");
    RdosWriteIni(handle, "Entry9", "9");
    RdosCloseIni(handle);
    
    for (i = 0; i < 16; i++)
    {
        sprintf(str, "%d", i);
        sprintf(name, "Write #%d", i);
        RdosCreateThread(WriterThread, name, str, 0x2000);
    }

    for (;;)
        RdosWaitMilli(1000);
}
