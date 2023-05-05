#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "disccmd.h"

static void Done(TVfsCmd *cmd)
{
    printf("\r\ndone\r\n");
}

static void Msg(TVfsCmd *cmd, const char *msg)
{
    printf(msg);
}

void main()
{
    TVfsDiscCmd *cmd;
    TWait Wait;

    cmd = new TVfsDiscCmd(1, "info");
    cmd->OnDone = ::Done;
    cmd->OnMsg = ::Msg;
    Wait.Add(cmd);

    while (!cmd->IsDone())
        Wait.WaitForever();

    printf("\r\n");

    delete cmd;
}
