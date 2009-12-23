#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "fileview.h"
#include "videodev.h"

#define FALSE	0
#define TRUE	!FALSE

int main(int argc, char **argv)
{
	int width = 640;
	int height = 480;
	TGraphicDevice *vbe;
	TControlThread *controlthread;
	TFileViewControl *fileview;
	char FileName[256];

	if (argc == 1)
	{
		printf("usage: showfile filename\r\n");
		return 1;
	 }

	strcpy(FileName, argv[1]);
	strlwr(FileName);

	vbe = new TVideoGraphicDevice(24, width, height);
	controlthread = new TControlThread("Control", vbe);
	fileview = new TFileViewControl(controlthread, 0, 0, width, height);
   fileview->SetFont(12);
	fileview->Load(FileName);
	fileview->Show();
	fileview->Redraw();

	RdosReadKeyboard();
	delete fileview;
	delete controlthread;
	delete vbe;

}

