/*#######################################################################
# MID
#
# mid.cpp
# Main MID DLL
#
########################################################################*/

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "rdos.h"
#include "ini.h"
#include "mid.h"
#include "midcust.h"
#include "str.h"
#include "discstor.h"
#include "midsave.h"
#include "midpump.h"
#include "midlong.h"
#include "midreip.h"
#include "midbit.h"
#include "midweb.h"
#include "md5.h"
#include "MidConst.h"
#include "mid.ver"

#define MAX_MID_PUMPS   128
#define CONFIG_LOG_FILENAME     "c:\\midconf.log"
#define DOWNLOAD_LOG_FILENAME    "c:\\middown.log"

#define FALSE   0
#define TRUE    !FALSE

static int HandleArr[MAX_MID_PUMPS];
static TMidCustomer *CurrCustArr[MAX_MID_PUMPS];
static TFillSave *FillSaveArr[MAX_MID_PUMPS];
static TMidPump *PumpArr[MAX_MID_PUMPS];
static int Section;
static TDisc *StoreDisc;
static TDiscStorage *SaveStore;
static TMidLongStorage *LongStore;
static TMidReceipt *MidReceipt;
static TMidBitmap *MidBitmap;

static int FiscalHandle = 0;

int NotifyCompacData(char *Msg, long *Volume, long *Amount);
int NotifyAutotankData(const char *Msg, int Size, const char *Crc, long *Volume, long *Amount, int *Price, int *Final);
int NotifyDartData(const char *Msg, int Size, long *Volume, long *Amount);
int NotifyWayneData(const char *Msg, long *Volume, long *Amount, int *Price);
int NotifyMpiData(const char *Msg, int Size, long *Volume, long *Amount, long *PulseDiff);
int NotifyTatsunoData(const char *Msg, long *Volume, long *Amount, int *Price);
int NotifyNgModbusData(int StartReg, int RegCount, const char *Msg, int Size, long *Volume, long *Amount);

int NotifyGilbarcoSpotData(const char *Msg, long *AmountOrVolume);
int NotifyGilbarcoFinalData(const char *Msg, long *Volume, long *Amount, int *Price);
int NotifyGilbarcoSpotDataLong(const char *Msg, long *AmountOrVolume);
int NotifyGilbarcoFinalDataLong(const char *Msg, long *Volume, long *Amount, int *Price);
int NotifyGilbarcoSpotDataDecimals(const char *Msg, long *AmountOrVolume, int AmountDecimals, int VisualAmountDecimals);
int NotifyGilbarcoFinalDataDecimals(const char *Msg, long *Volume, long *Amount, int *Price, int VolumeDecimals, int AmountDecimals, int VisualVolumeDecimals, int VisualAmountDecimals);
int NotifyGilbarcoSpotDataLongDecimals(const char *Msg, long *AmountOrVolume, int AmountDecimals, int VisualAmountDecimals);
int NotifyGilbarcoFinalDataLongDecimals(const char *Msg, long *Volume, long *Amount, int *Price, int VolumeDecimals, int AmountDecimals, int VisualVolumeDecimals, int VisualAmountDecimals);

int NotifyCotexSpotData(int PumpNr, const char *Msg, int Size, long *Volume, long *Amount, int *Price);
int NotifyCotexFinalData(int PumpNr, const char *Msg, int Size, long *Volume, long *Amount, int *Price);

int NotifyZapData(const char *Msg, int Size, long *Volume);
int NotifyKoppensEpsData(const char *Msg, int Size, long *Volume, long *Amount, int *Price, int *HasPrice);

int NotifyIFSFSpotData(unsigned char Fp, const char *Msg, int Size, long *Volume, long *Amount, int *Price);
int NotifyIFSFFinalData(const char *Msg, int Size, long *Volume, long *Amount);
int NotifyIFSFTransData(const char *DbField, const char *Msg, int Size, long *Volume, long *Amount);

int NotifyScheidtBachmannData(const char *Msg, int Size, long *Volume, long *Amount, int *Price);

int NotifyNuovoPignoneData(const char *Msg, long *Volume, long *Amount);

int NotifyPumaLanFinal(const char *Msg, int Size, long *Volume, long *Amount, int *Price);
int NotifyPumaLanFinalFactor(const char *Msg, int Size, long *Volume, long *Amount, int *Price, int CreditMultiplicationFactor);
int NotifyPumaLanSpot(const char *Msg, int Size, long *Volume, long *Amount);

int NotifyMidcoFinal(const char *Msg, int Size, long *Volume, long *Amount, int *Price);
int NotifyMidcoSpot(const char *Msg, int Size, long *Volume, long *Amount, int *Price);

int NotifyZSRData(const char *Msg, long *Volume, long *Amount, int VolumeDecimals, int AmountDecimals);

int NotifyHdxSpotData(const char *Msg, long *Val);
int NotifyHdxFinalData(const char *Msg, long *Volume, long *Amount);

int GetOcppBase(const char *Msg);
int NotifyOcppData(const char *Msg, long *Volume);
int NotifyOcppFinal(const char *Msg, long *base, long *final);

int NotifyDialectSpot(const char *Msg, int Address, long *Volume, int *Price);
int NotifyDialectFinal(const char *Msg, int Address, long *Volume, long *Amount, int *Price);

void SetReceiptCurrency(const char *Currency);

static unsigned short int ModuleCrc;
static char IpStr[41];
static int ForceFinal;

/*##################  LogConfigRow  ###############
*   Purpose....: Log row
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
static void LogConfigRow(const char *str)
{
    unsigned long msb, lsb;
    int year, month, day, hour, min, sec, milli, micro;
    char timestr[80];
    TFile File(CONFIG_LOG_FILENAME);

    RdosGetTime(&msb, &lsb);
    RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
    RdosDecodeLsbTics(lsb, &min, &sec, &milli, &micro);

    sprintf(timestr, "%04d-%02d-%02d %02d.%02d ", year, month, day, hour, min);

    File.SetPos(File.GetSize());
    File.Write(timestr);
    File.Write(str);
    File.Write("\r\n");
}

/*##################  LogDownloadRow  ###############
*   Purpose....: Log row
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
static void LogDownloadRow(const char *str)
{
    unsigned long msb, lsb;
    int year, month, day, hour, min, sec, milli, micro;
    char timestr[80];
    TFile File(DOWNLOAD_LOG_FILENAME);

    RdosGetTime(&msb, &lsb);
    RdosDecodeMsbTics(msb, &year, &month, &day, &hour);
    RdosDecodeLsbTics(lsb, &min, &sec, &milli, &micro);

    sprintf(timestr, "%04d-%02d-%02d %02d.%02d ", year, month, day, hour, min);

    File.SetPos(File.GetSize());
    File.Write(timestr);
    File.Write(str);
    File.Write(". Downloaded successfully from ");
    File.Write(IpStr);
    File.Write("\r\n");
}

/*##################  DllMain  ###############
*   Purpose....: DLL entrypoint                                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: i*                                                          #
*##########################################################################*/
int __stdcall DllMain(int hDll, int reason, void *reserved)
{
    int i;

    for (i = 0; i < MAX_MID_PUMPS; i++)
    {
        PumpArr[i] = 0;
        CurrCustArr[i] = 0;
        FillSaveArr[i] = 0;
        HandleArr[i] = 0;
    }

    StoreDisc = 0;
    SaveStore = 0;

    return 0;
}

