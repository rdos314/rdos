#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "keyboard.h"
#include "modbus.h"
#include "datetime.h"
#include "videodev.h"
#include "table.h"

void main()
{
    TLabelFactory CommentFactory;
    TLabelFactory ValueFactory;
    TLabelFactory UnitFactory;

    TTableControl *WeatherTable;
    TGraphicDevice *vbe;
    TControlThread *control;

    vbe = new TVideoGraphicDevice(32, 1400, 1050);
    control = new TDisplayControlThread("Control", vbe);

    CommentFactory.ForceNoScale();
    CommentFactory.SetSpace(4, 4);
    CommentFactory.SetFont(35);
    CommentFactory.SetBackTransparent();
    CommentFactory.SetDrawColor(0, 0, 0);
    CommentFactory.AlignLeft();

    ValueFactory.ForceNoScale();
    ValueFactory.SetSpace(4, 4);
    ValueFactory.SetFont(35);
    ValueFactory.SetBackColor(100, 100, 100);
    ValueFactory.SetDrawColor(0, 0, 0);
    ValueFactory.AlignRight();

    UnitFactory.ForceNoScale();
    UnitFactory.SetSpace(4, 4);
    UnitFactory.SetFont(35);
    UnitFactory.SetBackTransparent();
    UnitFactory.SetDrawColor(0, 0, 0);
    UnitFactory.AlignLeft();

    WeatherTable = new TTableControl(control, 5, 5, 450, 420);
    WeatherTable->SetBackColor(0, 20, 50);
    WeatherTable->SetRowSpacing(10);
    WeatherTable->SetColSpacing(16);
    WeatherTable->SetSpacingColor(0, 20, 50);
    WeatherTable->AddLabelColumn(&CommentFactory, 175);
    WeatherTable->AddLabelColumn(&ValueFactory, 150);
    WeatherTable->AddLabelColumn(&UnitFactory, 125);

    WeatherTable->AddRow(35, 55);
    WeatherTable->AddRow(35, 55);

    WeatherTable->SetText(0, 0, "Temperature");
    WeatherTable->SetText(0, 2, "C");

    WeatherTable->SetText(1, 0, "Wind");
    WeatherTable->SetText(1, 2, "m/s");

    WeatherTable->SetText(0, 1, "123234");
    WeatherTable->SetText(1, 1, "abcde");

    WeatherTable->Show();

/*    TFile file("e:/test.bin");
    char *buf = new char[1024];
    int size;
    int dummy;

    file.SetPos(500234);
    size = file.Read(buf, 267);

    file.SetPos(1000234);
    size = file.Read(buf, 99);

    file.SetPos(100234);
    size = file.Read(buf, 567);

    scanf("%d", &dummy);

    file.SetPos(760234);
    size = file.Read(buf, 455);

    char *buf = new char[1024];
    int size;
    int dummy;
    int handle = RdosOpenHandle("e:/test.bin", O_RDWR);

    RdosSetHandlePos(handle, 500234);
    size = RdosReadHandle(handle, buf, 267);

    RdosSetHandlePos(handle, 1000234);
    size = RdosReadHandle(handle, buf, 99);

    RdosSetHandlePos(handle, 1000234);
    size = RdosReadHandle(handle, buf, 567);

    RdosSetHandleSize(handle, 0);

    scanf("%d", &dummy);

    RdosSetHandlePos(handle, 760234);
    size = RdosReadHandle(handle, buf, 455);

    RdosCloseHandle(handle);

    delete buf;

*/


    char *buf = new char[1024];

    RdosTestGate(buf);
}



