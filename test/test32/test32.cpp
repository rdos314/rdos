#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <math.h>

#include "rdos.h"
#include "mp3.h"

TMp3Player *player = 0;

void Play(const char *filename)
{
    if (player->IsRunning())
        player->Stop();

    player->Load(filename);
    player->SetPosition(0);
    player->Start();
}


void main()
{
    char FileName[80];
    int ms;
    int id;

    player = new TMp3Player;

    for (;;)
    {
        ms = RdosGetRandom(5000);
        RdosWaitMilli(ms);

        id = RdosGetRandom(25);
        sprintf(FileName, "%d.mp3", id);
        Play(FileName);
    }

    RdosTestGate("");
}



