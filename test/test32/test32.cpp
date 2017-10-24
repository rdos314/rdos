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

#define FALSE 0
#define TRUE !FALSE

void main()
{
    int val;
    TBigNum num1("-233445565766");
    TBigNum num2(100);
    TBigNum num3(-2000);
    TString str;

    str = num1.GetDec();
    printf(str.GetData());
    printf("\r\n");

    str = num2.GetDec();
    printf(str.GetData());
    printf("\r\n");

    str = num3.GetDec();
    printf(str.GetData());
    printf("\r\n");

    str = num1.GetHex(8);
    printf(str.GetData());
    printf("\r\n");

    str = num2.GetHex(4);
    printf(str.GetData());
    printf("\r\n");

    num1.SaveUnsigned((char *)&val, 4);
    printf("%d\r\n", val);

    num2.SaveUnsigned((char *)&val, 4);
    printf("%d\r\n", val);

    num3.SaveUnsigned((char *)&val, 4);
    printf("%d\r\n", val);
    
}
