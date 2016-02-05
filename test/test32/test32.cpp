#include <rdos.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "serial.h"
#include "section.h"

#include <math.h>

struct TParam
{
    int ID;
};

struct TSect
{
    TSection *Section;
    int Owner;
    int Active;
};

TSect *SectionArr[4];

static void TestThread(void *ptr)
{
    int i;
    TParam *param = (TParam *)ptr;
    int count;
    TSect *sect;
    int sectnr = 0;
    int left = 0;

    for (;;)
    {
        if (left)
        {
            left--;
            if (sectnr == 3)
                sectnr = 0;
            else
                sectnr++;
        }
        else
        {
            sectnr = RdosGetRandom(4);
            left = RdosGetRandom(50000);
            count = RdosGetRandom(300);
        }
        
        sect = SectionArr[sectnr];

        sect->Section->Enter();
        sect->Active++;
        sect->Owner = param->ID;
        for (i = 0; i < count; i++)
            if (sect->Active != 1)
                printf("Active wrong: %d\r\n", sect->Active);        

        if (sect->Owner != param->ID)
            printf("Section failed\r\n");        

        sect->Active--;
        sect->Section->Leave();    

        RdosWaitMicro(25);
    }
}

void main()
{
    char str[80];
    int i;
    TParam *param;

    RdosTestGate();

    for (i = 0; i < 4; i++)
    {
        sprintf(str, "Section #%d", i);
        SectionArr[i] = new TSect;
        SectionArr[i]->Section = new TSection(str);
        SectionArr[i]->Owner = 0;
        SectionArr[i]->Active = 0;
    }

    for (i = 0; i < 24; i++)
    {
        param = new TParam;
        param->ID = i;
        sprintf(str, "Test #%d", i);
        RdosCreateThread(TestThread, str, param, 0x4000);
   }

   for (;;)
       RdosWaitMilli(200);
}
