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

static void *AllocMem(void *caller, size_t size)
{
    void *p;

    p = malloc(size);
    return p;
}

static void FreeMem(void *caller, void *p)
{
    if(p != NULL)
        free(p);
}

void *operator new(size_t size)
{
    void *p;
    void *caller;

    __asm
    {
        mov eax,[ebp+0x18]
        mov caller,eax
    }

    if( size == 0 )
        ++size;

    return AllocMem(caller, size);
}

void *operator new[](size_t size)
{
    void *p;
    void *caller;

    __asm
    {
        mov eax,[ebp+0x18]
        mov caller,eax
    }

    if( size == 0 )
        ++size;

    return AllocMem(caller, size);
}

void operator delete(void *p)
{
    void *caller;

    __asm
    {
        mov eax,[ebp+0x18]
        mov caller,eax
    }

    FreeMem(caller, p);
}

void operator delete[](void *p)
{
    void *caller;

    __asm
    {
        mov eax,[ebp+0x18]
        mov caller,eax
    }

    FreeMem(caller, p);
}


void main()
{
    int *valp;
    char *ptr;

    valp = new int;
    delete valp;

    ptr = new char[512];
    delete ptr;

    int Handle;

    Handle = RdosOpenSysIni();
    RdosCloseIni(Handle);

    Handle = RdosOpenIni("c:/id.ini");
    RdosCloseIni(Handle);

    RdosSetCurDrive('c' - 'a');
    Handle = RdosOpenIni("config.ini");
    RdosCloseIni(Handle);

    RdosSetCurDrive('d' - 'a');
    Handle = RdosOpenIni("/r1/comp.ini");
    RdosCloseIni(Handle);

    RdosSetCurDir("d:/r1");
    Handle = RdosOpenIni("comp.ini");
    RdosCloseIni(Handle);

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

    int handlet1;
    int handlet2;
    int handlet3;

    str = new char[65536];

    for (;;)
    {
        handle1 = RdosCreateRandomBigNum(2 + RdosGetRandom(128));

        val = RdosGetRandom(100);
        handle2 = RdosCreateBigNum();
        RdosLoadBigNum64(handle2,  val);

//        handle2 = RdosCreateRandomBigNum(2 + RdosGetRandom(128));
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

        handle4 = RdosPowModBigNum(handle1, handle2, handle3);

        size = RdosGetBigNumSize10(handle4);
        RdosGetBigNumString10(handle4, str, size);
        printf("Res: ");
        printf(str);
        printf("\r\n");

        handlet1 = RdosCreateBigNum();
        RdosLoadBigNum64(handlet1,  1);

        for (i = 0; i < val; i++)
        {
            handlet2 = RdosMulBigNum(handlet1, handle1);
            handlet3 = RdosModBigNum(handlet2, handle3);

            RdosDeleteBigNum(handlet1);
            RdosDeleteBigNum(handlet2);

            handlet1 = handlet3;
        }

        handle6 = RdosSubBigNum(handle4, handlet1);

        size = RdosGetBigNumSize10(handle6);
        if (size == 2)
            printf("OK\r\n");
        else
        {
            size = RdosGetBigNumSize10(handlet1);
            RdosGetBigNumString10(handlet1, str, size);
            printf("Modx: ");
            printf(str);
            printf("\r\n");

            size = RdosGetBigNumSize10(handle6);
            RdosGetBigNumString10(handle6, str, size);
            printf("Diff: ");
            printf(str);
            printf("\r\n");
            return;
        }

        RdosDeleteBigNum(handle1);
        RdosDeleteBigNum(handle2);
        RdosDeleteBigNum(handle3);
        RdosDeleteBigNum(handle4);
        RdosDeleteBigNum(handle6);

        RdosDeleteBigNum(handlet1);

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
