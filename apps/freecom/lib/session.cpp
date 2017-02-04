/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2003, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
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
#include "mount.h"
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
#include "temp.h"

#include "file.h"
#include "path.h"
#include "env.h"

#define MAX_X   79
#define MAX_Y   24
#define MAX_HISTORY 100

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
static TCommandFactory *mkdir;
static TCommandFactory *mkpart;
static TCommandFactory *mount;
static TCommandFactory *move;
static TCommandFactory *pci;
static TCommandFactory *ping;
static TCommandFactory *prompt;
static TCommandFactory *showpart;
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
static TCommandFactory *type;
static TCommandFactory *timev;
static TCommandFactory *temp;
static TCommandFactory *unzip;
static TCommandFactory *usb;
static TCommandFactory *volume;
static TCommandFactory *wait;
static TCommandFactory *wipedir;

static TStringList *History;
static TKeyboardDevice *Keyboard;

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
TSession::TSession()
{
    FArgList = 0;
    FEcho = TRUE;

    FCmdFile = 0;

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
        sysinfo = new TSysinfoFactory;
        synctime = new TSyncTimeFactory;
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
        showpart = new TShowPartitionFactory;
        move = new TMoveFactory;
        mount = new TMountFactory;
        mkpart = new TMakePartitionFactory;
        mkdir = new TMkdirFactory;
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

        History = new TStringList;
        Keyboard = new TKeyboardDevice;

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
{
    Count++;

    FArgList = 0;
    FEcho = TRUE;

    if (src.FCmdFile)
        FCmdFile = new TFile(*src.FCmdFile);
    else
        FCmdFile = 0;
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
    if (FCmdFile)
        delete FCmdFile;

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
        delete synctime;
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
        delete showpart;
        delete move;
        delete mount;
        delete mkpart;
        delete mkdir;
        delete md;
        delete lon;
        delete inithd;
        delete initfd;
        delete info;
        delete fd2file;
        delete exitcmd;
        delete erase;
        delete echo;
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

        delete History;
        delete Keyboard;
    }
}

/*##########################################################################
#
#   Name       : TSession::SetEchoOn
#
#   Purpose....: Set Echo state to on
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::SetEchoOn()
{
    FEcho = TRUE;
}

/*##########################################################################
#
#   Name       : TSession::SetEchoOff
#
#   Purpose....: Set Echo state to off
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::SetEchoOff()
{
    FEcho = FALSE;
}

/*##########################################################################
#
#   Name       : TSession::IsEchoOn
#
#   Purpose....: Check if echo is on
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSession::IsEchoOn()
{
    return FEcho;
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

/*################## TSession::FormatTime ##########################
 *   Purpose....: Format time                                                                            #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *##########################################################################*/
TString TSession::FormatTime(TDateTime &time)
{
    char str[40];
    sprintf(str, "%02d.%02d.%02d,%03d", time.GetHour(), time.GetMin(), time.GetSec(), time.GetMilliSec());
    return TString(str);
}

/*################## TSession::FormatLongDate ##########################
 *   Purpose....: Format long date                                                                       #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *##########################################################################*/
