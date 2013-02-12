#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rdos.h"
#include "mp3.h"

#include "fm.h"

#define FALSE   0
#define TRUE    !FALSE

int main(int argc, char **argv)
{
        int L, R;
        TMp3Player mp3;
        char FileName[256];

        if (argc == 1)
        {
                printf("usage: playmp3 filename\r\n");
                return 1;
        }

        RdosWaitMilli(250);

        strcpy(FileName, argv[1]);
        strlwr(FileName);

        RdosGetOutputVolume(&L, &R);
        if (L < 0 && R < 0)
                RdosSetOutputVolume(100, 100);

        mp3.Load(FileName);
        mp3.Play();

        return 0;
}
