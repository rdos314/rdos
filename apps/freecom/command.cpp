#include <stdio.h>
#include "rdos.h"
#include "str.h"
#include "path.h"
#include "env.h"
#include "langstr.h"
#include "lang.h"
#include "cmdhelp.h"
#include "pathcmd.h"
#include "set.h"
#include "help.h"
#include "time.h"
#include "date.h"
#include "cls.h"
#include "copy.h"
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
#include "ping.h"

#include "part.h"
#include "rdfspart.h"
#include "fatpart.h"
#include "ffspart.h"

TCdFactory *cd;
TChdirFactory *chdir;
TClsFactory *cls;
TCopyFactory *cpy;
TDateFactory *date;
TDelFactory *del;
TDirFactory *dir;
TEraseFactory *erase;
THelpFactory *help;
TInitHdFactory *inithd;
TMdFactory *md;
TMkdirFactory *mkdir;
TMakePartitionFactory *mkpart;
TPingFactory *ping;
TShowPartitionFactory *showpart;
TPathFactory *path;
TRdFactory *rd;
TRmdirFactory *rmdir;
TRemovePartitionFactory *rmpart;
TSetFactory *set;
TTypeFactory *type;
TTimeFactory *time;

void Init()
{
	char VersionStr[16];
	int Major;
	int Minor;
	int Release;

	TFsPartitionFactory *factory;

	factory = new TRdfsPartitionFactory;
	factory = new TFat12PartitionFactory;
	factory = new TFat16PartitionFactory;
	factory = new TFat32PartitionFactory;
	factory = new TFlashFsPartitionFactory;

	RdosGetVersion(&Major, &Minor, &Release);
	sprintf(VersionStr, "%d.%d.%d", Major, Minor, Release);

	TCommand *cmd;

	time = new TTimeFactory;
	type = new TTypeFactory;
	set = new TSetFactory;
	rmpart = new TRemovePartitionFactory;
	rmdir = new TRmdirFactory;
	rd = new TRdFactory;
	ping = new TPingFactory;
	path = new TPathFactory;
	showpart = new TShowPartitionFactory;
	mkpart = new TMakePartitionFactory;
	mkdir = new TMkdirFactory;
	md = new TMdFactory;
	inithd = new TInitHdFactory;
	erase = new TEraseFactory;
	dir = new TDirFactory;
	del = new TDelFactory;
	date = new TDateFactory;
	cpy = new TCopyFactory;
	cls = new TClsFactory;
	chdir = new TChdirFactory;
	cd = new TCdFactory;
	help = new THelpFactory;

	Write("FreeCom for RDOS ");
	Write(VersionStr);
	Write("\r\n");
	Write("Use @ before external command to detach\r\n\r\n");

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
		ok = ReadCmd(param, 256);
		if (ok)
		{
			cmd = new TCommandLine(param);
			cmd->Run();
			delete cmd;
		}
	}
}

