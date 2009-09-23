
#ifndef _IMAGE_H
#define _IMAGE_H

#include "panel.h"
#include "section.h"
#include "font.h"
#include "thread.h"
#include "sigdev.h"
#include "ini.h"

#define MAX_IMAGE_COUNT     255

class TImageControl;

class TLoaderThread : public TThread
{
public:
	TLoaderThread();
	~TLoaderThread();

	void StartLoad(TImageControl *img);

protected:
	virtual void Execute();

	TSection FSection;
	TImageControl *FCurrImg;
	TSignalDevice FSignal;
};

class TImageControl : public TControl
{
friend class TLoaderThread;
public:
    TImageControl(TControlThread *dev, int xstart, int ystart, int xsize, int ysize);
    TImageControl(TControl *control, int xstart, int ystart, int xsize, int ysize);
    TImageControl(TControlThread *dev);
	TImageControl(TControl *control);
	~TImageControl();

	virtual void Set(const char *IniName, const char *IniSection);

	void SetLoader(TLoaderThread *Loader);
	void SetLoadIni(const char *IniName, const char *IniSection);

	void SetBackColor(int r, int g, int b);
	void RestartSequence();

	void EraseBackground();
	void KeepBackground();

    virtual void Show();
    virtual void Hide();

    void SetKey(char key);

protected:
    int CheckJpg(const char *path);
    int CheckPng(const char *path);
    int CheckBmp(const char *path);
    int CheckGif(const char *path);

	void LoadOne(const char *path, int MaxCount);
	void Load(int MaxCount);
	
	virtual void Paint(TGraphicDevice *dev, int xmin, int ymin, int width, int height);
	virtual int OnLeftDown(int x, int y, int ButtonState, int KeyState);

	TIniFile *FLoadIni;
    TString FLoadSection;
	int FBackR;
	int FBackG;
	int FBackB;
	int FIndex;
	int FCount;

	int FErase;

    TSection FSection;
    TLoaderThread *FLoader;
    int FLoading;

	TBitmapGraphicDevice *FImgArr[MAX_IMAGE_COUNT];
	long FDelayArr[MAX_IMAGE_COUNT];

	char FKey;

private:
    void Init();

};

#endif