/*##################  MidInit  ###############
*   Purpose....: Init MID class                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
void __export _stdcall MidInit(const char *TerminalVersion, int Disc, long FillSaveSector, long LongStorageSector, long LongStorageSize)
{
    int ModuleHandle = RdosGetCurrentDllHandle();
    int CrcHandle = RdosCreateCrc(0x8408);
    int FileHandle = RdosDuplModuleFileHandle(ModuleHandle);
    char str[101];
    char osstr[80];
    char crcstr[6];
    char *Buf;
    int Size;
    int ok;
    int major, minor, release;
    TDiscStorage *store;
    int LogHandle;
    TIniFile ini;

    ForceFinal = TRUE;

    ini.GotoSection("SYS");
    strcpy(IpStr, "213.174.89.170");
    ini.ReadVar("TAPNETIP", IpStr, 40);

    LogHandle = RdosOpenFile(CONFIG_LOG_FILENAME, 0);
    if (!LogHandle)
        LogHandle = RdosCreateFile(CONFIG_LOG_FILENAME, 0);

    RdosCloseFile(LogHandle);

    LogHandle = RdosOpenFile(DOWNLOAD_LOG_FILENAME, 0);
    if (!LogHandle)
        LogHandle = RdosCreateFile(DOWNLOAD_LOG_FILENAME, 0);

    RdosCloseFile(LogHandle);

    Buf = new char[0x1000];
    Size = 0x1000;
    ModuleCrc = 0;

    RdosSetFilePos(FileHandle, 0);

    while (Size)
    {
        Size = RdosReadFile(FileHandle, Buf, Size);
        ModuleCrc = RdosCalcCrc(CrcHandle, ModuleCrc, Buf, Size);
    }

    delete Buf;
    RdosCloseFile(FileHandle); 
    RdosCloseCrc(CrcHandle);

    StoreDisc = new TDisc(Disc);
    SaveStore = new TDiscStorage(StoreDisc, FillSaveSector, MAX_MID_PUMPS);

    store = new TDiscStorage(StoreDisc, LongStorageSector, LongStorageSize);
    LongStore = new TMidLongStorage(store);
    MidReceipt = new TMidReceipt;
    MidBitmap = new TMidBitmap;

    Section = RdosCreateSection("MID");    

    sprintf(crcstr, "%04hX", ModuleCrc);

    ini.GotoSection("MID");
    ok = ini.ReadVar("CRC", str, 6);
    if (ok)
        if (strcmp(crcstr, str))
            ok = FALSE;

    if (!ok)
    {
        sprintf(str, "MID CRC changed to %s", crcstr);
        LogDownloadRow(str);
        ini.WriteVar("CRC", crcstr);
    }

    ok = ini.ReadVar("TerminalVersion", str, 50);
    if (ok)
        if (strcmp(TerminalVersion, str))
            ok = FALSE;

    if (!ok)
    {
        sprintf(str, "Terminal version changed to %s", TerminalVersion);
        LogDownloadRow(str);
        ini.WriteVar("TerminalVersion", TerminalVersion);
    }

    ok = ini.ReadVar("MidVersion", str, 50);
    if (ok)
        if (strcmp(MID_VER, str))
            ok = FALSE;

    if (!ok)
    {
        sprintf(str, "MID version changed to %s", MID_VER);
        LogDownloadRow(str);
        ini.WriteVar("MidVersion", MID_VER);
    }

    RdosGetVersion(&major, &minor, &release);
    sprintf(osstr, "RDOS-%d.%d.%d", major, minor, release);
    
    ok = ini.ReadVar("OsVersion", str, 80);
    if (ok)
        if (strcmp(osstr, str))
            ok = FALSE;

    if (!ok)
    {
        sprintf(str, "Operating system version changed to %s", osstr);
        LogDownloadRow(str);
        ini.WriteVar("OsVersion", osstr);
    }
    RdosCreateThread(&runWebServer, "MidWebServer", 0, 16132);
}

/*##################  MidSetCurrency  ###############
*   Purpose....: Set currency                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
void __export _stdcall MidSetCurrency(const char *Currency)
{
    SetReceiptCurrency(Currency);
}

/*##################  MidFilterFinalData  ###############
*   Purpose....: Set mid to filter final data                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
void __export _stdcall MidFilterFinalData()
{
    ForceFinal = FALSE;
}

/*##################  CreateHandle  ###############
*   Purpose....: Create a new handle                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int CreateHandle()
{
    int PumpNr;
    long val = 0;

    while (val == 0)
    {
        val = RdosGetLongRandom();

        for (PumpNr = 0; PumpNr < MAX_MID_PUMPS; PumpNr++)
            if (HandleArr[PumpNr] == val)
                val = 0;
        
    }
    return val;
}

/*##################  HandleToPumpNr  ###############
*   Purpose....: Convert from handle to PumpNr                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int HandleToPumpNr(int Handle)
{
    int PumpNr;

    for (PumpNr = 1; PumpNr < MAX_MID_PUMPS; PumpNr++)
        if (HandleArr[PumpNr] == Handle)
            return PumpNr;
        
    return 0;
}

/*##################  CodePumpType  ###############
*   Purpose....: Code pump type
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
static void CodePumpType(int PumpType, char *PumpStr)
{
    switch (PumpType)
    {
        case MID_PUMP_TYPE_COMPAC:
            strcpy(PumpStr, "Compac");
            break;

        case MID_PUMP_TYPE_AUTOTANK:
            strcpy(PumpStr, "Autotank");
            break;

        case MID_PUMP_TYPE_DART:
            strcpy(PumpStr, "Dart");
            break;

        case MID_PUMP_TYPE_WAYNE:
            strcpy(PumpStr, "Wayne");
            break;

        case MID_PUMP_TYPE_MPI:
            strcpy(PumpStr, "MPI");
            break;

        case MID_PUMP_TYPE_TATSUNO:
            strcpy(PumpStr, "Tatsuno");
            break;

        case MID_PUMP_TYPE_GILBARCO:
            strcpy(PumpStr, "Gilbarco");
            break;

        case MID_PUMP_TYPE_KIENZLE:
            strcpy(PumpStr, "Kienzle");
            break;

        case MID_PUMP_TYPE_IFSF:
            strcpy(PumpStr, "IFSF");
            break;

        case MID_PUMP_TYPE_KOPPENS_EPS:
            strcpy(PumpStr, "KoppensEPS");
            break;

        case MID_PUMP_TYPE_SCHEIDT:
            strcpy(PumpStr, "Scheidt&Bachmann");
            break;

        case MID_PUMP_TYPE_HDX:
            strcpy(PumpStr, "HDX");
            break;

        case MID_PUMP_TYPE_NPCL:
            strcpy(PumpStr, "NuovoPignone");
            break;

        case MID_PUMP_TYPE_PUMALAN:
            strcpy(PumpStr, "PumaLan");
            break;

        case MID_PUMP_TYPE_MIDCO:
            strcpy(PumpStr, "Midco");
            break;

        case MID_PUMP_TYPE_OCPP:
            strcpy(PumpStr, "OCPP");
            break;

        default:
            strcpy(PumpStr, "Unknown");
    }
}
    
/*##################  MidInstallPump  ###############
*   Purpose....: Install pump                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int __export _stdcall MidInstallPump(int PumpNr, int PumpType, int Address, int VolumeDigits, int AmountDigits, int PriceDigits)
{
    TFillSave *save;
    TMidPump *pump;
    int Handle;
    TIniFile ini;
    char str[101];
    char typestr[80];
    int ok;
    int val;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS && StoreDisc && !FillSaveArr[PumpNr])
    {    
        sprintf(str, "Pump%d", PumpNr);
        ini.GotoSection(str);
        ok = ini.ReadVar("Type", str, 100);
        if (ok)
        {
            val = atoi(str);
            if (val != PumpType)
            {
                sprintf(str, "%d", PumpType);
                ini.WriteVar("Type", str);

                CodePumpType(PumpType, typestr);
                sprintf(str, "Changed pump %d to (%s), address: %d", PumpNr, typestr, Address);
                LogConfigRow(str);
            }

            ok = ini.ReadVar("Address", str, 100);
            if (ok)
            {
                val = atoi(str);
                if (val != Address)
                {
                    sprintf(str, "%d", Address);
                    ini.WriteVar("Address", str);

                    sprintf(str, "Changed pump %d address to: %d", PumpNr, Address);
                    LogConfigRow(str);
                }
            }
        }
        else
        {
            CodePumpType(PumpType, typestr);
            sprintf(str, "Added pump %d (%s), address: %d", PumpNr, typestr, Address);
            LogConfigRow(str);

            sprintf(str, "%d", PumpType);
            ini.WriteVar("Type", str);

            sprintf(str, "%d", Address);
            ini.WriteVar("Address", str);
        }        
        
        pump = new TMidPump(PumpType, Address, VolumeDigits, AmountDigits, PriceDigits);
        PumpArr[PumpNr] = pump;
        
        save = new TFillSave(PumpNr, SaveStore);        
        FillSaveArr[PumpNr] = save;
        
        if (save->HasSavedFill())
        {
            CurrCustArr[PumpNr] = save->GetSavedCustomer();

            if (PumpType == MID_PUMP_TYPE_OCPP)
            {
                ok = ini.ReadVar("Base", str, 100);
                if (ok)
                    pump->BaseVolume = atoi(str);            
                else
                    pump->BaseVolume = -1;
            }
        }

        Handle = CreateHandle();
        HandleArr[PumpNr] = Handle;            
        
        return Handle;
    }
    return 0;
}

/*##################  MidInstallNozzle  ###############
*   Purpose....: Install nozzle for pump                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void __export _stdcall MidInstallNozzle(int Handle, int Nozzle, const char *ProdName, const char *ProdUnit)
{
    TMidPump *pump;
    int ok;
    TIniFile ini;
    char parstr[80];
    char str[101];

    int PumpNr = HandleToPumpNr(Handle);
    
    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
    {
        pump = PumpArr[PumpNr];
        if (pump)
        {
            sprintf(parstr, "Pump%d", PumpNr);
            ini.GotoSection(parstr);
            sprintf(parstr, "Nozzle%d", Nozzle + 1);
            ok = ini.ReadVar(parstr, str, 100);
            if (ok)
            {
                if (strcmp(str, ProdName))
                {
                    sprintf(str, "Changed product on nozzle %d, pump %d to %s unit %s", Nozzle + 1, PumpNr, ProdName, ProdUnit);
                    LogConfigRow(str);

                    ini.WriteVar(parstr, ProdName);
               }
            }            
            else
            {
                sprintf(str, "Added product %s unit %s on nozzle %d, pump %d", ProdName, ProdUnit, Nozzle + 1, PumpNr);
                LogConfigRow(str);
                ini.WriteVar(parstr, ProdName);
            }
            
            pump->InstallNozzle(Nozzle, ProdName, ProdUnit);
        }
    }
}

/*##################  MidHasLostFill  ###############
*   Purpose....: Check for lost fill                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int __export _stdcall MidHasLostFill(int Handle)
{
    int PumpNr = HandleToPumpNr(Handle);
    
    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS && FillSaveArr[PumpNr])
        return FillSaveArr[PumpNr]->HasSavedFill();
    return FALSE;
}

/*##################  LockMidCustomer  ###############
*   Purpose....: Lock MID customer                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
static TMidCustomer *LockMidCustomer(int PumpNr)
{
    RdosEnterSection(Section);

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        return CurrCustArr[PumpNr];
    else
        return 0;
}

/*##################  UnlockMidCustomer  ###############
*   Purpose....: Unlock MID customer                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
static void UnlockMidCustomer(int PumpNr)
{
    RdosLeaveSection(Section);
}

/*##################  CreateMidCustomer  ###############
*   Purpose....: Create MID customer                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
static TMidCustomer *CreateMidCustomer(int PumpNr, int StartPolls, long SeqNr)
{
    TFillSave *save;
    TMidPump *pump;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS && FillSaveArr[PumpNr])
    {
        pump = PumpArr[PumpNr];
        if (pump)
        {
            TMidCustomer *customer = CurrCustArr[PumpNr];
            if (customer)
                delete customer;
            
            customer = new TMidCustomer(PumpNr, pump, StartPolls, SeqNr, pump->GetVolumeDigits(), pump->GetAmountDigits(), pump->GetPriceDigits());
            CurrCustArr[PumpNr] = customer;

            save = FillSaveArr[PumpNr];
            save->StartFill(customer);

            return customer;
        }
    }
    return 0;
}

/*##################  NotifyFill  ###############
*   Purpose....: Notify fill                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
static int NotifyFill(int PumpNr, long *Volume, long *Amount, long PulseDiff)
{
    TMidCustomer *customer = LockMidCustomer(PumpNr);
    TFillSave *save;

    if (customer)
    {
        if (customer->UpdateSpot(Volume, Amount, PulseDiff))
        {
            save = FillSaveArr[PumpNr];
            save->Update();
        }
        
        UnlockMidCustomer(PumpNr);
        return TRUE;
    }
    else
    {
        UnlockMidCustomer(PumpNr);
        return FALSE;
    }
}

/*##################  NotifyFill  ###############
*   Purpose....: Notify fill (with price)                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
static int NotifyFill(int PumpNr, long *Volume, long *Amount, int *Price, long PulseDiff)
{
    TMidCustomer *customer = LockMidCustomer(PumpNr);
    TFillSave *save;

    if (customer)
    {
        if (customer->UpdateSpot(Volume, Amount, Price, PulseDiff))
        {
            save = FillSaveArr[PumpNr];
            save->Update();
        }
        
        UnlockMidCustomer(PumpNr);
        return TRUE;
    }
    else
    {
        UnlockMidCustomer(PumpNr);
        return FALSE;
    }
}

/*##################  NotifyFinalFill  ###############
*   Purpose....: Notify final fill                                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
static int NotifyFinalFill(int PumpNr, long *Volume, long *Amount, long PulseDiff)
{
    TMidCustomer *customer = LockMidCustomer(PumpNr);
    TFillSave *save;

    if (customer)
    {
        customer->UpdateFinalValidate(Volume, Amount, PulseDiff);

        save = FillSaveArr[PumpNr];
        save->Update();
        UnlockMidCustomer(PumpNr);
        return TRUE;
    }
    else
    {
        UnlockMidCustomer(PumpNr);
        return FALSE;
    }
}

/*##################  NotifyFinalFill  ###############
*   Purpose....: Notify final fill (with price)                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
static int NotifyFinalFill(int PumpNr, long *Volume, long *Amount, int *Price, long PulseDiff)
{
    TMidCustomer *customer = LockMidCustomer(PumpNr);
    TFillSave *save;

    if (customer)
    {
        customer->UpdateFinalValidate(Volume, Amount, Price, PulseDiff);

        save = FillSaveArr[PumpNr];
        save->Update();
        UnlockMidCustomer(PumpNr);
        return TRUE;
    }
    else
    {
        UnlockMidCustomer(PumpNr);
        return FALSE;
    }
}

/*##################  NotifyCalcAmountFinal  ###############
*   Purpose....: Notify amount calculated final                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
static int NotifyCalcAmountFinal(int PumpNr, long *Volume, long *Amount, long PulseDiff)
{
    TMidCustomer *customer = LockMidCustomer(PumpNr);
    TFillSave *save;

    if (customer)
    {
        if (ForceFinal)
            customer->SetCalcAmountFinal(Volume, Amount, PulseDiff);
        else
            customer->UpdateCalcAmountFinal(Volume, Amount, PulseDiff);

        save = FillSaveArr[PumpNr];
        save->Update();
        
        UnlockMidCustomer(PumpNr);
        return TRUE;
    }
    else
    {
        UnlockMidCustomer(PumpNr);
        return FALSE;
    }
}

/*##################  NotifyCalcAmountFinal  ###############
*   Purpose....: Notify amount calculated final                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
static int NotifyCalcAmountFinal(int PumpNr, long *Volume, long *Amount, int *Price, long PulseDiff)
{
    TMidCustomer *customer = LockMidCustomer(PumpNr);
    TFillSave *save;

    if (customer)
    {
        if (ForceFinal)
            customer->SetCalcAmountFinal(Volume, Amount, Price, PulseDiff);
        else
            customer->UpdateCalcAmountFinal(Volume, Amount, Price, PulseDiff);

        save = FillSaveArr[PumpNr];
        save->Update();
        
        UnlockMidCustomer(PumpNr);
        return TRUE;
    }
    else
    {
        UnlockMidCustomer(PumpNr);
        return FALSE;
    }
}

/*##################  NotifyCalcAmountFill  ###############
*   Purpose....: Notify fill                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
static int NotifyCalcAmountFill(int PumpNr, long *Volume, long *Amount, long PulseDiff)
{
    TMidCustomer *customer = LockMidCustomer(PumpNr);
    TFillSave *save;

    if (customer)
    {
        if (customer->UpdateCalcAmount(Volume, Amount, PulseDiff))
        {
            save = FillSaveArr[PumpNr];
            save->Update();
        }

        UnlockMidCustomer(PumpNr);
        return TRUE;
    }
    else
    {
        UnlockMidCustomer(PumpNr);
        return FALSE;
    }
}

/*##################  NotifyCalcAmountFill  ###############
*   Purpose....: Notify amount calculated fill                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
static int NotifyCalcAmountFill(int PumpNr, long *Volume, long *Amount, int *Price, long PulseDiff)
{
    TMidCustomer *customer = LockMidCustomer(PumpNr);
    TFillSave *save;

    if (customer)
    {
        if (customer->UpdateCalcAmount(Volume, Amount, Price, PulseDiff))
        {
            save = FillSaveArr[PumpNr];
            save->Update();
        }
        
        UnlockMidCustomer(PumpNr);
        return TRUE;
    }
    else
    {
        UnlockMidCustomer(PumpNr);
        return FALSE;
    }
}

/*##################  NotifyCalcVolumeFill  ###############
*   Purpose....: Notify volume calculated fill                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
static int NotifyCalcVolumeFill(int PumpNr, long *Volume, long *Amount, int *Price, long PulseDiff)
{
    TMidCustomer *customer = LockMidCustomer(PumpNr);
    TFillSave *save;

    if (customer)
    {
        if (customer->UpdateCalcVolume(Volume, Amount, Price, PulseDiff))
        {
            save = FillSaveArr[PumpNr];
            save->Update();
        }
        
        UnlockMidCustomer(PumpNr);
        return TRUE;
    }
    else
    {
        UnlockMidCustomer(PumpNr);
        return FALSE;
    }
}

/*##################  NotifyVolumeOrAmountSpot  ###############
*   Purpose....: Notify volume or amount spot-check                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
static int NotifyVolumeOrAmountSpot(int PumpNr, long InValue, long *Volume, long *Amount, int *Price, long PulseDiff)
{
    TMidCustomer *customer = LockMidCustomer(PumpNr);
    TFillSave *save;

    if (customer)
    {
        if (customer->UpdateVolumeOrAmountSpot(InValue, Volume, Amount, Price, PulseDiff))
        {
            save = FillSaveArr[PumpNr];
            save->Update();
        }
        
        UnlockMidCustomer(PumpNr);
        return TRUE;
    }
    else
    {
        UnlockMidCustomer(PumpNr);
        return FALSE;
    }
}

/*##########################  CheckVolumeSpotType  ##########################
*   Purpose....: Check if volume spot-check                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: 1 - Volume spot, 0 - amount spot, -1 -no customer          #
*##########################################################################*/
static int CheckVolumeSpotType(int PumpNr)
{
    TMidCustomer *customer = LockMidCustomer(PumpNr);

    if (customer)
    {
        if (customer->CheckVolumeSpotType())
        {
            UnlockMidCustomer(PumpNr);
            return 1;
        }
        else
        {
            UnlockMidCustomer(PumpNr);
            return 0;
        }
    }
    else
    {
        UnlockMidCustomer(PumpNr);
        return -1;
    }
}

