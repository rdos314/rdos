#include "rdos.h"
#include <ctype.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#include "bitdev.h"
#include "videodev.h"
#include "waitdev.h"
#include "keyboard.h"
#include "mouse.h"
#include "png.h"

#define FALSE   0
#define TRUE    !FALSE

#define PI      3.1415926373
#define SCALE   2

class TMale;
class TFemale;

struct TMale
{
    TMale();
    ~TMale();

    void Show();
    void Hide();
    void Update();
    double GetFemaleDir();
    double GetFemaleDist();

    TFemale *Female;

    double X;
    double Y;
    double Rot;
    double V;
    double VRot;

    int FCurrX;
    int FCurrY;
    double FCurrRot;
};    

struct TFemale
{
    TFemale();
    ~TFemale();

    void Show();
    void Hide();
    void Update();
    double GetMaleDist();

    TMale *Male;

    double X;
    double Y;
    double Rot;
    double V;
    double VRot;

    int FCurrX;
    int FCurrY;
    double FCurrRot;
};    

TGraphicDevice *vbe;
TMale Male;
TFemale Female;
int FileNr;

/*##########################################################################
#
#   Name       : Draw
#
#   Purpose....: Draw pattern
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void Draw(int x, int y, double rot, int len, int width)
{
    int i;
    double xdiff, ydiff;
    double px, py;
        
    px = (double)len * cos(rot);
    py = (double)len * sin(rot);        

    vbe->DrawLine(x, y, x + (int)px, y + (int)py);

    for (i = 1; i < width; i++)
    {
        xdiff = (double)i * cos(rot + PI / 2);
        ydiff = (double)i * sin(rot + PI / 2);

        vbe->DrawLine(x + (int)xdiff, y + (int)ydiff, x + (int)(px + xdiff), y + (int)(py + ydiff));

        xdiff = (double)i * cos(rot - PI / 2);
        ydiff = (double)i * sin(rot - PI / 2);

        vbe->DrawLine(x + (int)xdiff, y + (int)ydiff, x + (int)(px + xdiff), y + (int)(py + ydiff));
    }
}

/*##########################################################################
#
#   Name       : ShowCue
#
#   Purpose....: Show cue
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void ShowCue(int female, int x, int y, double rot)
{
    if (female)
        vbe->SetDrawColor(255, 128, 0);
    else
        vbe->SetDrawColor(0, 128, 255);

    Draw(x * SCALE, y * SCALE, rot, 5 * SCALE, 2);
    Draw(x * SCALE, y * SCALE, rot + PI + PI / 12, 7 * SCALE, 2);
    Draw(x * SCALE, y * SCALE, rot + PI - PI / 12, 7 * SCALE, 2);
}

/*##########################################################################
#
#   Name       : HideCue
#
#   Purpose....: Hide cue
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void HideCue(int x, int y, double rot)
{
    vbe->SetDrawColor(0, 0, 0);

    Draw(x * SCALE, y * SCALE, rot, 5 * SCALE, 2);
    Draw(x * SCALE, y * SCALE, rot + PI + PI / 12, 7 * SCALE, 2);
    Draw(x * SCALE, y * SCALE, rot + PI - PI / 12, 7 * SCALE, 2);
}

/*##########################################################################
#
#   Name       : TMale::TMale
#
#   Purpose....: Male constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMale::TMale()
{
    X = 0.0;
    Y = 0.0;
    Rot = 0.0;
    V = 0.0;
    VRot = 0.0;

    Female = 0;
}

/*##########################################################################
#
#   Name       : TMale::~TMale
#
#   Purpose....: Male destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TMale::~TMale()
{
}

/*##########################################################################
#
#   Name       : TMale::Show
#
#   Purpose....: Show male
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMale::Show()
{
    FCurrX = (int)X;
    FCurrY = (int)Y;
    FCurrRot = Rot;
    
    ShowCue(FALSE, FCurrX, FCurrY, FCurrRot);
}

/*##########################################################################
#
#   Name       : TMale::Hide
#
#   Purpose....: Hide male
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMale::Hide()
{
    HideCue(FCurrX, FCurrY, FCurrRot);
}

/*##########################################################################
#
#   Name       : TMale::GetFemaleDir
#
#   Purpose....: Get female direction
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TMale::GetFemaleDir()
{
    double dx, dy;

    dx = X - Female->X;
    dy = Y - Female->Y;

    if (dx > 0)
        return PI + atan(dy / dx);
    else
        return atan(dy / dx);
    
}

/*##########################################################################
#
#   Name       : TMale::GetFemaleDist
#
#   Purpose....: Get female distance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TMale::GetFemaleDist()
{
    double dx, dy;

    dx = X - Female->X;
    dy = Y - Female->Y;

    return sqrt(dx * dx + dy * dy);
}

/*##########################################################################
#
#   Name       : TMale::Update
#
#   Purpose....: Update position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TMale::Update()
{
    double dx, dy;
    double dist;
    
    dx = V * cos(VRot);
    dy = V * sin(VRot);

    X += dx;
    Y += dy;

    if (Female)
    {
        Rot = GetFemaleDir();
        VRot = Rot - PI / 16;

        dist = GetFemaleDist();

        if (dist < 25)
            V = Female->V + (dist - 25.0) / 5.0;
        else
            V = Female->V + 0.5;
    }
}

/*##########################################################################
#
#   Name       : TFemale::TFemale
#
#   Purpose....: Female constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFemale::TFemale()
{
    X = 0.0;
    Y = 0.0;
    Rot = 0.0;
    V = 0.0;
    VRot = 0.0;

    Male = 0;
}

/*##########################################################################
#
#   Name       : TFemale::~TFemale
#
#   Purpose....: Female destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TFemale::~TFemale()
{
}

/*##########################################################################
#
#   Name       : TFemale::Show
#
#   Purpose....: Show female
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFemale::Show()
{
    FCurrX = (int)X;
    FCurrY = (int)Y;
    FCurrRot = Rot;
    
    ShowCue(TRUE, FCurrX, FCurrY, FCurrRot);
}

/*##########################################################################
#
#   Name       : TFemale::Hide
#
#   Purpose....: Hide female
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFemale::Hide()
{
    HideCue(FCurrX, FCurrY, FCurrRot);
}

/*##########################################################################
#
#   Name       : TFemale::GetMaleDist
#
#   Purpose....: Get male distance
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TFemale::GetMaleDist()
{
    double dx, dy;

    dx = X - Male->X;
    dy = Y - Male->Y;

    return sqrt(dx * dx + dy * dy);
}

/*##########################################################################
#
#   Name       : TFemale::Update
#
#   Purpose....: Update position
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TFemale::Update()
{
    double dist;
    double dx, dy;

    Rot = VRot;
    
/*    if (Male)
    {
        dist = GetMaleDist();

        if (dist > 25)
            Rot = VRot;
        else
            Rot = VRot - PI / 2 * (25 - dist);
    } */
    
    dx = V * cos(VRot);
    dy = V * sin(VRot);

    X += dx;
    Y += dy;

    
}

