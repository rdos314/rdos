#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rdos.h"
#include "mp3.h"

#define FALSE	0
#define	TRUE	!FALSE

int main(int argc, char **argv)
{
	char FileName[256];
	TMp3Player mp3;

	if (argc == 1)
	{
		printf("usage: playmp3 filename\r\n");
		return 1;
	}

	RdosWaitMilli(250);

	strcpy(FileName, argv[1]);
	strlwr(FileName);

	mp3.Load(FileName);
	mp3.SetPosition(1000);

	return 0;
}
