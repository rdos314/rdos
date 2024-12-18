#ifndef _OCPPDEV_H
#define _OCPPDEV_H

#include "str.h"
#include "websock.h"
#include "httpfact.h"
#include "httpsfact.h"
#include "json.h"
#include "rdoslog.h"

class TOcppNotify
{
friend class TOcppSocketServer;
public:
    TOcppNotify();
    virtual ~TOcppNotify();

    void (*OnState)(TOcppNotify *Server, const char *state);
    void (*OnStart)(TOcppNotify *Server, int val);
    void (*OnStop)(TOcppNotify *Server, int val);
    void (*OnData)(TOcppNotify *Server);
    void (*OnKey)(TOcppNotify *Server, const char *key, bool rdonly, const char *value);

    double GetVoltage(int phase);
    double GetCurrent(int phase);
    int GetStartEnergy();
    int GetCurrentEnergy();
    int GetEnergy();
    bool IsCharging();

    void GetConfiguration();
    void LimitCurrent(int conn, double val);
    void LimitPower(int conn, double val);
    void ChangeConfiguration(const char *key, const char *value);

protected:
    void NotifyState(const char *State);
    void NotifyStart(int val);
    void NotifyStop(int val);
    void NotifyVoltage(int Phase, double val);
    void NotifyCurrent(int Phase, double val);
    void NotifyEnergy(int val);
    void NotifyNewData();
    void NotifyKey(const char *key, bool rdonly, const char *value);

    TOcppSocketServer *FServer;

    bool FCharging;
    double FVoltage[3];
    double FCurrent[3];
    int FStartEnergy;
    int FCurrEnergy;
    TString FState;
};

class TOcppSocketServerFactory : public THttpSocketServerFactory, public TOcppNotify
{
public:
    TOcppSocketServerFactory(int Port, int MaxConnections, int BufferSize);
    virtual ~TOcppSocketServerFactory();

    virtual TSocketServer *Create(TTcpSocket *Socket);
};

class TOcppSslSocketServerFactory : public THttpsSocketServerFactory, public TOcppNotify
{
public:
    TOcppSslSocketServerFactory(int Port, int MaxConnections, int BufferSize);
    ~TOcppSslSocketServerFactory();

    virtual TSocketServer *Create(TTcpSocket *Socket);
};

class TOcppSocketServer : public TWebSocketServer
{
public:
    TOcppSocketServer(TOcppNotify *Factory, const char *Name, int StackSize, TTcpSocket *Socket);
    virtual ~TOcppSocketServer();

    void SendReply(TJsonDocument *json);
    void SendReq(int Seq, const char *Action, TJsonDocument *json);

    void SetZone(int diff);
    void LimitCurrent(int conn, double val);
    void LimitPower(int conn, double val);
    void GetConfiguration();
    void GetCompositeSchedule();
    void ClearChargingProfile();
    void ChangeConfiguration(const char *key, const char *value);

protected:
    void SetChargingProfile(int conn, const char *unit, double val);

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

    void HandleBootNotification(TJsonDocument *doc);
    void HandleStatus(TJsonDocument *doc);
    void HandleHeartbeat(TJsonDocument *doc);
    void HandleAuthorize(TJsonDocument *doc);
    void HandleStartTransaction(TJsonDocument *doc);
    void HandleStopTransaction(TJsonDocument *doc);
    void HandleMeterValues(TJsonDocument *doc);
    void ReplyBootNotification();
    void NotifyJsonReq(char *str);

    void HandleConfiguration(TJsonDocument *doc);

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
    TString FReq;

    int FSeq;

    TOcppNotify *FFactory;
    TRdosLogThread *FLogDev;
    TRdosLog *FMsgLog;

    int FUtcDiff;

    int FPollCount;
    long FTimeout;
    bool FBootReq;
};

#endif
