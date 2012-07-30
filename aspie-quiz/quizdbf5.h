
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
	int Distance;
	char Aspie;
	char ADHD;
	char OCD;
	char Social;
	long AsResult;
	long NtResult;
	char Quiz[200];
	char GroupResult[ACTIVE_GROUP_COUNT];
};
