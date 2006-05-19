#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rdos.h"
#include "jpeg.h"
#include "videodev.h"
#include "file.h"

#define FALSE	0
#define	TRUE	!FALSE

#define X_START     5
#define Y_START     5
#define X_SPACING   20

int main()
{
	TGraphicDevice *vbe;
	TBitmapGraphicDevice *checked;
	TBitmapGraphicDevice *question;
	TJpegBitmapDevice *jpeg;
	int cwidth, cheight;
	int qwidth, qheight;
	int twidth, theight;
	int ratio;
	TFile file("q.dat");
	char buf[80];
	int i, j, k;
	int x, y;
	int q;
    char filename[80];

	RdosWaitMilli(250);

	checked = TJpegBitmapDevice::Create("checked.jpg");
	cwidth = checked->GetWidth();
	cheight = checked->GetHeight();

	question = TJpegBitmapDevice::Create("q.jpg");
	qwidth = question->GetWidth();
	qheight = question->GetHeight();

	for (q = 0; q < 18; q++)
	{

    	twidth = 2 * X_START + 3 * (5 * (cwidth + 1)) + 3 * X_SPACING + qwidth;
	    theight = 2 * Y_START + 5 * (cheight + 1);

    	jpeg = new TJpegBitmapDevice(24, twidth, theight);

        jpeg->SetFilledStyle();
        jpeg->SetDrawColor(255, 255, 255);
        jpeg->DrawRect(0, 0, twidth - 1, theight - 1);
        jpeg->SetDrawColor(0, 0, 0);
    
        for (i = 0; i < 5; i++)
        {
		    file.Read(buf, 19);
    		if (buf[17] != 0xd)
                return 1;

    		y = Y_START + i * (cheight + 1);

	    	for (j = 0; j < 3; j++)
		    {
			    x = X_START + j * (5 * (cwidth + 1) + X_SPACING);
            
                for (k = 0; k < 5; k++)
                {
                    switch (buf[6 * j + k])
                    {
				    	case '0':
					    	break;

                        case '1':
                            jpeg->Blit(checked, 0, 0, 
		    								x + k * (cwidth + 1),
			    							y,
                                            cwidth, cheight);
                            break;

                        default:
                            return 1;
                    }
                }
            }
        }

        for (i = 0; i < 6; i++)
        {
            for (j = 0; j < 3; j++)
            {
	    		x = X_START + j * (5 * (cwidth + 1) + X_SPACING);
		    	y = Y_START + i * (cheight + 1);
			    jpeg->DrawLine(x, y, x + 5 * (cwidth + 1), y);
    		}
	    }

    	for (i = 0; i < 3; i++)
	    {
		    for (j = 0; j < 6; j++)
    		{
	    		x = X_START + j * (cwidth + 1) + i * (5 * (cwidth + 1) + X_SPACING);
		    	jpeg->DrawLine(x, Y_START, x, Y_START + 5 * (cheight + 1));
    		}
	    }

    	jpeg->Blit(question, 0, 0, twidth - qwidth - X_START, Y_START, qwidth, qheight);

        sprintf(filename, "q%d.jpg", q);    	
	    jpeg->Save(filename);

    	vbe = new TVideoGraphicDevice(24, 640, 480);
	    vbe->Blit(jpeg, 0, 0, 0, 0, twidth, theight);
    	delete jpeg;

    	file.Read(buf, 2);
	    if (buf[0] != 0xd)
		    return 1;

    	twidth = 2 * X_START + 6 * (5 * (cwidth + 1)) + 5 * X_SPACING;
	    theight = 2 * Y_START + 5 * (cheight + 1);

    	jpeg = new TJpegBitmapDevice(24, twidth, theight);
    
        jpeg->SetFilledStyle();
        jpeg->SetDrawColor(255, 255, 255);
        jpeg->DrawRect(0, 0, twidth - 1, theight - 1);
        jpeg->SetDrawColor(0, 0, 0);

        for (i = 0; i < 5; i++)
        {
            file.Read(buf, 37);
            if (buf[35] != 0xd)
                return 1;

    		y = Y_START + i * (cheight + 1);

	    	for (j = 0; j < 6; j++)
		    {
			    x = X_START + j * (5 * (cwidth + 1) + X_SPACING);
            
                for (k = 0; k < 5; k++)
                {
                    switch (buf[6 * j + k])
                    {
				    	case '0':
					    	break;

                        case '1':
                            jpeg->Blit(checked, 0, 0, 
		    								x + k * (cwidth + 1),
			    							y,
                                            cwidth, cheight);
                            break;

                        default:
                            return 1;
                    }
                }
            }
        }

        for (i = 0; i < 6; i++)
        {
            for (j = 0; j < 6; j++)
            {
	    		x = X_START + j * (5 * (cwidth + 1) + X_SPACING);
		    	y = Y_START + i * (cheight + 1);
			    jpeg->DrawLine(x, y, x + 5 * (cwidth + 1), y);
    		}
	    }

    	for (i = 0; i < 6; i++)
	    {
		    for (j = 0; j < 6; j++)
    		{   
	    		x = X_START + j * (cwidth + 1) + i * (5 * (cwidth + 1) + X_SPACING);
		    	jpeg->DrawLine(x, Y_START, x, Y_START + 5 * (cheight + 1));
    		}
	    }

        sprintf(filename, "a%d.jpg", q);    	
    	jpeg->Save(filename);
    	vbe->Blit(jpeg, 0, 0, 0, theight, twidth, theight);
	    delete jpeg;

    	file.Read(buf, 2);
	    if (buf[0] != 0xd)
		    return 1;
	}
	
	RdosReadKeyboard();
	delete checked;
	delete vbe;

	return 0;
}

