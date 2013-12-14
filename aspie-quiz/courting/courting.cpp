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

#define FALSE   0
#define TRUE    !FALSE

#define PI      3.1415926373
#define SCALE   3

class TMale;
class TFemale;

struct TMale
{
    TMale();
    ~TMale();

    void Show();
    void Hide();
    void Update();

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
    
    dx = -V * cos(VRot);
    dy = -V * sin(VRot);

    X += dx;
    Y += dy;
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
    double dx, dy;
    
    dx = -V * cos(VRot);
    dy = -V * sin(VRot);

    X += dx;
    Y += dy;
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


    for (;;)
    {
        Male.X = 170;
        Male.Y = 220;
        Male.V = 0;
        Male.Rot = -PI / 2;
        Male.VRot = -PI/ 2;
    
        Female.X = 120;
        Female.Y = 255;
        Female.V = -1.0;
        Female.Rot = -PI / 2;
        Female.VRot = -PI / 2;
    
        for (i = 0; i < 5; i++)
        {
            Male.Show();
            Female.Show();

            RdosWaitMilli(40);

            Female.Rot += PI / 400;
            Female.VRot = Female.Rot;

            Male.Update();
            Female.Update();

            Male.Hide();
            Female.Hide();
        }
    
        for (i = 0; i < 75; i++)
        {
            Male.Show();
            Female.Show();

            RdosWaitMilli(40);

            Female.Rot += PI / 200;
            Female.VRot = Female.Rot;

            Male.Update();
            Female.Update();

            Male.Hide();
            Female.Hide();
        }
    
        for (i = 0; i < 50; i++)
        {
            Male.Show();
            Female.Show();

            RdosWaitMilli(40);

            Female.Rot -= PI / 200;
            Female.VRot = Female.Rot;

            Male.Update();
            Female.Update();

            Male.Hide();
            Female.Hide();
        }
    
        for (i = 0; i < 500; i++)
        {
            Male.Show();
            Female.Show();

            RdosWaitMilli(40);

            Female.Rot -= PI / 300;
            Female.VRot = Female.Rot;

            Male.Update();
            Female.Update();

            Male.Hide();
            Female.Hide();
        }
    }
    
    return 0;        
}

