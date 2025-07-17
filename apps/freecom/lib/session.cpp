/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# session.cpp
# Session class
#
########################################################################*/

#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <unistd.h>

#include "session.h"
#include "rdos.h"
#include "cmdhelp.h"
#include "pathcmd.h"
#include "set.h"
#include "help.h"
#include "time.h"
#include "date.h"
#include "dhcp.h"
#include "cls.h"
#include "copy.h"
#include "newsess.h"
#include "cmdline.h"
#include "chdir.h"
#include "mkdir.h"
#include "rmdir.h"
#include "dir.h"
#include "type.h"
#include "del.h"
#include "showpart.h"
#include "rmpart.h"
#include "mkpart.h"
#include "syncpart.h"
#include "inithd.h"
#include "initfd.h"
#include "ping.h"
#include "state.h"
#include "part.h"
#include "fatpart.h"
#include "exit.h"
#include "echo.h"
#include "call.h"
#include "pause.h"
#include "wait.h"
#include "prompt.h"
#include "rem.h"
#include "move.h"
#include "synctime.h"
#include "fd2file.h"
#include "reboot.h"
#include "capture.h"
#include "com.h"
#include "can.h"
#include "lon.h"
#include "usb.h"
#include "info.h"
#include "volume.h"
#include "sysinfo.h"
#include "keyb.h"
#include "acpi.h"
#include "hid.h"
#include "dev.h"
#include "pci.h"
#include "debug.h"
#include "audio.h"
#include "remote.h"
#include "unzipc.h"
#include "wipedir.h"
#include "showcrash.h"
#include "switch.h"
#include "temp.h"
#include "net.h"
#include "parttool.h"

#include "file.h"
#include "path.h"
#include "env.h"

#define MAX_X   79
#define MAX_Y   24

#define STACK_SIZE      0x2000

#define FALSE 0
#define TRUE !FALSE

static TIdeFsPartitionFactory *ifat12;
static TIdeFsPartitionFactory *ifat16;
static TIdeFsPartitionFactory *ifat32;

static TCommandFactory *acpi;
static TCommandFactory *audio;
static TCommandFactory *call;
static TCommandFactory *cd;
static TCommandFactory *chdirc;
static TCommandFactory *cls;
static TCommandFactory *crash;
static TCommandFactory *newsess;
static TCommandFactory *can;
static TCommandFactory *capture;
static TCommandFactory *com;
static TCommandFactory *cpy;
static TCommandFactory *date;
static TCommandFactory *debug;
static TCommandFactory *del;
static TCommandFactory *dev;
static TCommandFactory *dhcp;
static TCommandFactory *dir;
static TCommandFactory *echo;
static TCommandFactory *erase;
static TCommandFactory *exitcmd;
static TCommandFactory *fd2file;
static TCommandFactory *help;
static TCommandFactory *hid;
static TCommandFactory *info;
static TCommandFactory *initfd;
static TCommandFactory *inithd;
static TCommandFactory *keyb;
static TCommandFactory *lon;
static TCommandFactory *md;
static TCommandFactory *mkdirf;
static TCommandFactory *mkpart;
static TCommandFactory *move;
static TCommandFactory *net;
static TCommandFactory *pci;
static TCommandFactory *ping;
static TCommandFactory *prompt;
static TCommandFactory *showpart;
static TCommandFactory *parttool;
static TCommandFactory *synctime;
static TCommandFactory *sysinfo;
static TCommandFactory *pause;
static TCommandFactory *path;
static TCommandFactory *rd;
static TCommandFactory *reboot;
static TCommandFactory *rem;
static TCommandFactory *remote;
static TCommandFactory *rmdirc;
static TCommandFactory *rmpart;
static TCommandFactory *set;
static TCommandFactory *state;
static TCommandFactory *switchcmd;
static TCommandFactory *syncpart;
static TCommandFactory *type;
static TCommandFactory *timev;
static TCommandFactory *temp;
static TCommandFactory *unzip;
static TCommandFactory *usb;
static TCommandFactory *volume;
static TCommandFactory *wait;
static TCommandFactory *wipedir;

int TSession::Count = 0;

