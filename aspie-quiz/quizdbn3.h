
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
	char Dyslexia;
	char OCD;
	char Bipolar;
	char Social;
	int PredAs;
	int PredAdd;
	int PredDyslexia;
	int PredOcd;
	int PredSocial;
	long AsResult;
	long NtResult;
	long EatResult;
	char Quiz[250];
	char GroupResult[ACTIVE_GROUP_COUNT];
};
