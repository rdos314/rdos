#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include "serial.h"
#include "section.h"
#include "file.h"
#include "rdos.h"
#include "videodev.h"
#include "table.h"
#include "file.h"

#define FALSE 0
#define TRUE !FALSE

/*##################  LoopThread  ##############################################
 *   Purpose....: Loop thread                                                                           #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-10-02 le                                                #
 *##########################################################################*/
void LoopThread(void *ptr)
{    
    for (;;)
        ;
}

/*##################  TestThread  ##############################################
 *   Purpose....: Test thread                                                                           #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-10-02 le                                                #
 *##########################################################################*/
void TestThread(void *ptr)
{    
    TFile file("d:/test/test32.exe");
}

/*##########################################################################
#
#   Name       : main
#
#   Purpose....: 
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void main()
{
    TGraphicDevice *vbe;
    TControlThread *control;
    TTableControl *Table;
    TLabelFactory CommentFactory;
    TLabelFactory ValueFactory;
    TLabelFactory ChangeFactory;
    TLabelControl *Label;
    int year, month, day;
    int hour, min, sec;
    int ms, us;
    unsigned long msb, lsb;
    char str[100];
    int Gdt;
    int GdtBase;
    int Handle;
    int HandleBase;
    int Mem;
    int MemBase;

    vbe = new TVideoGraphicDevice(32, 1024, 768);
    control = new TDisplayControlThread("Control", vbe);
    CommentFactory.SetSpace(4, 4);
    CommentFactory.SetFont(35);
    CommentFactory.SetBackTransparent();
    CommentFactory.SetDrawColor(0, 0, 0);
    CommentFactory.AlignLeft();
    
    ValueFactory.SetSpace(4, 4);
    ValueFactory.SetFont(35);
    ValueFactory.SetBackColor(100, 100, 100);
    ValueFactory.SetDrawColor(0, 0, 0);
    ValueFactory.AlignRight();

    ChangeFactory.SetSpace(4, 4);
    ChangeFactory.SetFont(35);
    ChangeFactory.SetBackColor(100, 100, 100);
    ChangeFactory.SetDrawColor(0, 0, 0);
    ChangeFactory.AlignRight();

    Table = new TTableControl(control, 5, 100, 500, 400);
    Table->SetBackColor(0, 20, 50);
    Table->SetRowSpacing(10);
    Table->SetColSpacing(16);
    Table->SetSpacingColor(0, 20, 50);
    Table->AddLabelColumn(&CommentFactory, 150);
    Table->AddLabelColumn(&ValueFactory, 150);
    Table->AddLabelColumn(&ChangeFactory, 150);

    Table->AddRow(35, 55);
    Table->AddRow(35, 55);
    Table->AddRow(35, 55);

    Table->SetText(0, 0, "GDT");
    Table->SetText(1, 0, "Handles");
    Table->SetText(2, 0, "App mem");
    Table->Show();

    Label = new TLabelControl(control, 5, 5, 300, 35);
    Label->SetFont(35);
    Label->SetBackColor(100, 100, 100);
    Label->SetDrawColor(0, 0, 0);
    Label->Show();

    RdosCreateThread(LoopThread, "Loop t", 0, 0x2000);

    GdtBase = RdosGetFreeGdt();
    HandleBase = RdosGetFreeHandles();
    MemBase = RdosGetFreeBigLocalLinear();

    for (;;)
    {
        Gdt = RdosGetFreeGdt();
        sprintf(str, "%d", Gdt);
        Table->SetText(0, 1, str);
        sprintf(str, "%d", Gdt - GdtBase);
        Table->SetText(0, 2, str);

        Handle = RdosGetFreeHandles();
        sprintf(str, "%d", Handle);
        Table->SetText(1, 1, str);
        sprintf(str, "%d", Handle - HandleBase);
        Table->SetText(1, 2, str);

        Mem = RdosGetFreeBigLocalLinear();
        sprintf(str, "%d", Mem / 1024);
        Table->SetText(2, 1, str);
        sprintf(str, "%d", (Mem - MemBase) / 1024);
        Table->SetText(2, 2, str);

        RdosGetTime(&msb, &lsb);
        RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
        RdosDecodeLsbTics(lsb, &min, &sec, &ms, &us);
    
        sprintf(str, "%04d-%02d-%02d %02d.%02d.%02d",
                        year, month, day,
                        hour, min, sec);
        Label->SetText(str);

        RdosCreateThread(TestThread, "Test t", 0, 0x2000);

        RdosWaitMilli(200);
    }  


//    RdosTestGate("");
}
