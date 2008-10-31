#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rdos.h"
#include "mp3.h"

#include "fm.h"

#define FALSE	0
#define	TRUE	!FALSE

int main(int argc, char **argv)
{
	int L, R;

	char FileName[256];
	TMp3Player mp3;

//	TFmInstrumentFactory fact(48000, 0x7FFFFFFFF);
//    TFmInstrument *inst = fact.Create(2, 5, 2.8);
//    inst->SetAttack(10.0);
//    inst->SetSustain(2000.0, 500.0);
//	 inst->SetRelease(100.0, 50.0);
//	 inst->Play(440.0, 99.0, 2500.0);
//    delete inst;

	if (argc == 1)
	{
		printf("usage: playmp3 filename\r\n");
		return 1;
	}

	RdosWaitMilli(250);

	strcpy(FileName, argv[1]);
	strlwr(FileName);

	RdosGetMasterVolume(&L, &R);
	if (L < 0 && R < 0)
		RdosSetMasterVolume(100, 100);

	RdosGetLineOutVolume(&L, &R);
	if (L < 0 && R < 0)
		RdosSetLineOutVolume(100, 100);

	mp3.Load(FileName);
	mp3.Play();

	return 0;
}