/*##################  NotifyNoSpotFill  ###############
*   Purpose....: Notify a fill without spot-check data                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
static int NotifyNoSpotFill(int PumpNr)
{
    TMidCustomer *customer = LockMidCustomer(PumpNr);
    TFillSave *save;

    if (customer)
    {
        customer->UpdateNoSpot();
        save = FillSaveArr[PumpNr];
        save->Update();
        
        UnlockMidCustomer(PumpNr);
        return TRUE;
    }
    else
    {
        UnlockMidCustomer(PumpNr);
        return FALSE;
    }
}

/*##################  MidCreate  ###############
*   Purpose....: Create new MID transaction                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export _stdcall MidCreate(int Handle, int StartPolls, long SeqNr)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidCustomer *customer;
    TMidPump *pump;

    RdosEnterSection(Section);

    customer = CreateMidCustomer(PumpNr, StartPolls, SeqNr);

    pump = PumpArr[PumpNr];
    customer->LastVolume = pump->LastVolume;
    customer->LastAmount = pump->LastAmount;
    pump->BaseVolume = -1;

    RdosLeaveSection(Section);

    if (customer)
        return TRUE;
    else
        return FALSE;
}

/*##################  MidEnd  ###############
*   Purpose....: Mid end fill                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int __export __stdcall MidEnd(int Handle)
{
    int PumpNr = HandleToPumpNr(Handle);
    TFillSave *save;
    TMidPump *pump;
    int id = 0;
    
    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
    {
        RdosEnterSection(Section);
        
        TMidCustomer *customer = CurrCustArr[PumpNr];
        if (customer)
        {
            pump = PumpArr[PumpNr];
            pump->LastVolume = customer->FMidData.Volume;
            pump->LastAmount = customer->FMidData.Amount;

            customer->EndFill();
            
            id = LongStore->Add(&customer->FMidData);
            
            save = FillSaveArr[PumpNr];
            save->EndFill();
            delete customer;
        }
             
        CurrCustArr[PumpNr] = 0;

        RdosLeaveSection(Section);
    }

    return id;
}

/*##################  MidEndNoFill  ###############
*   Purpose....: Mid end no fill                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int __export __stdcall MidEndNoFill(int Handle)
{
    int PumpNr = HandleToPumpNr(Handle);
    TFillSave *save;
    TMidPump *pump;
    int id = 0;
    
    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
    {
        RdosEnterSection(Section);
        
        TMidCustomer *customer = CurrCustArr[PumpNr];
        if (customer)
        {
            pump = PumpArr[PumpNr];
            pump->LastVolume = customer->FMidData.Volume;
            pump->LastAmount = customer->FMidData.Amount;

            customer->EndNoFill();
            
            id = LongStore->Add(&customer->FMidData);
            
            save = FillSaveArr[PumpNr];
            save->EndFill();
            delete customer;
        }
             
        CurrCustArr[PumpNr] = 0;

        RdosLeaveSection(Section);
    }

    return id;
}

/*##################  MidReservedCreate  ###############
*   Purpose....: Create new MID transaction + return mid id                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export _stdcall MidReservedCreate(int Handle, int StartPolls, long SeqNr)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidCustomer *customer;
    TMidPump *pump;
    int id = 0;

    RdosEnterSection(Section);

    customer = CreateMidCustomer(PumpNr, StartPolls, SeqNr);

    pump = PumpArr[PumpNr];
    customer->LastVolume = pump->LastVolume;
    customer->LastAmount = pump->LastAmount;
    pump->BaseVolume = -1;

    id = LongStore->Reserve();

    RdosLeaveSection(Section);

    return id;
}

/*##################  MidReservedEnd  ###############
*   Purpose....: Mid end fill with mid-id                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void __export __stdcall MidReservedEnd(int Handle, int MidId)
{
    int PumpNr = HandleToPumpNr(Handle);
    TFillSave *save;
    TMidPump *pump;
    
    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
    {
        RdosEnterSection(Section);
        
        TMidCustomer *customer = CurrCustArr[PumpNr];
        if (customer)
        {
            pump = PumpArr[PumpNr];
            pump->LastVolume = customer->FMidData.Volume;
            pump->LastAmount = customer->FMidData.Amount;

            customer->EndFill();

            if (!MidId)
                MidId = LongStore->Reserve();
            
            LongStore->Update(MidId, &customer->FMidData);
            
            save = FillSaveArr[PumpNr];
            save->EndFill();
            delete customer;
        }
             
        CurrCustArr[PumpNr] = 0;

        RdosLeaveSection(Section);
    }
}

/*##################  MidReservedEndNoFill  ###############
*   Purpose....: Mid end no fill                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void __export __stdcall MidReservedEndNoFill(int Handle, int MidId)
{
    int PumpNr = HandleToPumpNr(Handle);
    TFillSave *save;
    TMidPump *pump;
    int id = 0;
    
    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
    {
        RdosEnterSection(Section);
        
        TMidCustomer *customer = CurrCustArr[PumpNr];
        if (customer)
        {
            pump = PumpArr[PumpNr];
            pump->LastVolume = customer->FMidData.Volume;
            pump->LastAmount = customer->FMidData.Amount;

            customer->EndNoFill();
            
            LongStore->Update(MidId, &customer->FMidData);
            
            save = FillSaveArr[PumpNr];
            save->EndFill();
            delete customer;
        }
             
        CurrCustArr[PumpNr] = 0;

        RdosLeaveSection(Section);
    }
}

/*##################  MidSelectProduct  ###############
*   Purpose....: Mid select product                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
void __export __stdcall MidSelectProduct(int Handle, int Nozzle, int Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TFillSave *save;
    TMidPump *pump;
    TMidPumpNozzle *nozzle;
    
    TMidCustomer *customer = LockMidCustomer(PumpNr);

    if (customer)
    {
        pump = PumpArr[PumpNr];
        if (pump)
        {
            if (Nozzle > 0 && Nozzle <= MidConst::MAX_PUMP_NOZZLE_COUNT)
            {
                nozzle = pump->NozzleArr[Nozzle - 1];
                if (nozzle)
                {
                    if (customer->SelectProduct(Nozzle, nozzle->ProdName.GetData(), nozzle->ProdUnit.GetData(), Price))
                    {
                        save = FillSaveArr[PumpNr];
                        save->Select();
                    }
                }
            }
        }
    }

    UnlockMidCustomer(PumpNr);
}

/*##################  MidOffline  ###############
*   Purpose....: Mid pump is offline (truncate data series)                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
void __export __stdcall MidOffline(int Handle)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump;
    
    TMidCustomer *customer = LockMidCustomer(PumpNr);

    if (customer)
    {
        pump = PumpArr[PumpNr];
        if (pump)
            customer->Offline();
    }

    UnlockMidCustomer(PumpNr);
}

/*##################  MidAuthorized  ###############
*   Purpose....: Mid authorized indication                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
void __export __stdcall MidAuthorized(int Handle)
{
    int PumpNr = HandleToPumpNr(Handle);
    TFillSave *save;
    
    TMidCustomer *customer = LockMidCustomer(PumpNr);

    if (customer)
    {
        if (!customer->IsValid())
        {
            customer->Authorized();

            save = FillSaveArr[PumpNr];
            save->Select();
        }
    }

    UnlockMidCustomer(PumpNr);
}
    
/*##################  MidSetDecimals  ###############
*   Purpose....: Set decimals                                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void __export _stdcall MidSetDecimals(int Handle, int VolumeDigits, int AmountDigits, int PriceDigits)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        pump->SetDecimals(VolumeDigits, AmountDigits, PriceDigits);
}

/*##################  MidNotifyCompacFill  ###############
*   Purpose....: Notify compac filling data                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyCompacFill(int Handle, char *Msg, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyCompacData(Msg, Volume, Amount))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
    
            return NotifyFill(PumpNr, Volume, Amount , 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyCompacFinal  ###############
*   Purpose....: Notify compac final filling data                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyCompacFinal(int Handle, char *Msg, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyCompacData(Msg, Volume, Amount))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
    
            return NotifyFinalFill(PumpNr, Volume, Amount , 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyNgModbusSpot  ###############
*   Purpose....: Notify Nordic gas modbus spot-check                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyNgModbusSpot(int Handle, int StartReg, int RegCount, const char *Msg, int Size, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyNgModbusData(StartReg, RegCount, Msg, Size, Volume, Amount))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
    
            return NotifyFill(PumpNr, Volume, Amount , 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyNgModbusFinal  ###############
*   Purpose....: Notify Nordic gas modbus final data                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyNgModbusFinal(int Handle, int StartReg, int RegCount, const char *Msg, int Size, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyNgModbusData(StartReg, RegCount, Msg, Size, Volume, Amount))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
    
            return NotifyFinalFill(PumpNr, Volume, Amount , 0);
        }
    }
    return FALSE;
}

/*#####################  MidKienzleTotalizerDecode  #########################
*   Purpose....:                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
void __export __stdcall MidKienzleTotalizerDataDecode(
    const unsigned char *data,
    long *value,
    int *nozzle,
    bool *amount
    )
{
    *value = data[0] * 1000000000;
    *value += data[1] * 100000000;
    *value += data[2] * 10000000;
    *value += data[3] * 1000000;
    *value += data[4] * 100000;
    *value += data[5] * 10000;
    *value += data[6] * 1000;
    *value += data[7] * 100;
    *value += data[8] * 10;
    *value += data[9];
    *nozzle = data[10];
    if (*nozzle > 7) {
        *amount = true;
        *nozzle -= 8;
    }
    else {
        *amount = false;
    }
}
/*#####################  MidKienzleFillDataDecode  ##########################
*   Purpose....:                                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
void __export __stdcall MidKienzleFillDataDecode(
    const unsigned char *data, /**< [in] Raw message data */
    long *volume,               /**< [out] Decoded volume */
    long *amount,               /**< [out] Decoded amount */ 
    int *nozzle,               /**< [out] Decoded nozzle number */
    int *sequence              /**< [out] Decoded sequence */
    ) 
{

    *volume =  data[0] * 10000;
    *volume += data[1] * 1000;
    *volume += data[2] * 100;
    *volume += data[3] * 10;
    *volume += data[4];

    *amount =  data[5] * 10000;
    *amount += data[6] * 1000;
    *amount += data[7] * 100;
    *amount += data[8] * 10;
    *amount += data[9];

    *nozzle = data[10];
    // allways use two decimals
    if(*nozzle > 7) {
        *nozzle -= 8;
        *amount = *amount / 10;
    }
    *sequence  = data[11] * 10;
    *sequence += data[12];
}

