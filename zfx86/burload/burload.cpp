#include <stdio.h>
#include "rdos.h"
#include "ymodem.h"
#include "keyboard.h"

#define FALSE 0
#define TRUE !FALSE

#define PORT	2

TWait wait;
TSerialDevice *serial;
TKeyboardDevice *Keyboard;

void KeyPress(TKeyboardDevice *Keyboard, int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
	serial->Write((char)ScanCode);
}

void KeyRelease(TKeyboardDevice *Keyboard, int ExtKey, int KeyState, int VirtualKey, int ScanCode)
{
	serial->Write((char)ScanCode | 0x80);
}

void NewChar(TSerialDevice *Serial, char ch)
{
    RdosWriteChar(ch);
}

void EchoUntilSilent(int MaxWait)
{
	while (serial->WaitForChar(MaxWait))
		RdosWriteChar(serial->Read());
}

void StartYmodem()
{
	char ch;

	while (serial->WaitForChar(10))
		RdosWriteChar(serial->Read());

	serial->Write(0xD);

	if (serial->WaitForChar(100))
		RdosWriteChar(serial->Read());

	while (serial->WaitForChar(10))
	{
		ch = serial->Read();
		if (ch == 0xd)
		{
			RdosWriteString("\r\n");
			return;
		}
		else
			RdosWriteChar(ch);
	}
}

void cdecl main()
{
	char str[100];
	TYModem *ymodem;
	TFile File("demo.rom");
	char ch;

	serial = new TSerialDevice(&wait, PORT, 9600);

	serial->Write("speed 115 1");
	serial->Write(0xD);
	EchoUntilSilent(10);

	delete serial;

	serial = new TSerialDevice(&wait, PORT, 115200);

	serial->Write(0xD);

	ymodem = new TYModem(serial);

	serial->Write("yload 70:0");
	StartYmodem();

	if (ymodem->SendFile("sdram.bin"))
	{
		serial->Write("g 70:0");
		serial->Write(0xD);
		EchoUntilSilent(100);

		serial->Write("yload 200:0");
		StartYmodem();

		if (ymodem->SendFile(&File))
		{
			serial->Write("yload 70:0");
			StartYmodem();

			if (ymodem->SendFile("flash.bin"))
			{
				serial->Write("g 70:0");
				serial->Write(0xD);
				EchoUntilSilent(100);

				sprintf(str, "%08lX", File.GetSize());
				serial->Write(str);
				serial->Write(0xD);
				EchoUntilSilent(100);
			}
			else
				RdosWriteString("\r\nFailed sending flash.bin\r\n");
		}
		else
			RdosWriteString("\r\nFailed sending burn file\r\n");
	}
	else
		RdosWriteString("\r\nFailed sending sdram.bin\r\n");

	serial->OnChar = NewChar;
	Keyboard = new TKeyboardDevice(&wait);
	Keyboard->OnKeyPress = KeyPress;
//	Keyboard->OnKeyRelease = KeyRelease;
	for (;;)
		wait.WaitForever();
}

