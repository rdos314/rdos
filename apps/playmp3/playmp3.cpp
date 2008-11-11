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
	int i;

	char FileName[256];
	TMp3Player mp3;

	RdosGetMasterVolume(&L, &R);
	if (L < 0 && R < 0)
		RdosSetMasterVolume(30, 100);

	RdosGetLineOutVolume(&L, &R);
	if (L < 0 && R < 0)
		RdosSetLineOutVolume(100, 100);

	TFm *fm;
	fm = new TFm(48000);
	TFmInstrument *inst = fm->Create(1, 1, 0.0);
	inst->SetAttack(2.0);
	inst->SetSustain(3000.0, 35.0);
	inst->SetRelease(150.0, 15.0);

	long double freq = 15000.0;

	inst->Play(freq, 90.0, 90.0, 3000.0);

	delete inst;
	delete fm;

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