/*##########################################################################
#
#   Name       : SavePng
#
#   Purpose....: Save to PNG
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void SavePng()
{
/*
    char FileName[256];
    TBitmapGraphicDevice bitmap(24, SCALE * 210, SCALE * 140);

    bitmap.Blit(vbe, 0, 0, 0, 0, SCALE * 210, SCALE * 140);

    sprintf(FileName, "png\\%d.png", FileNr);
    FileNr++;

    TPngBitmapDevice::Save(FileName, &bitmap);
*/
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....: Main
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int main()
{
    int i;
    
    vbe = new TVideoGraphicDevice(24, 1366, 768);
//    vbe = new TVideoGraphicDevice(24, 640, 480);


    vbe->SetDrawColor(255, 255, 255);
    vbe->DrawLine(SCALE * 210, 0, SCALE * 210, SCALE * 140);
    vbe->DrawLine(0, SCALE * 140, SCALE * 210, SCALE * 140);

    FileNr = 1000;
    
//    for (;;)
    {
        Male.Female = 0;
        Male.X = 200;
        Male.Y = 120;
        Male.V = 1.0;
        Male.Rot = -PI / 2;
        Male.VRot = -PI / 2;

        Female.Male = 0;    
        Female.X = 220;
        Female.Y = 50;
        Female.V = 0;
        Female.Rot = -PI;
        Female.VRot = -PI;
    
        for (i = 0; i < 35; i++)
        {
            Male.Show();
            Female.Show();

            SavePng();

            RdosWaitMilli(40);

            Male.Update();
            Female.Update();

            Male.Hide();
            Female.Hide();
        }

        Female.V = 0.75;
        Female.Rot = PI;
        
        for (i = 0; i < 20; i++)
        {
            Male.Show();
            Female.Show();

            SavePng();

            RdosWaitMilli(40);

            Female.Rot += PI / 50;
            Female.VRot = Female.Rot;

            Male.Update();
            Female.Update();

            Male.Hide();
            Female.Hide();
        }

        Male.Female = &Female;
        
        for (i = 0; i < 25; i++)
        {
            Male.Show();
            Female.Show();

            SavePng();

            RdosWaitMilli(40);

            Female.Rot -= PI / 100;
            Female.VRot = Female.Rot;

            Male.Update();
            Female.Update();

            Male.Hide();
            Female.Hide();
        }
    
        for (i = 0; i < 150; i++)
        {
            Male.Show();
            Female.Show();

            SavePng();

            RdosWaitMilli(40);

            Female.VRot -= PI / 600;
            Female.Rot = Female.VRot;

            Male.Update();
            Female.Update();

            Male.Hide();
            Female.Hide();
        }
    
        for (i = 0; i < 80; i++)
        {
            Male.Show();
            Female.Show();

            SavePng();

            RdosWaitMilli(40);

            Female.VRot -= PI / 150;
            Female.Rot = Female.VRot;

            Male.Update();
            Female.Update();

            Male.Hide();
            Female.Hide();
        }
    
        for (i = 0; i < 200; i++)
        {
            Male.Show();
            Female.Show();

            SavePng();

            RdosWaitMilli(40);

            Female.VRot -= PI / 600;
            Female.Rot = Female.VRot;

            Male.Update();
            Female.Update();

            Male.Hide();
            Female.Hide();
        }
    
        for (i = 0; i < 80; i++)
        {
            Male.Show();
            Female.Show();

            SavePng();

            RdosWaitMilli(40);

            Female.VRot -= PI / 150;
            Female.Rot = Female.VRot;

            Male.Update();
            Female.Update();

            Male.Hide();
            Female.Hide();
        }
    
        for (i = 0; i < 150; i++)
        {
            Male.Show();
            Female.Show();

            SavePng();

            RdosWaitMilli(40);

            Female.VRot -= PI / 400;
            Female.Rot = Female.VRot;

            Male.Update();
            Female.Update();

            Male.Hide();
            Female.Hide();
        }

        for (i = 0; i < 75; i++)
        {
            Male.Show();
            Female.Show();

            SavePng();

            RdosWaitMilli(40);

            if (Female.V > 0)
                Female.V -= 0.01;

            Female.VRot -= PI / 200;
            Female.Rot = Female.VRot;

            Male.Update();
            Female.Update();

            Male.Hide();
            Female.Hide();
        }

        for (i = 0; i < 75; i++)
        {
            Male.Show();
            Female.Show();

            SavePng();

            RdosWaitMilli(40);

            Female.V = 0;

            Male.Update();
            Female.Update();

            Male.Hide();
            Female.Hide();
        }
    }
    
    return 0;        
}

