#include <stdio.h>
#include "rdos.h"
#include "str.h"
#include "path.h"
#include "env.h"
#include "langstr.h"
#include "lang.h"
#include "pathcmd.h"
#include "syspath.h"
#include "set.h"
#include "sysset.h"

TPathFactory *path;
TSysPathFactory *syspath;
TSetFactory *set;
TSysSetFactory *sysset;

void Init()
{
	path = new TPathFactory;
	syspath = new TSysPathFactory;
	set = new TSetFactory;
	sysset = new TSysSetFactory;
}

void main()
{
//	TLangString::SetLanguage("swedish.dll");
	char param[256];
	int ok;
	TCommand *cmd;

	Init();

	for (;;)
	{
		DisplayPrompt();
		ok = Read(param, 256);
		if (ok)
		{
			cmd = TCommandFactory::Parse(param);
			if (cmd)
				cmd->Run();
		}
	}
}

