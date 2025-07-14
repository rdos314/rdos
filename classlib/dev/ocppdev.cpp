/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2025, Leif Ekblad
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# The author of this program may be contacted at leif@rdos.net
#
# ocppdev.cpp
# OCPP class
#
########################################################################*/

#include <stdio.h>
#include "rdos.h"
#include "file.h"
#include "ocppdev.h"

#define MAX_LOG_FILES                   50
#define MAX_FILE_SIZE                   256 * 1024

/*##################  UuidToStr  #############
*   Purpose....: Convert UUID to string                                                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-10-02 le                                                #
*##########################################################################*/
static void UuidToStr(const char *uuid, char *str)
{
    int ival;
    int *ip;
    short int sval;
    short int *sp;

    ip = (int *)uuid;
    ival = *ip;
    sprintf(str, "%08lX-", ival);

    sp = (short int *)(uuid + 4);
    sval = *sp;
    sprintf(str+9, "%04hX-", sval);

    sp = (short int *)(uuid + 6);
    sval = *sp;
    sprintf(str+14, "%04hX-", sval);

    sp = (short int *)(uuid + 8);
    sval = RdosSwapShort(*sp);
    sprintf(str+19, "%04hX-", sval);

    sp = (short int *)(uuid + 10);
    sval = RdosSwapShort(*sp);
    sprintf(str+24, "%04hX", sval);

    sp = (short int *)(uuid + 12);
    sval = RdosSwapShort(*sp);
    sprintf(str+28, "%04hX", sval);

    sp = (short int *)(uuid + 14);
    sval = RdosSwapShort(*sp);
    sprintf(str+32, "%04hX", sval);
}

