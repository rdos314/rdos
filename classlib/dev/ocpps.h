#ifndef _OCPPS_H
#define _OCPPS_H

#include "str.h"
#include "websock.h"
#include "httpsfact.h"
#include "json.h"
#include "rdoslog.h"

class TOcppSslSocketServerFactory : public THttpsSocketServerFactory
{
public:
    TOcppSslSocketServerFactory(int Port, int MaxConnections, int BufferSize);
    ~TOcppSslSocketServerFactory();

    virtual TSocketServer *Create(TTcpSocket *Socket);
};

class TOcppSocketServer : public TWebSocketServer
{
public:
    TOcppSocketServer(const char *Name, int StackSize, TTcpSocket *Socket);
    virtual ~TOcppSocketServer();

    void SendReply(TJsonDocument *json);
    void SendReq(int Seq, const char *Action, TJsonDocument *json);

    void SetZone(int diff);
    
protected:
    void StartLog();
    void StopLog();
    void LogMsg(const char *Dir, const char *Msg);

    void HandleBootNotification(TJsonDocument *doc);
    void HandleStatusNotification(TJsonDocument *doc);
    void HandleHeartbeat(TJsonDocument *doc);
    void ReplyBootNotification(bool Defined);
    void NotifyJsonReq(char *str);
    void NotifyJsonReply(int seq, char *str);

    virtual const char *GetProtocol();
    virtual void ReceivedText(char *str);
    virtual void ReceivedBinary(char *str, int size);
    virtual void ReceivedPing(char *str);
    virtual void StartWebSocket();
    virtual void EndWebSocket();
    virtual void PollWebSocket();

    TString FRecSeq;
    TString FAction;

    TRdosLogThread *FLogDev;
    TRdosLog *FMsgLog;

    int FUtcDiff;

    int FPollCount;
    long FTimeout;
    bool FBootReq;
};

#endif
