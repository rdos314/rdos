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

void main()
{
	TLangString::SetLanguage("lang\\swedish");
	char param[256];
	int size;

	size = RdosReadLine(param, 256);
	param[size] = 0;

	TSysSetCommand set(param);

	set.Run();
}

