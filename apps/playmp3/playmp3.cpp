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
		RdosSetMasterVolume(100, 100);

	RdosGetLineOutVolume(&L, &R);
	if (L < 0 && R < 0)
		RdosSetLineOutVolume(100, 100);

	TFm *fm;
	fm = new TFm(48000);
	TFmInstrument *inst = fm->Create(2, 5, 5.0);
	inst->SetAttack(2.0);
	inst->SetSustain(300.0, 35.0);
	inst->SetRelease(15.0, 15.0);

	long double freq = 8 * 55.0;
	long double fact = 1.059463094359;

	for (i = 1; i < 2; i++)
	{
		inst->Play(freq, 60.0, 60.0, 150.0);
		fm->Wait(250.0);
		freq = freq * fact;
	}
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
