#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "dlltest.h"
#include "dllcpp.h"

int __stdcall DllMain(int handle, int reason, void *resv)
{
    return 1;
}

void  __export TestFunc(char *str, int *vol)
{
    int i;

    CppTest();

    *vol = 55;
    i = 1;
}
