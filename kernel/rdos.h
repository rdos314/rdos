
#ifndef _RDOS_H
#define _RDOS_H

#ifdef __cplusplus
extern "C" {
#endif

//#undef WIN32

#define FILE_ATTRIBUTE_READONLY         0x1
#define FILE_ATTRIBUTE_HIDDEN           0x2
#define FILE_ATTRIBUTE_SYSTEM           0x4
#define FILE_ATTRIBUTE_DIRECTORY        0x10
#define FILE_ATTRIBUTE_ARCHIVE          0x20
#define FILE_ATTRIBUTE_NORMAL           0x80

#define LGOP_NULL  0
#define LGOP_NONE  1
#define LGOP_OR  2
#define LGOP_AND  3
#define LGOP_XOR  4
#define LGOP_INVERT  5
#define LGOP_INVERT_OR  6
#define LGOP_INVERT_AND  7
#define LGOP_INVERT_XOR  8
#define LGOP_ADD  9
#define LGOP_SUBTRACT  10
#define LGOP_MULTIPLY  11

#define getred(pgc)       (((pgc)>>16)&0xFF)
#define getgreen(pgc)     (((pgc)>>8)&0xFF)
#define getblue(pgc)      ((pgc)&0xFF)
#define mkcolor(r,g,b)    (((r)<<16)|((g)<<8)|(b))

#if sizeof(int) == 2
#define __stdcall
#endif

void __stdcall RdosSetTextMode();
int __stdcall RdosSetVideoMode(int *BitsPerPixel, int *xres, int *yres, int *linesize, void **buffer);
void __stdcall RdosSetClipRect(int handle, int xmin, int ymin, int xmax, int ymax);
void __stdcall RdosClearClipRect(int handle);
void __stdcall RdosSetDrawColor(int handle, int color);
void __stdcall RdosSetLGOP(int handle, int lgop);
void __stdcall RdosSetHollowStyle(int handle);
void __stdcall RdosSetFilledStyle(int handle);
int __stdcall RdosOpenFont(int height);
void __stdcall RdosCloseFont(int font);
void __stdcall RdosGetStringMetrics(int font, const char *str, int *width, int *height);
void __stdcall RdosSetFont(int handle, int font);
int __stdcall RdosGetPixel(int handle, int x, int y);
void __stdcall RdosSetPixel(int handle, int x, int y);
void __stdcall RdosBlit(int SrcHandle, int DestHandle, int width, int height,
				int SrcX, int SrcY, int DestX, int DestY);
void __stdcall RdosDrawMask(int handle, void *mask, int RowSize, int width, int height,
				int SrcX, int SrcY, int DestX, int DestY); 
void __stdcall RdosDrawLine(int handle, int x1, int y1, int x2, int y2);
void __stdcall RdosDrawString(int handle, int x, int y, const char *str);
void __stdcall RdosDrawRect(int handle, int x, int y, int width, int height);
void __stdcall RdosDrawEllipse(int handle, int x, int y, int width, int height);
int __stdcall RdosCreateBitmap(int BitsPerPixel, int width, int height);
int __stdcall RdosDuplicateBitmapHandle(int handle);
void __stdcall RdosCloseBitmap(int handle);
int __stdcall RdosCreateStringBitmap(int font, const char *str);
void __stdcall RdosGetBitmapInfo(int handle, int *BitPerPixel, int *width, int *height,
					   int *linesize, void **buffer);

int __stdcall RdosCreateSprite(int DestHandle, int BitmapHandle, int MaskHandle, int lgop); 
void __stdcall RdosCloseSprite(int handle);
void __stdcall RdosShowSprite(int handle);
void __stdcall RdosHideSprite(int handle);
void __stdcall RdosMoveSprite(int handle, int x, int y);

void __stdcall RdosSetForeColor(int color);
void __stdcall RdosSetBackColor(int color);
int __stdcall RdosGetMemSize(void *ptr);
void *__stdcall RdosAllocateMem(int Size);
void __stdcall RdosFreeMem(void *ptr);

int __stdcall RdosOpenCom(int Base, int Irq, int Divisor, char Parity, char DataBits, char StopBits, int SendBufSize, int RecBufSize); 
void __stdcall RdosCloseCom(int Handle);
void __stdcall RdosFlushCom(int Handle);
char __stdcall RdosReadCom(int Handle);
void __stdcall RdosWriteCom(int Handle, char Val);
void __stdcall RdosSetDtr(int Handle);
void __stdcall RdosResetDtr(int Handle);
void __stdcall RdosSetRts(int Handle);
void __stdcall RdosResetRts(int Handle);
int __stdcall RdosGetReceiveBufferSpace(int Handle);
int __stdcall RdosGetSendBufferSpace(int Handle);

int __stdcall RdosOpenFile(const char *FileName, char Access);
int __stdcall RdosCreateFile(const char *FileName, int Attrib);
void __stdcall RdosCloseFile(int Handle);
int __stdcall RdosDuplFile(int Handle);
long __stdcall RdosGetFileSize(int Handle);
void __stdcall RdosSetFileSize(int Handle, long Size);
long __stdcall RdosGetFilePos(int Handle);
void __stdcall RdosSetFilePos(int Handle, long Pos);
int __stdcall RdosReadFile(int Handle, void *Buf, int Size);
int __stdcall RdosWriteFile(int Handle, const void *Buf, int Size);
void __stdcall RdosGetFileTime(int Handle, unsigned long *MsbTime, unsigned long *LsbTime);
void __stdcall RdosSetFileTime(int Handle, unsigned long MsbTime, unsigned long LsbTime);

int __stdcall RdosCreateMapping(int Size);
int __stdcall RdosCreateNamedMapping(const char *Name, int Size); 
int __stdcall RdosCreateNamedFileMapping(const char *Name, int Size, int FileHandle);
int __stdcall RdosOpenNamedMapping(const char *Name);
void __stdcall RdosSyncMapping(int Handle);
void __stdcall RdosCloseMapping(int Handle);
void __stdcall RdosMapView(int Handle, int Offset, void *Base, int Size);
void __stdcall RdosUnmapView(int Handle);

int __stdcall RdosSetCurDrive(int Drive);
int __stdcall RdosGetCurDrive();
int __stdcall RdosSetCurDir(const char *PathName);
int __stdcall RdosGetCurDir(int Drive, char *PathName);
int __stdcall RdosMakeDir(const char *PathName);
int __stdcall RdosRemoveDir(const char *PathName);
int __stdcall RdosRenameFile(const char *ToName, const char *FromName);
int __stdcall RdosDeleteFile(const char *PathName);
int __stdcall RdosGetFileAttribute(const char *PathName, int *Attribute);
int __stdcall RdosSetFileAttribute(const char *PathName, int Attribute);
int __stdcall RdosOpenDir(const char *PathName);
void __stdcall RdosCloseDir(int Handle);
int __stdcall RdosReadDir(int Handle, int EntryNr, int MaxNameSize, char *PathName, long *FileSize, int *Attribute, unsigned long *MsbTime, unsigned long *LsbTime);

void __stdcall RdosCreateThread(void (*Start)(void *Param), const char *Name, void *Param, int StackSize);
void __stdcall RdosTerminateThread();
void __stdcall RdosWaitMilli(int ms);
void __stdcall RdosGetTics(unsigned long *msb, unsigned long *lsb);
void __stdcall RdosTicsToRecord(unsigned long msb, unsigned long lsb, int *year, int *month, int *day, int *hour, int *min, int *sec, int *milli);
void __stdcall RdosRecordToTics(unsigned long *msb, unsigned long *lsb, int year, int month, int day, int hour, int min, int sec, int milli);
void __stdcall RdosGetSysTime(int *year, int *month, int *day, int *hour, int *min, int *sec, int *milli);
void __stdcall RdosGetTime(int *year, int *month, int *day, int *hour, int *min, int *sec, int *milli);
void __stdcall RdosAddTics(unsigned long *msb, unsigned long *lsb, long tics);
void __stdcall RdosAddMilli(unsigned long *msb, unsigned long *lsb, long ms);
void __stdcall RdosAddSec(unsigned long *msb, unsigned long *lsb, long sec);
void __stdcall RdosAddMin(unsigned long *msb, unsigned long *lsb, long min);
void __stdcall RdosAddHour(unsigned long *msb, unsigned long *lsb, long hour);
void __stdcall RdosAddDay(unsigned long *msb, unsigned long *lsb, long day);

int __stdcall RdosCreateSection();
void __stdcall RdosDeleteSection(int Handle);
void __stdcall RdosEnterSection(int Handle);
void __stdcall RdosLeaveSection(int Handle);

int __stdcall RdosCreateWait();
void __stdcall RdosCloseWait(int Handle);
void * __stdcall RdosCheckWait(int Handle);
void * __stdcall RdosWaitForever(int Handle);
void * __stdcall RdosWaitTimeout(int Handle, int MillSec);
void __stdcall RdosStopWait(int Handle);
void __stdcall RdosRemoveWait(int Handle, void *ID);
void __stdcall RdosAddWaitForKeyboard(int Handle, void *ID);
void __stdcall RdosAddWaitForMouse(int Handle, void *ID);
void __stdcall RdosAddWaitForCom(int Handle, int ComHandle, void *ID);
void __stdcall RdosAddWaitForAdc(int Handle, int AdcHandle, void *ID);

int __stdcall RdosNameToIp(const char *HostName);
int __stdcall RdosIpToName(int Ip, char *HostName, int MaxSize);

int __stdcall RdosOpenTcpConnection(int RemoteIp, int LocalPort, int RemotePort, int Timeout, int BufferSize);
void __stdcall RdosListenTcpPort(int Port, int BufferSize, void (*Callb)(int Handle));
int __stdcall RdosWaitForTcpConnection(int Handle, long Timeout);
void __stdcall RdosCloseTcpConnection(int Handle);
void __stdcall RdosDeleteTcpConnection(int Handle);
void __stdcall RdosAbortTcpConnection(int Handle);
void __stdcall RdosPushTcpConnection(int Handle);
int __stdcall RdosIsTcpConnectionClosed(int Handle);
int __stdcall RdosReadTcpConnection(int Handle, void *Buf, int Size);
int __stdcall RdosWriteTcpConnection(int Handle, void *Buf, int Size);

int __stdcall RdosGetLocalMailslot(const char *Name);
int __stdcall RdosGetRemoteMailslot(long Ip, const char *Name);
void __stdcall RdosFreeMailslot(int Handle);
int __stdcall RdosSendMailslot(int Handle, const void *Msg, int Size, void *ReplyBuf, int MaxReplySize);

void __stdcall RdosDefineMailslot(const char *Name, int MaxSize);
int __stdcall RdosReceiveMailslot(void *Msg);
void __stdcall RdosReplyMailslot(const void *Msg, int Size);

void __stdcall RdosSetFocus(char FocusKey);

void __stdcall RdosClearKeyboard();
int __stdcall RdosPollKeyboard();
int __stdcall RdosReadKeyboard();
int __stdcall RdosGetKeyboardState();
int __stdcall RdosPeekKeyEvent(int *ExtKey, int *KeyState, int *VirtualKey, int *ScanCode);
int __stdcall RdosReadKeyEvent(int *ExtKey, int *KeyState, int *VirtualKey, int *ScanCode);

void __stdcall RdosHideMouse();
void __stdcall RdosShowMouse();
void __stdcall RdosGetMousePosition(int *x, int *y);
void __stdcall RdosSetMousePosition(int x, int y);
void __stdcall RdosSetMouseWindow(int StartX, int StartY, int EndX, int EndY);
void __stdcall RdosSetMouseMickey(int x, int y);
int __stdcall RdosGetLeftButton();
int __stdcall RdosGetRightButton();
void __stdcall RdosGetLeftButtonPressPosition(int *x, int *y);
void __stdcall RdosGetRightButtonPressPosition(int *x, int *y);
void __stdcall RdosGetLeftButtonReleasePosition(int *x, int *y);
void __stdcall RdosGetRightButtonReleasePosition(int *x, int *y);

void __stdcall RdosSetCursorPosition(int Row, int Col);
void __stdcall RdosWriteChar(char ch);
void __stdcall RdosWriteSizeString(const char *Buf, int Size);
void __stdcall RdosWriteString(const char *Buf);
int __stdcall RdosReadLine(char *Buf, int MaxSize);

int __stdcall RdosPing(long Node, long Timeout);

int __stdcall RdosGetDiscInfo(int DiscNr, int *SectorSize, long *Sectors, int *BiosSectorsPerCyl, int *BiosHeads);
int __stdcall RdosReadDisc(int DiscNr, long Sector, char *Buf, int Size);
int __stdcall RdosWriteDisc(int DiscNr, long Sector, const char *Buf, int Size);

void __stdcall RdosGetRdfsInfo(void *CryptTab, void *KeyTab, void *ExtentSizeTab);
void __stdcall RdosFormatDrive(int DiscNr, long StartSector, int Size, const char *FsName);

int __stdcall RdosCreateFileDrive(long Size, const char *FsName, const char *FileName);
int __stdcall RdosOpenFileDrive(const char *FileName);

int __stdcall RdosLoadDll(const char *Name);
void __stdcall RdosFreeDll(int handle);
int __stdcall RdosReadResource(int handle, int ID, char *Buf, int Size);

int __stdcall RdosOpenAdc(int channel);
void __stdcall RdosCloseAdc(int handle);
void __stdcall RdosDefineAdcTime(int handle, unsigned long msg, unsigned long lsb);
long __stdcall RdosReadAdc(int handle);

int __stdcall RdosReadSerialLines(int device, int *val);
int __stdcall RdosToggleSerialLine(int device, int line);
int __stdcall RdosReadSerialVal(int device, int line, int *val);
int __stdcall RdosWriteSerialVal(int device, int line, int val);

int __stdcall RdosOpenSysEnv();
int __stdcall RdosOpenProcessEnv();
void __stdcall RdosCloseEnv(int handle);
void __stdcall RdosAddEnvVar(int handle, const char *var, const char *value);
void __stdcall RdosDeleteEnvVar(int handle, const char *var);
int __stdcall RdosFindEnvVar(int handle, const char *var, char *value);
void __stdcall RdosGetEnvData(int handle, char *buf);
void __stdcall RdosSetEnvData(int handle, const char *buf);

int __stdcall RdosOpenSysIni();
void __stdcall RdosCloseIni(int handle);
int __stdcall RdosGotoIniSection(int handle, const char *name);
int __stdcall RdosRemoveIniSection(int handle);
int __stdcall RdosReadIni(int handle, const char *var, char *str, int maxsize);
int __stdcall RdosWriteIni(int handle, const char *var, const char *str);
int __stdcall RdosDeleteIni(int handle, const char *var);

#ifdef __cplusplus
}
#endif

#endif



