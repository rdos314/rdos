
#ifndef _SYSTEM_H
#define _SYSTEM_H

#ifdef __cplusplus
extern "C" {
#endif

#undef WIN32

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

int RdosSetVBEMode(int *BitsPerPixel, int *xres, int *yres, int *linesize, void **buffer);
void RdosSetDrawColor(int handle, int color);
void RdosSetLGOP(int handle, int lgop);
void RdosSetHollowStyle(int handle);
void RdosSetFilledStyle(int handle);
int RdosOpenFont(int height);
void RdosCloseFont(int font);
void RdosGetStringMetrics(int font, const char *str, int *width, int *height);
void RdosSetFont(int handle, int font);
int RdosGetPixel(int handle, int x, int y);
void RdosSetPixel(int handle, int x, int y);
void RdosBlit(int SrcHandle, int DestHandle, int width, int height,
				int SrcX, int SrcY, int DestX, int DestY);
void RdosDrawMask(int handle, void *mask, int RowSize, int width, int height,
				int SrcX, int SrcY, int DestX, int DestY); 
void RdosDrawLine(int handle, int x1, int y1, int x2, int y2);
void RdosDrawString(int handle, int x, int y, const char *str);
void RdosDrawRect(int handle, int x, int y, int width, int height);
void RdosDrawEllipse(int handle, int x, int y, int width, int height);
int RdosCreateBitmap(int BitsPerPixel, int width, int height);
void RdosCloseBitmap(int handle);
int RdosCreateStringBitmap(int font, const char *str);
void RdosGetBitmapInfo(int handle, int *BitPerPixel, int *width, int *height,
					   int *linesize, void **buffer);

void RdosSetForeColor(int color);
void RdosSetBackColor(int color);
int RdosGetMemSize(void *ptr);
void *RdosAllocateMem(int Size);
void RdosFreeMem(void *ptr);

int RdosOpenCom(int Base, int Irq, int Divisor, char Parity, char DataBits, char StopBits, int SendBufSize, int RecBufSize); 
void RdosCloseCom(int Handle);
void RdosFlushCom(int Handle);
int RdosPollCom(int Handle);
int RdosWaitForCom(int Handle, int Timeout);
char RdosReadCom(int Handle);
void RdosWriteCom(int Handle, char Val);
void RdosSetDtr(int Handle);
void RdosResetDtr(int Handle);

int RdosOpenFile(const char *FileName, char Access);
int RdosCreateFile(const char *FileName, int Attrib);
void RdosCloseFile(int Handle);
long RdosGetFileSize(int Handle);
void RdosSetFileSize(int Handle, long Size);
long RdosGetFilePos(int Handle);
void RdosSetFilePos(int Handle, long Pos);
int RdosReadFile(int Handle, void *Buf, int Size);
int RdosWriteFile(int Handle, const void *Buf, int Size);

int RdosCreateMapping(int Size);
int RdosCreateNamedMapping(const char *Name, int Size); 
int RdosCreateNamedFileMapping(const char *Name, int Size, int FileHandle);
int RdosOpenNamedMapping(const char *Name);
void RdosSyncMapping(int Handle);
void RdosCloseMapping(int Handle);
void RdosMapView(int Handle, int Offset, void *Base, int Size);
void RdosUnmapView(int Handle);

void RdosSetCurDir(const char *PathName);

void RdosCreateThread(void (*Start)(void *Param), const char *Name, void *Param, int StackSize);
void RdosTerminateThread();
void RdosWaitMilli(int ms);
void RdosGetTics(int *msb, int *lsb);
void RdosConvertTics(int msb, int lsb, int *year, int *month, int *day, int *hour, int *min, int *sec, int *milli);
void RdosGetSysTime(int *year, int *month, int *day, int *hour, int *min, int *sec, int *milli);
void RdosGetTime(int *year, int *month, int *day, int *hour, int *min, int *sec, int *milli);

int RdosCreateSection();
void RdosDeleteSection(int Handle);
void RdosEnterSection(int Handle);
void RdosLeaveSection(int Handle);

int RdosNameToIp(const char *HostName);
int RdosIpToName(int Ip, char *HostName, int MaxSize);

int RdosOpenTcpConnection(int RemoteIp, int LocalPort, int RemotePort, int Timeout, int BufferSize);
void RdosListenTcpPort(int Port, int BufferSize, void (*Callb)(int Handle));
int RdosWaitForTcpConnection(int Handle, long Timeout);
void RdosCloseTcpConnection(int Handle);
void RdosDeleteTcpConnection(int Handle);
void RdosAbortTcpConnection(int Handle);
void RdosPushTcpConnection(int Handle);
int RdosIsTcpConnectionClosed(int Handle);
int RdosReadTcpConnection(int Handle, void *Buf, int Size);
int RdosWriteTcpConnection(int Handle, void *Buf, int Size);

int RdosGetLocalMailslot(const char *Name);
int RdosGetRemoteMailslot(long Ip, const char *Name);
void RdosFreeMailslot(int Handle);
int RdosSendMailslot(int Handle, const void *Msg, int Size, void *ReplyBuf, int MaxReplySize);

void RdosDefineMailslot(const char *Name, int MaxSize);
int RdosReceiveMailslot(void *Msg);
void RdosReplyMailslot(const void *Msg, int Size);

void RdosSetFocus(char FocusKey);

void RdosClearKeyboard();
int RdosPollKeyboard();
int RdosReadKeyboard();

void RdosHideMouse();
void RdosShowMouse();
void RdosGetMousePosition(int *x, int *y);
void RdosSetMousePosition(int x, int y);
void RdosSetMouseWindow(int StartX, int StartY, int EndX, int EndY);
void RdosSetMouseMickey(int x, int y);
int RdosGetLeftButton();
int RdosGetRightButton();
void RdosGetLeftButtonPressPosition(int *x, int *y);
void RdosGetRightButtonPressPosition(int *x, int *y);
void RdosGetLeftButtonReleasePosition(int *x, int *y);
void RdosGetRightButtonReleasePosition(int *x, int *y);

void RdosSetCursorPosition(int Row, int Col);
void RdosWriteString(const char *Buf);
int RdosReadLine(char *Buf, int MaxSize);

int RdosPing(long Node, long Timeout);

int RdosGetDiscInfo(int DiscNr, int *SectorSize, long *Sectors, int *BiosSectorsPerCyl, int *BiosHeads);
int RdosReadDisc(int DiscNr, long Sector, char *Buf, int Size);
int RdosWriteDisc(int DiscNr, long Sector, const char *Buf, int Size);

void RdosGetRdfsInfo(void *CryptTab, void *KeyTab, void *ExtentSizeTab);
void RdosFormatDrive(int DiscNr, long StartSector, int Size, const char *FsName);

int RdosReadResource(int Module, int ID, char *Buf, int Size);

#ifdef __cplusplus
}
#endif

#endif



