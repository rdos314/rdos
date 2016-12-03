#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "dllcpp.h"

class TTest
{
public:
    TTest();
    ~TTest();

    void Test(char *str);

    char *FStr;    
};

TTest::TTest()
{
    FStr = 0;
}

TTest::~TTest()
{
    if (FStr)
        delete FStr;
}

void TTest::Test(char *str)
{
    int len = strlen(str);
    FStr = new char[len+1];
    strcpy(FStr, str);
}

void CppTest()
{
    TTest *test = new TTest;
    test->Test("A string");
    delete test;
}
