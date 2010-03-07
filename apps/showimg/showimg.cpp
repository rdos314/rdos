#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "rdos.h"
#include "bmp.h"
#include "jpeg.h"
#include "gif.h"
#include "png.h"
#include "videodev.h"

#define FALSE   0
#define TRUE    !FALSE

int main(int argc, char **argv)
{
        TGraphicDevice *vbe;
        TBitmapGraphicDevice *bitmap;
        int width, height;
        int ratio;
        char FileName[256];

        if (argc == 1)
        {
        int i;

                vbe = new TVideoGraphicDevice(24, 1024, 600);

        for (;;)
        {       
                for (i = 0; i <= 256; i++)
                {
                sprintf(FileName, "%d.jpg", i);
                    bitmap = TJpegBitmapDevice::Create(FileName);

                if (bitmap)
                {
                        vbe->Blit(bitmap, 0, 0, 0, 0, bitmap->GetWidth(), bitmap->GetHeight());
                        delete bitmap;
                }
            }                                           
                }

//              printf("usage: showimg filename\r\n");
//              return 1;
        }

        RdosWaitMilli(250);

        strcpy(FileName, argv[1]);
        strlwr(FileName);

        bitmap = 0;

        if (strstr(FileName, ".png"))
                bitmap = TPngBitmapDevice::Create(FileName, 255, 255, 255);

        if (!bitmap && strstr(FileName, ".gif"))
                bitmap = TGifBitmapDevice::Create(FileName);

        if (!bitmap && strstr(FileName, ".jpg"))
                bitmap = TJpegBitmapDevice::Create(FileName);

        if (!bitmap && strstr(FileName, ".bmp"))
                bitmap = TBmpBitmapDevice::Create(FileName);

        if (!bitmap)
        {
                strcpy(FileName, argv[1]);
                strcat(FileName, ".jpg");
                bitmap = TJpegBitmapDevice::Create(FileName);
        }

        if (!bitmap)
        {
                strcpy(FileName, argv[1]);
                strcat(FileName, ".bmp");
                bitmap = TBmpBitmapDevice::Create(FileName);
        }

        if (!bitmap)
        {
                strcpy(FileName, argv[1]);
                strcat(FileName, ".png");
                bitmap = TPngBitmapDevice::Create(FileName, 255 ,255, 255);
        }

        if (!bitmap)
        {
                strcpy(FileName, argv[1]);
                strcat(FileName, ".gif");
                bitmap = TGifBitmapDevice::Create(FileName);
        }

        if (bitmap)
        {
                width = bitmap->GetWidth();
                height = bitmap->GetHeight();
                if (width < 640)
                        width = 640;
                if (height < 480)
                        height = 480;

                ratio = height * 4 / width;
                if (ratio > 3)
                        height = 3 * width / 4;
                else
                        width = 4 * height / 3;

                width = 1400;
                height = 1050;

                vbe = new TVideoGraphicDevice(24, width, height);
                vbe->Blit(bitmap, 0, 0, 0, 0, bitmap->GetWidth(), bitmap->GetHeight());
                RdosReadKeyboard();
                delete bitmap;
                delete vbe;
        }
        else
                printf("invalid filename\r\n");

        return 0;
}
