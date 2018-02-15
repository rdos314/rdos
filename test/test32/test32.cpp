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

#include <math.h>
#include "bignum.h"

#include "testlib.h"

#define FALSE 0
#define TRUE !FALSE

//#define LOAD_DLL  1
#define CREATE_THREAD  1

void TestThread(void *)
{
    RdosWaitMilli(140);
}

void main()
{
    int i;
    int gdt;
    int linear;
    int handle;

//    TestFunc();

#if defined(CREATE_THREAD) || defined(LOAD_DLL)

    for (i = 0; i < 100000; i++)
    {

#ifdef LOAD_DLL
        handle = RdosLoadDll("testlib.dll");
#endif

#ifdef CREATE_THREAD
//        RdosCreateThread(&TestThread, "Test", 0, 0x40000);
#endif

        gdt = RdosGetFreeGdt();
        linear = RdosGetFreeBigLocalLinear();

        printf("GDT: %d, Linear: %08lX\r\n", gdt, linear);

        RdosWaitMilli(250);

#ifdef LOAD_DLL
        RdosFreeDll(handle);
#endif
    }
#endif
}
