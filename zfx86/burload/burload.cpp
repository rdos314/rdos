#include "rdos.h"
#include "serial.h"

void cdecl main()
{
	TSerialDevice *serial;
	char ch;

	serial = new TSerialDevice(1, 9600);
	serial->Open();

	serial->Write("speed 115 1");
	serial->Write(0xD);

	while (serial->WaitForChar(10))
		RdosWriteChar(serial->Read());

	serial->SetBaudrate(115200);

	serial->Write(0xD);

	for (;;)
	{
		if (serial->WaitForChar(10))
		{
			ch = serial->Read();
			RdosWriteChar(ch);
		}

		if (RdosPollKeyboard())
		{
			ch = (char)RdosReadKeyboard();
			serial->Write(ch);
		}
	}
}