/*##################  MidNotifyKienzleFill  ###############
*   Purpose....: Notify kienzle filling data                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
    int __export __stdcall MidNotifyKienzleFill(
    int Handle, 
    const unsigned char *Msg, 
    long *volume, 
    long *amount,
    int *nozzle,
    int *sequence
    )
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        MidKienzleFillDataDecode(Msg, volume, amount, nozzle, sequence);
        return NotifyFinalFill(PumpNr, volume, amount , 0);
    }
    return FALSE;
}

/*##################  MidNotifyAutotankFill  ###############
*   Purpose....: Notify autotank filling data                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
    int __export __stdcall MidNotifyAutotankFill(int Handle, const char *Msg, int Size, const char *Crc, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;
    int Final;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyAutotankData(Msg, Size, Crc, Volume, Amount, Price, &Final))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
            *Price = pump->ConvFromPumpPrice(*Price);

            if (Final)
                return NotifyFinalFill(PumpNr, Volume, Amount, Price, 0);
            else
                return NotifyFill(PumpNr, Volume, Amount, Price, 0);
    
        }
    }
    return FALSE;
}

/*##################  MidNotifyDartFill  ###############
*   Purpose....: Notify DART filling data                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyDartFill(int Handle, const char *Msg, int Size, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyDartData(Msg, Size, Volume, Amount))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
    
            return NotifyFill(PumpNr, Volume, Amount, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyDartFibal  ###############
*   Purpose....: Notify DART final filling data                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyDartFinal(int Handle, const char *Msg, int Size, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyDartData(Msg, Size, Volume, Amount))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
    
            return NotifyFinalFill(PumpNr, Volume, Amount, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyWayneFill  ###############
*   Purpose....: Notify wayne filling data                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyWayneFill(int Handle, const char *Msg, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyWayneData(Msg, Volume, Amount, Price))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
            *Price = pump->ConvFromPumpPrice(*Price);
    
            return NotifyFill(PumpNr, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyWayneFinal  ###############
*   Purpose....: Notify wayne final filling data                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyWayneFinal(int Handle, const char *Msg, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyWayneData(Msg, Volume, Amount, Price))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
            *Price = pump->ConvFromPumpPrice(*Price);
    
            return NotifyFinalFill(PumpNr, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyMpiFill  ###############
*   Purpose....: Notify MPI filling data                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyMpiFill(int Handle, char *Msg, int Size, long *Volume, long *Amount, long *PulseDiff, int PulseFactor)
{    
    return MidNotifyMpiSpot(Handle, Msg, Size, Volume, Amount, PulseDiff, PulseFactor, TRUE);
}

/*##################  MidNotifyMpiSpot  ###############
*   Purpose....: Notify MPI spot data                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyMpiSpot(int Handle, char *Msg, int Size, long *Volume, long *Amount, long *PulseDiff, int PulseFactor, int LargeAmount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;
    int ok;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyMpiData(Msg, Size, Volume, Amount, PulseDiff))
        {
            if (PulseFactor == 10 && !LargeAmount)
            {
                *Volume = pump->ConvFromPumpVolume(*Volume);
                *Amount = pump->ConvFromPumpAmount(*Amount);
                ok = NotifyFill(PumpNr, Volume, Amount, *PulseDiff);
            }
            else
            {
                *Volume = *Volume * PulseFactor / 10;
                *Volume = pump->ConvFromPumpVolume(*Volume);
                ok = NotifyCalcAmountFill(PumpNr, Volume, Amount, *PulseDiff);
            }
    
            return ok;
        }
    }
    return FALSE;
}


/*##################  MidNotifyMpiFinal  ###############
*   Purpose....: Notify MPI final filling data                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyMpiFinal(int Handle, char *Msg, int Size, long *Volume, long *Amount, long *PulseDiff, int PulseFactor, int LargeAmount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;
    int ok;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyMpiData(Msg, Size, Volume, Amount, PulseDiff))
        {
            if (PulseFactor == 10 && !LargeAmount)
            {
                *Volume = pump->ConvFromPumpVolume(*Volume);
                *Amount = pump->ConvFromPumpAmount(*Amount);
                ok = NotifyFinalFill(PumpNr, Volume, Amount, *PulseDiff);
                if (*PulseDiff < 30)
                   ok = NotifyFinalFill(PumpNr, Volume, Amount, *PulseDiff);
            }
            else
            {
                *Volume = *Volume * PulseFactor / 10;
                *Volume = pump->ConvFromPumpVolume(*Volume);
                ok = NotifyCalcAmountFill(PumpNr, Volume, Amount, *PulseDiff);
            }
    
            return ok;
        }
    }
    return FALSE;
}

/*##################  MidNotifyTatsunoFill  ###############
*   Purpose....: Notify Tatsuno filling data                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyTatsunoFill(int Handle, const char *Msg, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyTatsunoData(Msg, Volume, Amount, Price))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
            *Price = pump->ConvFromPumpPrice(*Price);
    
            return NotifyFill(PumpNr, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyTatsunoFinal  ###############
*   Purpose....: Notify Tatsuno final filling data                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyTatsunoFinal(int Handle, const char *Msg, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyTatsunoData(Msg, Volume, Amount, Price))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
            *Price = pump->ConvFromPumpPrice(*Price);
    
            return NotifyFinalFill(PumpNr, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyGilbarcoFinal  ###############################
*   Purpose....: Notify final Gilbarco filling data                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyGilbarcoFinal(int Handle, const char *Msg, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        if (NotifyGilbarcoFinalData(Msg, Volume, Amount, Price))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
            *Price = pump->ConvFromPumpPrice(*Price);

            return NotifyFinalFill(PumpNr, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyGilbarcoFinalDecimals    #####################
*   Purpose....: Notify final Gilbarco filling data                         #
*                with decimals for amount and volume                        # 
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyGilbarcoFinalDecimals(int Handle, const char *Msg, long *Volume, long *Amount, int *Price, int AmountDecimals, int VolumeDecimals)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        if (NotifyGilbarcoFinalDataDecimals(Msg, Volume, Amount, Price, AmountDecimals, VolumeDecimals, pump->GetAmountDigits(), pump->GetVolumeDigits()))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
            *Price = pump->ConvFromPumpPrice(*Price);

            return NotifyFinalFill(PumpNr, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyGilbarcoSpot  ################################
*   Purpose....: Notify Gilbarco spot check filling data                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyGilbarcoSpot(int Handle, const char *Msg, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;
    int spotType;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        long AmountOrVolume;
        if (NotifyGilbarcoSpotData(Msg, &AmountOrVolume))
        {
            spotType = CheckVolumeSpotType(PumpNr);
            if (spotType == 1)  // If volume spot type
                AmountOrVolume = pump->ConvFromPumpVolume(AmountOrVolume);
            else if (spotType == 0) // If amount spot type
                AmountOrVolume = pump->ConvFromPumpAmount(AmountOrVolume);
            else   // No customer
                return FALSE;

            return NotifyVolumeOrAmountSpot(PumpNr, AmountOrVolume, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyGilbarcoSpotDecimals  ########################
*   Purpose....: Notify Gilbarco spot check filling data                    #
*                with decimals for amount                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyGilbarcoSpotDecimals(int Handle, const char *Msg, long *Volume, long *Amount, int *Price, int AmountDecimals)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;
    int spotType;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        long AmountOrVolume;
        if (NotifyGilbarcoSpotDataDecimals(Msg, &AmountOrVolume, AmountDecimals, pump->GetAmountDigits()))
        {
            spotType = CheckVolumeSpotType(PumpNr);
            if (spotType == 1)  // If volume spot type
                AmountOrVolume = pump->ConvFromPumpVolume(AmountOrVolume);
            else if (spotType == 0) // If amount spot type
                AmountOrVolume = pump->ConvFromPumpAmount(AmountOrVolume);
            else   // No customer
                return FALSE;

            return NotifyVolumeOrAmountSpot(PumpNr, AmountOrVolume, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyGilbarcoFinalLong  ###########################
*   Purpose....: Notify final Gilbarco filling data (long message)          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyGilbarcoFinalLong(int Handle, const char *Msg, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        if (NotifyGilbarcoFinalDataLong(Msg, Volume, Amount, Price))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
            *Price = pump->ConvFromPumpPrice(*Price);

            return NotifyFinalFill(PumpNr, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyGilbarcoFinalLongDecimals    #################
*   Purpose....: Notify final Gilbarco filling data (long message)          #
*                with decimals for amount and volume                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyGilbarcoFinalLongDecimals(int Handle, const char *Msg, long *Volume, long *Amount, int *Price, int AmountDecimals, int VolumeDecimals)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        if (NotifyGilbarcoFinalDataLongDecimals(Msg, Volume, Amount, Price, AmountDecimals, VolumeDecimals, pump->GetAmountDigits(), pump->GetVolumeDigits()))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
            *Price = pump->ConvFromPumpPrice(*Price);

            return NotifyFinalFill(PumpNr, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyGilbarcoSpotLong  ############################
*   Purpose....: Notify Gilbarco spot check filling data (long message)     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyGilbarcoSpotLong(int Handle, const char *Msg, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;
    int spotType;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        long AmountOrVolume;
        if (NotifyGilbarcoSpotDataLong(Msg, &AmountOrVolume))
        {
            spotType = CheckVolumeSpotType(PumpNr);
            if (spotType == 1)  // If volume spot type
                AmountOrVolume = pump->ConvFromPumpVolume(AmountOrVolume);
            else if(spotType == 0) // If amount spot type
                AmountOrVolume = pump->ConvFromPumpAmount(AmountOrVolume);
            else   // No customer
                return FALSE;

            return NotifyVolumeOrAmountSpot(PumpNr, AmountOrVolume, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyGilbarcoSpotLongDecimals        ##############
*   Purpose....: Notify Gilbarco spot check filling data (long message)     #
*                with decimals for amount                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyGilbarcoSpotLongDecimals(int Handle, const char *Msg, long *Volume, long *Amount, int *Price, int AmountDecimals)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;
    int spotType;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        long AmountOrVolume;
        if (NotifyGilbarcoSpotDataLongDecimals(Msg, &AmountOrVolume, AmountDecimals, pump->GetAmountDigits()))
        {
            spotType = CheckVolumeSpotType(PumpNr);
            if (spotType == 1)  // If volume spot type
                AmountOrVolume = pump->ConvFromPumpVolume(AmountOrVolume);
            else if (spotType == 0) // If amount spot type
                AmountOrVolume = pump->ConvFromPumpAmount(AmountOrVolume);
            else   // No customer
                return FALSE;

            return NotifyVolumeOrAmountSpot(PumpNr, AmountOrVolume, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyCotexSpot  ################################
*   Purpose....: Notify cotex spot check filling data                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyCotexSpot(int Handle, const char *Msg, int Size, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        if (NotifyCotexSpotData(PumpNr, Msg, Size, Volume, Amount, Price))
            return NotifyFill(PumpNr, Volume, Amount, Price, 0);
    return FALSE;
}

/*##################  MidNotifyCotexFinal  ################################
*   Purpose....: Notify cotex final filling data                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyCotexFinal(int Handle, const char *Msg, int Size, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        if (NotifyCotexFinalData(PumpNr, Msg, Size, Volume, Amount, Price))
            return NotifyFinalFill(PumpNr, Volume, Amount, Price, 0);
    return FALSE;
}

/*##################  MidNotifyZapFill  ###############
*   Purpose....: Notify ZAP filling data                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyZapFill(int Handle, const char *Msg, int Size, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;
    long long temp;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        *Volume = pump->ConvToPumpVolume(*Volume);

        if (NotifyZapData(Msg, Size, Volume))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
    
            return NotifyCalcAmountFill(PumpNr, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyIFSFSpot  ###############
*   Purpose....: Notify IFSF spotcheck data                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyIFSFSpot(int Handle, unsigned char Fp, const char *Msg, int Size, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyIFSFSpotData(Fp, Msg, Size, Volume, Amount, Price))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
            *Price = pump->ConvFromPumpPrice(*Price);
    
            return NotifyFill(PumpNr, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyIFSFFinal  ###############
*   Purpose....: Notify IFSF final fueling data                                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyIFSFFinal(int Handle, const char *Msg, int Size, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyIFSFFinalData(Msg, Size, Volume, Amount))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
    
            return NotifyFinalFill(PumpNr, Volume, Amount, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyIFSFTrans  ###############
*   Purpose....: Notify IFSF trans based data                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyIFSFTrans(int Handle, const char *DbField, const char *Msg, int Size, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyIFSFTransData(DbField, Msg, Size, Volume, Amount))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
    
            return NotifyFinalFill(PumpNr, Volume, Amount, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyKoppensEpsFill  ##############################
*   Purpose....: Notify KoppensEPS filling data                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyKoppensEpsFill(int Handle, const char *Msg, int Size, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;
    int HasPrice = FALSE;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        if (NotifyKoppensEpsData(Msg, Size, Volume, Amount, Price, &HasPrice))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);

            if (HasPrice)
                *Price = pump->ConvFromPumpPrice(*Price);

            if (HasPrice)
               return NotifyFill(PumpNr, Volume, Amount, Price, 0);
            else
               return NotifyFill(PumpNr, Volume, Amount, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyKoppensEpsFinal  ##############################
*   Purpose....: Notify KoppensEPS final filling data                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyKoppensEpsFinal(int Handle, const char *Msg, int Size, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;
    int HasPrice = FALSE;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        if (NotifyKoppensEpsData(Msg, Size, Volume, Amount, Price, &HasPrice))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);

            if (HasPrice)
                *Price = pump->ConvFromPumpPrice(*Price);

            if (HasPrice)
               return NotifyFinalFill(PumpNr, Volume, Amount, Price, 0);
            else
               return NotifyFinalFill(PumpNr, Volume, Amount, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyScheidtBachmannFill  ########################
*   Purpose....: Notify Scheidt&Bachmann spot                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyScheidtBachmannFill(int Handle, const char *Msg, int Size, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyScheidtBachmannData(Msg, Size, Volume, Amount, Price))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
            *Price = pump->ConvFromPumpPrice(*Price);

            return NotifyFill(PumpNr, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyScheidtBachmannFinal  ########################
*   Purpose....: Notify Scheidt&Bachmann final spot                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyScheidtBachmannFinal(int Handle, const char *Msg, int Size, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyScheidtBachmannData(Msg, Size, Volume, Amount, Price))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
            *Price = pump->ConvFromPumpPrice(*Price);

            return NotifyFinalFill(PumpNr, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyNuovoPignoneFill  ############################
*   Purpose....: Notify Nuovo Pignone filling data                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyNuovoPignoneFill(int Handle, const char *Msg, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        if (NotifyNuovoPignoneData(Msg, Volume, Amount))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);

            return NotifyFill(PumpNr, Volume, Amount, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyNuovoPignoneFinal  ############################
*   Purpose....: Notify Nuovo Pignone final filling data                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyNuovoPignoneFinal(int Handle, const char *Msg, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        if (NotifyNuovoPignoneData(Msg, Volume, Amount))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);

            return NotifyFinalFill(PumpNr, Volume, Amount, 0);
        }
    }
    return FALSE;
}


/*#########################  MidNotifyPumaLanFinal  ############################
*   Purpose....: Notify PumaLan filling data                                   #
*   In params..: *                                                             #
*   Out params.: *                                                             #
*   Returns....: MID ID                                                        #
*###############################################################################*/
int __export __stdcall MidNotifyPumaLanFinal(int Handle, const char *Msg, int Size, long *Volume, long *Amount, int *Price, int CalcAmountFill)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        if (NotifyPumaLanFinal(Msg, Size, Volume, Amount, Price))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
            *Price = pump->ConvFromPumpPrice(*Price);

            if (CalcAmountFill)
                return NotifyCalcAmountFill(PumpNr, Volume, Amount, Price, 0);
            else
                return NotifyFinalFill(PumpNr, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*####################  MidNotifyPumaLanFinalFactor  ###########################
*   Purpose....: Notify PumaLan filling data with CreditMultiplicationFactor   #
*   In params..: *                                                             #
*   Out params.: *                                                             #
*   Returns....: MID ID                                                        #
*###############################################################################*/
int __export __stdcall MidNotifyPumaLanFinalFactor(int Handle, const char *Msg, int Size, long *Volume, long *Amount, int *Price, int CalcAmountFill, int CreditMultiplicationFactor)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        if (NotifyPumaLanFinalFactor(Msg, Size, Volume, Amount, Price, CreditMultiplicationFactor))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
            *Price = pump->ConvFromPumpPrice(*Price);

            if(CalcAmountFill)
                return NotifyCalcAmountFill(PumpNr, Volume, Amount, Price, 0);
            else
                return NotifyFinalFill(PumpNr, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*######################  MidNotifyPumaLanFill  #############################
*   Purpose....: Notify PumaLan filling data                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyPumaLanSpot(int Handle, const char *Msg, int Size, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        if (NotifyPumaLanSpot(Msg, Size, Volume, Amount))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);

            return NotifyFill(PumpNr, Volume, Amount, 0);
        }
    }
    return FALSE;
}

