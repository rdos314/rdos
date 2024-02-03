#ifndef _OCPPS_H
#define _OCPPS_H

#include "str.h"
#include "websock.h"
#include "httpsfact.h"
#include "json.h"
#include "rdoslog.h"

class TOcppSslSocketServerFactory : public THttpsSocketServerFactory
{
friend class TOcppSocketServer;
public:
    TOcppSslSocketServerFactory(int Port, int MaxConnections, int BufferSize);
    ~TOcppSslSocketServerFactory();

    virtual TSocketServer *Create(TTcpSocket *Socket);

    void (*OnOnline)(TOcppSslSocketServerFactory *Server);
    void (*OnOffline)(TOcppSslSocketServerFactory *Server);
    void (*OnState)(TOcppSslSocketServerFactory *Server, const char *State);
    void (*OnStart)(TOcppSslSocketServerFactory *Server, int val);
    void (*OnStop)(TOcppSslSocketServerFactory *Server, int val);
    void (*OnVoltage)(TOcppSslSocketServerFactory *Server, int Phase, double Val);
    void (*OnCurrent)(TOcppSslSocketServerFactory *Server, int Phase, double Val);
    void (*OnEnergy)(TOcppSslSocketServerFactory *Server, int Val);

    void LimitCurrent(int conn, double val);

protected:
    void NotifyOnline();
    void NotifyOffline();
    void NotifyState(const char *State);
    void NotifyStart(int val);
    void NotifyStop(int val);
    void NotifyVoltage(int Phase, double val);
    void NotifyCurrent(int Phase, double val);
    void NotifyEnergy(int val);

    TOcppSocketServer *FServer;
};

class TOcppSocketServer : public TWebSocketServer
{
public:
    TOcppSocketServer(TOcppSslSocketServerFactory *Factory, const char *Name, int StackSize, TTcpSocket *Socket);
    virtual ~TOcppSocketServer();

    void SendReply(TJsonDocument *json);
    void SendReq(int Seq, const char *Action, TJsonDocument *json);

    void SetZone(int diff);
    void LimitCurrent(int conn, double val);

protected:
    void SetChargingProfile(int conn, const char *unit, double val);

    void NotifyOnline();
    void NotifyOffline();
    void NotifyVoltage(const char *phase, const char *unit, const char *data);
    void NotifyCurrent(const char *phase, const char *unit, const char *data);
    void NotifyEnergy(const char *unit, const char *data);

    void StartLog();
    void StopLog();
    void LogMsg(const char *Dir, const char *Msg);

    int DecodePhase(const char *phase);
    void NotifyData(const char *param, const char *unit, const char *data);
    void NotifyData(const char *param, const char *phase, const char *unit, const char *data);

    void UpdateMeter(TJsonCollection *root);
    void HandleMeterValues(TJsonCollection *root);

    void HandleBootNotification(TJsonDocument *doc);
    void HandleStatus(TJsonDocument *doc);
    void HandleHeartbeat(TJsonDocument *doc);
    void HandleAuthorize(TJsonDocument *doc);
    void HandleStartTransaction(TJsonDocument *doc);
    void HandleStopTransaction(TJsonDocument *doc);
    void HandleMeterValues(TJsonDocument *doc);
    void ReplyBootNotification();
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

    int FSeq;

    TOcppSslSocketServerFactory *FFactory;
    TRdosLogThread *FLogDev;
    TRdosLog *FMsgLog;

    int FUtcDiff;

    int FPollCount;
    long FTimeout;
    bool FBootReq;
};

#endif
