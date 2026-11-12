#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <math.h>
#include "json.h"

#include "rdos.h"
#include "datetime.h"

void main()
{
    TFile file("rem.txt");
    char ch;
    char temp_str[256];
    int i;
    char *dst;
    TJsonDocument *doc;
    bool ok;
    int len = file.GetSize();

    dst = temp_str;

    for (i = 0; i < len; i++)
    {
        file.Read(&ch, 1);

        if (ch == '}')
        {
            *dst = ch;
            dst++;
            *dst = 0;

            doc = new TJsonDocument;
            ok = doc->Parse(temp_str);
            if (ok)
                dst = temp_str;
        }
        else
        {
            *dst = ch;
            dst++;
        }
    }



    RdosTestGate("");
}



