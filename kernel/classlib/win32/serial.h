#ifndef	_SERIAL_H
#define _SERIAL_H

#include "windows.h"
#include "device.h"

class TSerialDebug
{
public:
	short int Channel;
	unsigned long TimeLSB;
	unsigned long TimeMSB;
	char ch;
};

class TSerialDevice : public TDevice
{
public:
	TSerialDevice(const char *IniSection, int Port, long Baudrate);
	TSerialDevice(const char *IniSection, int Port, long Baudrate, char Parity, int DataBits, int StopBits);
	TSerialDevice(int Port, long Baudrate);
	TSerialDevice(int Port, long Baudrate, char Parity, int DataBits, int StopBits);
	TSerialDevice(const char *IniSection);
	TSerialDevice();
	virtual ~TSerialDevice();
	
	virtual void DeviceName(char *Name, int MaxLen) const;

	void Block();
	void Unblock();
	
	void SetComPort(int Port);
	virtual void SetBaudrate(long Baudrate);
	virtual void SetParity(char Parity);
	virtual void SetDataBits(int Bits);
	virtual void SetStopBits(int Bits);
	virtual long GetBaudrate() const;
	virtual char GetParity() const;
	virtual int GetDataBits() const;
	virtual int GetStopBits() const;
    virtual int GetSendBufferSpace();
    virtual int GetReceiveBufferSpace();
	virtual int GetPort() const;
	virtual void Open();
	virtual void Close();

	virtual void ResetDtr();
	virtual void SetDtr();
    virtual void ResetRts();
    virtual void SetRts();
	virtual void EnableAutoRts();
	virtual void DisableAutoRts();
	virtual void Clear();
	virtual void Write(char ch);
	virtual void Write(const char *buf, int count);
	virtual void Write(const char *str);
	virtual int Poll();
	virtual char Read();
	virtual int WaitForChar(long MaxWait);


protected:

private:
	void Init(int Port, long Baudrate, char Parity, int DataBits, int StopBits);
	void OpenPort();
    void ClosePort();
    void ReadPort();

	int FPort;
	long FBaudrate;
	char FParity;
	int FDataBits;
	int FStopBits;
	int FDataMask;
	HANDLE FPortHandle;
    DCB FCommDCB;
    OVERLAPPED FReadOverlapped;
    OVERLAPPED FWriteOverlapped;

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

