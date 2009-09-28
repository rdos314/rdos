/*####################################  IMGAGE.CPP                      #################################################
##    Description: Image control                                                ##
##                                                                                                                  ##
##    Created....: 96-08-26 le                                                        Printed...: 90-10-25 an      ##
####################################################################################################################*/

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include "image.h"
#include "rdos.h"
#include "bmp.h"
#include "jpeg.h"
#include "gif.h"
#include "png.h"
#include "ini.h"

#define FALSE   0
#define TRUE    !FALSE

/*##################  TLoaderThread::TLoaderThread     ##########################
*   Purpose....: Constructor for loader thread                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-08-28 le                                                #
*##########################################################################*/
TLoaderThread::TLoaderThread()
{
    FCurrImg = 0;
    
    Start("Img loader", 0x10000);
}

/*##################  TLoaderThread::~TLoaderThread     ##########################
*   Purpose....: Destructor for loader thread                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-08-28 le                                                #
*##########################################################################*/
TLoaderThread::~TLoaderThread()
{
}

/*##################  TLoaderThread::StartLoad     ##########################
*   Purpose....: Start loader operation                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-08-28 le                                                #
*##########################################################################*/
void TLoaderThread::StartLoad(TImageControl *img)
{
    FSection.Enter();
    FCurrImg = img;
    FSection.Leave();
    FSignal.Signal();
}

/*##################  TLoaderThread::Execute     ##########################
*   Purpose....: Execute thread                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-08-28 le                                                #
*##########################################################################*/
void TLoaderThread::Execute()
{
    while (FInstalled)
    {
        FSignal.WaitForever();

        FSection.Enter();

        if (FCurrImg)
        {
            FCurrImg->Load(MAX_IMAGE_COUNT);
            FCurrImg = 0;
        }

        FSection.Leave();
    }
}

/*##################  TImageControl::TImageControl     ##########################
*   Purpose....: Constructor for image control                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-08-28 le                                                #
*##########################################################################*/
TImageControl::TImageControl(TControlThread *dev, int startx, int starty, int sizex, int sizey)
 : TControl(dev)
{
	Init();

	Resize(sizex, sizey);
	Move(startx, starty);
	Enable();
	Redraw();
}

/*##################  TImageControl::TImageControl     ##########################
*   Purpose....: Constructor for image control                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-08-28 le                                                #
*##########################################################################*/
TImageControl::TImageControl(TControl *control, int startx, int starty, int sizex, int sizey)
 : TControl(control)
{
	Init();

	Resize(sizex, sizey);
	Move(startx, starty);
	Enable();
	Redraw();
}

/*##################  TImageControl::TImageControl     ##########################
*   Purpose....: Constructor for image control                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-08-28 le                                                #
*##########################################################################*/
TImageControl::TImageControl(TControlThread *dev)
 : TControl(dev)
{
	Init();
}

/*##################  TImageControl::TImageControl     ##########################
*   Purpose....: Constructor for image control                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-08-28 le                                                #
*##########################################################################*/
TImageControl::TImageControl(TControl *control)
 : TControl(control)
{
	Init();
}

/*##################  TImageControl::~TImageControl     ##########################
*   Purpose....: Destructor for image control                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-08-28 le                                                #
*##########################################################################*/
TImageControl::~TImageControl()
{
	int i;

	if (FLoadIni)
		delete FLoadIni;

    for (i = 0; i < MAX_IMAGE_COUNT; i++)
		if (FImgArr[i])
            delete FImgArr[i];
}

/*##################  TImageControl::Init     ##########################
*   Purpose....: Init image control                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-08-28 le                                                #
*##########################################################################*/
void TImageControl::Init()
{
	int i;

	for (i = 0; i < MAX_IMAGE_COUNT; i++)
	{
		FImgArr[i] = 0;
		FDelayArr[i] = 1000;
	}

	FLoadIni = 0;

	FBackR = 0;
	FBackG = 0;
	FBackB = 0;

	FKey = 0;
	FCount = 0;
	FErase = FALSE;

	FIndex = MAX_IMAGE_COUNT;

	FLoader = 0;
	FLoading = FALSE;
}

