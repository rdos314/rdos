
#ifndef _SYSTEM_H
#define _SYSTEM_H

#ifdef __cplusplus
extern "C" {
#endif

#undef WIN32

void RdosSetVgaMode();
void RdosSetFont(int Height);
void RdosSetForeColor(int color);
void RdosSetBackColor(int color);
void RdosFillRect(int StartX, int StartY, int EndX, int EndY);
void RdosDrawMonoBitmap(void *Bitmap, int StartX, int StartY, int EndX, int EndY);
int RdosGetCharWidth(char ch);
int RdosDrawChar(int x, int y, char ch);
int RdosGetStringWidth(const char *str);
int RdosDrawString(int x, int y, const char *str);
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
void RdosCloseFile(int Handle);
long RdosGetFileSize(int Handle);
void RdosSetFileSize(int Handle, long Size);
long RdosGetFilePos(int Handle);
void RdosSetFilePos(int Handle, long Pos);
int RdosReadFile(int Handle, void *Buf, int Size);
int RdosWriteFile(int Handle, void *Buf, int Size);

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
int RdosGetTics();

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

void RdosClearKeyboard();
int RdosPollKeyboard();
int RdosReadKeyboard();

void RdosSetCursorPosition(int Row, int Col);
void RdosWriteString(const char *Buf);
int RdosReadLine(char *Buf, int MaxSize);
int RdosPing(long Node, long Timeout);

#ifdef __cplusplus
}
#endif

#endif



