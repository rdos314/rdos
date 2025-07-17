/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# image.h
# Image class
#
########################################################################*/

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
    virtual ~TImageControl();

    void CreateImage(int bpp);

    static int IsImageControl(TControl *control);

    virtual void Set(TAppIniFile *Ini, const char *IniSection);
    virtual void Set(const char *IniName, const char *IniSection);

    void LoadImage(const char *FileName);
    void SetImage(const TGraphicDevice *Image);

    TBitmapGraphicDevice *GetImage(int Id);

    const char *GetImage();

    void SetLoader(TLoaderThread *Loader);
    void SetLoadIni(const char *Name, TAppIniFile *Ini, const char *IniSection);
    void SetLoadIni(const char *IniName, const char *IniSection);

    void SetBackColor(int r, int g, int b);
    void RestartSequence();

    void EraseBackground();
    void KeepBackground();
    void TransparentBackground();

    virtual void Show();

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

    TAppIniFile *FLoadIni;
    TString FLoadSection;
    int FBackR;
    int FBackG;
    int FBackB;
    int FIndex;
    int FCount;
    int FMultiImage;

    int FErase;

    TLoaderThread *FLoader;
    int FLoading;
    int FAborted;
    int FDeleted;
    int FLoadActive;

    TBitmapGraphicDevice *FImgArr[MAX_IMAGE_COUNT];
    long FDelayArr[MAX_IMAGE_COUNT];

    char FKey;

    TString FImageName;

private:
    void Init();

};

#endif

