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
#include "dir.h"
#include "type.h"
#include "del.h"

TCdFactory *cd;
TChdirFactory *chdir;
TClsFactory *cls;
TCopyFactory *cpy;
TDateFactory *date;
TDelFactory *del;
TDirFactory *dir;
TEraseFactory *erase;
THelpFactory *help;
TMdFactory *md;
TMkdirFactory *mkdir;
TPathFactory *path;
TRdFactory *rd;
TRmdirFactory *rmdir;
TSetFactory *set;
TSysPathFactory *syspath;
TSysSetFactory *sysset;
TTypeFactory *type;
TTimeFactory *time;

#include "list.h"

void TestList()
{
	TList list1;
	TList list2;
	TList list3;
	TListNode node;

	list1.AddFirst(TListNode("abc", 3));
	list1.AddLast(TListNode("cde", 3));
	list1.AddFirst(TListNode("ferg", 4));

	list2.AddFirst(TListNode("x", 1));
	list2.AddFirst(TListNode("abc", 3));
	list2.AddLast(TListNode("y", 1));

	list3 = list1 & list2;

	list3.AddFirst(TListNode("abc", 3));
	list3.RemoveDuplicates();

	list3.GotoFirst();
	node = list3.Get();
	while (node.IsValid())
	{
		list3.GotoNext();
		node = list3.Get();
	}

	node = list3[3];
	list1 = list3;
}

void Init()
{
	char VersionStr[16];
	int Major;
	int Minor;
	int Release;

    TestList();

	RdosGetVersion(&Major, &Minor, &Release);
	sprintf(VersionStr, "%d.%d.%d", Major, Minor, Release);

	TCommand *cmd;

	time = new TTimeFactory;
	type = new TTypeFactory;
	sysset = new TSysSetFactory;
	syspath = new TSysPathFactory;
	set = new TSetFactory;
	rmdir = new TRmdirFactory;
	rd = new TRdFactory;
	path = new TPathFactory;
	mkdir = new TMkdirFactory;
	md = new TMdFactory;
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
		ok = Read(param, 256);
		if (ok)
		{
			cmd = new TCommandLine(param);
			cmd->Run();
			delete cmd;
		}
	}
}

