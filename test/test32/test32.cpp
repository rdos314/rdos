#include <rdos.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "serial.h"
#include "section.h"
#include "file.h"

#include <math.h>

#define FALSE 0
#define TRUE !FALSE

#define MAX_SAVED_SPOTS 15
#define MAX_USED_SPOTS  10

struct TDataValue
{
    int ID;
    long Value;
};

struct TDataPath
{
    int Size;
    int IndArr[MAX_SAVED_SPOTS];
};

int FCurrID = 0;
int FBestPath;

int FCount;
struct TDataValue FArr[MAX_SAVED_SPOTS];

/*################## Add  ###############
*   Purpose....: Add volume value                                           #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                      #
*##########################################################################*/
void Add(long Value)
{
    int i;

    FCurrID++;

    if (FCount)
        if (Value == FArr[FCount - 1].Value)
            return;
    
    if (FCount == MAX_SAVED_SPOTS)
    {
        for (i = 1; i < MAX_SAVED_SPOTS; i++)
            FArr[i-1] = FArr[i];

        FCount--;
    }

    FArr[FCount].Value = Value;
    FArr[FCount].ID = FCurrID;
    FCount++;
}

/*##################  CountSpotPath  ###############
*   Purpose....: Count entries for spot path                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                      #
*##########################################################################*/
void CountSpotPath(struct TDataPath *Path, int DataCount, struct TDataValue DataArr[MAX_SAVED_SPOTS])
{
    long val;
    int DataPos;
    int Index = Path->Size - 1;

    DataPos = Path->IndArr[Index];
    val = DataArr[DataPos].Value;
    DataPos++;

    while (DataPos < DataCount)
    {
        if (DataArr[DataPos].Value > val)
        {
            Index++;
            Path->IndArr[Index] = DataPos;
            val = DataArr[DataPos].Value;
        }
        DataPos++;
    }

    Path->Size = Index + 1;
}

/*##################  WalkSpotPath  ###############
*   Purpose....: Try to setup next path entry                               #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                      #
*##########################################################################*/
int WalkSpotPath(struct TDataPath *Path, int DataCount, struct TDataValue DataArr[MAX_SAVED_SPOTS])
{
    long val;
    int DataPos;
    int Index = Path->Size - 1;
    int found = FALSE;

    DataPos = Path->IndArr[Index-1];
    val = DataArr[DataPos].Value;

    DataPos = Path->IndArr[Index];
    DataPos++;

    while (DataPos < DataCount)
    {
        if (DataArr[DataPos].Value > val)
        {
            Path->IndArr[Index] = DataPos;
            found = TRUE;
            break;
        }
        DataPos++;
    }

    return found;
}

/*################## ExtractSpotPath  ###############
*   Purpose....: Extract spot path                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                      #
*##########################################################################*/
void ExtractSpotPath(struct TDataPath *Path, struct TDataValue SpotArr[MAX_USED_SPOTS], struct TDataValue DataArr[MAX_SAVED_SPOTS])
{
    int Index = Path->Size;
    int i;
    int start = 0;
    int count = Index;
    int ind;

    if (count > MAX_USED_SPOTS)
    {
        start = count - MAX_USED_SPOTS;
        count = MAX_USED_SPOTS;
    }
    
    for (i = 0; i < count; i++)
    {
        ind = Path->IndArr[i + start];
        SpotArr[i].Value = DataArr[ind].Value;
        SpotArr[i].ID = DataArr[ind].ID;
    }
}

/*##################  HandleSpotPath  ###############
*   Purpose....: Handle spot path                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                      #
*##########################################################################*/
void HandleSpotPath(struct TDataPath *Path, struct TDataValue SpotArr[MAX_USED_SPOTS], int DataCount, struct TDataValue DataArr[MAX_SAVED_SPOTS])
{
    int i;
    int ok;
    int size;
 
    size = Path->Size;

    ok = WalkSpotPath(Path, DataCount, DataArr);
    while (ok)
    {
        CountSpotPath(Path, DataCount, DataArr);
        if (Path->Size >= FBestPath)
        {
            FBestPath = Path->Size;
            ExtractSpotPath(Path, SpotArr, DataArr);
        }

        for (i = Path->Size; i > size; i--)
        {
            Path->Size = i;
            HandleSpotPath(Path, SpotArr, DataCount, DataArr);
        }

        Path->Size = size;
        ok = WalkSpotPath(Path, DataCount, DataArr);
    }
}