/*##########################################################################
#
#   Name       : TImageControl::SetKey
#
#   Purpose....: Set key
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TImageControl::SetKey(char ch)
{
    FKey = ch;
}

/*##################  TImageControl::SetLoader     ##########################
*   Purpose....: Set image loader                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-08-28 le                                                #
*##########################################################################*/
void TImageControl::SetLoader(TLoaderThread *loader)
{
    FLoader = loader;
}

/*##########################################################################
#
#   Name       : TImageControl::Set
#
#   Purpose....: Set control settings from Ini-file section
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TImageControl::Set(const char *IniName, const char *IniSection)
{
    TIniFile Ini(IniName);
    char str[256];

    Ini.GotoSection(IniSection);

    if (Ini.ReadVar("BackColor.R", str, 255))
        FBackR = atoi(str);
    
    if (Ini.ReadVar("BackColor.G", str, 255))
		FBackG = atoi(str);

    if (Ini.ReadVar("BackColor.B", str, 255))
        FBackB = atoi(str);
    
    TControl::Set(IniName, IniSection);
}

/*##########################################################################
#
#   Name       : TImageControl::SetLoadIni
#
#   Purpose....: Set information about background loading
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TImageControl::SetLoadIni(const char *IniName, const char *IniSection)
{
    int i;
    int fh;

    if (FLoadIni)
        delete FLoadIni;

    FLoadIni = 0;

    for (i = 0; i < MAX_IMAGE_COUNT; i++)
    {
		if (FImgArr[i])
		{
            delete FImgArr[i];
            FImgArr[i] = 0;
        }
		FDelayArr[i] = 1000;
    }

	FIndex = MAX_IMAGE_COUNT;

    fh = RdosOpenFile(IniName, 0);
    if (fh)
    {
        RdosCloseFile(fh);

        FLoadIni = new TIniFile(IniName);
        FLoadSection = IniSection;

    	if (FLoader)
    	    Load(1);
	    else
    		Load(MAX_IMAGE_COUNT);
    }
}
            
/*##########################################################################
#
#   Name       : TImageControl::Show
#
#   Purpose....: Show image
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TImageControl::Show()
{
    TControl::Show();

    if (FLoader)
        FLoader->StartLoad(this);
    
}
            
/*##########################################################################
#
#   Name       : TImageControl::Hide
#
#   Purpose....: Hide image
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TImageControl::Hide()
{
    int i;
    
    TControl::Hide();

    if (FLoader)
    {
        FSection.Enter();

        for (i = 1; i < MAX_IMAGE_COUNT; i++)
        {
            if (FImgArr[i])
            {
                delete FImgArr[i];
                FImgArr[i] = 0;
            }
        }

        FSection.Leave();
    }
}
            
/*##########################################################################
#
#   Name       : TImageControl::CheckJpg
#
#   Purpose....: Check if filename has jpg extension
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TImageControl::CheckJpg(const char *path)
{
    int ok = FALSE;
    
    if (strstr(path, "JPG"))
        ok = TRUE;

    return ok;
}
            
/*##########################################################################
#
#   Name       : TImageControl::CheckPng
#
#   Purpose....: Check if filename has png extension
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TImageControl::CheckPng(const char *path)
{
    int ok = FALSE;
    
    if (strstr(path, "PNG"))
        ok = TRUE;

    return ok;
}
            
/*##########################################################################
#
#   Name       : TImageControl::CheckBmp
#
#   Purpose....: Check if filename has bmp extension
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TImageControl::CheckBmp(const char *path)
{
    int ok = FALSE;
    
    if (strstr(path, "BMP"))
        ok = TRUE;

    return ok;
}
            
/*##########################################################################
#
#   Name       : TImageControl::CheckGif
#
#   Purpose....: Check if filename has gif extension
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TImageControl::CheckGif(const char *path)
{
    int ok = FALSE;
    
    if (strstr(path, "GIF"))
        ok = TRUE;

    return ok;
}
            
/*##########################################################################
#
#   Name       : TImageControl::LoadOne
#
#   Purpose....: Load one image array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TImageControl::LoadOne(const char *path, int MaxCount)
{
    char str[256];
    int FirstNr = 0;
    int LastNr = MAX_IMAGE_COUNT;
    long StdDelay = 1000;
    long delay;
    int i;
    int fh;
    TBitmapGraphicDevice *bitmap;
    TIniFile *SeqIni = 0;

    int DoCheckJpg = TRUE;
    int DoCheckPng = TRUE;
    int DoCheckBmp = TRUE;
    int DoCheckGif = TRUE;

    fh = RdosOpenFile(path, 0);
    if (fh)
    {
        RdosCloseFile(fh);

        bitmap = 0;

        strcpy(str, path);
        strupr(str);

        if (CheckJpg(str))
            bitmap = TJpegBitmapDevice::Create(str);

        if (CheckBmp(str) && !bitmap)
            bitmap = TBmpBitmapDevice::Create(str);

        if (CheckPng(str) && !bitmap)
            bitmap = TPngBitmapDevice::Create(str, FBackR, FBackG, FBackB);

        if (CheckGif(str) && !bitmap)
            bitmap = TGifBitmapDevice::Create(str);

        if (bitmap)
        {
            FSection.Enter();
            
            if (FImgArr[FCount])
                delete FImgArr[FCount];
            
            FImgArr[FCount] = bitmap;
            FDelayArr[FCount] = StdDelay;
            FCount++;

            FSection.Leave();
        }
    }
    else
    {
        strcpy(str, path);
        strcat(str, "\\image.ini");

        fh = RdosOpenFile(str, 0);
        if (fh)
        {
            RdosCloseFile(fh);

            SeqIni = new TIniFile(str);

            SeqIni->GotoSection("ALL");

            if (SeqIni->ReadVar("First", str, 255))
                FirstNr = atoi(str);

            if (SeqIni->ReadVar("Last", str, 255))
                LastNr = atoi(str);

            if (SeqIni->ReadVar("Delay", str, 255))
                StdDelay = atoi(str);

            if (SeqIni->ReadVar("ImgType", str, 255))
            {
                strupr(str);

                DoCheckPng = CheckPng(str);
                DoCheckJpg = CheckJpg(str);
                DoCheckBmp = CheckBmp(str);
                DoCheckGif = CheckGif(str);
            }
        }

        for (i = FirstNr; FCount < MaxCount && i <= LastNr; i++)
        {
            if (FLoader && FCount && !IsVisible())
                break;
                
            delay = StdDelay;
        
            if (SeqIni)
            {
                sprintf(str, "%d", i);
                SeqIni->GotoSection(str);

               if (SeqIni->ReadVar("Delay", str, 255))
                    delay = atoi(str);
            }

            bitmap = 0;

            if (DoCheckJpg)
            {       
                sprintf(str, "%s\\%d.jpg", path, i);
                bitmap = TJpegBitmapDevice::Create(str);
            }

            if (DoCheckBmp && !bitmap)
            {
                sprintf(str, "%s\\%d.bmp", path, i);
                bitmap = TBmpBitmapDevice::Create(str);
            }

            if (DoCheckPng && !bitmap)
            {
                sprintf(str, "%s\\%d.png", path, i);
                bitmap = TPngBitmapDevice::Create(str, FBackR, FBackG, FBackB);
            }

            if (DoCheckGif && !bitmap)
            {
                sprintf(str, "%s\\%d.gif", path, i);
                bitmap = TGifBitmapDevice::Create(str);
            }

            if (bitmap)
            {
                FSection.Enter();
            
                if (FImgArr[FCount])
                    delete FImgArr[FCount];
            
                FImgArr[FCount] = bitmap;
                FDelayArr[FCount] = delay;
                FCount++;

                FSection.Leave();
            }
        }
    }

    if (SeqIni)
        delete SeqIni;
}

/*##########################################################################
#
#   Name       : TImageControl::Load
#
#   Purpose....: Load image array
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TImageControl::Load(int MaxCount)
{
    char str[40];
    char SeqPath[256];
    int i;

    if (FLoadIni)
    {
        FLoading = TRUE;
        FCount = 0;

        FLoadIni->GotoSection(FLoadSection.GetData());

        if (FLoadIni->ReadVar("Path", SeqPath, 255))
            LoadOne(SeqPath, MaxCount);
        else
        {
            for (i = 0; i < 256; i++)
            {
                sprintf(str, "Path%i", i);

                if (FLoadIni->ReadVar(str, SeqPath, 255))
                    LoadOne(SeqPath, MaxCount);
            }
        }
        FLoading = FALSE;
    }
}

/*##########################################################################
#
#   Name       : TImageControl::SetBackColor
#
#   Purpose....: Set background
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TImageControl::SetBackColor(int r, int g, int b)
{
    FBackR = r;
    FBackG = g;
    FBackB = b;
}

/*##########################################################################
#
#   Name       : TImageControl::RestartSequence
#
#   Purpose....: Restart image sequence
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TImageControl::RestartSequence()
{
    FIndex = MAX_IMAGE_COUNT;
}

/*##########################################################################
#
#   Name       : TImageControl::EraseBackground
#
#   Purpose....: Erase background to handle differing picture sizes
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TImageControl::EraseBackground()
{
    FErase = TRUE;
}

/*##########################################################################
#
#   Name       : TImageControl::KeepBackground
#
#   Purpose....: Keep background unaltered
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TImageControl::KeepBackground()
{
    FErase = FALSE;
}

/*##########################################################################
#
#   Name       : TImageControl::OnLeftDown
#
#   Purpose....: Handle left button down
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TImageControl::OnLeftDown(int x, int y, int ButtonState, int KeyState)
{
    if (IsInside(x, y))
    {
        if (FKey)
            PutKey(FKey);
            
        return TRUE;
    }
    else
        return FALSE;
}

/*##########################################################################
#
#   Name       : TImageControl::Paint
#
#   Purpose....: Paint control
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TImageControl::Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height)
{
    int bmx;
    int bmy;
    int xstart;
    int ystart;
    TBitmapGraphicDevice *bitmap;
    
    dev->SetLgopNone();

    ClearRedraw();

    FSection.Enter();

    FIndex++;

    if (FIndex >= MAX_IMAGE_COUNT)
        FIndex = 0;

    if (FImgArr[FIndex] == 0)
    {
        if (FLoading)
        {
            FIndex--;
            FSection.Leave();
            Redraw(25);
            return;            
        }
        else
            FIndex = 0;
    }

    bitmap = FImgArr[FIndex];

    if (bitmap)
    {
        bmx = bitmap->GetWidth();
        bmy = bitmap->GetHeight();
    }
    else
    {
        bmx = 0;
        bmy = 0;
    }

    xstart = xmin + width - bmx;
    ystart = ymin + height - bmy;

    if (FErase)
    {
        dev->SetLgopNone();
        dev->SetFilledStyle();
        dev->SetDrawColor(FBackR, FBackG, FBackB);
        dev->DrawRect(xmin, ymin, width, height);
    }

    if (bitmap)
        dev->Blit(bitmap, 0, 0, xstart, ystart, bmx, bmy);

    FSection.Leave();

    if (IsVisible() && (FCount >= 2 || FLoader))
        Redraw(FDelayArr[FIndex]);
}
