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

void main()
{
    TestFunc();

    int handle = RdosLoadDll("testlib.dll");
    RdosFreeDll(handle);
    
    
    RdosTestGate("");


    int val;
    TBigNum num1("-233445565766");
    TBigNum num2(100);
    TBigNum num3(-2000);
    TString str;

    str = num1.GetDec();
    printf(str.GetData());
    printf("\r\n");

    num1 = 1234;

    str = num1.GetDec();
    printf(str.GetData());
    printf("\r\n");

    num1 += 5576;

    str = num1.GetDec();
    printf(str.GetData());
    printf("\r\n");

    num1 -= 8888;
    
    str = num1.GetDec();
    printf(str.GetData());
    printf("\r\n");

}
