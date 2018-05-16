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
#include "modbus.h"

#include <math.h>
#include "bignum.h"

#include "section.h"

#include "testlib.h"


#define FALSE 0
#define TRUE !FALSE

#define LOAD_DLL  1
#define CREATE_THREAD  1

void TestThread(void *)
{
    RdosWaitMilli(140);
}

void main()
{
    int size;
    int val;
    int ok;
    int i;
    char str[40];
    TSerialDevice serial(1, 19200);
    TModbus Modbus(&serial, 1);

    serial.Open();
    serial.Enable();

    for (;;)
    {
        for (i = 0; i < 20; i++)
        {
            val = Modbus.ReadInputStatus(10001 + i);
            printf("Input%d: %d\n", 10001 + i, val);
        }
        RdosWaitMilli(500);
    }

    val = Modbus.ReadInputStatus(10001);
    printf("Input: %d\n", val);

    val = Modbus.ReadInputRegister(30001);
    printf("Inupt: %d\n", val);

    ok = Modbus.PresetRegister(40009, 1234);

    for (;;)
    {
        RdosSetCursorPosition(10, 0);

        for (i = 40001; i <= 40020; i++)
        {
            val = Modbus.ReadHoldingRegister(i);
            sprintf(str, "Register%d: %d\r\n", i, val);
            RdosWriteString(str);

            if (i == 40001)
            {
                switch (val)
                {
                    case 1:
                        ok = Modbus.PresetRegister(40010, 5000);
                        ok = Modbus.PresetRegister(40008, 1);
                        break;

                    case 3:
                        ok = Modbus.PresetRegister(40008, 2);
                        break;
                }
            }
        }
    }


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



    handle = open("test.txt", O_CREAT | O_TEXT | O_RDWR);
    write(handle, "\ntest\n123\n4", 11);


    gdt_base = RdosGetFreeGdt();
    ldt_base = RdosGetFreeLdt();
    handlec_base = RdosGetFreeHandles();
    linear_base = RdosGetFreeBigLocalLinear();
    big_base = RdosGetFreeBigKernelLinear();
    small_base = RdosGetFreeSmallKernelLinear();
    phys_base = RdosGetFreePhysical();

#if defined(CREATE_THREAD) || defined(LOAD_DLL)

    for (i = 0; i < 100000; i++)
    {

        id = fork();
        if (id == 0)
        {
            RdosWaitMilli(150);
            exit(1);
        }

#ifdef LOAD_DLL
        handle = RdosLoadDll("testlib.dll");
#endif

#ifdef CREATE_THREAD
        RdosCreateThread(&TestThread, "Test", 0, 0x40000);
#endif

        gdt = RdosGetFreeGdt();
        ldt = RdosGetFreeLdt();
        handlec = RdosGetFreeHandles();
        linear = RdosGetFreeBigLocalLinear();
        big = RdosGetFreeBigKernelLinear();
        small = RdosGetFreeSmallKernelLinear();
        phys = RdosGetFreePhysical();

        diff_gdt = gdt - gdt_base;
        diff_ldt = ldt - ldt_base;
        diff_handlec = handlec - handlec_base;
        diff_linear = linear - linear_base;
        diff_small = small - small_base;
        diff_big = (big - big_base) / 0x1000;
        diff_phys = (int)(phys - phys_base) / 0x1000;

        gdt_base = gdt;
        ldt_base = ldt;
        handlec_base = handlec;
        linear_base = linear;
        small_base = small;
        big_base = big;
        phys_base = phys;

        printf("GDT: %d, LDT: %d, Handles: %d, Linear: %d, Big: %d, Small: %d, Phys: %d\r\n", diff_gdt, diff_ldt, diff_handlec, diff_linear, diff_big, diff_small, diff_phys);

        RdosWaitMilli(250);

#ifdef LOAD_DLL
        RdosFreeDll(handle);
#endif
    }
#endif
}