/*######################  MidNotifyMidcoFinal  ##############################
*   Purpose....: Notify Midco filling data                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyMidcoFinal(int Handle, const char *Msg, int Size, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        if (NotifyMidcoFinal(Msg, Size, Volume, Amount, Price))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
            *Price = pump->ConvFromPumpPrice(*Price);

            return NotifyFinalFill(PumpNr, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*######################  MidNotifyMidcoFill  ###############################
*   Purpose....: Notify Midco filling data                                  #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyMidcoSpot(int Handle, const char *Msg, int Size, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        if (NotifyMidcoSpot(Msg, Size, Volume, Amount, Price))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
            *Price = pump->ConvFromPumpPrice(*Price);

            return NotifyFill(PumpNr, Volume, Amount, Price, 0);
        }
    }
    return FALSE;
}

/*#######################  MidNotifyZSRFill  ################################
*   Purpose....: Notify ZSR filling data                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyZSRFill(int Handle, const char *Msg, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    { 
        if (NotifyZSRData(Msg, Volume, Amount, pump->GetVolumeDigits(), pump->GetAmountDigits()))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);

            return NotifyFill(PumpNr, Volume, Amount, 0);
        }
    }
    return FALSE;
}

/*#######################  MidNotifyZSRFinal  ################################
*   Purpose....: Notify ZSR final filling data                                    #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyZSRFinal(int Handle, const char *Msg, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    { 
        if (NotifyZSRData(Msg, Volume, Amount, pump->GetVolumeDigits(), pump->GetAmountDigits()))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);

            return NotifyFinalFill(PumpNr, Volume, Amount, 0);
        }
    }
    return FALSE;
}

/*##################  MidSetHdxSpotVolume  ########################
*   Purpose....: Notify HDX spot volume                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
void __export __stdcall MidSetHdxSpotVolume(int Handle)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        pump->SpotVolume = TRUE;
}

/*##################  MidSetHdxSpotAmount  ########################
*   Purpose....: Notify HDX spot amount                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
void __export __stdcall MidSetHdxSpotAmount(int Handle)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        pump->SpotVolume = FALSE;
}

/*##################  MidNotifyHdxSpot  ########################
*   Purpose....: Notify HDX spot check                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyHdxSpot(int Handle, const char *Msg, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;
    long Val;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyHdxSpotData(Msg, &Val))
        {
            if (pump->SpotVolume)
            {
                *Volume = pump->ConvFromPumpVolume(Val);
                return NotifyCalcAmountFill(PumpNr, Volume, Amount, Price, 0);
            }
            else
            {
                *Amount = pump->ConvFromPumpAmount(Val);
                return NotifyCalcVolumeFill(PumpNr, Volume, Amount, Price, 0);
            }
        }
    }
    return FALSE;
}

/*##################  MidNotifyHdxFinal  ########################
*   Purpose....: Notify HDX final fueling data                 #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyHdxFinal(int Handle, const char *Msg, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        if (NotifyHdxFinalData(Msg, Volume, Amount))
        {
            *Volume = pump->ConvFromPumpVolume(*Volume);
            *Amount = pump->ConvFromPumpAmount(*Amount);
            return NotifyFinalFill(PumpNr, Volume, Amount, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyOcppBase  ##############################
*   Purpose....: Notify OCPP filling data                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
void __export __stdcall MidNotifyOcppBase(int Handle, const char *Msg)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;
    char str[40];
    TIniFile ini;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        pump->BaseVolume = GetOcppBase(Msg);

        sprintf(str, "Pump%d", PumpNr);
        ini.GotoSection(str);

        sprintf(str, "%d", pump->BaseVolume);
        ini.WriteVar("Base", str);
    }
}

/*##################  MidNotifyOcppFill  ##############################
*   Purpose....: Notify OCPP filling data                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyOcppFill(int Handle, const char *Msg, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;
    long val;
    char str[40];

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        if (NotifyOcppData(Msg, &val))
        {
            pump->LastVolume = 0;
            pump->LastAmount = 0;

            if (pump->BaseVolume < 0)
            {
                TIniFile ini;

                sprintf(str, "Pump%d", PumpNr);
                ini.GotoSection(str);

                if (ini.ReadVar("Base", str, 100))
                    pump->BaseVolume = atoi(str);            
                else
                    pump->BaseVolume = val;
            }

            val -= pump->BaseVolume;

            *Volume = val;
            *Volume = pump->ConvFromPumpVolume(*Volume);
            return NotifyCalcAmountFill(PumpNr, Volume, Amount, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyOcppFinal  ##############################
*   Purpose....: Notify OCPP final data                             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidNotifyOcppFinal(int Handle, const char *Msg, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;
    long base;
    long final;
    char str[40];

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {
        if (NotifyOcppFinal(Msg, &base, &final))
        {
            if (pump->BaseVolume < 0)
            {
                TIniFile ini;

                sprintf(str, "Pump%d", PumpNr);
                ini.GotoSection(str);

                if (ini.ReadVar("Base", str, 100))
                    pump->BaseVolume = atoi(str);            
                else
                    pump->BaseVolume = final;
            }

            final -= pump->BaseVolume;
            *Volume = final;
            *Volume = pump->ConvFromPumpVolume(*Volume);
            return NotifyCalcAmountFinal(PumpNr, Volume, Amount, 0);
        }
    }
    return FALSE;
}

/*##################  MidNotifyDialectSpot  ###############
*   Purpose....: Notify dialect spot check                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyDialectSpot(int Handle, const char *Msg, int Address, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;
    int ok;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        if (NotifyDialectSpot(Msg, Address, Amount, Price))
            return NotifyCalcVolumeFill(PumpNr, Volume, Amount, Price, 0);

    return FALSE;
}

/*##################  MidNotifyDialectFinal  ###############
*   Purpose....: Notify dialect final data                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyDialectFinal(int Handle, const char *Msg, int Address, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        if (NotifyDialectFinal(Msg, Address, Volume, Amount, Price))
            return NotifyFinalFill(PumpNr, Volume, Amount, Price, 0);

    return FALSE;
}

/*##################  MidNotifyTestFill  ###############
*   Purpose....: Notify test filling data                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyTestFill(int Handle, int InVolume, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        *Volume = pump->ConvFromPumpVolume(InVolume);
        return NotifyCalcAmountFill(PumpNr, Volume, Amount, 0);
    }
    else
        return FALSE;
}

/*##################  MidNotifyTestSpot  ###############
*   Purpose....: Notify test spot check using volume or amount (undecided)                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyTestSpot(int Handle, int InValue, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;
    int Price;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        return NotifyVolumeOrAmountSpot(PumpNr, InValue, Volume, Amount, &Price, 0);
    else
        return FALSE;
}

/*##################  MidNotifyTestVolumeSpot1  ###############
*   Purpose....: Notify test spot check using only volume                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyTestVolumeSpot1(int Handle, int InVolume, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        *Volume = pump->ConvFromPumpVolume(InVolume);
        return NotifyCalcAmountFill(PumpNr, Volume, Amount, 0);
    }
    else
        return FALSE;
}

/*##################  MidNotifyTestVolumeFinal1  ###############
*   Purpose....: Notify test final check using only volume                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyTestVolumeFinal1(int Handle, int InVolume, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        *Volume = pump->ConvFromPumpVolume(InVolume);
        return NotifyCalcAmountFinal(PumpNr, Volume, Amount, 0);
    }
    else
        return FALSE;
}

/*##################  MidNotifyTestAmountSpot1  ###############
*   Purpose....: Notify test spot check using only amount                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyTestAmountSpot1(int Handle, int InAmount, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;
    int Price;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        *Amount = pump->ConvFromPumpAmount(InAmount);
        return NotifyCalcVolumeFill(PumpNr, Volume, Amount, &Price, 0);
    }
    else
        return FALSE;
}

/*##################  MidNotifyTestSpot2  ###############
*   Purpose....: Notify test spot check using volume and amount                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyTestSpot2(int Handle, int InVolume, int InAmount, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        *Volume = pump->ConvFromPumpVolume(InVolume);
        *Amount = pump->ConvFromPumpAmount(InAmount);
        return NotifyFill(PumpNr, Volume, Amount, 0);
    }
    else
        return FALSE;
}

/*##################  MidNotifyTestSpot3  ###############
*   Purpose....: Notify test spot check using volume, amount and price                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyTestSpot3(int Handle, int InVolume, int InAmount, int InPrice, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        *Volume = pump->ConvFromPumpVolume(InVolume);
        *Amount = pump->ConvFromPumpAmount(InAmount);
        *Price = InPrice;
        return NotifyFill(PumpNr, Volume, Amount, Price, 0);
    }
    else
        return FALSE;
}


/*##################  MidNotifyTestFinal2  ###############
*   Purpose....: Notify test final data using volume and amount                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyTestFinal2(int Handle, int InVolume, int InAmount, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        *Volume = pump->ConvFromPumpVolume(InVolume);
        *Amount = pump->ConvFromPumpAmount(InAmount);
        return NotifyFinalFill(PumpNr, Volume, Amount, 0);
    }
    else
        return FALSE;
}

/*##################  MidNotifyTestFinal3  ###############
*   Purpose....: Notify test final data using volume and amount                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidNotifyTestFinal3(int Handle, int InVolume, int InAmount, int InPrice, long *Volume, long *Amount, int *Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
    {        
        *Volume = pump->ConvFromPumpVolume(InVolume);
        *Amount = pump->ConvFromPumpAmount(InAmount);
        *Price = InPrice;
        return NotifyFinalFill(PumpNr, Volume, Amount, Price, 0);
    }
    else
        return FALSE;
}

/*##################  MidInitNoSpotFill  ###############
*   Purpose....: Initiate filling without spot-check data                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidInitNoSpotFill(int Handle)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        return NotifyNoSpotFill(PumpNr);
    else
        return FALSE;
}

/*##################  MidConvToPumpVolume  ###############
*   Purpose....: Cnovert from global volume to pump volume                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidConvToPumpVolume(int Handle, int Volume)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        return pump->ConvToPumpVolume(Volume);
    else
        return 0;
}

/*##################  MidConvFromPumpVolume  ###############
*   Purpose....: Cnovert from pump volume to global volume                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidConvFromPumpVolume(int Handle, int PumpVolume)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        return pump->ConvFromPumpVolume(PumpVolume);
    else
        return 0;
}

/*##################  MidConvToPumpAmount  ###############
*   Purpose....: Cnovert from global amount to pump amount                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidConvToPumpAmount(int Handle, int Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        return pump->ConvToPumpAmount(Amount);
    else
        return 0;
}

/*##################  MidConvFromPumpAmount  ###############
*   Purpose....: Cnovert from pump amount to global amount                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidConvFromPumpAmount(int Handle, int PumpAmount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        return pump->ConvFromPumpAmount(PumpAmount);
    else
        return 0;
}

/*##################  MidConvToPumpPrice  ###############
*   Purpose....: Cnovert from global price to pump price                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidConvToPumpPrice(int Handle, int Price)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        return pump->ConvToPumpPrice(Price);
    else
        return 0;
}

/*##################  MidConvFromPumpPrice  ###############
*   Purpose....: Cnovert from pump price to global price                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export __stdcall MidConvFromPumpPrice(int Handle, int PumpPrice)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        return pump->ConvFromPumpPrice(PumpPrice);
    else
        return 0;
}

/*##################  MidLongConvToPumpVolume  ###############
*   Purpose....: Cnovert from global volume to pump volume                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
long long __export __stdcall MidLongConvToPumpVolume(int Handle, long long Volume)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        return pump->LongConvToPumpVolume(Volume);
    else
        return 0;
}

/*##################  MidLongConvFromPumpVolume  ###############
*   Purpose....: Cnovert from pump volume to global volume                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
long long __export __stdcall MidLongConvFromPumpVolume(int Handle, long long PumpVolume)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        return pump->LongConvFromPumpVolume(PumpVolume);
    else
        return 0;
}

/*##################  MidLongConvToPumpAmount  ###############
*   Purpose....: Cnovert from global amount to pump amount                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
long long __export __stdcall MidLongConvToPumpAmount(int Handle, long long Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        return pump->LongConvToPumpAmount(Amount);
    else
        return 0;
}

/*##################  MidLongConvFromPumpAmount  ###############
*   Purpose....: Cnovert from pump amount to global amount                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
long long __export __stdcall MidLongConvFromPumpAmount(int Handle, long long PumpAmount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidPump *pump = 0;

    if (PumpNr > 0 && PumpNr < MAX_MID_PUMPS)
        pump = PumpArr[PumpNr];

    if (pump)
        return pump->LongConvFromPumpAmount(PumpAmount);
    else
        return 0;
}

/*##################  MidCurrentId  ###############
*   Purpose....: Get current mid-id                                         #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int __export __stdcall MidCurrentId()
{
    return LongStore->GetIndex() + 1;
}

/*##################  MidIsValid  ###############
*   Purpose....: Check if Mid ID has valid data                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int __export __stdcall MidIsValid(int MidId)
{
    TMidData MidData;

    if (MidId)
        if (LongStore->Get(MidId - 1, &MidData))
            return MidData.Valid;
            
    return FALSE;
}

/*##################  MidGetStartTime  ###############
*   Purpose....: Get StartTime for Mid-ID                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
long __export __stdcall MidGetStartTime(int MidId)
{
    TMidData MidData;
    
    if (LongStore->Get(MidId - 1, &MidData))
        return MidData.StartTime;
    else
        return 0;
}

/*##################  MidGetPulseStartTime  ###############
*   Purpose....: Get PulseStartTime for Mid-ID                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
long __export __stdcall MidGetPulseStartTime(int MidId)
{
    TMidData MidData;
    
    if (LongStore->Get(MidId - 1, &MidData))
        return MidData.PulseStartTime;
    else
        return 0;
}

/*##################  MidGetPulseEndTime  ###############
*   Purpose....: Get PulseEndTime for Mid-ID                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
long __export __stdcall MidGetPulseEndTime(int MidId)
{
    TMidData MidData;
    
    if (LongStore->Get(MidId - 1, &MidData))
        return MidData.PulseEndTime;
    else
        return 0;
}

/*##################  MidGetEndTime  ###############
*   Purpose....: Get EndTime for Mid-ID                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
long __export __stdcall MidGetEndTime(int MidId)
{
    TMidData MidData;
    
    if (LongStore->Get(MidId - 1, &MidData))
        return MidData.EndTime;
    else
        return 0;
}

/*##################  MidGetPumpNr  ###############
*   Purpose....: Get pump # for Mid-ID                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int __export __stdcall MidGetPumpNr(int MidId)
{
    TMidData MidData;
    
    if (LongStore->Get(MidId - 1, &MidData))
        return MidData.PumpNr;
    else
        return 0;
}

/*##################  MidGetVolume  ###############
*   Purpose....: Get volume for Mid-ID                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
long __export __stdcall MidGetVolume(int MidId)
{
    TMidData MidData;
    
    if (LongStore->Get(MidId - 1, &MidData))
        return MidData.Volume;
    else
        return 0;
}

/*##################  MidGetAmount  ###############
*   Purpose....: Get amount for Mid-ID                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
long __export __stdcall MidGetAmount(int MidId)
{
    TMidData MidData;
    
    if (LongStore->Get(MidId - 1, &MidData))
        return MidData.Amount;
    else
        return 0;
}

/*##################  MidGetPrice  ###############
*   Purpose....: Get price for Mid-ID                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int __export __stdcall MidGetPrice(int MidId)
{
    TMidData MidData;
    
    if (LongStore->Get(MidId - 1, &MidData))
        return MidData.ExternalPrice;
    else
        return 0;
}

/*##################  MidGetExternalPrice  ###############
*   Purpose....: Get external price for Mid-ID                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int __export __stdcall MidGetExternalPrice(int MidId)
{
    TMidData MidData;
    
    if (LongStore->Get(MidId - 1, &MidData))
        return MidData.ExternalPrice;
    else
        return 0;
}

/*##################  MidGetPumpPrice  ###############
*   Purpose....: Get pump price for Mid-ID                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int __export __stdcall MidGetPumpPrice(int MidId)
{
    TMidData MidData;
    
    if (LongStore->Get(MidId - 1, &MidData))
        return MidData.PumpPrice;
    else
        return 0;
}

/*##################  MidGetPulseErrors  ###############
*   Purpose....: Get pulse errors for Mid-ID                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int __export __stdcall MidGetPulseErrors(int MidId)
{
    TMidData MidData;
    
    if (LongStore->Get(MidId - 1, &MidData))
        return MidData.PulseErrors;
    else
        return 0;
}

/*##################  MidGetProduct  ###############
*   Purpose....: Get product for Mid-ID                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int __export __stdcall MidGetNozzle(int MidId)
{
    TMidData MidData;
    
    if (LongStore->Get(MidId - 1, &MidData))
        return MidData.Nozzle;
    else
        return 0;
}

/*##################  MidGetProdUnit  ###############
*   Purpose....: Get product unit for Mid-ID                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int __export __stdcall MidGetProdUnit(int MidId, char *buf)
{
    TMidData MidData;
    
    if (LongStore->Get(MidId - 1, &MidData))
    {
        strcpy(buf, MidData.ProductUnit);
        return TRUE;
    }
    else
        return FALSE;
}

/*##################  MidGetMd5  ###############
*   Purpose....: Get MD5 for mid-id                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int __export __stdcall MidGetMd5(int MidId, char *buf)
{
    TMidData MidData;
    char str[80];
    TMd5Hash Hash;
    char md5str[16];
    char *ptr;
    int i;
    
    if (LongStore->Get(MidId - 1, &MidData))
    {
        sprintf(str, "%08d%02d%08d%08d%08d", MidId, MidData.PumpNr, MidData.Volume, MidData.Amount, MidData.ExternalPrice);
        Hash.Add(str, strlen(str));

        Hash.GetHashData(md5str);

        ptr = buf;
        
        for (i = 0; i < 16; i++)
        {
            sprintf(str, "%04hX", md5str[i]);
            *ptr = str[2];
            ptr++;
            *ptr = str[3];
            ptr++;
        }
        *ptr = 0;

        return TRUE;
    }
    else
        return FALSE;
}

/*##################  MidPrint  ###############
*   Purpose....: Print SeqNr for Mid-ID                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void __export __stdcall MidPrint(int MidId, int PrinterHandle, int BitmapHandle, int xstart, int ystart, const char *CommonIni, const char *CommonSection, const char *LoadIni, char Delim)
{
    TMidData MidData;
    TMidReceiptForm *form;

    if (LongStore->Get(MidId - 1, &MidData))
    {
        form = MidReceipt->CreateMidForm(CommonIni, CommonSection, LoadIni);
        form->Move(xstart, ystart);
        form->Apply(MidId, &MidData, Delim, ModuleCrc);
        form->SetBackTransparent();
        form->Show();
        MidReceipt->Apply(BitmapHandle);
        delete form;
    }
    
    RdosPrintBitmap(PrinterHandle, BitmapHandle);
}

/*##################  MidPrintCotex  ###############
*   Purpose....: Create cotex print for SeqNr for Mid-ID                                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void __export __stdcall MidPrintCotex(int MidId, TCotexTag *tag, int xstart, int ystart, const char *CommonIni, const char *CommonSection, const char *LoadIni, char Delim)
{
    TMidData MidData;
    TMidReceiptForm *form;

    if (LongStore->Get(MidId - 1, &MidData))
    {
        form = MidReceipt->CreateMidForm(CommonIni, CommonSection, LoadIni);
        form->Move(xstart, ystart);
        form->Apply(MidId, &MidData, Delim, ModuleCrc);
        form->SetBackTransparent();
        form->Show();
        MidReceipt->Save(tag);
        delete form;
    }
}

/*##################  MidShowLongStorage  ###############
*   Purpose....: Create bitmap for long-term storage item                   #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void __export __stdcall MidShowLongStorage(int MidId, int BitmapHandle, int xstart, int ystart, const char *CommonIni, const char *CommonSection, const char *LoadIni, char Delim)
{
    TMidData MidData;
    TMidBitmapForm *form;

    if (LongStore->Get(MidId - 1, &MidData))
    {
        form = MidBitmap->CreateMidForm(CommonIni, CommonSection, LoadIni);
        form->Move(xstart, ystart);
        form->Apply(MidId, &MidData, Delim);
        form->SetBackTransparent();
        form->Show();
        MidBitmap->Apply(BitmapHandle);
        delete form;
    }
}

/*##################  GetMidData  ###########################################
*   Purpose....: Populate mid data structure from mid entry data            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
int GetMidData(int midId, TMidData *midData) 
{
        return (LongStore->Get(midId - 1, midData));
}


/*##################  GetMidCC  #############################################
*   Purpose....: Return the MID DLL checksum as calculated on startup       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
unsigned short int GetMidCRC() {
    return ModuleCrc;
}

/*##################  FormatVolume  ###############
*   Purpose....: Format volume using correct precision                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                      #
*##########################################################################*/
void FormatVolume(char *str, struct TMidData *data, char delim)
{
    int value = data->Volume;
    
    switch (data->UsedVolumeDigits)
    {
        case 0:
            value = value / 100;
            sprintf(str, "%d", value);
            break;

        case 1:
            value = value / 10;
            sprintf(str, "%d%c%01d", value / 10, delim, value % 10);
            break;
        
        default:
            sprintf(str, "%d%c%02d", value / 100, delim, value % 100);
            break;
    }                       
}

