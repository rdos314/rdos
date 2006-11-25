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
#include "rdfspart.h"
#include "fatpart.h"
#include "ffspart.h"
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
#include "usb.h"

#include "file.h"
#include "path.h"
#include "env.h"

#define MAX_X   79
#define MAX_Y   24
#define MAX_HISTORY 100

#define FALSE 0
#define TRUE !FALSE

static TFsPartitionFactory *rdfs;
static TFsPartitionFactory *fat12;
static TFsPartitionFactory *fat16;
static TFsPartitionFactory *fat32;
static TFsPartitionFactory *flashfs;

static TCommandFactory *call;
static TCommandFactory *cd;
static TCommandFactory *chdir;
static TCommandFactory *cls;
static TCommandFactory *newsess;
static TCommandFactory *capture;
static TCommandFactory *cpy;
static TCommandFactory *date;
static TCommandFactory *del;
static TCommandFactory *dir;
static TCommandFactory *echo;
static TCommandFactory *erase;
static TCommandFactory *exitcmd;
static TCommandFactory *fd2file;
static TCommandFactory *help;
static TCommandFactory *initfd;
static TCommandFactory *inithd;
static TCommandFactory *md;
static TCommandFactory *mkdir;
static TCommandFactory *mkpart;
static TCommandFactory *mount;
static TCommandFactory *move;
static TCommandFactory *ping;
static TCommandFactory *prompt;
static TCommandFactory *showpart;
static TCommandFactory *synctime;
static TCommandFactory *pause;
static TCommandFactory *path;
static TCommandFactory *rd;
static TCommandFactory *reboot;
static TCommandFactory *rem;
static TCommandFactory *rmdir;
static TCommandFactory *rmpart;
static TCommandFactory *set;
static TCommandFactory *state;
static TCommandFactory *type;
static TCommandFactory *timev;
static TCommandFactory *usb;
static TCommandFactory *wait;

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
    FCmdFile = new TFile("CON");
    FInputFile = new TFile("CON");
    FOutputFile = new TFile("CON");
    FErrorFile = new TFile("CON");

    if (Count == 0)
    {
    	rdfs = new TRdfsPartitionFactory;
    	fat12 = new TFat12PartitionFactory;
    	fat16 = new TFat16PartitionFactory;
    	fat32 = new TFat32PartitionFactory;
    	flashfs = new TFlashFsPartitionFactory;

    	wait = new TWaitFactory;
    	usb = new TUsbFactory;
    	timev = new TTimeFactory;
    	type = new TTypeFactory;
    	synctime = new TSyncTimeFactory;
    	state = new TStateFactory;
    	set = new TSetFactory;
    	rmpart = new TRemovePartitionFactory;
    	rmdir = new TRmdirFactory;
    	rem = new TRemFactory;
    	reboot = new TRebootFactory;
    	rd = new TRdFactory;
    	prompt = new TPromptFactory;
    	ping = new TPingFactory;
    	pause = new TPauseFactory;
    	path = new TPathFactory;
    	showpart = new TShowPartitionFactory;
    	move = new TMoveFactory;
    	mount = new TMountFactory;
    	mkpart = new TMakePartitionFactory;
    	mkdir = new TMkdirFactory;
    	md = new TMdFactory;
    	inithd = new TInitHdFactory;
    	initfd = new TInitFdFactory;
    	exitcmd = new TExitFactory;
    	fd2file = new TFloppyToFileFactory;
    	erase = new TEraseFactory;
    	echo = new TEchoFactory;
    	dir = new TDirFactory;
    	del = new TDelFactory;
    	date = new TDateFactory;
    	cpy = new TCopyFactory;
    	newsess = new TNewSessionFactory;
    	cls = new TClsFactory;
    	chdir = new TChdirFactory;
    	cd = new TCdFactory;
    	capture = new TCaptureFactory;
    	call = new TCallFactory;
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
    
	if (src.FCmdFile->IsDevice())
        FCmdFile = new TFile("CON");
    else
        FCmdFile = new TFile(*src.FCmdFile);

	if (src.FInputFile->IsDevice())
        FInputFile = new TFile("CON");
    else
        FInputFile = new TFile(*src.FInputFile);
        
	if (src.FOutputFile->IsDevice())
        FOutputFile = new TFile("CON");
    else
        FOutputFile = new TFile(*src.FOutputFile);

	if (src.FErrorFile->IsDevice())
        FErrorFile = new TFile("CON");
    else
        FErrorFile = new TFile(*src.FErrorFile);
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
	delete FCmdFile;
	delete FInputFile;
	delete FOutputFile;
	delete FErrorFile;

    Count--;

    if (Count == 0)
    {

    	delete rdfs;
    	delete fat12;
    	delete fat16;
    	delete fat32;
    	delete flashfs;

        delete wait;
        delete usb;
    	delete timev;
	    delete type;
	    delete synctime;
    	delete state;
    	delete set;
    	delete rmpart;
    	delete rmdir;
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
    	delete inithd;
    	delete initfd;
    	delete fd2file;
    	delete exitcmd;
    	delete erase;
    	delete echo;
    	delete dir;
    	delete del;
    	delete date;
    	delete cpy;
    	delete newsess;
    	delete cls;
	    delete chdir;
    	delete cd;
    	delete capture;
    	delete call;
    	delete help;

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
*   Purpose....: Format time			   					      	        #
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
*   Purpose....: Format long date		   					      	        #
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
*   Purpose....: Display prompt for user	   					      	        #
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

	TEnv *env = TEnv::OpenSysEnv();
	if (!env->Find("PROMPT", promptstr))
		strcpy(promptstr, "$p$g");

	pr = promptstr;

	while (*pr)
	{
		if (*pr != '$')
			RdosWriteChar(*pr);
		else
		{
			switch (toupper(*++pr))
				{
                case 'Q':
                    RdosWriteChar('=');
                    break;
            
				case '$':
						  RdosWriteChar('$');
						  break;

					 case 'T':
						  str = FormatTime(TDateTime());
						  RdosWriteString(str.GetData());
                    break;

				case 'D':
					str = FormatLongDate(TDateTime());
					RdosWriteString(str.GetData());
					break;

				case 'P':
					str = path.GetFullPathName();
						  str.Lower();
					RdosWriteString(str.GetData());
					break;

					 case 'V':
						  RdosWriteString("command");
						  break;

					 case 'N':
						  RdosWriteChar(RdosGetCurDrive() + 'A');
						  break;

					 case 'G':
						  RdosWriteChar('>');
					break;

					 case 'L':
						  RdosWriteChar('<');
						  break;

					 case 'B':
						  RdosWriteChar('|');
						  break;

					 case '_':
						  RdosWriteChar('\n');
					break;

					 case 'E':
						  RdosWriteChar(27);
						  break;

					 case 'H':
						  RdosWriteChar(8);
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

	RdosGetCursorPosition(&OrgY, &OrgX);
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
                            RdosSetCursorPosition(CurrY, CurrX);
                            RdosWriteChar(' ');
                            RdosSetCursorPosition(CurrY, CurrX);
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
                            RdosSetCursorPosition(CurrY, CurrX);
                            RdosWriteString(&str[CurrPos - 1]);
                            RdosWriteChar(' ');
                            RdosSetCursorPosition(CurrY, CurrX);
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
                        RdosWriteString(&str[CurrPos]);
                        RdosWriteChar(' ');
                        RdosSetCursorPosition(CurrY, CurrX);
                    }
                    break;

                case VK_HOME:
                    if (CurrPos)
                    {
                        CurrX = OrgX;
                        CurrY = OrgY;
                        RdosSetCursorPosition(CurrY, CurrX);
                        CurrPos = 0;
                    }
                    break;

                case VK_END:
                    if (CurrPos != Count)
                    {
                        RdosSetCursorPosition(OrgY, OrgX);
                        RdosWriteString(str);
                    	RdosGetCursorPosition(&CurrY, &CurrX);
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
                    RdosWriteString("\r\n");
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
                        RdosSetCursorPosition(CurrY, CurrX);
                        break;
                    }

                case VK_F1:
                    if (CurrPos < strlen(prevstr))
                    {
                        str[CurrPos] = prevstr[CurrPos];
                        RdosWriteChar(str[CurrPos]);
                    	RdosGetCursorPosition(&CurrY, &CurrX);
                        CurrPos++;
                        Count = CurrPos;
                        str[Count] = 0;
                    }
                    break;

                case VK_F3:
                	memset(str, ' ', Count);
                    RdosSetCursorPosition(OrgY, OrgX);
                    RdosWriteString(str);
                	
                    strcpy(str, prevstr);
                    RdosSetCursorPosition(OrgY, OrgX);
                    RdosWriteString(str);
                    RdosGetCursorPosition(&CurrY, &CurrX);
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
                        RdosSetCursorPosition(OrgY, OrgX);
                        RdosWriteString(str);
                	
								prev = History->Get();
								prevstr = prev.GetData();
								strcpy(str, prevstr);
								RdosSetCursorPosition(OrgY, OrgX);
								RdosWriteString(str);
								RdosGetCursorPosition(&CurrY, &CurrX);
								Count = strlen(str);
								CurrPos = Count;
						  }
						  break;

					 case VK_DOWN:
                    if (History->GotoPrev())
                    {
                    	memset(str, ' ', Count);
                        RdosSetCursorPosition(OrgY, OrgX);
                        RdosWriteString(str);
                	
                        prev = History->Get();
                        prevstr = prev.GetData();
                        strcpy(str, prevstr);
                        RdosSetCursorPosition(OrgY, OrgX);
                        RdosWriteString(str);
                        RdosGetCursorPosition(&CurrY, &CurrX);
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
                        RdosSetCursorPosition(CurrY, CurrX);
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
    	                    RdosWriteChar(str[CurrPos]);
    	                    RdosGetCursorPosition(&CurrY, &CurrX);
	                        str[Count] = 0;
	                        RdosWriteString(&str[CurrPos + 1]);
    	                    RdosSetCursorPosition(CurrY, CurrX);
                        }
                        else
                        {
                            if (CurrPos == Count)
                                Count++;
	                        str[CurrPos] = (char)ExtKey;
    	                    RdosWriteChar(str[CurrPos]);
	                        RdosGetCursorPosition(&CurrY, &CurrX);
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
#   Name       : TSession::SetInputFile
#
#   Purpose....: Set input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::SetInputFile(TFile *File)
{
	FInputFile = File;
}

/*##########################################################################
#
#   Name       : TSession::SetOutputFile
#
#   Purpose....: Set output file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::SetOutputFile(TFile *File)
{
	FOutputFile = File;
}

/*##########################################################################
#
#   Name       : TSession::SetErrorFile
#
#   Purpose....: Set error file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::SetErrorFile(TFile *File)
{
	FErrorFile = File;
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
#   Name       : TSession::GetInputFile
#
#   Purpose....: Get input file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TSession::GetInputFile()
{
	return FInputFile;
}

/*##########################################################################
#
#   Name       : TSession::GetOutputFile
#
#   Purpose....: Get output file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TSession::GetOutputFile()
{
	return FOutputFile;
}

/*##########################################################################
#
#   Name       : TSession::GetErrorFile
#
#   Purpose....: Get error file
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFile *TSession::GetErrorFile()
{
	return FErrorFile;
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
	char str[2];

	str[0] = ch;
	str[1] = 0;

	if (FOutputFile)
		FOutputFile->Write(str, 1);
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
	int size = strlen(str);

	if (FOutputFile)
		FOutputFile->Write(str, size);
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
	char str[2];

	str[0] = ch;
	str[1] = 0;

	if (FOutputFile)
		FOutputFile->Write(str, 1);
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
	int size = strlen(str);

	if (FOutputFile)
		FOutputFile->Write(str, size);
}

/*##########################################################################
#
#   Name       : TSession::WriteNumber
#
#   Purpose....: Write number to standard output
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TSession::WriteLong(long value)
{
	char str[4];
	int tmp;
	int use = FALSE;

	tmp = value / 1000000000;
	if (tmp)
	{
		use = TRUE;
		sprintf(str, "%2d", tmp);
	}
	else
		strcpy(str, "  ");
	Write(str);
	Write(" ");
	value = value % 1000000000;

	tmp = value / 1000000;
	if (use)
		sprintf(str, "%03d", tmp);
	else
	{
		if (tmp)
		{
			use = TRUE;
			sprintf(str, "%3d", tmp);
		}
		else
			strcpy(str, "   ");
	}
	Write(str);
	Write(" ");
	value = value % 1000000;

	tmp = value / 1000;
	if (use)
		sprintf(str, "%03d", tmp);
	else
	{
		if (tmp)
		{
			use = TRUE;
			sprintf(str, "%3d", tmp);
		}
		else
			strcpy(str, "   ");
	}
	Write(str);
	Write(" ");
	value = value % 1000;

	tmp = value;
	if (use)
		sprintf(str, "%03d", tmp);
	else
		sprintf(str, "%3d", tmp);
	Write(str);
}

/*##########################################################################
#
#   Name       : TSession::Read
#
#   Purpose....: Read a character from standard input
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
char TSession::Read()
{
	char ch = 3;

	if (FInputFile)
		FInputFile->Read(&ch, 1);

	return ch;
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

	if (FCmdFile->IsDevice())
	    return ReadCon(str, maxsize);
	else
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
	char ch;
	int i;

	if (FInputFile->IsDevice())
	    return ReadCon(str, maxsize);
	else
	{
		for (i = 0; i < maxsize; i++)
		{
			ch = 0;
			FInputFile->Read(&ch, 1);

			if (ch == 3)
				return FALSE;

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
			    break;
			}
			else
            {	    		
    			cmd->Run();
	    		delete cmd;
	    	}
		}
	}
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
	int ok;
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
	    	    return 1;
    	}
        return 0;
    }
    else
        return 1;
}