/*##########################################################################
#
#   Name       : TSession::TSession
#
#   Purpose....: Session constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSession::TSession(TKeyboardDevice *Keyboard)
 : TInteract(Keyboard)
{
    FArgList = 0;

    if (Count == 0)
    {
        ifat12 = new TIdeFat12PartitionFactory;
        ifat16 = new TIdeFat16PartitionFactory;
        ifat32 = new TIdeFat32PartitionFactory;

        wipedir = new TWipeDirFactory;
        wait = new TWaitFactory;
        volume = new TVolumeFactory;
        usb = new TUsbFactory;
        unzip = new TUnzipFactory;
        type = new TTypeFactory;
        timev = new TTimeFactory;
        temp = new TTempFactory;
        switchcmd = new TSwitchFactory;
        sysinfo = new TSysinfoFactory;
        synctime = new TSyncTimeFactory;
        syncpart = new TSyncPartitionFactory;
        state = new TStateFactory;
        set = new TSetFactory;
        rmpart = new TRemovePartitionFactory;
        rmdirc = new TRmdirFactory;
        remote = new TRemoteFactory;
        rem = new TRemFactory;
        reboot = new TRebootFactory;
        rd = new TRdFactory;
        prompt = new TPromptFactory;
        ping = new TPingFactory;
        pci = new TPciFactory;
        pause = new TPauseFactory;
        path = new TPathFactory;
        parttool = new TPartToolFactory;
        showpart = new TShowPartitionFactory;
        net = new TNetFactory;
        move = new TMoveFactory;
        mkpart = new TMakePartitionFactory;
        mkdirf = new TMkdirFactory;
        md = new TMdFactory;
        lon = new TLonFactory;
        keyb = new TKeybFactory;
        inithd = new TInitHdFactory;
        initfd = new TInitFdFactory;
        info = new TInfoFactory;
        hid = new THidFactory;
        exitcmd = new TExitFactory;
        fd2file = new TFloppyToFileFactory;
        erase = new TEraseFactory;
        echo = new TEchoFactory;
        dhcp = new TDhcpFactory;
        dir = new TDirFactory;
        dev = new TDeviceFactory;
        del = new TDelFactory;
        debug = new TDebugFactory;
        date = new TDateFactory;

        if (RdosHasCrashInfo())
            crash = new TShowCrashFactory;
        else
            crash = 0;

        cpy = new TCopyFactory;
        com = new TComFactory;
        newsess = new TNewSessionFactory;
        cls = new TClsFactory;
        chdirc = new TChdirFactory;
        cd = new TCdFactory;
        capture = new TCaptureFactory;
        can = new TCanFactory;
        call = new TCallFactory;
        audio = new TAudioFactory;
        acpi = new TAcpiFactory;
        help = new THelpFactory;
    }

    Count++;

    WriteWelcome();
}

/*##########################################################################
#
#   Name       : TSession::TSession
#
#   Purpose....: Copy constructor for session
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSession::TSession(const TSession &src)
 : TInteract(src)
{
    FArgList = 0;
    Count++;
}

/*##########################################################################
#
#   Name       : TSession::~TSession
#
#   Purpose....: Session destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSession::~TSession()
{
    Count--;

    if (Count == 0)
    {

        delete ifat12;
        delete ifat16;
        delete ifat32;

        delete wipedir;
        delete wait;
        delete volume;
        delete usb;
        delete unzip;
        delete timev;
        delete type;
        delete temp;
        delete switchcmd;
        delete synctime;
        delete syncpart;
        delete state;
        delete set;
        delete rmpart;
        delete rmdirc;
        delete remote;
        delete rem;
        delete reboot;
        delete rd;
        delete prompt;
        delete ping;
        delete path;
        delete pause;
        delete parttool;
        delete showpart;
        delete net;
        delete move;
        delete mkpart;
        delete mkdirf;
        delete md;
        delete lon;
        delete inithd;
        delete initfd;
        delete info;
        delete fd2file;
        delete exitcmd;
        delete erase;
        delete echo;
        delete dhcp;
        delete dir;
        delete del;
        delete date;
        delete cpy;
        delete com;
        delete newsess;
        delete cls;
        delete chdirc;
        delete cd;
        delete capture;
        delete can;
        delete call;
        delete help;

        if (crash)
            delete crash;
    }
}

/*##########################################################################
#
#   Name       : TSession::WriteWelcome
#
#   Purpose....: Write welcome message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::WriteWelcome()
{
    char VersionStr[16];
    int Major;
    int Minor;
    int Release;
    TCommand *cmd;

    RdosGetVersion(&Major, &Minor, &Release);
    sprintf(VersionStr, "%d.%d.%d", Major, Minor, Release);

    Write("FreeCom for RDOS ");
    Write(VersionStr);
    Write("\r\n");
    Write("Use @ before external command to detach\r\n\r\n");

    cmd = help->Create(this, "");
    if (cmd)
        cmd->Run();

    Write("\r\n");
}

/*################## TSession::DisplayPrompt ##########################
 *   Purpose....: Display prompt for user                                                                #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *##########################################################################*/
