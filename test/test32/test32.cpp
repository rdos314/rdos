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
    char *str;
    int i;
    TParam *param;

    int PortCount;
    int ModuleId;

    int size;
    long long val;
    int handle1;
    int handle2;
    int handle3;
    int handle4;
    int handle5;
    int handle6;
    int handle7;
    int handle8;

    str = new char[65536];

    for (;;)
    {

        handle1 = RdosCreateRandomBigNum(2 + RdosGetRandom(128));

        handle2 = RdosCreateRandomBigNum(2 + RdosGetRandom(128));

        handle3 = RdosCreateRandomBigNum(2 + RdosGetRandom(128));

        size = RdosGetBigNumSize10(handle1);
        RdosGetBigNumString10(handle1, str, size);
        printf("Base: ");
        printf(str);
        printf("\r\n");

        size = RdosGetBigNumSize10(handle2);
        RdosGetBigNumString10(handle2, str, size);
        printf("Exp: ");
        printf(str);
        printf("\r\n");

        size = RdosGetBigNumSize10(handle3);
        RdosGetBigNumString10(handle3, str, size);
        printf("Mod: ");
        printf(str);
        printf("\r\n");

//        handle4 = RdosModBigNum(handle1, handle3);
        handle4 = RdosPowModBigNum(handle1, handle2, handle3);

        size = RdosGetBigNumSize10(handle4);
        RdosGetBigNumString10(handle4, str, size);
        printf("Res: ");
        printf(str);
        printf("\r\n");

        handle5 = RdosDivBigNum(handle1, handle3);

        size = RdosGetBigNumSize10(handle5);
        RdosGetBigNumString10(handle5, str, size);
        printf("Quot: ");
        printf(str);
        printf("\r\n");

        handle6 = RdosMulBigNum(handle3, handle5);    

        size = RdosGetBigNumSize10(handle6);
        RdosGetBigNumString10(handle6, str, size);
        printf("Mult: ");
        printf(str);
        printf("\r\n");

        handle7 = RdosSubBigNum(handle1, handle6);

        size = RdosGetBigNumSize10(handle7);
        RdosGetBigNumString10(handle7, str, size);
        printf("Diff: ");
        printf(str);
        printf("\r\n");

        handle8 = RdosSubBigNum(handle7, handle4);

        size = RdosGetBigNumSize10(handle8);
        if (size <= 2)
            printf("OK\r\n");
        else
        {
            RdosGetBigNumString10(handle8, str, size);
            printf("Error: ");
            printf(str);
            printf("\r\n");
        }

        RdosDeleteBigNum(handle1);
        RdosDeleteBigNum(handle2);
        RdosDeleteBigNum(handle3);
        RdosDeleteBigNum(handle4);
        RdosDeleteBigNum(handle5);
        RdosDeleteBigNum(handle6);
        RdosDeleteBigNum(handle7);
        RdosDeleteBigNum(handle8);

    }


    handle2 = RdosCreateRandomBigNum(5);

    for (i = 1; i < 200; i++)
    {
        handle1 = RdosCreateRandomBigNum(i);
        handle3 = RdosMulBigNum(handle1, handle2);
        size = RdosGetBigNumSize10(handle3);
        RdosGetBigNumString10(handle3, str, size);
        printf("%i: ", i);
        printf(str);
        printf("\r\n");
        
        RdosDeleteBigNum(handle1);
        RdosDeleteBigNum(handle2);
        handle2 = handle3;
    }

    handle1 = RdosCreateBigNum();
    RdosLoadBigNum64(handle1,  4500000000);


    handle3 = RdosMulBigNum(handle1, handle1);
    handle4 = RdosMulBigNum(handle3, handle3);
    handle5 = RdosDivBigNum(handle4, handle3);

    size = RdosGetBigNumSize10(handle3);
    RdosGetBigNumString10(handle3, str, size);

    size = RdosGetBigNumSize10(handle4);
    RdosGetBigNumString10(handle4, str, size);

    size = RdosGetBigNumSize10(handle5);
    RdosGetBigNumString10(handle5, str, size);

    size = RdosGetBigNumSize16(handle4);
    RdosGetBigNumString16(handle4, str, size);

    RdosDeleteBigNum(handle1);
    RdosDeleteBigNum(handle2);
    RdosDeleteBigNum(handle3);

//    RdosWaitMilli(2000);
//    RdosSoftReset();

//    RdosTestGate();

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
