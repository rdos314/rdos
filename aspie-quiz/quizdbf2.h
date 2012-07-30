
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
	long Un;
	long Ue;
	long Uo;
	long Ua;
	long Uc;
	long Sn;
	long Se;
	long So;
	long Sa;
	long Sc;
	char Quiz[300];
	char GroupResult[ACTIVE_GROUP_COUNT];
};
