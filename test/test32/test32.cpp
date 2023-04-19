#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include "waitdev.h"

class TVfsCmd : public TWaitDevice
{
public:
    TVfsCmd();
    virtual ~TVfsCmd();

    bool IsDone();

    void (*OnDone)(TVfsCmd *VfsCmd);
    void (*OnMsg)(TVfsCmd *VfsCmd, const char *msg);

protected:
    virtual void SignalNewData();
    virtual void Add(TWait *Wait);

    int FHandle;
};

class TVfsDiscCmd : public TVfsCmd
{
public:
    TVfsDiscCmd(int disc, const char *cmd);
    virtual ~TVfsDiscCmd();
};

TVfsCmd::TVfsCmd()
{
    FHandle = 0;
    OnDone = 0;
    OnMsg = 0;
}

TVfsCmd::~TVfsCmd()
{
    if (FHandle)
        RdosCloseVfsCmd(FHandle);
}

bool TVfsCmd::IsDone()
{
    return RdosIsVfsCmdDone(FHandle);
}

void TVfsCmd::SignalNewData()
{
    int size;
    char *msg;

    if (IsDone())
    {
        if (OnDone)
            (*OnDone)(this);
    }
    else
    {
        size = RdosGetVfsResponseSize(FHandle);
        if (size)
        {
            msg = new char[size + 1];
            RdosGetVfsResponseData(FHandle, msg, size);
            msg[size] = 0;
            if (OnMsg)
                (*OnMsg)(this, msg);

            delete msg;
        }
    }
}

void TVfsCmd::Add(TWait *Wait)
{
    RdosAddWaitForVfsCmd(Wait->GetHandle(), FHandle, (int)this);
}

TVfsDiscCmd::TVfsDiscCmd(int DiscNr, const char *Msg)
{
    FHandle = RdosCreateVfsDiscCmd(DiscNr, Msg);
}

TVfsDiscCmd::~TVfsDiscCmd()
{
}

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

    cmd = new TVfsDiscCmd(2, "?");
    cmd->OnDone = ::Done;
    cmd->OnMsg = ::Msg;
    Wait.Add(cmd);

    while (!cmd->IsDone())
        Wait.WaitForever();

    printf("\r\n");

    delete cmd;
}
