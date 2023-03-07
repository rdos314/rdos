#include <string.h>
#include <ctype.h>
#include <stdarg.h>
#include <stdio.h>

class TMyClass
{
public:
    TMyClass();
    ~TMyClass();
    void printf(const char *frm, va_list args);
};

TMyClass::TMyClass()
{
}

TMyClass::~TMyClass()
{
}

void TMyClass::printf(const char *frm, va_list args)
{
    printf(frm, args);
}

void main()
{
    int probe = 3;
    char temp[20];
    TMyClass my;

    sprintf(temp, "$B%02d", probe);
    my.printf("%s", temp);
}
