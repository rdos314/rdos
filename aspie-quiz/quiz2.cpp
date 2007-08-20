/*#######################################################################
# RDOS operating system
# Copyright (C) 1988-2002, Leif Ekblad
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version. The only exception to this rule
# is for commercial usage in embedded systems. For information on
# usage in commercial embedded systems, contact embedded@rdos.net
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# The author of this program may be contacted at leif@rdos.net
#
# quiz2.cpp
# Quiz II class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "quiz2.h"
#include "file.h"
#include "quizdb2.h"

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizII::TQuizII
#
#   Purpose....: Constructor for TQuizII
#
#   In params..: Filename to load quiz II from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizII::TQuizII(const char *FileName, TQuiz *QuizI)
  : TQuiz(100),
    FDataFile(FileName)
{
    DefineCross(0, QuizI);

    SetupTexts();
    InitReferers();
    LoadReferers();
    SetupControlGroups();
	SortReferers();
    LoadPopulations();
	SetupCross(QuizI);
    Calculate();
}

/*##########################################################################
#
#   Name       : TQuizII::~TQuizII
#
#   Purpose....: Destructor for TQuizII
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizII::~TQuizII()
{
}

/*##################  TQuizII::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizII::GetPcaCount()
{
	return 3;
}

/*##########################################################################
#
#   Name       : TQuizII::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizII::WriteName(TFile &File)
{
    File.Write("II");
}

/*##########################################################################
#
#   Name       : TQuizII::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizII::SetupTexts()
{
	Quiz[16].Reverse = TRUE;
	Quiz[37].Reverse = TRUE;
	Quiz[43].Reverse = TRUE;
	Quiz[44].Reverse = TRUE;
	Quiz[47].Reverse = TRUE;
    Quiz[54].Reverse = TRUE;
    Quiz[55].Reverse = TRUE;
    Quiz[73].Reverse = TRUE;
    Quiz[74].Reverse = TRUE;
    Quiz[76].Reverse = TRUE;
    Quiz[77].Reverse = TRUE;
    Quiz[80].Reverse = TRUE;
    Quiz[89].Reverse = TRUE;
    Quiz[92].Reverse = TRUE;
	Quiz[93].Reverse = TRUE;

	Quiz[0].MyGroup = GROUP_SENSORY;
	Quiz[1].MyGroup = GROUP_NONVERBAL;
	Quiz[2].MyGroup = GROUP_SENSORY;
	Quiz[3].MyGroup = GROUP_SENSORY;
	Quiz[4].MyGroup = GROUP_SENSORY;
	Quiz[5].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[6].MyGroup = GROUP_SENSORY;
	Quiz[7].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[8].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[9].MyGroup = GROUP_SENSORY;
	Quiz[10].MyGroup = GROUP_SENSORY;
	Quiz[11].MyGroup = GROUP_SENSORY;
	Quiz[12].MyGroup = GROUP_SENSORY;
	Quiz[13].MyGroup = GROUP_ASPIE_COMM;
	Quiz[14].MyGroup = GROUP_ASPIE_COMM;
	Quiz[15].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[16].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[17].MyGroup = GROUP_NONVERBAL;
	Quiz[18].MyGroup = GROUP_ASPIE_NVC;
	Quiz[19].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[20].MyGroup = GROUP_ASPIE_COMM;
	Quiz[21].MyGroup = GROUP_NONVERBAL;
	Quiz[22].MyGroup = GROUP_NONVERBAL;
	Quiz[23].MyGroup = GROUP_NONVERBAL;
	Quiz[24].MyGroup = GROUP_NONVERBAL;
	Quiz[25].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[26].MyGroup = GROUP_ASPIE_NVC;
	Quiz[27].MyGroup = GROUP_ASPIE_COMM;
	Quiz[28].MyGroup = GROUP_ASPIE_NVC;
	Quiz[29].MyGroup = GROUP_NONVERBAL;
	Quiz[30].MyGroup = GROUP_NT_TALENT;
	Quiz[31].MyGroup = GROUP_ASPIE_NVC;
	Quiz[32].MyGroup = GROUP_NONVERBAL;
	Quiz[33].MyGroup = GROUP_NT_TALENT;
	Quiz[34].MyGroup = GROUP_ASPIE_COMM;
	Quiz[35].MyGroup = GROUP_ASPIE_COMM;
	Quiz[36].MyGroup = GROUP_ASPIE_COMM;
	Quiz[37].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[38].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[39].MyGroup = GROUP_ASPIE_COMM;
	Quiz[40].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[41].MyGroup = GROUP_NONVERBAL;
	Quiz[42].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[43].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[44].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[45].MyGroup = GROUP_ASPIE_COMM;
	Quiz[46].MyGroup = GROUP_ASPIE_COMM;
	Quiz[47].MyGroup = GROUP_NONVERBAL;
	Quiz[48].MyGroup = GROUP_NONVERBAL;
	Quiz[49].MyGroup = GROUP_NONVERBAL;
	Quiz[50].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[51].MyGroup = GROUP_ASPIE_COMM;
	Quiz[52].MyGroup = GROUP_MIXED;
	Quiz[53].MyGroup = GROUP_ASPIE_COMM;
	Quiz[54].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[55].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[56].MyGroup = GROUP_SEX;
	Quiz[57].MyGroup = GROUP_SEX;
	Quiz[58].MyGroup = GROUP_SEX;
	Quiz[59].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[60].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[61].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[62].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[63].MyGroup = GROUP_NT_TALENT;
	Quiz[64].MyGroup = GROUP_NT_TALENT;
	Quiz[65].MyGroup = GROUP_NT_TALENT;
	Quiz[66].MyGroup = GROUP_ASPIE_COMM;
	Quiz[67].MyGroup = GROUP_ASPIE_COMM;
	Quiz[68].MyGroup = GROUP_ASPIE_COMM;
	Quiz[69].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[70].MyGroup = GROUP_NONVERBAL;
	Quiz[71].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[72].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[73].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[74].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[75].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[76].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[77].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[78].MyGroup = GROUP_ASPIE_COMM;
	Quiz[79].MyGroup = GROUP_SENSORY;
	Quiz[80].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[81].MyGroup = GROUP_ASPIE_COMM;
	Quiz[82].MyGroup = GROUP_ASPIE_COMM;
	Quiz[83].MyGroup = GROUP_ASPIE_COMM;
	Quiz[84].MyGroup = GROUP_SENSORY;
	Quiz[85].MyGroup = GROUP_ASPIE_COMM;
	Quiz[86].MyGroup = GROUP_ASPIE_COMM;
	Quiz[87].MyGroup = GROUP_ASPIE_COMM;
	Quiz[88].MyGroup = GROUP_ASPIE_COMM;
	Quiz[89].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[90].MyGroup = GROUP_NT_TALENT;
	Quiz[91].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[92].MyGroup = GROUP_NT_TALENT;
	Quiz[93].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[94].MyGroup = GROUP_ASPIE_COMM;
	Quiz[95].MyGroup = GROUP_NT_TALENT;
	Quiz[96].MyGroup = GROUP_ASPIE_BIOLOGY;
	Quiz[97].MyGroup = GROUP_ASPIE_BIOLOGY;
	Quiz[98].MyGroup = GROUP_ASPIE_BIOLOGY;
	Quiz[99].MyGroup = GROUP_ASPIE_BIOLOGY;

#ifdef ENGLISH

	Quiz[0].Text = "Do you notice small sounds that others don't, and feel pained by loud or irritating noise?";
	Quiz[1].Text = "Do you have problems distinguishing voices from background noise, or from other voices?";
	Quiz[2].Text = "Do you feel uncomfortable in fluorescent light?";
	Quiz[3].Text = "Do you have a very acute sense of smell and/or taste?";
	Quiz[4].Text = "Do you feel strongly attracted to, or appalled by, certain tastes, smells, sounds, colours, shapes, textures or materials?";
	Quiz[5].Text = "Do you dislike being touched - especially without prior warning, by the \"wrong\" person or at the \"wrong\" time?";
	Quiz[6].Text = "Are you easily overexcited, stressed and overwhelmed by things like noise, crowds, clutter, patterns, flicker and movement?";
	Quiz[7].Text = "Do you get exceedingly tired after socializing, and need to regenerate alone?";
	Quiz[8].Text = "Do you have difficulties judging distances, height, depth or speed?";
	Quiz[9].Text = "Do you have an unusual sensitivity to pain?";
	Quiz[10].Text= "Are you sensitive to electromagnetic fields?";
	Quiz[11].Text = "Do you often use peripheral vision?";
	Quiz[12].Text = "Do you believe in ghosts and / or supernatural phenomens?";
	Quiz[13].Text = "Do you often get depressed during winter-time (SAD)?";
	Quiz[14].Text = "Do you often have thoughts of committing suicide?";
	Quiz[15].Text = "Were you clumsy as a child?";
	Quiz[16].Text = "Did you learn to crawl as a baby?";
	Quiz[17].Text = "Did you have speech difficulties as a child?'";
	Quiz[18].Text = "Do you have a history of bed-wetting past 5 years of age?";
	Quiz[19].Text = "Did you perceive practical classes like handi-work or gymnasics as hard in school?";
	Quiz[20].Text = "Do you feel much younger inside than your biological age?";
	Quiz[21].Text = "Do you find it hard to tell the age of people?";
	Quiz[22].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
	Quiz[23].Text = "Do you have difficulties interpreting body language and/or facial expressions and figuring out what people feel and want, unless they tell you?";
	Quiz[24].Text = "Do you have problems recognizing faces out of their usual context (e.g. your doctor at the supermarket without his white robe)?";
	Quiz[25].Text = "Do you find it easier to understand & communicate with computers, animals and/or Aspies than with 'ordinary' people?";
	Quiz[26].Text = "Do you have an odd posture, gait and/or difficulties sitting/standing erect?";
	Quiz[27].Text = "Do you perceive moving legs as a signal of nervousness?";
	Quiz[28].Text = "Do people sometimes think you are smiling at the wrong occasion?";
	Quiz[29].Text = "Do you have a monotonous voice and/or difficulty adjusting volume and speed when you talk?";
	Quiz[30].Text = "Do you get confused by verbal instructions - especially several at the same time?";
	Quiz[31].Text = "Do you sometimes say \"we\" instead of \"I\"?";
	Quiz[32].Text = "Do you mostly talk when you have something concrete to say?";
	Quiz[33].Text = "Do you find it difficult to read written material unless it is very interesting or very easy?";
	Quiz[34].Text = "Do you sometimes flip letters?";
	Quiz[35].Text = "Do you more easily get very upset over 'minor' things (e.g. losing your favourite pen) than over which others get upset about (e.g. a relative passing away)?";
	Quiz[36].Text = "Do you sometimes get very emotional about simple objects?";
	Quiz[37].Text = "Do you find it easy to describe your feelings and emotions to others?";
	Quiz[38].Text = "Are you sometimes very calm in situations that others find stressful?";
	Quiz[39].Text = "Do you expect other people to know your thoughts, experiences and opinions?";
	Quiz[40].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
	Quiz[41].Text = "Are you usually unaware of social rules & boundaries unless they are specifically spelled out?";
	Quiz[42].Text = "Do you find social chitchat difficult, tiresome and/or a waste of time?";
	Quiz[43].Text = "Do you enjoy meeting new people every day?";
	Quiz[44].Text = "Do you enjoy being in a big crowd, such as a football game?";
	Quiz[45].Text = "Have you had the feeling of playing a game to pretend to be like people around you?";
	Quiz[46].Text = "Do you find it natural to keep track of whom owes whom favours?";
	Quiz[47].Text = "Do you know when you are expected to offer an apology?";
	Quiz[48].Text = "Do you have difficulty summarizing and reporting conversations or describing events?";
	Quiz[49].Text = "Do others often misunderstand you?";
	Quiz[50].Text = "Do you have more difficulties than others of the same age when it comes to making friendships and getting into relationships?";
	Quiz[51].Text = "Is it hard for you to break up from a relationship?";
	Quiz[52].Text = "Can you often appreciate people without putting demands on them?";
 	Quiz[53].Text = "Do you have an alternative view of what is attractive in the opposite sex compared to most others?";
 	Quiz[54].Text = "Do you find the usual courting behavior natural?";
	Quiz[55].Text = "Do you find it natural that males take initiatives to start a romantic relationship?";
 	Quiz[56].Text = "Are you homosexual or bisexual?";
 	Quiz[57].Text = "Do you feel like you were born with the wrong gender?";
 	Quiz[58].Text = "Do you have an interest in or have practised BD/SM?";
 	Quiz[59].Text = "Are you asexual?";
	Quiz[60].Text = "Do you have unconventional, often unique ways of solving problems?";
	Quiz[61].Text = "Is you imagination unusual, with unique ideas that others don't have?";
	Quiz[62].Text = "Do you like to work out how things work?";
	Quiz[63].Text = "If you work on more than one project at a time do you seldom finish them?";
	Quiz[64].Text = "Are you easily distracted and/or bored?";
	Quiz[65].Text = "Are you impatient and have low frustration tolerance?";
	Quiz[66].Text = "Do you have irregular eating habits that are adapted to what you are doing right now?";
	Quiz[67].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
 	Quiz[68].Text = "Does it cause chaos in your body or mind if your plans, environment or daily routines suddenly get changed, or if an activity that is important to you gets interrupted?";
	Quiz[69].Text = "Are you punctual, conscientious and perfectionist?";
 	Quiz[70].Text = "Are you so honest and sincere yourself that you assume everyone is, and therefore easily miss dishonesty and hidden agendas?";
 	Quiz[71].Text = "Do you dislike shaking hands?";
	Quiz[72].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";
 	Quiz[73].Text = "Do you have an interest for fashions?";
	Quiz[74].Text = "Do you enjoy the status of a new car/new stereo/new TV?";
 	Quiz[75].Text = "Do you more often get things because you need them than because others have them?";
 	Quiz[76].Text = "Do your friends mean more to you than hobbies and interests?";
	Quiz[77].Text = "Is your style and image very important to you?";
 	Quiz[78].Text = "Is your sense of humor different from mainstream and / or considered odd?";
	Quiz[79].Text = "Are you very interested in environmental issues?";
 	Quiz[80].Text = "Do you enjoy gossip?";
 	Quiz[81].Text = "Have you had an urge to try drugs or illegal substances?";
 	Quiz[82].Text = "Do you find the norms of hygiene too strict?";
 	Quiz[83].Text = "Do you think others should have the same friends and enemies as yourself?";
	Quiz[84].Text = "Do you prefer to go bare footed over using footwear?";
 	Quiz[85].Text = "Did you prefer to sleep in your parents bed rather than in your own room as a child?";
 	Quiz[86].Text = "Do you have an intense dislike for the military?";
 	Quiz[87].Text = "Do you feel an urge to peel flakes off yourself and / or others?";
 	Quiz[88].Text = "Do you like to collect items to make a set?";
 	Quiz[89].Text = "Do you prefer romance/drama films to science fiction/documentary films?";
 	Quiz[90].Text = "Do you frequently misplace things?";
	Quiz[91].Text = "Do you often find reasons to question authorities?";
 	Quiz[92].Text = "Do you find it easy to organize your daily life?";
 	Quiz[93].Text = "Do you appreciate to be in charge of other people?";
 	Quiz[94].Text = "Do you have difficulty accepting criticism, correction, and direction?";
 	Quiz[95].Text = "Do you have money management difficulties?";
	Quiz[96].Text = "Do you have fair skin that burn easy?";
 	Quiz[97].Text = "Do you have freckles?";
	Quiz[98].Text = "Are you flat-footed?";
	Quiz[99].Text = "Do you have crooked teeth or underbite?";

#endif

#ifdef SWEDISH
 
 	Quiz[0].Text = "Brukar du höra ljud som andra inte hör och plågas av höga eller störande ljud?";
 	Quiz[1].Text = "Har du svårt att urskilja röster från bakgrundsljud, eller från andra röster?";
	Quiz[2].Text = "Är du känslig för vissa typer av ljus, t.ex lysrörsljus? ";
	Quiz[3].Text = "Har du extra känsligt lukt- och/eller smaksinne? ";
 	Quiz[4].Text = "Brukar du känna stark lust eller häftigt obehag av vissa färger, former, dofter, smaker, material eller konsistenser?";
 	Quiz[5].Text = "Ogillar du beröring - särskilt oväntad, av \"fel\" person eller vid \"fel\" tillfälle? ";
 	Quiz[6].Text = "Blir du lätt överstimulerad och stressad av för mycket ljud, mönster, flimmer, oreda, trängsel o. dyl.?";
 	Quiz[7].Text = "Brukar du bli utmattad av att umgås med folk och efteråt behöva vila ut ifred?";
 	Quiz[8].Text = "Har du svårigheter att bedöma avstånd, höjd, djup och hastighet?";
 	Quiz[9].Text = "Har du ovanlig känslighet för smärta? ";
 	Quiz[10].Text= "Är du känslig för elektromagnetiska fält?";
 	Quiz[11].Text = "Tittar du ofta i ögonvrån? ";
	Quiz[12].Text = "Tror du på spöken och / eller övernaturliga fenomen?";
 	Quiz[13].Text = "Brukar du drabbas av depressioner under vintern (SAD)?";
 	Quiz[14].Text = "Har du ofta självmordstankar?";
 	Quiz[15].Text = "Var du klumpig som barn?";
 	Quiz[16].Text = "Lärde du dig att krypa som barn?";
 	Quiz[17].Text = "Hade du talsvårigheter som barn?";
	Quiz[18].Text = "Kissade du i sängen efter 5 års ålder?";
	Quiz[19].Text = "Tyckte du praktiska ämnen som slöjd och gymnastik var svårt i skolan?";
 	Quiz[20].Text = "Känner du dig mycket yngre än din biologiska ålder?";
 	Quiz[21].Text = "Har du svårt för att bedöma andra människors ålder?";
	Quiz[22].Text = "I samtal, brukar du ibland ha problem med saker som timing, turtagning och ömsesidighet?";
 	Quiz[23].Text = "Brukar du ha svårt för att tolka kroppsspråk och ansiktsuttryck och att förstå vad andra känner och vill om de inte säger det rakt ut?";
 	Quiz[24].Text = "Har du svårt för att känna igen ansikten i oväntade sammanhang (t ex din läkare i snabbköpet utan sin vita rock?";
 	Quiz[25].Text = "Har du lättare att förstå dig på datorer, djur och/eller Aspergare än att umgås och kommunicera framgångsrikt med \"vanliga\" människor? ";
 	Quiz[26].Text = "Har du ovanlig kroppshållning, gångstil och/eller svårt att sitta/stå upprätt? ";
 	Quiz[27].Text = "Tolkar du viftande ben som ett tecken på nervositet?";
 	Quiz[28].Text = "Tycker andra ibland att du ler vid fel tillfällen?";
 	Quiz[29].Text = "Har du en monoton röst och/eller svårigheter att finjustera ljudnivå och hastighet när du talar?";
 	Quiz[30].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
 	Quiz[31].Text = "Säger du ibland \"vi\" istället för \"jag\"?";
	Quiz[32].Text = "Brukar du tala endast när du upplever att du har något konkret att säga?";
 	Quiz[33].Text = "Tycker du det är svårt att läsa skrivet material om det inte antingen är väldigt intressant eller lättläst?";
 	Quiz[34].Text = "Vänder du ibland på bokstäver?";
	Quiz[35].Text = "Brukar du bli mer upprörd över smärre saker (t ex att du tappat din favoritpenna eller någon satt sig på din favoritplats) än över sånt som andra blir upprörda av (t ex en släktings bortgång)?";
 	Quiz[36].Text = "Brukar du ofta fästa dig vid olika föremål?";
 	Quiz[37].Text = "Tycker du det är lätt att beskriva dina känslor för andra?";
 	Quiz[38].Text = "Är du ibland väldigt lugn i situationer som andra blir stressade av?";
 	Quiz[39].Text = "Förväntar du dig att andra vet om dina tankar, upplevelser och åsikter?";
 	Quiz[40].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
 	Quiz[41].Text = "Är du oftast omedveten om outtalade sociala regler?";
 	Quiz[42].Text = "Tycker du att vanligt kallprat är svårt, plågsamt eller slöseri med tid? ";
	Quiz[43].Text = "Tycker du om att möta nya människor varje dag?";
	Quiz[44].Text = "Tycker du om att vara bland mycket folk som t.ex. på en fotbollsmatch?";
 	Quiz[45].Text = "Har du haft en känsla av att spela ett spel för att vara som andra runt omkring dig?";
 	Quiz[46].Text = "Känns det naturligt för dig att hålla reda på tjänster och gentjänster?";
 	Quiz[47].Text = "Känner du på dig när det förväntas att du ska be folk om ursäkt?";
 	Quiz[48].Text = "Har du problem med att redogöra för konversationer eller händelser och att sammanfatta?";
 	Quiz[49].Text = "Blir du ofta missförstådd av andra?";
 	Quiz[50].Text = "Har du svårare än dina jämnåriga att få vänner och/eller partners?";
	Quiz[51].Text = "Har du svårt för att bryta upp från ett förhållande?";
 	Quiz[52].Text = "Uppskattar du ofta folk på ett kravlöst sätt?";
	Quiz[53].Text = "Har du avvikande uppfattning om vad som är attraktivt hos det motsatta könet än vad många andra anser?";
 	Quiz[54].Text = "Tycker du att det normala sättet att uppvakta varandra är naturligt?";
 	Quiz[55].Text = "Tycker du det är naturligt att män tar initiativ till att starta ett förhållande?";
 	Quiz[56].Text = "Är du homosexuell eller bisexuell?";
	Quiz[57].Text = "Känns det som du föddes med fel kön?";
 	Quiz[58].Text = "Har du intresse för eller har du medverkat i BD/SM?";
 	Quiz[59].Text = "Är du asexuell?";
 	Quiz[60].Text = "Har du okonventionella, ofta unika sätt att lösa problem på?";
 	Quiz[61].Text = "Är din fantasi ovanlig med unika idéer som andra inte har?";
 	Quiz[62].Text = "Tycker du om att reda ut hur saker fungerar? ";
 	Quiz[63].Text = "Om du jobbar med mer än ett projekt slutför du då sällan dem? ";
	Quiz[64].Text = "Blir du lätt distraherad och/eller uttråkad?";
 	Quiz[65].Text = "Är du otålig och lättfrustrerad?";
 	Quiz[66].Text = "Har du oregelbunda mattider som anpassas efter det du för stunden håller på med?";
 	Quiz[67].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
 	Quiz[68].Text = "Blir det kaos inom dig om det händer något oväntat som förändrar din miljö, dina planer, rutiner eller som avbryter dig mitt i en för dig viktig aktivitet?";
	Quiz[69].Text = "Är du punktlig, noggrann och/eller perfektionistisk?";
	Quiz[70].Text = "Är du så ärlig och uppriktig själv att du utgår från att alla är det och därför lätt missar oärlighet och dolda motiv?";
	Quiz[71].Text = "Ogillar du att behöva ta i hand?";
 	Quiz[72].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";
 	Quiz[73].Text = "Är du intressad av mode?";
 	Quiz[74].Text = "Njuter du av den status som en ny bil/stereo/TV ger?";
 	Quiz[75].Text = "Skaffar du dig oftare prylar för att du behöver dem än för att andra har dem?";
 	Quiz[76].Text = "Betyder dina vänner mer för dig än dina hobbies och intressen?";
 	Quiz[77].Text = "Är din stil och image mycket viktig för dig?";
 	Quiz[78].Text = "Är ditt sinne för humor annorlunda än andras och / eller ansett som udda?";
 	Quiz[79].Text = "Är du väldigt intresserad av miljöfrågor?";
	Quiz[80].Text = "Tycker du om skvaller?";
 	Quiz[81].Text = "Har du haft ett intresse av att prova på droger eller olagliga substanser?";
 	Quiz[82].Text = "Tycker du att normerna för hygien är för strikta?";
	Quiz[83].Text = "Tycker du andra borde ha samma vänner och fiender som du själv?";
 	Quiz[84].Text = "Tycker du bättre om att gå barfota än med skor på?";
 	Quiz[85].Text = "Föredrog du att sova i dina föräldrars säng hellre än att sova själv som barn?";
 	Quiz[86].Text = "Ogillar du intensivt militären?";
 	Quiz[87].Text = "Känner du behov av att rycka loss hudflisor från dig själv (eller andra)?";
	Quiz[88].Text = "Tycker du om att samla på saker?";
 	Quiz[89].Text = "Föredrar du filmer om romantik / drama före filmer om vetenskap/dokumentärer?";
 	Quiz[90].Text = "Tappar du ofta bort saker?";
	Quiz[91].Text = "Tycker du att det ofta finns skäl att ifrågasätta auktoriteter?";
	Quiz[92].Text = "Tycker du det är enkelt att organisera ditt dagliga liv?";
 	Quiz[93].Text = "Uppskattar du att leda andra människor?";
	Quiz[94].Text = "Har du svårt för att acceptera kritik, korrektion och direktiv?";
 	Quiz[95].Text = "Har du svårt att hantera din ekonomi?";
	Quiz[96].Text = "Har du ljus hy som lätt blir bränd av solen?";
 	Quiz[97].Text = "Har du fräknar?";
 	Quiz[98].Text = "Är du plattfot??";
 	Quiz[99].Text = "Har du sneda tänder eller underbett?";

#endif

}

/*##########################################################################
#
#   Name       : TQuizII::InitReferers
#
#   Purpose....: Init referers
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizII::InitReferers()
{
	AddReferer("livejournal.com/community/asperger", "livejournal.com/community/asperger");
	AddReferer("lushforum.co.uk", "lushforum.co.uk");
	AddReferer("whoa.nu", "whoa.nu");
	AddReferer("flashback.info", "flashback.info");
	AddReferer("gentlechristianmothers.com", "gentlechristianmothers.com");
	AddReferer("georgewbush.org", "georgewbush.org");
	AddReferer("aspie-forum.htm", "groups.yahoo.com/group/aspie-forum");
	AddReferer("fam.htm", "groups.yahoo.com/group/FAMSecretSociety");
	AddReferer("aspiesforfreedom.", "aspiesforfreedom.com");
	AddReferer("aspergianisland.com", "aspergianisland.com");
	AddReferer("ddrsverige.com", "ddrsverige.com");
	AddReferer("nevro.info", "nevro.info");
	AddReferer("google.com", "google.com");
	AddReferer("wrongplanet.net", "wrongplanet.net");
	AddReferer("xmission.com/~winter", "xmission.com/~winter");
	AddReferer("rdos.net/sv", "rdos.net/sv");
}

/*##########################################################################
#
#   Name       : TQuizII::UpdateReferer
#
#   Purpose....: Update a referer
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizII::UpdateReferer(TReferer *ref, int AsResult, int NtResult)
{
	int diff;

	ref->Count++;
	ref->AsResult += AsResult;
	ref->NtResult += NtResult;

	diff = AsResult - NtResult;

	if (diff >= 35)
		ref->ResultAs++;
	else
	{
		if (diff <= -35)
			ref->ResultNt++;
		else
			ref->ResultMixed++;
	}
}

/*##################  TQuizII::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizII::LoadReferers()
{
	TQuizRow Row;
	TReferer *ref;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		ref = FindReferer(Row.Referer);
		if (!ref)
			ref = AddReferer(Row.Referer, Row.Referer);

		if (ref)
			UpdateReferer(ref, Row.AsResult, Row.NtResult);

		switch (Row.Diagnos)
		{
			case DX_AS:
				ref = &DxAsRef;
				break;

			case DX_TS:
				ref = &DxTsRef;
				break;

			case DX_ADD:
				ref = &DxAddRef;
				break;

			case SELF_AS:
				ref = &SelfAsRef;
				break;

			case SELF_TS:
				ref = &SelfTsRef;
				break;

			case SELF_ADD:
				ref = &SelfAddRef;
				break;

			default:
				ref = 0;
				break;
		}

		if (ref)
			UpdateReferer(ref, Row.AsResult, Row.NtResult);

		switch (Row.Diagnos)
		{
			case DX_AS:
			case SELF_AS:
				if (Row.Gender == 1)
					ref = &MaleAsRef;
				else
					ref = &FemaleAsRef;
				break;

			default:
				ref = 0;
				break;
		}

		if (ref)
			UpdateReferer(ref, Row.AsResult, Row.NtResult);

	}
}

/*##########################################################################
#
#   Name       : TQuizII::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizII::LoadPopulations()
{
	TQuizRow Row;
	int i;
	 TReferer *ref;
	 int aspie = FALSE;

	 for (i = 0; i < N; i++)
		  Quiz[i].NoAnswer = 0;

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		  for (i = 0; i < N; i++)
		  {
				if (Row.Quiz[i] == 0)
					 Quiz[i].NoAnswer++;

		  }

		switch (Row.Diagnos)
		{
			 case DX_AS:
			 case SELF_AS:
					aspie = TRUE;
					 if (Row.AsResult < 100)
						  LowAs.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

					if (Row.Gender == 1)
					{
						if (Row.BirthYear > 1986)
							YoungMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

						AsMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
					}
					else
					{
						if (Row.BirthYear > 1986)
							YoungFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

						AsFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
					}

					if (Row.Diagnos == DX_AS)
						As.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

					if (Row.Diagnos == SELF_AS)
						AspieControl.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
				break;

			case DX_ADD:
			case SELF_ADD:
				 Add.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
				if (Row.Gender == 1)
					AddMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
				else
					AddFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
				break;

			case DX_TS:
			case SELF_TS:
				Ts.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
				break;
		}

		All.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);

		if (strlen(Row.Referer) == 0)
		{
			 Mix.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				MixMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			else
				MixFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}
		else
		{
			ref = FindReferer(Row.Referer);
			if (ref && ref->NT)
				NtControl.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}

		if (Row.NtResult - Row.AsResult >= 35)
		{
			Nt.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				NtMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			else
				NtFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}

		if (Row.AsResult - Row.NtResult >= 35)
		{

			Aspie.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			if (Row.Gender == 1)
				AspieMale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
			else
				AspieFemale.Add(Row.AsResult, Row.NtResult, aspie, Row.Quiz, Row.GroupResult);
		}
	}
}

/*##########################################################################
#
#   Name       : TQuizII::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizII::SetupControlGroups()
{
	DefineNt("rdos.net/sv");
	DefineNt("lushforum.co.uk");
	DefineNt("flashback.info");
	DefineNt("whoa.nu");
	DefineNt("gentlechristianmothers.com");
	DefineNt("ddrsverige.com");

	DefineAspie("wrongplanet.net");
	DefineAspie("livejournal.com/community/asperger");
	DefineAspie("aspie-forum.htm");
	DefineAspie("aspiesforfreedom.");
	DefineAspie("aspergianisland.com");
	DefineAspie("xmission.com/~winter");
}

/*##########################################################################
#
#   Name       : TQuizII::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizII::SetupCross(TQuiz *QuizI)
{
	DefineCross(QuizI, 0, 52);
	DefineCross(QuizI, 1, 53);
	DefineCross(QuizI, 2, 55);
	DefineCross(QuizI, 3, 56);
	DefineCross(QuizI, 4, 57);
	DefineCross(QuizI, 5, 61);
	DefineCross(QuizI, 6, 64);
	DefineCross(QuizI, 7, 65);
	DefineCross(QuizI, 8, 45);
	DefineGlobalId(    9, 100);
	DefineGlobalId(    10, 101);
	DefineGlobalId(    11, 102);
	DefineGlobalId(    12, 103);
	DefineGlobalId(    13, 104);
	DefineGlobalId(    14, 105);
	DefineGlobalId(    15, 106);
	DefineGlobalId(    16, 107);
	DefineGlobalId(    17, 108);
	DefineGlobalId(    18, 109);
	DefineGlobalId(    19, 110);
	DefineGlobalId(    20, 111);
	DefineGlobalId(    21, 112);
	DefineCross(QuizI, 22, 82);
	DefineCross(QuizI, 23, 87);
	DefineCross(QuizI, 24, 88);
	DefineCross(QuizI, 25, 89);
	DefineCross(QuizI, 26, 42);
	DefineGlobalId(    27, 113);
	DefineGlobalId(    28, 114);
	DefineCross(QuizI, 29, 17);
	DefineCross(QuizI, 30, 2);
	DefineGlobalId(    31, 115);
	DefineGlobalId(    32, 116);
	DefineGlobalId(    33, 117);
	DefineGlobalId(    34, 118);
	DefineCross(QuizI, 35, 76);
	DefineGlobalId(    36, 119);
	DefineGlobalId(    37, 120);
	DefineGlobalId(    38, 121);
	DefineGlobalId(    39, 122);
	DefineCross(QuizI, 40, 69);
	DefineCross(QuizI, 41, 81);
	DefineCross(QuizI, 42, 97);
	DefineGlobalId(    43, 123);
	DefineGlobalId(    44, 124);
	DefineGlobalId(    45, 125);
	DefineGlobalId(    46, 126);
	DefineGlobalId(    47, 127);
	DefineGlobalId(    48, 128);
	DefineGlobalId(    49, 129);
	DefineCross(QuizI, 50, 90);
	DefineGlobalId(    51, 130);
	DefineGlobalId(    52, 131);
	DefineGlobalId(    53, 132);
	DefineGlobalId(    54, 133);
	DefineGlobalId(    55, 134);
	DefineGlobalId(    56, 135);
	DefineGlobalId(    57, 136);
	DefineGlobalId(    58, 137);
	DefineGlobalId(    59, 138);
	DefineCross(QuizI, 60, 22);
	DefineGlobalId(    61, 139);
	DefineGlobalId(    62, 140);
	DefineGlobalId(    63, 141);
	DefineGlobalId(    64, 142);
	DefineGlobalId(    65, 143);
	DefineGlobalId(    66, 144);
	DefineCross(QuizI, 67, 36);
	DefineCross(QuizI, 68, 39);
	DefineCross(QuizI, 69, 9);
	DefineCross(QuizI, 70, 91);
	DefineCross(QuizI, 71, 72);
	DefineCross(QuizI, 72, 99);
	DefineGlobalId(    73, 145);
	DefineGlobalId(    74, 146);
	DefineGlobalId(    75, 147);
	DefineGlobalId(    76, 148);
	DefineGlobalId(    77, 149);
	DefineGlobalId(    78, 150);
	DefineGlobalId(    79, 151);
	DefineGlobalId(    80, 152);
	DefineGlobalId(    81, 153);
	DefineGlobalId(    82, 154);
	DefineGlobalId(    83, 155);
	DefineGlobalId(    84, 156);
	DefineGlobalId(    85, 157);
	DefineGlobalId(    86, 158);
	DefineGlobalId(    87, 159);
	DefineGlobalId(    88, 160);
	DefineGlobalId(    89, 161);
	DefineGlobalId(    90, 162);
	DefineGlobalId(    91, 163);
	DefineGlobalId(    92, 164);
	DefineGlobalId(    93, 165);
	DefineGlobalId(    94, 166);
	DefineGlobalId(    95, 167);
	DefineGlobalId(    96, 168);
	DefineGlobalId(    97, 169);
	DefineGlobalId(    98, 170);
	DefineGlobalId(    99, 171);
}

/*##########################################################################
#
#   Name       : TQuizII::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizII::GetReferer(const char *referer, TPopulation *pop)
{
	int i;
	TReferer *ref;
	TQuizRow Row;

	for (i = 0; i < RefCount; i++)
	{
		ref = RefArr[i];
		if (ref->IsMatch(referer))
			break;
	}

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
		if (ref->IsMatch(Row.Referer))
		    pop->Add(Row.AsResult, Row.NtResult, FALSE, Row.Quiz, Row.GroupResult);
}

/*##################  IsPca ##########################
*   Purpose....: Check quiz row against pca-type                 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
static int IsPca(TQuizRow *row, int PcaType)
{
    switch (PcaType)
    {
		case PCA_TYPE_ALL:
		case PCA_TYPE_MIXED:
			return TRUE;

		case PCA_TYPE_MALE:
			if (row->Gender == 1)
				return TRUE;
			else
				return FALSE;

		case PCA_TYPE_FEMALE:
			if (row->Gender == 2)
				return TRUE;
			else
				return FALSE;

		case PCA_TYPE_YOUNG:
            if (row->BirthYear >= 1980)
                return TRUE;
            else
                return FALSE;

        case PCA_TYPE_OLD:
            if (row->BirthYear <= 1965)
                return TRUE;
            else
                return FALSE;

        case PCA_TYPE_AS:
            if (row->Diagnos == DX_AS)
				return TRUE;
            else
                return FALSE;
                
    }
    return FALSE;
}

/*##################  TQuizII::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizII::ExportExcelCase(const char *filename, int PcaType)
{
	TQuizRow Row;
    int i;
    int ival;
    char str[80];
	TFile file(filename, 0);

    file.Write("\"\", ");
    file.Write("\"\", ");

	for (i = 0; i < N; i++)
	{
		if (PcaType != PCA_TYPE_MIXED || Quiz[i].MyGroup == GROUP_MIXED)
		{
			file.Write("\"");

//        	strncpy(str, Quiz[i].Text, 35);
//        	str[35] = 0;
			sprintf(str, "#%d", i + 1);
			file.Write(str);

			file.Write("\"");
			if (i != N - 1)
				file.Write(", ");
		}
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (IsPca(&Row, PcaType))
		{
			sprintf(str, "\%d\", ", Row.AsResult);
			file.Write(str);

			sprintf(str, "\"%d\", ", Row.Diagnos);
			file.Write(str);

			for (i = 0; i < N; i++)
			{
				if (PcaType != PCA_TYPE_MIXED || Quiz[i].MyGroup == GROUP_MIXED)
				{
					ival = Row.Quiz[i];
					if (ival)
						ival--;

					if (ival > 2)
						ival = 0;

					sprintf(str, "\"%d\"", ival);
					file.Write(str);
					if (i != N - 1)
						file.Write(", ");
				}
			}
			file.Write("\n");
		}
	}
}

/*##################  TQuizII::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizII::ImportMvsp(const char *filename, int PcaType)
{
	char buf[MAX_IN_ROW];
	int size;
	char *rowstr;
	char *ptr;
	long pos = 0;
	int i;
	long double d1, d2, d3;
	int q;
	int count;
	TFile infile(filename);

	while (size = infile.Read(buf, MAX_IN_ROW))
	{
		buf[size] = 0;
		rowstr = strstr(buf, "#");
		if (rowstr)
		{
			rowstr++;
			ptr = strstr(rowstr, "\r");
			if (ptr)
				 *ptr = 0;
			else
				 rowstr = 0;
		}

		pos += strlen(buf) + 1;
		infile.SetPos(pos);

		if (rowstr)
		{
			for (i = 0; i < strlen(rowstr); i++)
			{
				switch (rowstr[i])
				{
					case ',':
						rowstr[i] = '.';
						break;

					case 0x9:
					case 0xd:
						rowstr[i] = ' ';
						break;
				}
			}

			if (sscanf(rowstr, "%d %Lf %Lf %Lf", &q, &d1, &d2, &d3) == 4)
			{
				if (PcaType != PCA_TYPE_MIXED)
				{
					if (PcaType == PCA_TYPE_AS || PcaType == PCA_TYPE_ALL || PcaType == PCA_TYPE_MALE)
						d2 = -d2;

					if (PcaType == PCA_TYPE_ALL)
					    d3 = -d3;
				}

				switch (PcaType)
				{
					case PCA_TYPE_ALL:
						Quiz[q - 1].Pca[0] = d1;
						Quiz[q - 1].Pca[1] = d2;
						Quiz[q - 1].Pca[2] = d3;
						break;

					case PCA_TYPE_MALE:
						Quiz[q - 1].MalePca[0] = d1;
						Quiz[q - 1].MalePca[1] = d2;
						Quiz[q - 1].MalePca[2] = d3;
						break;

					case PCA_TYPE_FEMALE:
						Quiz[q - 1].FemalePca[0] = d1;
						Quiz[q - 1].FemalePca[1] = d2;
						Quiz[q - 1].FemalePca[2] = d3;
						break;

					case PCA_TYPE_YOUNG:
						Quiz[q - 1].YoungPca[0] = d1;
						Quiz[q - 1].YoungPca[1] = d2;
						Quiz[q - 1].YoungPca[2] = d3;
						break;

					case PCA_TYPE_OLD:
						Quiz[q - 1].OldPca[0] = d1;
						Quiz[q - 1].OldPca[1] = d2;
						Quiz[q - 1].OldPca[2] = d3;
						break;

					case PCA_TYPE_AS:
						Quiz[q - 1].AsPca[0] = d1;
						Quiz[q - 1].AsPca[1] = d2;
						Quiz[q - 1].AsPca[2] = d3;
						break;

					case PCA_TYPE_MIXED:
						Quiz[q - 1].MixedPca[0] = d1;
						Quiz[q - 1].MixedPca[1] = d2;
						Quiz[q - 1].MixedPca[2] = d3;
						break;

				}
			}
		}
	}
}
