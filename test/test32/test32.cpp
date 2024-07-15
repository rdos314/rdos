#include <string.h>
#include <stdio.h>
#include <stdlib.h>

#include "rdos.h"
#include "keyboard.h"
#include "sockobj.h"
#include "json.h"
#include "str.h"

TString FWanIp;
TString FImei;
TString FImsi;
TString FNetState;
TString FSimState;
TString FCellId;
TString FOperator;
TString FConType;
TString FBand;

static void HandleGzipJson(TJsonDocument *json)
{
    TJsonCollection *root = json->GetRoot();
    TJsonCollection *cache = 0;
    TJsonCollection *coll;
    TJsonArrayCollection *cell;
    TString str;
    int ival;
    int signal;
    int rsrp;
    double rsrq;
    double sinr;
    double temp;

    if (root)
        cache = root->GetCollection("cache");

    if (cache)
    {
        str = cache->GetText("imei", FImei.GetData());
        if (str != FImei)
        {
            FImei = str;
            str = "IMEI: " + FImei; 
        }        

        str = cache->GetText("imsi", FImsi.GetData());
        if (str != FImsi)
        {
            FImsi = str;
            str = "IMSI: " + FImsi; 
        }        

        coll = cache->GetCollection("cell_info");
        if (coll && coll->IsArray())
        {
            cell = (TJsonArrayCollection *)coll;
            str = cell->GetText("cellid", FCellId.GetData());
            if (str != FCellId)
            {
                FCellId = str;
                str = "Cell Id: " + FCellId; 
            }        
        }

        str = cache->GetText("band_str", FNetState.GetData());
        if (str != FNetState)
        {
            FNetState = str;
            str = "Band: " + FNetState; 
        }        

        ival = cache->GetInt("sim", 0);
        str.printf("%d", ival);
        if (str != FSimState)
        {
            FSimState = str;
            str = "SimState: " + FSimState; 
        }        

        str = cache->GetText("operator", FOperator.GetData());
        if (str != FOperator)
        {
            FOperator = str;
            str = "Operator: " + FOperator; 
        }        

        signal = cache->GetInt("rssi_value", 0);
        rsrp = cache->GetInt("rsrp_value", 0);
        rsrq = cache->GetInt("rsrq_value", 0);
        sinr = cache->GetInt("sinr_value", 0);

        temp = (double)cache->GetInt("temperature", 0) / 10.0;
    }            
}

void main()
{
    TFile file("udp.txt");
    int size = file.GetSize();
    char *buf = new char[size + 1];
    TJsonDocument *json;

    file.Read(buf, size);
    buf[size] = 0;

    json = new TJsonDocument(buf);
    HandleGzipJson(json);
    delete json;

    RdosTestGate("");
}



