
struct TQuizRow
{
    long ID;
    long UserID;
    long LsbTime;
    long MsbTime;
    long FilloutTime;
    int  BirthYear;
    int  BirthMonth;
	char Gender;
	int Country;
	int Ancestry;
	char Aspie;
	char ADHD;
	char OCD;
	char Social;
	long AsResult;
	long NtResult;
	long TsResult;
	char Quiz[250];
	char GroupResult[ACTIVE_GROUP_COUNT];
};