/*##################  FormatAmount  ###############
*   Purpose....: Format amount using correct precision                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                      #
*##########################################################################*/
void FormatAmount(char *str, struct TMidData *data, char delim)
{
    int value = data->Amount;
    
    switch (data->UsedAmountDigits)
    {
        case 0:
            value = value / 100;
            sprintf(str, "%d", value);
            break;

        case 1:
            value = value / 10;
            sprintf(str, "%d%c%01d", value / 10, delim, value % 10);
            break;
        
        default:
            sprintf(str, "%d%c%02d", value / 100, delim, value % 100);
            break;
    }                       
}

/*##################  FormatPrice  ###############
*   Purpose....: Format price using correct precision                       #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                      #
*##########################################################################*/
void FormatPrice(char *str, struct TMidData *data, char delim)
{
    int value = data->ExternalPrice;
    
    switch (data->UsedPriceDigits)
    {
        case 0:
            value = value / 1000;
            sprintf(str, "%d", value);
            break;

        case 1:
            value = value / 100;
            sprintf(str, "%d%c%01d", value / 10, delim, value % 10);
            break;

        case 2:        
            value = value / 10;
            sprintf(str, "%d%c%02d", value / 100, delim, value % 100);
            break;

        default:
            sprintf(str, "%d%c%03d", value / 1000, delim, value % 1000);
            break;

    }                       
}

