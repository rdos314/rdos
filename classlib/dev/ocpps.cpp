/*####################################  ocpps.CPP                      #################################################
##    Description: ocpp ssl class                                                ##
##                                                                                                                  ##
##    Created....: 18-11-29 le                                                        Printed...: 90-10-25 an      ##
####################################################################################################################*/

#include <stdio.h>
#include "rdos.h"
#include "file.h"
#include "ocpps.h"

#define STATE_UNKNOWN      0
#define STATE_FAULT        1
#define STATE_AVAILABLE    2
#define STATE_PREPARE      3
#define STATE_CHARGE       4
#define STATE_FINISH       5
#define STATE_SUSP_EV      6
#define STATE_SUSP_EVSE    7
#define STATE_RESERVED     8
#define STATE_UNAVAILABLE  9

#define MAX_LOG_FILES                   50
#define MAX_FILE_SIZE                   256 * 1024

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
    return new TOcppSocketServer("OCPP", 0x10000, Socket);
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
TOcppSocketServer::TOcppSocketServer(const char *Name, int StackSize, TTcpSocket *Socket)
  : TWebSocketServer(Name, StackSize, Socket)
{
    FBootReq = false;
    FUtcDiff = 0;

    FLogDev = 0;
    FMsgLog = 0;
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
    TJsonCollection *info;

    TJsonDocument *json = new TJsonDocument;
    root = json->CreateRoot();
    root->AddInt("transactionId", 123);
    info = root->AddCollection("idTagInfo");
    info->AddString("status", "Accepted");
    SendReply(json);

    delete json;
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
    TJsonCollection *info;

    TJsonDocument *json = new TJsonDocument;
    root = json->CreateRoot();
    info = root->AddCollection("idTagInfo");
    info->AddString("status", "Accepted");
    SendReply(json);

    delete json;
}

/*##################  TOcppSocketServer::UpdateMeter ############################
*   Purpose....: Update meter value                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
long long TOcppSocketServer::UpdateMeter(TJsonCollection *root)
{
    TJsonArrayCollection *values;
    TJsonArrayCollection *sample;
    TJsonObject *obj;
    int i;
    int count;
    TString valstr;
    const char *ptr;
    long long val;
    bool use;
    bool kwh;

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
                        obj = sample->GetObj("measurand");
                        
                        if (obj)
                        {
                            valstr = obj->GetText();
                            ptr = valstr.GetData();
//                            FLog.Write(TLog::DEBUG, "UpdateMeter", "Measurand: %s", ptr);

                            if (strstr(ptr, "Energy") == 0)
                                use = false;
                            else
                                use = true;
                        }
                        else
                            use = true;

                        if (use)
                        {
                            obj = sample->GetObj("location");
                        
                            if (obj)
                            {
                                valstr = obj->GetText();
                                ptr = valstr.GetData();
//                                FLog.Write(TLog::DEBUG, "UpdateMeter", "Location: %s", ptr);

                                if (strstr(ptr, "Outlet") == 0)
                                    use = false;
                            }
                        }

                        if (use)
                        {
                            obj = sample->GetObj("format");
                        
                            if (obj)
                            {
                                valstr = obj->GetText();
                                ptr = valstr.GetData();
//                                FLog.Write(TLog::DEBUG, "UpdateMeter", "Format: %s", ptr);

                                if (strstr(ptr, "Raw") == 0)
                                    use = false;
                            }
                        }


                        if (use)
                        {
                            obj = sample->GetObj("unit");
                        
                            if (obj)
                            {
                                valstr = obj->GetText();
                                ptr = valstr.GetData();
//                                FLog.Write(TLog::DEBUG, "UpdateMeter", "Unit: %s", ptr);

                                if (strstr(ptr, "Wh"))
                                    kwh = false;
                                else if (strstr(ptr, "kWh"))
                                    kwh = true;
                                else
                                    use = false;
                            }
                        }

                        if (use)
                        {
                            obj = sample->GetObj("value");
                        
                            if (obj)
                            {
                                valstr = obj->GetText();
                                ptr = valstr.GetData();
//                                FLog.Write(TLog::DEBUG, "UpdateMeter", "Value: %s", ptr);
                                val = atoll(ptr);
                                if (kwh)
                                    return val * 100;
                                else
                                    return val / 10;
                            }
                        }
                    }
                }
            }
        }
    }

    return 0;

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
void TOcppSocketServer::HandleMeterValues(TJsonCollection *root)
{
    TJsonCollection *values = root->GetCollection("meterValue");
    TJsonCollection *sample;
    TJsonObject *obj;
    TString valstr;
    const char *ptr;

    if (values)
    {
        sample = values->GetCollection("sampledValue");

        if (sample)
        {
            obj = sample->GetObj("value");
            if (obj)
            {
                valstr = obj->GetText();
                ptr = valstr.GetData();
                printf("Meter: %s Wh", ptr);
            }
        }
    }
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

        if (id == 0)
            HandleMeterValues(root);
        else
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
    TJsonDocument *json;

    json = new TJsonDocument(str);

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

    str.printf("[2,\r\n\"%d\", \"%s\",\r\n", seq, action);
    json->Write(jsonstr);
    str += jsonstr;
    str += "]";

    LogMsg("W", str.GetData());

    SendText(str.GetData());
}