/*##########################################################################
#
#   Name       : TOcppNotify::TOcppNotify
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOcppNotify::TOcppNotify()
{
    int i;

    for (i = 0; i < 3; i++)
    {
        FVoltage[i] = 0.0;
        FCurrent[i] = 0.0;
    }

    FStartEnergy = 0;
    FCurrEnergy = 0;
    FCharging = false;

    OnState = 0;
    OnStart = 0;
    OnStop = 0;
    OnData = 0;
    OnKey = 0;


    FServer = 0;
}

/*##########################################################################
#
#   Name       : TOcppNotify::~TOcppNotify
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOcppNotify::~TOcppNotify()
{
}

/*##########################################################################
#
#   Name       : TOcppNotify::GetConfiguration
#
#   Purpose....: Get configuration
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppNotify::GetConfiguration()
{
    if (FServer)
        FServer->GetConfiguration();
}

/*##########################################################################
#
#   Name       : TOcppNotify::LimitCurrent
#
#   Purpose....: Limit current
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppNotify::LimitCurrent(int conn, double val)
{
    if (FServer)
        FServer->LimitCurrent(conn, val);
}

/*##########################################################################
#
#   Name       : TOcppNotify::LimitPower
#
#   Purpose....: Limit power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppNotify::LimitPower(int conn, double val)
{
    if (FServer)
        FServer->LimitPower(conn, val);
}

/*##########################################################################
#
#   Name       : TOcppNotify::ChangeConfiguration
#
#   Purpose....: Change configuration
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppNotify::ChangeConfiguration(const char *key, const char *value)
{
    if (FServer)
        FServer->ChangeConfiguration(key, value);
}

/*##########################################################################
#
#   Name       : TOcppNotify::GetVoltage
#
#   Purpose....: Get voltage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TOcppNotify::GetVoltage(int phase)
{
    return FVoltage[phase];
}

/*##########################################################################
#
#   Name       : TOcppNotify::GetCurrent
#
#   Purpose....: Get current
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
double TOcppNotify::GetCurrent(int phase)
{
    return FCurrent[phase];
}

/*##########################################################################
#
#   Name       : TOcppNotify::IsCharging
#
#   Purpose....: Is charging?
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
bool TOcppNotify::IsCharging()
{
    return FCharging;
}

/*##########################################################################
#
#   Name       : TOcppNotify::GetStartEnergy
#
#   Purpose....: Get start energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TOcppNotify::GetStartEnergy()
{
    return FStartEnergy;
}

/*##########################################################################
#
#   Name       : TOcppNotify::GetCurrentEnergy
#
#   Purpose....: Get current energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TOcppNotify::GetCurrentEnergy()
{
    return FCurrEnergy;
}

/*##########################################################################
#
#   Name       : TOcppNotify::GetEnergy
#
#   Purpose....: Get energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
int TOcppNotify::GetEnergy()
{
    return FCurrEnergy - FStartEnergy;
}

/*##########################################################################
#
#   Name       : TOcppNotify::NotifyState
#
#   Purpose....: Notify state
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppNotify::NotifyState(const char *State)
{
    if (!strcmp(State, "Charging"))
        FCharging = true;
    else if (!strcmp(State, "Preparing"))
        FCharging = true;
    else
        FCharging = false;

    if (OnState)
        (*OnState)(this, State);
}

/*##########################################################################
#
#   Name       : TOcppNotify::NotifyStart
#
#   Purpose....: Notify start
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppNotify::NotifyStart(int val)
{
    FStartEnergy = val;
    FCurrEnergy = val;
    FCharging = true;

    if (OnStart)
        (*OnStart)(this, val);
}

/*##########################################################################
#
#   Name       : TOcppNotify::NotifyStop
#
#   Purpose....: Notify stop
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppNotify::NotifyStop(int val)
{
    FCurrEnergy = val;
    FCharging = false;

    if (OnStop)
        (*OnStop)(this, val);
}

/*##########################################################################
#
#   Name       : TOcppNotify::NotifyVoltage
#
#   Purpose....: Notify voltage
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppNotify::NotifyVoltage(int phase, double val)
{
    FVoltage[phase] = val;
}

/*##########################################################################
#
#   Name       : TOcppNotify::NotifyCurrent
#
#   Purpose....: Notify current
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppNotify::NotifyCurrent(int phase, double val)
{
    FCurrent[phase] = val;
}

/*##########################################################################
#
#   Name       : TOcppNotify::NotifyEnergy
#
#   Purpose....: Notify energy
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppNotify::NotifyEnergy(int val)
{
    FCurrEnergy = val;
}

/*##########################################################################
#
#   Name       : TOcppNotify::NotifyNewData
#
#   Purpose....: Notify new data
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppNotify::NotifyNewData()
{
    if (OnData)
        (*OnData)(this);
}

/*##########################################################################
#
#   Name       : TOcppNotify::NotifyKey
#
#   Purpose....: Notify key
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppNotify::NotifyKey(const char *key, bool rdonly, const char *value)
{
    if (OnKey)
        (*OnKey)(this, key, rdonly, value);
}

/*##########################################################################
#
#   Name       : TOcppSslSocketServerFactory::TOcppSslSocketServerFactory
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOcppSslSocketServerFactory::TOcppSslSocketServerFactory(int Port, int MaxConnections, int BufferSize)
  : THttpsSocketServerFactory(Port, MaxConnections, BufferSize)
{
    Start("OCPP Listen", 0x10000);
}

/*##########################################################################
#
#   Name       : TOcppSslSocketServerFactory::~TOcppSslSocketServerFactory
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOcppSslSocketServerFactory::~TOcppSslSocketServerFactory()
{
}

/*##########################################################################
#
#   Name       : TOcppSslSocketServerFactory::Create
#
#   Purpose....: Create web socket server
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *TOcppSslSocketServerFactory::Create(TTcpSocket *Socket)
{
    FServer = new TOcppSocketServer(this, "OCPP", 0x10000, Socket);
    return FServer;
}

/*##########################################################################
#
#   Name       : TOcppSocketServerFactory::TOcppSocketServerFactory
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOcppSocketServerFactory::TOcppSocketServerFactory(int Port, int MaxConnections, int BufferSize)
  : THttpSocketServerFactory(Port, MaxConnections, BufferSize)
{
    Start("OCPP Listen", 0x10000);
}

/*##########################################################################
#
#   Name       : TOcppSocketServerFactory::~TOcppSocketServerFactory
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOcppSocketServerFactory::~TOcppSocketServerFactory()
{
}

/*##########################################################################
#
#   Name       : TOcppSocketServerFactory::Create
#
#   Purpose....: Create web socket server
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TSocketServer *TOcppSocketServerFactory::Create(TTcpSocket *Socket)
{
    FServer = new TOcppSocketServer(this, "OCPP", 0x10000, Socket);
    return FServer;
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::TOcppSocketServer
#
#   Purpose....: Constructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOcppSocketServer::TOcppSocketServer(TOcppNotify *Factory, const char *Name, int StackSize, TTcpSocket *Socket)
  : TWebSocketServer(Name, StackSize, Socket)
{
    FBootReq = false;
    FUtcDiff = 0;
    FSeq = 0;

    FLogDev = 0;
    FMsgLog = 0;
    FFactory = Factory;
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::~TOcppSocketServer
#
#   Purpose....: Destructor
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TOcppSocketServer::~TOcppSocketServer()
{
    StopLog();
}

/*##################  TOcppSocketServer::StartLog  ########################
 *   Purpose....: Start log                                                    #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-09-10 le                                                #
 *##########################################################################*/