/*##################  MidHasConsistenceError  ##############################
*   Purpose....: Check for consistence error                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
int __export __stdcall MidHasConsistenceError(int Handle)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidCustomer *customer = LockMidCustomer(PumpNr);
    int ok = FALSE;

    if (customer)
        ok = customer->HasConsistenceError();
        

    UnlockMidCustomer(PumpNr);

    return ok;
}

/*##################  MidGetRawData  ##############################
*   Purpose....: Get last raw data                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
void __export __stdcall MidGetRawData(int Handle, long *Volume, long *Amount)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidCustomer *customer = LockMidCustomer(PumpNr);

    *Volume = -1;
    *Amount = -1;

    if (customer)
        customer->GetRawData(Volume, Amount);
        
    UnlockMidCustomer(PumpNr);
}

/*##################  MidUseRawData  ##############################
*   Purpose....: Use raw data instead of calculated                                          #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                     #
*##########################################################################*/
void __export __stdcall MidUseRawData(int Handle)
{
    int PumpNr = HandleToPumpNr(Handle);
    TMidCustomer *customer = LockMidCustomer(PumpNr);

    if (customer)
        customer->UseRawData();
        
    UnlockMidCustomer(PumpNr);
}


/*##################  MidSetupFiscal  ###############
*   Purpose....: Init MID setup fiscal module                                              #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: MID ID                                                          #
*##########################################################################*/
int __export _stdcall MidSetupFiscal(const char *Name, int Handle)
{
    TIniFile ini;
    int ok;
    char str[101];

    if (FiscalHandle)
        return FALSE;

    ini.GotoSection("MID");

    ok = ini.ReadVar("Fiscal", str, 101);
    if (ok)
    {
        if (strcmp(Name, str))
            ok = FALSE;
    }
    else
    {
        strcpy(str, Name);
        strcat(str, " fiscal module configured");
        LogDownloadRow(str);
        ok = ini.WriteVar("Fiscal", Name);
    }

    if (ok)
        FiscalHandle = Handle;

    return ok;
}


/*##################  MidMarkFiscal  ###############
*   Purpose....: Mark mid-id as fiscal                                      #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*##########################################################################*/
void __export __stdcall MidMarkFiscal(int Handle, int MidId)
{
    TMidData MidData;

    if (Handle == 0)
        return;

    if (Handle != FiscalHandle)
        return;
    
    if (LongStore->Get(MidId - 1, &MidData))
    {
        if (MidData.Valid)
        {
            MidData.Valid = 2;

            LongStore->Update(MidId, &MidData);
        }
    }
}
