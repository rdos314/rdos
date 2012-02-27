
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
	 char Lang;
	char Aspie;
	char ADHD;
	char OCD;
	char Social;
	int PredAs;
	int PredAdd;
	int PredOcd;
	int PredSocial;
	long AsResult;
	long NtResult;
	char Quiz[250];
	char GroupResult[ACTIVE_GROUP_COUNT];
};