/*################## GetOptimalSpotPath  ###############
*   Purpose....: Get longest spot path                                     #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                      #
*##########################################################################*/
int GetOptimalSpotPath(struct TDataValue SpotArr[MAX_USED_SPOTS], int DataCount, struct TDataValue DataArr[MAX_SAVED_SPOTS])
{
    int StartPos = 0;
    int ind;
    int wind;
    int ok;
    int i;
    struct TDataPath path;

    FBestPath = 0;

    if (DataCount == 0)
        return 0;

    for (StartPos = 0; StartPos < DataCount; StartPos++)
    {
        path.Size = 1;
        path.IndArr[0] = StartPos;

        CountSpotPath(&path, DataCount, DataArr);
        if (path.Size >= FBestPath)
        {
            FBestPath = path.Size;
            ExtractSpotPath(&path, SpotArr, DataArr);
        }

        for (i = path.Size; i > 1; i--)
        {
            path.Size = i;
            HandleSpotPath(&path, SpotArr, DataCount, DataArr);
        }
    }

    if (FBestPath <= MAX_USED_SPOTS)
        return FBestPath;
    else
        return MAX_USED_SPOTS;
}

/*################## GetSpotFlow  ###############
*   Purpose....: Get spot check flow                                        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                      #
*##########################################################################*/
void GetSpotFlow(int SpotCount, struct TDataValue SpotArr[MAX_USED_SPOTS], long FlowArr[MAX_USED_SPOTS])
{
    int i;
    int diff;
    long temp;

    for (i = 1; i < SpotCount; i++)
    {
        diff = SpotArr[i].ID - SpotArr[i-1].ID;
        temp = SpotArr[i].Value;
        temp -= SpotArr[i-1].Value;
        temp = temp / diff;
        FlowArr[i-1] = temp;
    }
}

/*################## GetSpotFlowAverage  ###############
*   Purpose....: Get spot check average flow                                #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                      #
*##########################################################################*/
long GetSpotFlowAverage(int FlowCount, long FlowArr[MAX_USED_SPOTS])
{
    int i;
    long sum = 0;

    for (i = 0; i < FlowCount; i++)
        sum += FlowArr[i];

    return sum / FlowCount;
}

/*################## GetSpotFlowSd2  ###############
*   Purpose....: Get spot check flow squared standard deviation             #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                      #
*##########################################################################*/
long long GetSpotFlowSd2(long Average, int FlowCount, long FlowArr[MAX_USED_SPOTS])
{
    int i;
    long long sum = 0;
    long val;

    for (i = 0; i < FlowCount; i++)
    {
        val = FlowArr[i] - Average;
        sum += (long long)val * (long long)val;
    }

    return sum / (long long)(FlowCount - 1);
}

/*################## GetSqrt  ###############
*   Purpose....: Get square root                                            #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                      #
*##########################################################################*/
long GetSqrt(long long Value)
{
    int i;
    int digits;
    long long temp;
    long long base;
    long long diff;

    for (i = 0; i < 31; i++)
    {
        temp = (long long)1 << (2 * i);
        if (temp > Value)
            break;
    }

    digits = i - 1;
    base = (long long)1 << digits;

    for (i = digits - 1; i >= 0; i--)
    {
        diff = (long long)1 << i;
        temp = base + diff;
        if (temp * temp < Value)
            base += diff;        
    }

    return base;
}

void main()
{
    int handle1, handle2;
    int handle3, handle4;
    unsigned int mode;
    int len;
    char buf[32];
    int size;
    int pos;
    int val;
    
    handle1 = RdosOpenHandle("fil.txt", O_RDONLY);

    val = RdosEofHandle(1);
    val = RdosEofHandle(2);
    val = RdosEofHandle(handle1);

    handle3 = RdosDupHandle(handle1);

    memset(buf, 0, 32);
    RdosReadHandle(handle3, buf, 32);
    val = RdosEofHandle(handle3);
        
    handle4 = RdosDup2Handle(handle3, 2);

    size = RdosGetHandleSize(handle4);
    RdosSetHandleSize(handle4, size - 1);

    mode = RdosGetHandleMode(handle4);
    mode |= _WRITE;
    RdosSetHandleMode(handle4, mode);

    pos = RdosGetHandlePos(handle4);
    RdosSetHandlePos(handle4, pos - 6);
    
    strcpy(buf, "Testing");
    len = strlen(buf);
    RdosWriteHandle(handle4, buf, len);

    
    if (handle2)
        RdosCloseHandle(handle2);
    if (handle1)
        RdosCloseHandle(handle1);


    int count;
    struct TDataValue SpotArr[MAX_USED_SPOTS];
    long FlowArr[MAX_USED_SPOTS];
    long avg;
    long long sd2;
    long tavg;
    long long tsd2;
    long sd;
    long tsd;

    Add(20);
    Add(40);
    Add(140);
    Add(60);
    Add(80);
    Add(180);

    count = GetOptimalSpotPath(SpotArr, FCount, FArr);

    if (count > 3)
    {
        GetSpotFlow(count, SpotArr, FlowArr);
        tavg = GetSpotFlowAverage(count - 1, FlowArr);
        tsd2 = GetSpotFlowSd2(tavg, count - 1, FlowArr);
        avg = GetSpotFlowAverage(count - 2, FlowArr);
        sd2 = GetSpotFlowSd2(avg, count - 2, FlowArr);

        tsd = GetSqrt(tsd2);
        sd = GetSqrt(sd2);
    }
}
