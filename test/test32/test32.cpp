#include <rdos.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "serial.h"
#include "section.h"
#include "file.h"

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

#define FALSE 0
#define TRUE !FALSE

char FStrip[100];
int FStripSize;
char RefStrip[100];

const int ParityTable[32] =
                {
                    FALSE,  // 0000 0000 =  0, 0 set bits - odd is false
                    TRUE,   // 0000 0001 =  1, 1 set bits - odd is true
                    TRUE,   // 0000 0010 =  2, 1 set bits - odd is true 
                    FALSE,  // 0000 0011 =  3, 2 set bits - odd is false
                    TRUE,   // 0000 0100 =  4, 1 set bits - odd is true 
                    FALSE,  // 0000 0101 =  5, 2 set bits - odd is false 
                    FALSE,  // 0000 0110 =  6, 2 set bits - odd is false 
                    TRUE,   // 0000 0111 =  7, 3 set bits - odd is true
                    TRUE,   // 0000 1000 =  8, 1 set bits - odd is true 
                    FALSE,  // 0000 1001 =  9, 2 set bits - odd is false 
                    FALSE,  // 0000 1010 = 10, 2 set bits - odd is false
                    TRUE,   // 0000 1011 = 11, 3 set bits - odd is true
                    FALSE,  // 0000 1100 = 12, 2 set bits - odd is false
                    TRUE,   // 0000 1101 = 13, 3 set bits - odd is true
                    TRUE,   // 0000 1110 = 14, 3 set bits - odd is true
                    FALSE,  // 0000 1111 = 15, 4 set bits - odd is false
                    TRUE,   // 0001 0000 = 16, 1 set bits - odd is true
                    FALSE,  // 0001 0001 = 17, 2 set bits - odd is false
                    FALSE,  // 0001 0010 = 18, 2 set bits - odd is false
                    TRUE,   // 0001 0011 = 19, 3 set bits - odd is true
                    FALSE,  // 0001 0100 = 20, 2 set bits - odd is false
                    TRUE,   // 0001 0101 = 21, 3 set bits - odd is true
                    TRUE,   // 0001 0110 = 22, 3 set bits - odd is true
                    FALSE,  // 0001 0111 = 23, 4 set bits - odd is false
                    FALSE,  // 0001 1000 = 24, 2 set bits - odd is false
                    TRUE,   // 0001 1001 = 25, 3 set bits - odd is true
                    TRUE,   // 0001 1010 = 26, 3 set bits - odd is true
                    FALSE,  // 0001 1011 = 27, 4 set bits - odd is false
                    TRUE,   // 0001 1100 = 28, 3 set bits - odd is true 
                    FALSE,  // 0001 1101 = 29, 4 set bits - odd is false 
                    FALSE,  // 0001 1110 = 30, 4 set bits - odd is false 
                    TRUE    // 0001 1111 = 31, 5 set bits - odd is true
                };

void NotifyGoodCard(const char *buf)
{
    int i;
    char ch;
    char strip[41];

    buf++;
    for (i = 0; i < FStripSize - 3; i++)
    {
        ch = *buf & 0xF;
        if (ch <= 9)
            strip[i] = ch + '0';
        else
            strip[i] = ch + 'A' - 10;
        buf++;
    }
    strip[i] = 0;

    if (strcmp(strip, RefStrip))
    {
        printf("Strip differs. In: <");
        printf(RefStrip);
        printf(">, Out: <");
        printf(strip);
        printf(">\r\n");
    }
}

int CheckLrc()
{
    int i;
    char value;
    char *buf = FStrip;

    value = 0;
    for (i = 0; i < FStripSize - 1; i++)
    {
        value ^= *buf & 0xF;
        buf++;
    }

    return value == (*buf & 0xF);
}

int CheckParity()
{
    int i;
    char *buf = FStrip;

    for (i = 0; i < FStripSize; i++)
    {
        if (!ParityTable[*buf])
            return FALSE;
        buf++;
    }

    return TRUE;
}


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
    int i;
    int size;
    char *str;

    str = new char[65536];

    TFile File("d:\\test\\912684.txt");

    size = File.Read(str, 65535);
    str[size] = 0;

    FStripSize = RdosTestGate(str);
    while (FStripSize)
    {
        memcpy(FStrip, str, FStripSize);
        FStrip[FStripSize] = 0;

        if (CheckParity() && CheckLrc())
            NotifyGoodCard(FStrip);
        else
            printf("Wrong parity or CRC\r\n");

        str[0] = 0;
        FStripSize = RdosTestGate(str);
    }

    for (;;)
    {
        size = 1 + RdosGetRandom(36);
        for (i = 0; i < size; i++)
            FStrip[i] = '0' + RdosGetRandom(10);
        FStrip[size] = 0;
        strcpy(RefStrip, FStrip);
 
        FStripSize = RdosTestGate(FStrip);
        if (FStripSize == size + 3)
        {
            if (CheckParity() && CheckLrc())
                NotifyGoodCard(FStrip);
            else
                printf("Wrong parity or CRC\r\n");
        }
        else
            printf("Wrong size\r\n");
    }


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

//    int i;
    TParam *param;

    int PortCount;
    int ModuleId;

//    int size;
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