void TOcppSocketServer::StartLog()
{
    FLogDev = new TRdosLogThread("d:/occp", MAX_LOG_FILES, MAX_FILE_SIZE, "OCPP Log");
    FMsgLog = new TRdosLog(FLogDev, "");

    FMsgLog->Log(0, "", "Connected");
}

/*##################  TOcppSocketServer::StopLog  ########################
 *   Purpose....: Stop log                                                    #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-09-10 le                                                #
 *##########################################################################*/
void TOcppSocketServer::StopLog()
{
    if (FMsgLog)
    {
        FMsgLog->Log(0, "", "Disconnected");

        delete FMsgLog;
        FMsgLog = 0;
    }

    if (FLogDev)
    {
        FLogDev->Stop();
        delete FLogDev;
        FLogDev = 0;
    }
}

/*##################  TOcppSocketServer::LogMsg  ########################
 *   Purpose....: Log message                                                    #
 *   In params..: *                                                          #
 *   Out params.: *                                                          #
 *   Returns....: *                                                          #
 *   Created....: 96-09-10 le                                                #
 *##########################################################################*/
void TOcppSocketServer::LogMsg(const char *Dir, const char *Msg)
{
    TString str(Dir);

    str += "\r\n";
    str += Msg;

    if (Dir[0] == 'R')
        str += "\r\n";

    if (FMsgLog)
        FMsgLog->Log(0, "", str.GetData());
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::SetChargingProfile
#
#   Purpose....: Set charging profile
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::SetChargingProfile(int conn, const char *unit, double val)
{
    TJsonDocument *json = new TJsonDocument;
    TJsonCollection *root = json->CreateRoot();
    TJsonCollection *prof;
    TJsonCollection *sched;
    TJsonArrayCollection *period;
    TDateTime from(2024, 1, 1);
    TDateTime to(2061, 1, 1);
    TDateTime now;

    root->AddInt("connectorId", 1);

    prof = root->AddCollection("csChargingProfiles");
    prof->AddInt("chargingProfileId", 100);
    prof->AddInt("stackLevel", 0);
//    prof->AddInt("transactionId", 123);
    prof->AddString("chargingProfilePurpose", "TxDefaultProfile");
    prof->AddString("chargingProfileKind", "Recurring");
    prof->AddString("RecurrencyKindType", "Daily");
//    prof->AddDateTimeZone("validFrom", from, FUtcDiff);
//    prof->AddDateTimeZone("validTo", to, FUtcDiff);

    sched = prof->AddCollection("chargingSchedule");
    sched->AddDateTimeZone("startSchedule", now, FUtcDiff);
    sched->AddInt("duration", 86400);
    sched->AddString("chargingRateUnit", "A");

    period = sched->AddArrayCollection("chargingSchedulePeriod");
    period->AddInt("startPeriod", 0);
    period->AddInt("limit", 5);

    period->AddArray();
    period->AddInt("startPeriod", 3600);
    period->AddInt("limit", 6);

    FSeq++;
    SendReq(FSeq, "SetChargingProfile", json);
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::GetConfiguration
#
#   Purpose....: Get configuration
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::GetConfiguration()
{
    TJsonDocument *json = new TJsonDocument;
    TJsonCollection *root = json->CreateRoot();

    FSeq++;
    SendReq(FSeq, "GetConfiguration", json);
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::GetCompositeSchedule
#
#   Purpose....: Get composite schedule
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::GetCompositeSchedule()
{
    TJsonDocument *json = new TJsonDocument;
    TJsonCollection *root = json->CreateRoot();

    root->AddInt("connectorId", 0);
    root->AddInt("duration", 3600);
    root->AddString("chargingRateUnit", "A");

    FSeq++;
    SendReq(FSeq, "GetCompositeSchedule", json);
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::ClearChargingProfile
#
#   Purpose....: Clear charging profile
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::ClearChargingProfile()
{
    TJsonDocument *json = new TJsonDocument;
    TJsonCollection *root = json->CreateRoot();

    root->AddInt("connectorId", 1);

    FSeq++;
    SendReq(FSeq, "ClearChargingProfile", json);
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::LimitCurrent
#
#   Purpose....: Limit current
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::LimitCurrent(int conn, double val)
{
    SetChargingProfile(conn, "A", val);
}


/*##########################################################################
#
#   Name       : TOcppSocketServer::LimitPower
#
#   Purpose....: Limit power
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::LimitPower(int conn, double val)
{
    SetChargingProfile(conn, "W", val);
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::ChangeConfiguration
#
#   Purpose....: Change configuration
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::ChangeConfiguration(const char *key, const char *value)
{
    TJsonDocument *json = new TJsonDocument;
    TJsonCollection *root = json->CreateRoot();

    root->AddString("key", key);
    root->AddString("value", value);

    FSeq++;
    SendReq(FSeq, "ChangeConfiguration", json);
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::SetZone
#
#   Purpose....: Set time zone
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::SetZone(int diff)
{
    FUtcDiff = diff;
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::GetProtocol
#
#   Purpose....: Get protocol to use
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
const char *TOcppSocketServer::GetProtocol()
{
    int i;
    int count = FProtocols->GetArgCount();
    TString str;

    for (i = 0; i < count; i++)
    {
        str = FProtocols->GetArg(i);

        if (strstr(str.GetData(), "ocpp1.6"))
            return "ocpp1.6";
    }

    return 0;
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::HandleBootNotification
#
#   Purpose....: Handle boot notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::HandleBootNotification(TJsonDocument *doc)
{
    ReplyBootNotification();
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::ReplyBootNotification
#
#   Purpose....: Reply to boot notification
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::ReplyBootNotification()
{
    TDateTime now;
    TJsonDocument *json = new TJsonDocument;
    TJsonCollection *root = json->CreateRoot();

    root->AddDateTimeZone("currentTime", now, FUtcDiff);

    root->AddInt("interval", 15);
    root->AddString("status", "Accepted");

    SendReply(json);

    delete json;

    FBootReq = false;
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::HandleHeartbeat
#
#   Purpose....: Handle heartbeat
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::HandleHeartbeat(TJsonDocument *doc)
{
    TDateTime now;
    TJsonDocument *json = new TJsonDocument;
    TJsonCollection *root = json->CreateRoot();

    root->AddDateTime("currentTime", now, true);

    SendReply(json);

    delete json;
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::HandleStatus
#
#   Purpose....: Handle status
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::HandleStatus(TJsonDocument *doc)
{
    TJsonCollection *root = doc->GetRoot();
    long long cid = root->GetInt("connectorId", 0);
    const char *state = root->GetText("status", "");
    TJsonDocument *json = new TJsonDocument;

    root = json->CreateRoot();
    SendReply(json);

    delete json;

    if (cid)
        FFactory->NotifyState(state);
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::HandleAuthorize
#
#   Purpose....: Handle authorize
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::HandleAuthorize(TJsonDocument *doc)
{
    TJsonCollection *root = doc->GetRoot();
    const char *id = root->GetText("idTag", "");
    TJsonCollection *info;

    TJsonDocument *json = new TJsonDocument;
    root = json->CreateRoot();
    info = root->AddCollection("idTagInfo");
    info->AddString("status", "Accepted");
    SendReply(json);

    delete json;
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::HandleStartTransaction
#
#   Purpose....: Handle start transaction
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::HandleStartTransaction(TJsonDocument *doc)
{
    TJsonCollection *root = doc->GetRoot();
    const char *id = root->GetText("idTag", "");
    long meter = (int)root->GetInt("meterStart", 0);
    TJsonCollection *info;

    TJsonDocument *json = new TJsonDocument;
    root = json->CreateRoot();
    root->AddInt("transactionId", 123);
    info = root->AddCollection("idTagInfo");
    info->AddString("status", "Accepted");
    SendReply(json);

    delete json;

    FFactory->NotifyStart(meter);
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::HandleStopTransaction
#
#   Purpose....: Handle stop transaction
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::HandleStopTransaction(TJsonDocument *doc)
{
    TJsonCollection *root = doc->GetRoot();
    const char *id = root->GetText("idTag", "");
    long meter = (int)root->GetInt("meterStop", 0);
    TJsonCollection *info;

    TJsonDocument *json = new TJsonDocument;
    root = json->CreateRoot();
    info = root->AddCollection("idTagInfo");
    info->AddString("status", "Accepted");
    SendReply(json);

    delete json;

    FFactory->NotifyStop(meter);
}

/*##################  TOcppSocketServer::DecodePhase ############################
*   Purpose....: Decode phase                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TOcppSocketServer::DecodePhase(const char *phase)
{
    if (!strcmp(phase, "L1"))
        return 0;

    if (!strcmp(phase, "L2"))
        return 1;

    if (!strcmp(phase, "L3"))
        return 2;

    return -1;
}

/*##################  TOcppSocketServer::NotifyVoltage ############################
*   Purpose....: Notify voltage                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TOcppSocketServer::NotifyVoltage(const char *phase, const char *unit, const char *data)
{
    int ph = DecodePhase(phase);
    double val;

    if (!strcmp(unit, "V"))
    {
        val = atof(data);
        FFactory->NotifyVoltage(ph, val);
    }
}

/*##################  TOcppSocketServer::NotifyCurrent ############################
*   Purpose....: Notify current                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TOcppSocketServer::NotifyCurrent(const char *phase, const char *unit, const char *data)
{
    int ph = DecodePhase(phase);
    double val;

    if (!strcmp(unit, "A"))
    {
        val = atof(data);
        FFactory->NotifyCurrent(ph, val);
    }
}

/*##################  TOcppSocketServer::NotifyData ############################
*   Purpose....: Notify data                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TOcppSocketServer::NotifyData(const char *param, const char *phase, const char *unit, const char *data)
{
    if (strstr(param, "Voltage"))
        NotifyVoltage(phase, unit, data);
    else if (strstr(param, "Current"))
        NotifyCurrent(phase, unit, data);
}

/*##################  TOcppSocketServer::NotifyEnergy ############################
*   Purpose....: Notify energy                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TOcppSocketServer::NotifyEnergy(const char *unit, const char *data)
{
    int val = 0;

    if (!strcmp(unit, "Wh"))
        val = atoi(data);

    if (!strcmp(unit, "kWh"))
        val = 1000 * atoi(data);

    if (val > 0)
        FFactory->NotifyEnergy(val);
}

/*##################  TOcppSocketServer::NotifyData ############################
*   Purpose....: Notify data                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TOcppSocketServer::NotifyData(const char *param, const char *unit, const char *data)
{
    if (strstr(param, "Energy"))
        NotifyEnergy(unit, data);
}

/*##################  TOcppSocketServer::UpdateMeter ############################
*   Purpose....: Update meter value                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TOcppSocketServer::UpdateMeter(TJsonCollection *root)
{
    TJsonArrayCollection *values;
    TJsonArrayCollection *sample;
    TJsonObject *obj;
    int i;
    int count;
    TString valstr;
    TString phase;
    TString param;
    TString unit;
    const char *ptr;
    bool use;
    bool data = false;

    if (root)
    {
        values = (TJsonArrayCollection *)root->GetCollection("meterValue");
        if (values)
        {
            values->SelectArray(0);

            sample = (TJsonArrayCollection *)values->GetCollection("sampledValue");

            if (sample)
            {
                count = sample->GetArrayCount();

                for (i = 0; i < count; i++)
                {
                    sample->SelectArray(i);

                    if (sample)
                    {
                        phase.Reset();

                        obj = sample->GetObj("location");

                        if (obj)
                        {
                            valstr = obj->GetText();
                            ptr = valstr.GetData();
                            if (strstr(ptr, "Outlet"))
                                use = true;
                            else
                                use = false;
                        }
                        else
                            use = false;

                        if (use)
                        {
                            obj = sample->GetObj("measurand");

                            if (obj)
                                param = obj->GetText();
                            else
                                use = false;
                        }

                        if (use)
                        {
                            obj = sample->GetObj("phase");

                            if (obj)
                                phase = obj->GetText();
                        }

                        if (use)
                        {
                            obj = sample->GetObj("unit");

                            if (obj)
                                unit = obj->GetText();
                            else
                                use = false;
                        }

                        if (use)
                        {
                            obj = sample->GetObj("value");

                            if (obj)
                            {
                                data = true;
                                valstr = obj->GetText();
                                if (phase.GetSize())
                                    NotifyData(param.GetData(), phase.GetData(), unit.GetData(), valstr.GetData());
                                else
                                    NotifyData(param.GetData(), unit.GetData(), valstr.GetData());
                            }
                        }
                    }
                }
            }
        }
    }

    if (data)
        FFactory->NotifyNewData();
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::HandleMeterValues
#
#   Purpose....: Handle meter values
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::HandleMeterValues(TJsonDocument *doc)
{
    TJsonCollection *root = doc->GetRoot();
    TJsonObject *obj;
    int id;
    TJsonDocument *json = new TJsonDocument;

    obj = root->GetObj("connectorId");
    if (obj)
    {
        id = (int)obj->GetInt();

        if (id)
            UpdateMeter(root);
    }

    root = json->CreateRoot();
    SendReply(json);

    delete json;
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::NotifyJsonReq
#
#   Purpose....: Notify json req message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::NotifyJsonReq(char *str)
{
    const char *action = FAction.GetData();
    bool handled = false;
    TJsonDocument *json;

    json = new TJsonDocument(str);

    if (!strcmp(action, "BootNotification"))
    {
        HandleBootNotification(json);
        handled = true;
    }

    if (!handled && !strcmp(action, "Heartbeat"))
    {
        HandleHeartbeat(json);
        handled = true;
    }

    if (!handled && !strcmp(action, "StatusNotification"))
    {
        HandleStatus(json);
        handled = true;
    }

    if (!handled && !strcmp(action, "Authorize"))
    {
        HandleAuthorize(json);
        handled = true;
    }

    if (!handled && !strcmp(action, "StartTransaction"))
    {
        HandleStartTransaction(json);
        handled = true;
    }

    if (!handled && !strcmp(action, "StopTransaction"))
    {
        HandleStopTransaction(json);
        handled = true;
    }

    if (!handled && !strcmp(action, "MeterValues"))
    {
        HandleMeterValues(json);
        handled = true;
    }

    delete json;
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::HandleConfiguration
#
#   Purpose....: Handle configuration
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::HandleConfiguration(TJsonDocument *doc)
{
    int i;
    int count;
    TJsonCollection *root = doc->GetRoot();
    TJsonArrayCollection *keys = (TJsonArrayCollection *)root->GetCollection("configurationKey");
    const char *key;
    bool rdonly;
    const char *value;

    if (keys && keys->IsArray())
    {
        count = keys->GetArrayCount();
        for (i = 0; i < count; i++)
        {
            keys->SelectArray(i);
            key = keys->GetText("key", "");
            rdonly = keys->GetBoolean("readonly", false);
            value = keys->GetText("value", "");
            FFactory->NotifyKey(key, rdonly, value);
        }
    }
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::NotifyJsonReply
#
#   Purpose....: Notify json reply message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::NotifyJsonReply(int seq, char *str)
{
    const char *action = FReq.GetData();
    bool handled = false;
    TJsonDocument *json;

    json = new TJsonDocument(str);

    if (!strcmp(action, "GetConfiguration"))
    {
        HandleConfiguration(json);
        handled = true;
    }
    delete json;
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::StartWebSocket
#
#   Purpose....: Start web socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::StartWebSocket()
{
    FPollCount = 0;

    StartLog();

//    ChangeConfiguration("SupervisionUrl", "ws://ocpp.rdos.se:7000/");
//    ChangeConfiguration("SecurityProfile", "1");
//    GetConfiguration();
//    GetCompositeSchedule();
//    ClearChargingProfile();
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::EndWebSocket
#
#   Purpose....: End web socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::EndWebSocket()
{
    StopLog();
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::PollWebSocket
#
#   Purpose....: Poll web socket
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::PollWebSocket()
{
    FPollCount++;

    if (FPollCount == 30)
    {
        FPollCount = 0;
        FSocket->Push();
    }
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::ReceivedText
#
#   Purpose....: Received text message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::ReceivedText(char *str)
{
    int size = strlen(str);
    int id;
    int seq;
    char *ptr;
    char *tempptr;

    if (strstr(str, "Heartbeat") == 0)
        LogMsg("R", str);

    if (str[0] != '[')
        return;

    if (str[size - 1] != ']')
        return;

    str[size - 1] = 0;
    ptr = str + 1;

    tempptr = strchr(ptr, ',');
    if (!tempptr)
        return;

    *tempptr = 0;
    id = atoi(ptr);

    if (id == 0)
        return;

    ptr = tempptr + 1;

    tempptr = strchr(ptr, '"');
    if (!tempptr)
        return;

    ptr = tempptr + 1;
    tempptr = strchr(ptr, '"');
    if (!tempptr)
        return;

    *tempptr = 0;

    if (id == 2)
    {
        FRecSeq = ptr;

        ptr = tempptr + 1;

        tempptr = strchr(ptr, '"');
        if (!tempptr)
            return;

        ptr = tempptr + 1;
        tempptr = strchr(ptr, '"');
        if (!tempptr)
            return;

        *tempptr = 0;
        FAction = ptr;
    }

    if (id == 3)
        seq = atoi(ptr);

    ptr = tempptr + 1;

    tempptr = strchr(ptr, '{');
    if (tempptr)
    {
        if (id == 2)
            NotifyJsonReq(tempptr);

        if (id == 3)
            NotifyJsonReply(seq, tempptr);
    }
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::ReceivedBinary
#
#   Purpose....: Received binary message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::ReceivedBinary(char *str, int size)
{
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::ReceivedPing
#
#   Purpose....: Received ping message
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::ReceivedPing(char *str)
{
//    LogMsg("P", str);
    SendPong(str);
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::SendReply
#
#   Purpose....: Send reply
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::SendReply(TJsonDocument *json)
{
    TString str;
    TString jsonstr;

    str.printf("[3,\r\n\"%s\",\r\n", FRecSeq.GetData());
    json->Write(jsonstr);
    str += jsonstr;
    str += "]";

    if (strstr(FAction.GetData(), "Heartbeat") == 0)
        LogMsg("W", str.GetData());

    SendText(str.GetData());
}

/*##########################################################################
#
#   Name       : TOcppSocketServer::SendReq
#
#   Purpose....: Send req
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TOcppSocketServer::SendReq(int seq, const char *action, TJsonDocument *json)
{
    TString str;
    TString jsonstr;
    char Guid[16];
    char GuidStr[60];

    RdosCreateUuid(Guid);
    UuidToStr(Guid, GuidStr);

    FReq = action;

    str.printf("[2,\r\n\"%s\", \"%s\",\r\n", GuidStr, action);
    json->Write(jsonstr);
    str += jsonstr;
    str += "]";

    LogMsg("W", str.GetData());

    SendText(str.GetData());
}
