#include <stdio.h>
#include "rdos.h"
#include "ymodem.h"

TSerialDevice serial(1, 9600);

void EchoUntilSilent(int MaxWait)
{
	while (serial.WaitForChar(MaxWait))
		RdosWriteChar(serial.Read());
}

void StartYmodem()
{
	char ch;

	while (serial.WaitForChar(10))
		RdosWriteChar(serial.Read());

	serial.Write(0xD);

	if (serial.WaitForChar(100))
		RdosWriteChar(serial.Read());

	while (serial.WaitForChar(10))
	{
		ch = serial.Read();
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
	TYModem ymodem(&serial);
	TFile File("demo.rom");
	char ch;

	serial.Open();

	serial.Write("speed 115 1");
	serial.Write(0xD);
	EchoUntilSilent(10);

	serial.SetBaudrate(115200);
	serial.Write(0xD);

	serial.Write("yload 70:0");
	StartYmodem();

	if (ymodem.SendFile("sdram.bin"))
	{
		serial.Write("g 70:0");
		serial.Write(0xD);
		EchoUntilSilent(100);

		serial.Write("yload 200:0");
		StartYmodem();

		if (ymodem.SendFile(&File))
		{
			serial.Write("yload 70:0");
			StartYmodem();

			if (ymodem.SendFile("flash.bin"))
			{
				serial.Write("g 70:0");
				serial.Write(0xD);
				EchoUntilSilent(100);

				sprintf(str, "%08lX", File.GetSize());
				serial.Write(str);
				serial.Write(0xD);
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

	for (;;)
	{
		if (serial.WaitForChar(10))
		{
			ch = serial.Read();
			RdosWriteChar(ch);
		}

		if (RdosPollKeyboard())
		{
			ch = (char)RdosReadKeyboard();
			serial.Write(ch);
		}
	}
}

