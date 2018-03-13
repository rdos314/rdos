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

#include "section.h"

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
    int handle;
    int id;

    int gdt_base;
    int ldt_base;
    int handlec_base;
    int linear_base;
    int big_base;
    int small_base;
    long long phys_base;

    int gdt;
    int ldt;
    int handlec;
    int linear;
    int big;
    int small;
    long long phys;

    int diff_gdt;
    int diff_ldt;
    int diff_handlec;
    int diff_linear;
    int diff_big;
    int diff_small;
    int diff_phys;

    gdt_base = RdosGetFreeGdt();
    ldt_base = RdosGetFreeLdt();
    handlec_base = RdosGetFreeHandles();
    linear_base = RdosGetFreeBigLocalLinear();
    big_base = RdosGetFreeBigKernelLinear();
    small_base = RdosGetFreeSmallKernelLinear();
    phys_base = RdosGetFreePhysical();

#if defined(CREATE_THREAD) || defined(LOAD_DLL)

    RdosWaitMilli(2000);

    for (i = 0; i < 2; i++)
    {

        id = RdosFork();
        if (id == 0)
        {
            RdosWaitMilli(1000);
            exit(1);
        }

        RdosWaitMilli(2000);

    }
#endif
}