void TSession::DisplayPrompt()
{
    char promptstr[128];
    char *pr;
    TString str;
    TPathName path("");
    TDateTime currtime;

    TEnv *env = TEnv::OpenSysEnv();
    if (!env->Find("PROMPT", promptstr))
        strcpy(promptstr, "$p$g");

    pr = promptstr;

    while (*pr)
    {
        if (*pr != '$')
            Write(*pr);
        else
        {
            switch (toupper(*++pr))
            {
                case 'Q':
                    Write('=');
                    break;

                case '$':
                    Write('$');
                    break;

                case 'T':
                    str = FormatTime(currtime);
                    Write(str.GetData());
                    break;

                case 'D':
                    str = FormatLongDate(currtime);
                    Write(str.GetData());
                    break;

                case 'P':
                    str = path.GetFullPathName();
                    str.Lower();
                    Write(str.GetData());
                    break;

                case 'V':
                    Write("command");
                    break;

                case 'N':
                    Write(RdosGetCurDrive() + 'A');
                    break;

                case 'G':
                    Write('>');
                    break;

                case 'L':
                    Write('<');
                    break;

                case 'B':
                    Write('|');
                    break;

                case '_':
                    Write('\n');
                    break;

                case 'E':
                    Write(27);
                    break;

                case 'H':
                    Write(8);
                    break;

            }
        }
        pr++;
    }
    delete env;
}

/*##########################################################################
#
#   Name       : TSession::Run
#
#   Purpose....: Run session
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::Run()
{
    char param[256];
    int ok;
    TCommandLine *cmd;
    TEnv *env = TEnv::OpenSysEnv();

    if (!env->Find("COMSPEC", param))
    {
        TPathName CurrDir;
        CurrDir += "command.exe";
        env->Add("COMSPEC", CurrDir.Get().GetData());

        TSession *session = new TSession(*this);
        if (session->Run("autoexec.bat", 0) != 0)
            session->Run("autoexec.cmd", 0);
        delete session;
    }
    delete env;

    for (;;)
    {
        if (FEcho)
            DisplayPrompt();

        ok = ReadCmd(param, 256);
        if (ok)
        {
            cmd = new TCommandLine(this, param);
            if (cmd->IsExit())
            {
                delete cmd;
                break;
            }
            else
            {
                cmd->Run();
                delete cmd;
            }
        }
    }

    RdosWaitMilli(50);
}

/*##########################################################################
#
#   Name       : TSession::Run
#
#   Purpose....: Run session
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::Run(const char *param)
{
    TCommandLine *cmd;

    cmd = new TCommandLine(this, param);
    if (cmd->IsExit())
        delete cmd;
    else
    {
        cmd->Run();
        delete cmd;
    }
}

/*##########################################################################
#
#   Name       : TSession::Run
#
#   Purpose....: Run batch session
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSession::Run(const char *name, TArg *ArgList)
{
    char param[256];
    int ok;
    TCommandLine *cmd;
    TString CmdStr;
    const char *ptr;

    FArgList = ArgList;
    FName = name;

    FBatHandle = open(name, O_RDONLY);

    if (FBatHandle >= 0)
    {
        while (!eof(FBatHandle))
        {
            if (FEcho)
                DisplayPrompt();

            ok = ReadCmd(param, 256);
            if (ok)
            {
                CmdStr = ExpandParam(param);
                ptr = CmdStr.GetData();

                if (FEcho)
                {
                    Write(ptr);
                    Write('\n');
                }

                cmd = new TCommandLine(this, ptr);
                if (cmd->IsExit())
                {
                    delete cmd;
                    break;
                }
                else
                {
                    cmd->Run();
                    delete cmd;
                }
            }
            else
            {
                close(FBatHandle);
                FBatHandle = 0;
                return 1;
            }
        }
        close(FBatHandle);
        FBatHandle = 0;
        return 0;
    }
    else
    {
        FBatHandle = 0;
        return 1;
    }
}

/*##########################################################################
#
#   Name       : TSession::GetArg
#
#   Purpose....: Get an argument # (1-based)
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TSession::GetArg(int ArgNr)
{
    int i;
    TArg *arg;

    i = 1;
    arg = FArgList;

    while(i != ArgNr && arg)
        arg = arg->FList;

    if (arg)
        return arg->FName.GetData();
    else
        return "";
}

/*##########################################################################
#
#   Name       : TSession::ExpandParam
#
#   Purpose....: Expand parameters
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TString TSession::ExpandParam(const char *param)
{
    TString str;

    while (*param)
    {
        if (*param == '%')
        {
            param++;
            switch (*param)
            {
                case '0':
                    str += FName;
                    break;

                case '1':
                case '2':
                case '3':
                case '4':
                case '5':
                case '6':
                case '7':
                case '8':
                case '9':
                    str += GetArg(*param - '0');
                    break;

                default:
                    str += '%';
                    str += *param;
            }
            param++;

        }
        else
        {
            str += *param;
            param++;
        }
    }
    return str;
}
