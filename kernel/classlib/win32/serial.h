#ifndef	_SERIAL_H
#define _SERIAL_H

#include "device.h"

class TSerialDevice : public TDevice
{
public:
	TSerialDevice();
    TSerialDevice(const char *IniSection);
	virtual ~TSerialDevice();

	void Block();
	void Unblock();
	virtual void SetBaudrate(long Baudrate) = 0;
	virtual void SetParity(char Parity) = 0;
	virtual void SetDataBits(int Bits) = 0;
	virtual void SetStopBits(int Bits) = 0;
	virtual long GetBaudrate() const = 0;
	virtual char GetParity() const = 0;
	virtual int GetDataBits() const = 0;
	virtual int GetStopBits() const = 0;
	virtual int GetSendBufferSpace() = 0;
	virtual int GetReceiveBufferSpace() = 0;
	virtual void Clear() = 0;
	virtual void ResetDtr();
	virtual void SetDtr();
	virtual void ResetRts();
	virtual void SetRts();
	virtual void EnableAutoRts();
	virtual void DisableAutoRts();
	virtual void Write(char ch) = 0;
    virtual void Write(const char *buf, int count) = 0;
	virtual void Write(const char *str) = 0;
    virtual int Poll() = 0;
	virtual char Read() = 0;
	virtual int WaitForChar(long MaxWait) = 0;

protected:

private:
	TSection FSection;
};

class TSerialCommand
{
public:
	TSerialCommand(TSerialDevice *serial);
	virtual ~TSerialCommand();
	int Run();

protected:
	void Block();
	void Unblock();
	virtual int Execute() = 0;
	void Clear();
	void ResetDtr();
	void SetDtr();
	void ResetRts();
	void SetRts();
	void EnableAutoRts();
	void DisableAutoRts();
	void Write(char ch);
	void Write(const char *buf, int count);
	void Write(const char *str);
    int Poll();
	char Read();
    int WaitForChar(long MaxWait);

	TSerialDevice *FSerial;

private:

};

#endif

