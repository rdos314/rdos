#include <stdio.h>
#include "rdos.h"
#include "str.h"
#include "path.h"
#include "env.h"
#include "langstr.h"
#include "lang.h"
#include "cmdhelp.h"
#include "pathcmd.h"
#include "syspath.h"
#include "set.h"
#include "sysset.h"
#include "help.h"
#include "time.h"
#include "date.h"
#include "cls.h"
#include "copy.h"
#include "cmdline.h"
#include "chdir.h"
#include "mkdir.h"
#include "rmdir.h"

TCdFactory *cd;
TChdirFactory *chdir;
TClsFactory *cls;
TCopyFactory *cpy;
TDateFactory *date;
THelpFactory *help;
TMdFactory *md;
TMkdirFactory *mkdir;
TPathFactory *path;
TRdFactory *rd;
TRmdirFactory *rmdir;
TSetFactory *set;
TSysPathFactory *syspath;
TSysSetFactory *sysset;
TTimeFactory *time;

void Init()
{
	TCommand *cmd;

	time = new TTimeFactory;
	sysset = new TSysSetFactory;
	syspath = new TSysPathFactory;
	set = new TSetFactory;
	rmdir = new TRmdirFactory;
	rd = new TRdFactory;
	path = new TPathFactory;
	mkdir = new TMkdirFactory;
	md = new TMdFactory;
	date = new TDateFactory;
	cpy = new TCopyFactory;
	cls = new TClsFactory;
	chdir = new TChdirFactory;
	cd = new TCdFactory;
	help = new THelpFactory;

	Write("FreeCom for RDOS\r\n\r\n");

	cmd = help->Create("");
	if (cmd)
		cmd->Run();

	Write("\r\n");
}

void main()
{
//	TLangString::SetLanguage("swedish.dll");
	char param[256];
	int ok;
	TCommandLine *cmd;

	Init();

	for (;;)
	{
		DisplayPrompt();
		ok = Read(param, 256);
		if (ok)
		{
			cmd = new TCommandLine(param);
			cmd->Run();
			delete cmd;
		}
	}
}

