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
#include "cmdline.h"

THelpFactory *help;
TPathFactory *path;
TSetFactory *set;
TSysPathFactory *syspath;
TSysSetFactory *sysset;

void Init()
{
	TCommand *cmd;

	sysset = new TSysSetFactory;
	syspath = new TSysPathFactory;
	set = new TSetFactory;
	path = new TPathFactory;
	help = new THelpFactory;

	Write("FreeCom for RDOS\r\n\r\n");

	cmd = help->Create("");
	if (cmd)
		cmd->Run();
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

