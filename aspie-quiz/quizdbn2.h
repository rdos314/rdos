
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
	int PredBipolar;
	int PredSocial;
	long AsResult;
	long NtResult;
	char Quiz[250];
	char Rating[10];
	char GroupResult[ACTIVE_GROUP_COUNT];
};
