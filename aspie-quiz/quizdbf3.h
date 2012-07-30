
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
	int Children;
	int Relationship;
	char Aspie;
	char ADHD;
	char OCD;
	char Social;
	long AsResult;
	long NtResult;
	char Quiz[300];
	char GroupResult[ACTIVE_GROUP_COUNT];
};