TString TSession::FormatLongDate(TDateTime &date)
{
    char str[40];
    sprintf(str, "%04d-%02d-%02d", date.GetYear(), date.GetMonth(), date.GetDay());
    return TString(str);
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
#   Name       : TSession::ReadCon
#
#   Purpose....: Read a string from console
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSession::ReadCon(char *str, int maxsize)
{
    int OrgX;
    int OrgY;
    int CurrX;
    int CurrY;
    int ExtKey;
    int State;
    int VirtKey;
    int ScanCode;
    int Count = 0;
    int CurrPos = 0;
    int i;
    int Insert = TRUE;
    TString prev;
    const char *prevstr;
    int ok;
    int GetNext = FALSE;

    if (History->GotoFirst())
        prev = History->Get();

    prevstr = prev.GetData();

    RdosGetConsoleCursorPosition(&OrgY, &OrgX);
    CurrX = OrgX;
    CurrY = OrgY;

    memset(str, 0, maxsize);

    for (;;)
    {
        Keyboard->WaitForever();

        ok = Keyboard->ReadEvent(&ExtKey, &State, &VirtKey, &ScanCode);
        if (ok)
            ok = Keyboard->IsStdKey(ExtKey, VirtKey);

        if (ok)
        {
            switch (VirtKey)
            {
                case VK_BACK:
                    if (Count && CurrPos)
                    {
                        if (Count == CurrPos)
                        {
                            str[CurrPos - 1] = 0;

                            if (CurrX)
                                CurrX--;
                            else
                            {
                                CurrX = MAX_X;
                                CurrY--;
                            }                                
                            RdosSetConsoleCursorPosition(CurrY, CurrX);
                            Write(' ');
                            RdosSetConsoleCursorPosition(CurrY, CurrX);
                        }
                        else
                        {
                            for (i = CurrPos - 1; i < Count; i++)
                                str[i] = str[i + 1];

                            if (CurrX)
                                CurrX--;
                            else
                            {
                                CurrX = MAX_X;
                                CurrY--;
                            }
                            RdosSetConsoleCursorPosition(CurrY, CurrX);
                            Write(&str[CurrPos - 1]);
                            Write(' ');
                            RdosSetConsoleCursorPosition(CurrY, CurrX);
                        }
                        CurrPos--;
                        Count--;
                        str[Count] = 0;
                    }
                    break;


                case VK_INSERT:
                    Insert = !Insert;
                    break;

                case VK_DELETE:
                    if (Count && CurrPos != Count)
                    {
                        for (i = CurrPos; i < Count; i++)
                            str[i] = str[i + 1];
                        Count--;
                        str[Count] = 0;
                        Write(&str[CurrPos]);
                        Write(' ');
                        RdosSetConsoleCursorPosition(CurrY, CurrX);
                    }
                    break;

                case VK_HOME:
                    if (CurrPos)
                    {
                        CurrX = OrgX;
                        CurrY = OrgY;
                        RdosSetConsoleCursorPosition(CurrY, CurrX);
                        CurrPos = 0;
                    }
                    break;

                case VK_END:
                    if (CurrPos != Count)
                    {
                        RdosSetConsoleCursorPosition(OrgY, OrgX);
                        Write(str);
                        RdosGetConsoleCursorPosition(&CurrY, &CurrX);
                    }
                    break;

                case VK_RETURN:
                    if (Count)
                    {
                        TString s(str);

                        if (History->Find(s))
                            History->RemoveCurrent();

                        History->AddFirst(s);
                        if (History->GetSize() >= MAX_HISTORY)
                            History->RemoveLast();
                    }
                    Write("\r\n");
                    return TRUE;

                case VK_ESCAPE:
                    return FALSE;


                case VK_RIGHT:
                    if (CurrPos != Count)
                    {
                        CurrPos++;
                        if (CurrX == MAX_X)
                        {
                            CurrX = 1;
                            CurrY++;
                        }
                        else
                            CurrX++;
                        RdosSetConsoleCursorPosition(CurrY, CurrX);
                        break;
                    }

                case VK_F1:
                    if (CurrPos < strlen(prevstr))
                    {
                        str[CurrPos] = prevstr[CurrPos];
                        Write(str[CurrPos]);
                        RdosGetConsoleCursorPosition(&CurrY, &CurrX);
                        CurrPos++;
                        Count = CurrPos;
                        str[Count] = 0;
                    }
                    break;

                case VK_F3:
                    memset(str, ' ', Count);
                    RdosSetConsoleCursorPosition(OrgY, OrgX);
                    Write(str);

                    strcpy(str, prevstr);
                    RdosSetConsoleCursorPosition(OrgY, OrgX);
                    Write(str);
                    RdosGetConsoleCursorPosition(&CurrY, &CurrX);
                    Count = strlen(str);
                    CurrPos = Count;
                    break;

                case VK_UP:
                    if (GetNext)
                        ok = History->GotoNext();
                    else
                    {
                        ok = History->GotoFirst();
                        GetNext = TRUE;
                    }

                    if (ok)
                    {
                        memset(str, ' ', Count);
                        RdosSetConsoleCursorPosition(OrgY, OrgX);
                        Write(str);

                        prev = History->Get();
                        prevstr = prev.GetData();
                        strcpy(str, prevstr);
                        RdosSetConsoleCursorPosition(OrgY, OrgX);
                        Write(str);
                        RdosGetConsoleCursorPosition(&CurrY, &CurrX);
                        Count = strlen(str);
                        CurrPos = Count;
                    }
                    break;

                case VK_DOWN:
                    if (History->GotoPrev())
                    {
                        memset(str, ' ', Count);
                        RdosSetConsoleCursorPosition(OrgY, OrgX);
                        Write(str);

                        prev = History->Get();
                        prevstr = prev.GetData();
                        strcpy(str, prevstr);
                        RdosSetConsoleCursorPosition(OrgY, OrgX);
                        Write(str);
                        RdosGetConsoleCursorPosition(&CurrY, &CurrX);
                        Count = strlen(str);
                        CurrPos = Count;
                    }
                    break;

                case VK_LEFT:
                    if (CurrPos)
                    {
                        CurrPos--;
                        if (CurrX)
                            CurrX--;
                        else
                        {
                            CurrX = MAX_X;
                            CurrY--;
                        }
                        RdosSetConsoleCursorPosition(CurrY, CurrX);
                    }
                    break;

                default:
                    ExtKey = ExtKey & 0xFF;
                    if (ExtKey >= ' ' && Count < maxsize - 1)
                    {
                        if (Insert && CurrPos != Count)
                        {
                            for (i = Count; i > CurrPos; i--)
                                str[i] = str[i - 1];
                            Count++;
                            str[CurrPos] = (char)ExtKey;
                            Write(str[CurrPos]);
                            RdosGetConsoleCursorPosition(&CurrY, &CurrX);
                            str[Count] = 0;
                            Write(&str[CurrPos + 1]);
                            RdosSetConsoleCursorPosition(CurrY, CurrX);
                        }
                        else
                        {
                            if (CurrPos == Count)
                                Count++;
                            str[CurrPos] = (char)ExtKey;
                            Write(str[CurrPos]);
                            RdosGetConsoleCursorPosition(&CurrY, &CurrX);
                            str[Count] = 0;
                        }
                        if (CurrX == 0)
                            OrgY--;
                        CurrPos++;
                    }
                    break;
            }
        }
    }
}

/*##########################################################################
#
#   Name       : TSession::SetCmdFile
#
#   Purpose....: Set cmd file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::SetCmdFile(TFile *File)
{
    FCmdFile = File;
}

/*##########################################################################
#
#   Name       : GetCmdFile
#
#   Purpose....: Get cmd file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TSession::GetCmdFile()
{
    return FCmdFile;
}

/*##########################################################################
#
#   Name       : TSession::Write
#
#   Purpose....: Write character to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::Write(char ch)
{
    write(1, &ch, 1);
}

/*##########################################################################
#
#   Name       : TSession::Write
#
#   Purpose....: Write string to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::Write(const char *str)
{
    write(1, str, strlen(str));
}

/*##########################################################################
#
#   Name       : TSession::WriteError
#
#   Purpose....: Write character to standard error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::WriteError(char ch)
{
    write(2, &ch, 1);
}

/*##########################################################################
#
#   Name       : TSession::WriteError
#
#   Purpose....: Write string to standard error
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::WriteError(const char *str)
{
    write(2, str, strlen(str));
}

/*##########################################################################
#
#   Name       : TSession::ReadCmd
#
#   Purpose....: Read a string from cmd input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSession::ReadCmd(char *str, int maxsize)
{
    char ch;
    int i;

    if (FCmdFile)
    {
        for (i = 0; i < maxsize; i++)
        {
            ch = 0;
            FCmdFile->Read(&ch, 1);
    
            if (ch == 0 || ch == 0xa)
            {
                *str = 0;
                break;
            }
            else
            {
                *str = ch;
                str++;
            }
        }
        *str = 0;
        return TRUE;
    }
    else
        return ReadCon(str, maxsize);

    return FALSE;
}

/*##########################################################################
#
#   Name       : TSession::Read
#
#   Purpose....: Read a string from standard input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TSession::Read(char *str, int maxsize)
{
    return read(0, str, maxsize);
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
                if (FThreadExit)
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

    if (FCmdFile)
        delete FCmdFile;

    FCmdFile = new TFile(name);
    if (FCmdFile->IsOpen())
    {
        while (FCmdFile->GetPos() != FCmdFile->GetSize())
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
                delete FCmdFile;
                FCmdFile = 0;
                return 1;
            }
        }
        delete FCmdFile;
        FCmdFile = 0;
        return 0;
    }
    else
    {
        delete FCmdFile;
        FCmdFile = 0;
        return 1;
    }
}
