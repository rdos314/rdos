#include <stdio.h>
#include "rdos.h"
#include "str.h"
#include "path.h"
#include "env.h"
#include "langstr.h"
#include "lang.h"
#include "path.h"
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
	int size;
	TCommand *cmd;

    Init();

	size = RdosReadLine(param, 256);
	param[size] = 0;

	cmd = sysset->Create(param);
	cmd->Run();
}

