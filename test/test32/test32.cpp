#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "keyboard.h"
#include "unzip.h"


void main()
{
    TUnzip unzip;
    int i;
    bool ok;
    TUnzipFile *file;
    const char *filename;

    ok = GzipToZip("udp.zip", "my.zip", "udp.txt");

    unzip.OpenNoHeader("my.zip");

    for (i = 0; i < unzip.GetFileCount(); i++)
    {
        file = unzip.GetFile(i);
        filename = file->GetFileName();

        ok = file->IsOk();

        if (ok)
             ok = file->Extract(filename);
    }

    RdosTestGate("");
}



