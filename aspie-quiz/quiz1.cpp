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
# quiz1.cpp
# Quiz I class
#
########################################################################*/

#include <string.h>
#include <stdio.h>

#include "quiz1.h"
#include "file.h"
#include "quizdb.h"

#define MAX_IN_ROW		4096

#define FALSE 0
#define TRUE !FALSE

/*##########################################################################
#
#   Name       : TQuizI::TQuizI
#
#   Purpose....: Constructor for TQuizI
#
#   In params..: File to load quiz I from
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizI::TQuizI(const char *FileName)
  : TQuiz(100),
    FDataFile(FileName)
{
    UseNtResult = FALSE;
    
    SetupTexts();
    InitReferers();
    LoadReferers();
    SetupControlGroups();
	SortReferers();
    LoadPopulations();
	SetupCross();
    Calculate();
}

/*##########################################################################
#
#   Name       : TQuizI::~TQuizI
#
#   Purpose....: Destructor for TQuizI
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
TQuizI::~TQuizI()
{
}

/*##################  TQuizI::GetPcaCount ##########################
*   Purpose....: Return number of available PCA axises  	       	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
int TQuizI::GetPcaCount()
{
	return 1;
}

/*##########################################################################
#
#   Name       : TQuizI::WriteName
#
#   Purpose....: Write quiz name
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizI::WriteName(TFile &File)
{
    File.Write("I");
}

/*##########################################################################
#
#   Name       : TQuizI::SetupTexts
#
#   Purpose....: Init quiz texts and more
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizI::SetupTexts()
{
	Quiz[0].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[1].MyGroup = GROUP_MIXED;
	Quiz[2].MyGroup = GROUP_NT_TALENT;
	Quiz[3].MyGroup = GROUP_NT_TALENT;
	Quiz[4].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[5].MyGroup = GROUP_NT_TALENT;
	Quiz[6].MyGroup = GROUP_NT_TALENT;
	Quiz[7].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[8].MyGroup = GROUP_NT_TALENT;
	Quiz[9].MyGroup = GROUP_MIXED;
	Quiz[10].MyGroup = GROUP_NT_TALENT;
	Quiz[11].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[12].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[13].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[14].MyGroup = GROUP_ASPIE_NVC;
	Quiz[15].MyGroup = GROUP_ASPIE_NVC;
	Quiz[16].MyGroup = GROUP_ASPIE_NVC;
	Quiz[17].MyGroup = GROUP_NONVERBAL;
	Quiz[18].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[19].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[20].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[21].MyGroup = GROUP_OCD;
	Quiz[22].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[23].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[24].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[25].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[26].MyGroup = GROUP_NT_TALENT;
	Quiz[27].MyGroup = GROUP_ENVIRONMENT;
	Quiz[28].MyGroup = GROUP_OCD;
	Quiz[29].MyGroup = GROUP_ENVIRONMENT;
	Quiz[30].MyGroup = GROUP_ENVIRONMENT;
	Quiz[31].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[32].MyGroup = GROUP_MIXED;
	Quiz[33].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[34].MyGroup = GROUP_OCD;
	Quiz[35].MyGroup = GROUP_OCD;
	Quiz[36].MyGroup = GROUP_OCD;
	Quiz[37].MyGroup = GROUP_OCD;
	Quiz[38].MyGroup = GROUP_OCD;
	Quiz[39].MyGroup = GROUP_OCD;
	Quiz[40].MyGroup = GROUP_ASPIE_NVC;
	Quiz[41].MyGroup = GROUP_ASPIE_BIOLOGY;
	Quiz[42].MyGroup = GROUP_ASPIE_NVC;
	Quiz[43].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[44].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[45].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[46].MyGroup = GROUP_NT_BIOLOGY;
	Quiz[47].MyGroup = GROUP_MIXED;
	Quiz[48].MyGroup = GROUP_MIXED;
	Quiz[49].MyGroup = GROUP_NT_TALENT;
	Quiz[50].MyGroup = GROUP_OCD;
	Quiz[51].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[52].MyGroup = GROUP_SENSORY;
	Quiz[53].MyGroup = GROUP_SENSORY;
	Quiz[54].MyGroup = GROUP_MIXED;
	Quiz[55].MyGroup = GROUP_SENSORY;
	Quiz[56].MyGroup = GROUP_SENSORY;
	Quiz[57].MyGroup = GROUP_SENSORY;
	Quiz[58].MyGroup = GROUP_SENSORY;
	Quiz[59].MyGroup = GROUP_SENSORY;
	Quiz[60].MyGroup = GROUP_SENSORY;
	Quiz[61].MyGroup = GROUP_SENSORY;
	Quiz[62].MyGroup = GROUP_SENSORY;
	Quiz[63].MyGroup = GROUP_OCD;
	Quiz[64].MyGroup = GROUP_SENSORY;
	Quiz[65].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[66].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[67].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[68].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[69].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[70].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[71].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[72].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[73].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[74].MyGroup = GROUP_MIXED;
	Quiz[75].MyGroup = GROUP_MIXED;
	Quiz[76].MyGroup = GROUP_OCD;
	Quiz[77].MyGroup = GROUP_MIXED;
	Quiz[78].MyGroup = GROUP_MIXED;
	Quiz[79].MyGroup = GROUP_MIXED;
	Quiz[80].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[81].MyGroup = GROUP_NONVERBAL;
	Quiz[82].MyGroup = GROUP_NONVERBAL;
	Quiz[83].MyGroup = GROUP_NONVERBAL;
	Quiz[84].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[85].MyGroup = GROUP_NONVERBAL;
	Quiz[86].MyGroup = GROUP_NONVERBAL;
	Quiz[87].MyGroup = GROUP_NONVERBAL;
	Quiz[88].MyGroup = GROUP_NONVERBAL;
	Quiz[89].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[90].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[91].MyGroup = GROUP_NONVERBAL;
	Quiz[92].MyGroup = GROUP_ENVIRONMENT;
	Quiz[93].MyGroup = GROUP_ENVIRONMENT;
	Quiz[94].MyGroup = GROUP_NONVERBAL;
	Quiz[95].MyGroup = GROUP_MIXED;
	Quiz[96].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[97].MyGroup = GROUP_ASPIE_SOCIAL;
	Quiz[98].MyGroup = GROUP_ASPIE_TALENT;
	Quiz[99].MyGroup = GROUP_ASPIE_TALENT;


#ifdef ENGLISH

	Quiz[0].Text = "Are you very logical and get surprised or impatient when others aren't?";
	Quiz[1].Text = "Do you find visualizing easy?";
	Quiz[2].Text = "Do you get confused by verbal instructions - especially several at the same time?";
	Quiz[3].Text = "Do you need to see, touch or do things yourself in order to remember them?";
	Quiz[4].Text = "Do you take an interest in, and remember, details that others do not seem to notice?";
	Quiz[5].Text = "Do you tend to get so stuck on details that you miss the overall picture?";
	Quiz[6].Text = "Do you find it difficult to generalize?";
	Quiz[7].Text = "Are you fascinated by dates and/or numbers?";
	Quiz[8].Text = "Is it easier and more interesting for you to focus on the outer form (e.g. the font and layout of a text) than on the actual content?";
	Quiz[9].Text = "Are you punctual, conscientious and perfectionist?";
	Quiz[10].Text = "Do you find concrete things easier to grasp than abstract concepts?";
	Quiz[11].Text = "Do you have excellent long-term memory in subjects that interest you?";
	Quiz[12].Text = "Do you have excellent vocabulary and/or a fascination with words?";
	Quiz[13].Text = "Is it difficult or tiresome for you to talk?";
	Quiz[14].Text = "Do you have a habit of repeating your own or others' last words, internally or out loud (echolalia)?";
	Quiz[15].Text = "Do you sometimes mix up pronouns and, for example, say \"you\" or \"we\" when you mean \"me\" or vice versa?";
	Quiz[16].Text = "Do you use stock phrases or phrases borrowed from other situations or people?";
	Quiz[17].Text = "Do you have a monotonous voice and/or difficulty adjusting volume and speed when you talk?";
	Quiz[18].Text = "Are you very gifted in one or more areas?";
	Quiz[19].Text = "Do you focus on one interest at a time and become an expert on that subject?";
	Quiz[20].Text = "Do you enjoy gathering information about categories of things (types of birds, cars etc.)?";
	Quiz[21].Text = "Do you love to collect and organize things, make lists & diagrams etc?";
	Quiz[22].Text = "Do you have unconventional, often unique ways of solving problems?";
	Quiz[23].Text = "Do you have an ability to stick to something that interests you and not give up?";
	Quiz[24].Text = "Does it feel vitally important to be left undisturbed to persue your special interests?";
	Quiz[25].Text = "Do you tend to get so absorbed in your projects that you forget everything else (e.g. eating, sleeping, taking a shower, other people)?";
	Quiz[26].Text = "Do you find it hard to multi-task or shift your attention rapidly from one thing to another and therefore need to finish one task before turning to the next?";
	Quiz[27].Text = "Do you feel stress, panic or have a brain malfunction in unfamiliar or demanding situations?";
	Quiz[28].Text = "Before doing something or going somewhere, do you need to have a picture in your mind of what's going to happen so as to be able to preparei yourself mentally first?";
	Quiz[29].Text = "Do you feel a lot safer if you have a trusted companion with you?";
	Quiz[30].Text = "Is it harder for you to make it on your own, than it seems to be for most others of your age?";
	Quiz[31].Text = "Do you have a tendency to be passive and not initiate things yourself?";
	Quiz[32].Text = "Do you prefer the company of those older than yourself to that of your peers?";
	Quiz[33].Text = "Do you prefer to only meet people you know, one-on-one, or in small, familiar groups?";
	Quiz[34].Text = "Do you have a need for comfort items like blankets, stuffed animals etc?";
	Quiz[35].Text = "Do you have certain simple & logical routines which you need to follow?";
	Quiz[36].Text = "Do you prefer to wear the same clothes and/or eat the same food every day?";
	Quiz[37].Text = "Do you need to sit on your favourite seat, go the same route or shop in the same shop every time?";
	Quiz[38].Text = "Do you have very strong attachments to certain objects, e.g. a favourite cup or a favourite towel and really need to have that precise one?";
	Quiz[39].Text = "Does it cause chaos in your body or mind if your plans, environment or daily routines suddenly get changed, or if an activity that is important to you gets interrupted?";
	Quiz[40].Text = "Do you use self-stimulation i.e., rocking, tapping, humming, staring at a rotating object etc., to increase concentration & attention or to calm down and relax?";
	Quiz[41].Text = "Do you look younger than your biological age??";
	Quiz[42].Text = "Do you have an odd posture, gait and/or difficulties sitting/standing erect?";
	Quiz[43].Text = "Do you have difficulties with fine motor skills and/or hand-eye co-ordination?";
	Quiz[44].Text = "Do you have poor gross motor skills (= clumsiness)?";
	Quiz[45].Text = "Do you have difficulties judging distances, height, depth or speed?";
	Quiz[46].Text = "Do you confuse left and right?";
	Quiz[47].Text = "Are you fairly insensitive to, or have unusual reactions to, physical pain?";
	Quiz[48].Text = "Do you have unusual sleeping patterns?";
	Quiz[49].Text = "Do you have poor concept of time?";
	Quiz[50].Text = "Do you have obsessions or compulsions (repeated irresistible impulses to do certain things)?";
	Quiz[51].Text = "Are you musically gifted? Do you, for example, have perfect pitch and/or the ability to play one or more instruments?";
	Quiz[52].Text = "Do you notice small sounds that others don't, and feel pained by loud or irritating noise?";
	Quiz[53].Text = "Do you have problems distinguishing voices from background noise, or from other voices?";
	Quiz[54].Text = "Do recently heard phrases, tunes or rhythms tend to stick and repeat themselves in your head?";
	Quiz[55].Text = "Do you feel uncomfortable in fluorescent light?";
	Quiz[56].Text = "Do you have a very acute sense of smell and/or taste?";
	Quiz[57].Text = "Do you feel strongly attracted to, or appalled by, certain tastes, smells, sounds, colours, shapes, textures or materials?";
	Quiz[59].Text = "Do you love water?";
	Quiz[58].Text = "Do you have to be particular with what you eat and/or how it is combined on the plate in order not to get sick?";
	Quiz[59].Text = "Are you sensitive to heat, cold, wind and/or changes in air-pressure, humidity etc?";
	Quiz[60].Text = "Do you feel tortured by clothes tags, clothes that are too tight in certain places or are made in the 'wrong' material?";
	Quiz[61].Text = "Do you dislike being touched - especially without prior warning, by the \"wrong\" person or at the \"wrong\" time?";
	Quiz[62].Text = "If you have to be touched, do you prefer it to be firmly rather than lightly?";
	Quiz[63].Text = "Do you have a need for order and neatness?";
	Quiz[64].Text = "Are you easily overexcited, stressed and overwhelmed by things like noise, crowds, clutter, patterns, flicker and movement?";
	Quiz[65].Text = "Do you get exceedingly tired after socializing, and need to regenerate alone?";
	Quiz[66].Text = "Are you more of an observer than one who participates in life - being a detached observer ?";
	Quiz[67].Text = "Are you fairly self-absorbed, more interested in yourself than in others and/or an objective observer of yourself?";
	Quiz[68].Text = "Do you find yourself more attracted to things, ideas, music, computers, animals, buildings or vehicles than to people and social exchange?";
	Quiz[69].Text = "Do you dislike or have difficulty with team sports and other group endeavours?";
	Quiz[70].Text = "Do you mostly prefer to play/work/do things on your own - in your own way and at your own pace?";
	Quiz[71].Text = "Do you have problems with eye-contact?";
	Quiz[72].Text = "Do you dislike shaking hands?";
	Quiz[73].Text = "Are you fairly cool & dispassionate and usually only have feelings when provoked or excited?";
	Quiz[74].Text = "Do you easily get frustrated and upset when you are stressed, tired, hungry, interrupted, questioned, over-stimulated, or when things don't go as you had anticipated?";
	Quiz[75].Text = "Do you tend to express your feelings in ways that may baffle others (e.g. banging your head in the wall, or being unable to show anything at all)?";
	Quiz[76].Text = "Do you more easily get very upset over 'minor' things (e.g. losing your favourite pen) than over which others get upset about (e.g. a relative passing away)?";
	Quiz[77].Text = "Do you sometimes not feel anything at all, even though other people expect you to?";
	Quiz[78].Text = "Are you sometimes so empathic that you feel other peoples' or animals' feelings as your own?";
	Quiz[79].Text = "Are you sometimes afraid in safe situations, yet fearless in situations which may actually be dangerous?";
	Quiz[80].Text = "Do you tend to feel get nervous, shy, confused and/or like you don't fit in, in various social situations?";
	Quiz[81].Text = "Are you usually unaware of social rules & boundaries unless they are specifically spelled out?";
	Quiz[82].Text = "In conversations, do you have trouble with things like timing and reciprocity?";
	Quiz[83].Text = "Do you have difficulties judging unseen limits and other people's personal space unless clearly instructed?";
	Quiz[84].Text = "Do you often talk about your special interests whether others seem to be interested or not?";
	Quiz[85].Text = "Do you tend to interpret things literally and/or reply to rhetorical questions?";
	Quiz[86].Text = "Do you have difficulties understanding figures of speech, parodies, allegories, irony etc?";
	Quiz[87].Text = "Do you have difficulties interpreting body language and/or facial expressions and figuring out what people feel and want, unless they tell you?";
	Quiz[88].Text = "Do you have problems recognizing faces out of their usual context (e.g. your doctor at the supermarket without his white robe)?";
	Quiz[89].Text = "Do you find it easier to understand & communicate with computers, animals and/or Aspies than with 'ordinary' people?";
	Quiz[90].Text = "Do you have more difficulties than others of the same age when it comes to making friendships and getting into relationships?";
	Quiz[91].Text = "Are you so honest and sincere yourself that you assume everyone is, and therefore easily miss dishonesty and hidden agendas?";
	Quiz[92].Text = "Have you been bullied, abused or taken advantage of in various situations?";
	Quiz[93].Text = "Do you get surprised and disappointed when people are unfriendly and don't seem to understand or accept you as you are?";
	Quiz[94].Text = "Is being honest so natural to you that you often don't notice - or care - if others may find your remarks inappropriate, hurtful or rude?";
	Quiz[95].Text = "Once you understand how someone feels, do you usually want to express you sympathy, help or cheer that person up if he or she is in distress?";
	Quiz[96].Text = "Are you usually unaware of/disinterested in what is currently in vogue?";
	Quiz[97].Text = "Do you find social chitchat difficult, tiresome and/or a waste of time?";
	Quiz[98].Text = "Do you have high morals and a tendency to stand up for your ideals and beliefs even if they are contrary to general consensus, or if it means social or economical disadvantages?";
	Quiz[99].Text = "Do you have values & views that are either very old-fashioned or way ahead of their time?";

#endif

#ifdef SWEDISH

	Quiz[0].Text = "Är du en väldigt logisk person som blir förvånad när andra inte är det?";
	Quiz[1].Text = "Har du lätt att visualisera och skapa bilder i huvudet?"; 
	Quiz[2].Text = "Blir du förvirrad av verbala instruktioner - särskilt flera på en gång?";
	Quiz[3].Text = "Har du behov av att SE, ta i, eller själv bearbeta saker för att riktigt minnas dem?";
	Quiz[4].Text = "Brukar du lägga märke till och intressera dig för detaljer som andra inte verkar se eller bry sig om?";
	Quiz[5].Text = "Händer det att du fastnar så för vissa detaljer att du missar eller struntar i helhetsbilden?";
	Quiz[6].Text = "Har du svårt att generalisera?";
	Quiz[7].Text = "Är du fascinerad av datum och/eller siffror?";
	Quiz[8].Text = "Är det lättare och mer intressant för dig att fokusera på den yttre formen (t ex typsnittet och layouten i en text) än på själva innehållet?";
	Quiz[9].Text = "Är du punktlig, noggrann och/eller perfektionistisk?"; 
	Quiz[10].Text = "Har du lättare för konkreta saker än abstrakta begrepp?";
	Quiz[11].Text = "Har du utmärkt långtidsminne när det gäller de ämnen du är intresserad av?";
	Quiz[12].Text = "Har du utmärkt vokabulär och intresse för språk?";
	Quiz[13].Text = "Finner du det svårt eller tröttsamt att tala?";
	Quiz[14].Text = "Har du för vana att upprepa de sista orden som du själv eller någon annan just sagt?"; 
	Quiz[15].Text = "Blandar du ibland ihop pronomen och t ex säger \"vi\" eller \"du\" när du menar \"jag\" eller tvärtom?";
	Quiz[16].Text = "Brukar du memorera och använda uttryck som du kopierat från andra människor och situationer?";
	Quiz[17].Text = "Har du en monoton röst och/eller svårigheter att finjustera ljudnivå och hastighet när du talar?";
	Quiz[18].Text = "Är du ovanligt begåvad inom ett eller flera områden?";
	Quiz[19].Text = "Brukar du fördjupa dig i ett ämne i taget och bli expert det?";
	Quiz[20].Text = "Gillar du att skaffa information om en viss kategori av saker (t ex fåglar, bilar etc.)?";
	Quiz[21].Text = "Älskar du att samla på, sortera & organisera saker och/eller göra listor och diagram?";
	Quiz[22].Text = "Har du okonventionella, ofta unika sätt att lösa problem på?";
	Quiz[23].Text = "Har du förmåga till ihärdighet och uthållighet när det gäller något som intresserar dig?";
	Quiz[24].Text = "Känns det livsviktigt att få vara ifred och ägna dig åt dina specialintressen i lugn och ro?"; 
	Quiz[25].Text = "Brukar du bli så absorberad av dina projekt att du glömmer/struntar i allting annat (äta, duscha, sova, andra människor etc.)?";
	Quiz[26].Text = "Har du svårt att göra flera saker samtidigt, snabbt skifta fokus från en sak till en annan och därför behov av att få göra klart det du håller på med innan du kan ta itu med något annat?"; 
	Quiz[27].Text = "Har du en tendens att lätt bli stressad och få panik eller kortslutning i hjärnan i nya och kravfyllda situationer?";
	Quiz[28].Text = "Innan du gör något nytt, känns det viktigt att ha en inre bild av den platsen, aktiviteten eller personen du ska träffa, så att du kan förbereda dig mentalt?";
	Quiz[29].Text = "Känner du dig väldigt mycket säkrare om du har en person du känner dig trygg med som sällskap?";
	Quiz[30].Text = "Har du svårare att klara dig själv - känslomässigt och/eller praktiskt - än andra i samma ålder?";
	Quiz[31].Text = "Har du en tendens att vara passiv och ha svårt att ta initiativ och komma igång med saker på egen hand?";
	Quiz[32].Text = "Umgås du hellre med människor som är äldre/mer erfarna, än med dina jämnåriga?";
	Quiz[33].Text = "Föredrar du att umgås med folk du känner väl, och helst på tu man hand eller i en mindre grupp?";
	Quiz[34].Text = "Har du ibland behov av gosefilt, kramdjur eller liknande?";
	Quiz[35].Text = "Har du vissa enkla, logiska rutiner som gör att du slipper tänka och som det känns bra att följa?";
	Quiz[36].Text = "Föredrar du att använda samma kläder och/eller äta samma mat varje dag?";
	Quiz[37].Text = "Har du starkt behov av att t ex sitta på din favoritplats, åka samma väg eller handla i samma affär varje gång?";
	Quiz[38].Text = "Är du exceptionellt fäst vid vissa saker, t ex en favoritkopp, en favorittröja, en favorithandduk, och verkligen MÅSTE ha just den?";
	Quiz[39].Text = "Blir det kaos i dig om det händer något oväntat som förändrar din miljö, dina planer, rutiner eller som avbryter dig mitt i en för dig viktig aktivitet?";
	Quiz[40].Text = "Brukar du vagga, nynna, trumma med fingrarna, titta på ett roterande objekt el. dyl. för att lugna ner dig själv, öka din koncentration eller ge utlopp för överflödig energi?";
	Quiz[41].Text = "Ser du yngre ut än din biologiska ålder?";
	Quiz[42].Text = "Har du ovanlig kroppshållning, gångstil och/eller svårt att sitta/stå upprätt?";
	Quiz[43].Text = "Har du problem med finmotorik och/eller öga-hand koordination?";
	Quiz[44].Text = "Har du problem med grovmotorik (=klumpighet)?";
	Quiz[45].Text = "Har du svårigheter att bedöma avstånd, höjd, djup och fart?";
	Quiz[46].Text = "Brukar du blanda ihop höger och vänster?";
	Quiz[47].Text = "Är du relativt okänslig för smärta?";
	Quiz[48].Text = "Har du ovanliga sovmönster/sovvanor?";
	Quiz[49].Text = "Har du dålig tidsuppfattning?";
	Quiz[50].Text = "Har du tvångssyndrom (= tvångstankar eller oemotståndliga, upprepade, irrationella impulser att göra vissa saker)?";
	Quiz[51].Text = "Är du musikaliskt begåvad, t ex i form av att ha perfekt gehör, kunna spela ett eller flera instrument el. dyl?";
	Quiz[52].Text = "Brukar du höra ljud som andra inte hör och plågas av höga eller störande ljud?";
	Quiz[53].Text = "Har du svårt att urskilja röster från bakgrundsljud, eller från andra röster?";
	Quiz[54].Text = "Brukar fraser, melodier eller rytmer du nyligen hört fastna i huvudet och fortsätta spelas up om och om igen?";
	Quiz[55].Text = "Är du känslig för lyrsrörsljus?";
	Quiz[56].Text = "Har du extra känsligt lukt- och/eller smaksinne?";
	Quiz[57].Text = "Brukar du känna stark lust eller häftigt obehag av vissa färger, former, dofter, smaker, material eller konsistenser?";
	Quiz[59].Text = "Älskar du vatten?";
	Quiz[58].Text = "Är du tvungen att vara petig med vad du äter och/eller hur maten kombineras på tallriken för att inte bli illamående?";
	Quiz[59].Text = "Är du känslig för värme, kyla, blåst och/eller förändringar i lufttyck, luftfuktighet o. dyl.?";
	Quiz[60].Text = "Pinas du av skavande sömmar och etiketter i kläderna, av kläder som sitter åt på vissa ställen eller som är gjorda i \"fel\" material?";
	Quiz[61].Text = "Ogillar du beröring - särskilt oväntad, av \"fel\" person eller vid \"fel\" tillfälle?";
	Quiz[62].Text = "Om någon tar i dig, föredrar du då hårdare tag framför lätt beröring?";
	Quiz[63].Text = "Har du behov av ordning och enkelhet?";
	Quiz[64].Text = "Blir du lätt överstimulerad och stressad av för mycket ljud, mönster, flimmer, oreda, trängsel o. dyl.?";
	Quiz[65].Text = "Brukar du blir utmattad av att umgås med folk och efteråt behöva vila ut ifred?";
	Quiz[66].Text = "Känner du dig mer som en observatör än som en deltagare i livet?";
	Quiz[67].Text = "Är du rätt självupptagen, mer intresserad av dig själv än av andra och/eller en objektiv självobservatör?";
	Quiz[68].Text = "Är du i grunden mer intresserad av saker, idéer, filmer, datorer, musik, djur, hus, fordon el. dyl., än av människor och social samvaro?";
	Quiz[69].Text = "Har du problem med lagsporter och andra saker som kräver samarbete i grupp?";
	Quiz[70].Text = "Brukar du föredra att leka/arbeta/göra saker själv - på ditt eget sätt och i din egen takt?";
	Quiz[71].Text = "Har du problem med ögonkontakt?";
	Quiz[72].Text = "Ogillar du att behöva ta i hand?";
	Quiz[73].Text = "Är du tämligen stillsam, opassionerad och låg-emotionell, utom då du blir provocerad eller upprymd?";
	Quiz[74].Text = "Blir du lätt frustrerad och upprörd när du blir stressad, trött, hungrig, ifrågasatt, avbruten, överstimulerad, eller när saker inte går som du har tänkt dig och ställt in dig på?";
	Quiz[75].Text = "Brukar du uttrycka känslor på okonventionella sätt (t ex banka huvudet i väggen eller inte visa något alls)?";
	Quiz[76].Text = "Brukar du bli mer upprörd över smärre saker (t ex att du tappat din favoritpenna eller någon satt sig på din favoritplats) än över sånt som andra blir upprörda av (t ex en släktings bortgång)?";
	Quiz[77].Text = "Händer det att du inte känner något alls fastän andra tycker att du borde?";
	Quiz[78].Text = "Är du ibland så medkännande att du känner djurs eller andra människors känslor som om de var dina egna?";
	Quiz[79].Text = "Händer det att du är rädd i ofarliga situationer men orädd i situationer som faktiskt kan vara farliga?";
	Quiz[80].Text = "Brukar du bli nervös, blyg, förvirrad och/eller känna dig annorlunda och utanför i olika sociala situationer?";
	Quiz[81].Text = "Är du oftast omedveten om outtalade sociala regler?";
	Quiz[82].Text = "I samtal, brukar du ibland ha problem med saker som timing, turtagning och ömsesidighet?";
	Quiz[83].Text = "Brukar du ha svårt att uppfatta personliga och andra osynliga gränser om ingen talar om var de går ";
	Quiz[84].Text = "Brukar du gärna prata om dina specialintressen oavsett om någon verkar intresserad eller inte?"; 
	Quiz[85].Text = "Har du en tendens att tolka saker bokstavligt och/eller svara på retoriska frågor?";
	Quiz[86].Text = "Har du svårt att förstå talesätt, allegorier, parodier, ironi och liknande?";
	Quiz[87].Text = "Brukar du ha svårt att tolka kroppsspråk och ansiktsuttryck och att förstå vad andra känner och vill om de inte säger det rakt ut?";
	Quiz[88].Text = "Har du svårt att känna igen ansikten i oväntade sammanhang (t ex din läkare i snabbköpet utan sin vita rock?";
	Quiz[89].Text = "Har du lättare att förstå dig på datorer, djur och/eller Aspergare än att umgås och kommunicera framgångsrikt med \"vanliga\" människor?";
	Quiz[90].Text = "Har du svårare än dina jämnåriga att få vänner och/eller partners?";
	Quiz[91].Text = "Är du så ärlig och uppriktig själv att du utgår från att alla är det och därför lätt missar oärlighet och dolda motiv?";
	Quiz[92].Text = "Har du blivit mobbad, lurad, utnyttjad eller illa behandlad i olika situationer?";
	Quiz[93].Text = "Blir du förvånad och besviken när folk är ovänliga och inte tycks förstå eller acceptera dig som du är?";
	Quiz[94].Text = "Är det så naturligt för dig att vara totalt ärlig att du ibland inte märker - eller bryr dig om - ifall andra finner din uppriktighet stötande?";
	Quiz[95].Text = "När du väl förstår hur någon känner, brukar du då vilja försöka uttrycka din sympati, hjälpa eller muntra upp personen ifråga, om denne har problem?";
	Quiz[96].Text = "Är du ofta omedveten om eller ointresserad av vad som för tillfället råkar vara aktuellt/modernt/inne?";
	Quiz[97].Text = "Tycker du att vanligt kallprat är svårt, plågsamt eller slöseri med tid?";
	Quiz[98].Text = "Har du hög moral och en tendens att hålla fast vid dina ideal, övertygelser och principer även om de går emot det rådande synsättet och kan vara till din nackdel, t ex socialt eller ekonomiskt?";
	Quiz[99].Text = "Har du värderingar som antingen är väldigt gammaldags eller långt före sin tid?";

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
void TQuizI::InitReferers()
{
	AddReferer("wikipedia.org/wiki/As", "en.wikipedia.org/wiki/Aspergers");
	AddReferer("aspiesforfreedom.", "aspiesforfreedom.com");
	AddReferer("google.com", "google.com");
	AddReferer("wrongplanet.net", "wrongplanet.net");
	AddReferer("intpcentral.com", "intpcentral.com");
	AddReferer("xmission.com/~winter", "xmission.com/~winter");
	AddReferer("everyonesconnected.com", "everyonesconnected.com");
	AddReferer("tribe.net", "tribe.net");
	AddReferer("phpportalen.net", "phpportalen.net");
	AddReferer("aspforum.liebert.se", "aspforum.liebert.se");
	AddReferer("dickflash.com", "dickflash.com");
	AddReferer("99musik.com/forum", "99musik.com/forum");
	AddReferer("whoa.nu", "whoa.nu");
}

/*##################  TQuizI::LoadReferers ##########################
*   Purpose....: Load referers    					      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizI::LoadReferers()
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
		{
			ref->Count++;
			ref->Result += Row.ResultNow;

			if (Row.ResultNow >= 60)
			{
				if (Row.ResultNow >= 100)
				{
					if (Row.ResultNow >= 140)
						ref->Result140_200++;
					else
						ref->Result100_139++;
				}
				else
					ref->Result60_99++;
			}
			else
			    ref->Result0_59++;
		}

		switch (Row.Diagnos)
		{
			case DX_AS:
				ref = &DxAsRef;
				break;

			case DX_ADD:
				ref = &DxAddRef;
				break;

			default:
				ref = 0;
				break;
		}

		if (ref)
		{
			ref->Count++;
			ref->Result += Row.ResultNow;

			if (Row.ResultNow >= 60)
			{
				if (Row.ResultNow >= 100)
				{
					if (Row.ResultNow >= 140)
					    ref->Result140_200++;
					else
						ref->Result100_139++;
				}
				else
					ref->Result60_99++;
			}
			else
			    ref->Result0_59++;
		}

		switch (Row.Diagnos)
		{
			case DX_AS:
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
		{
			ref->Count++;
			ref->Result += Row.ResultNow;

			if (Row.ResultNow >= 60)
			{
				if (Row.ResultNow >= 100)
				{
					if (Row.ResultNow >= 140)
						ref->Result140_200++;
					else
						ref->Result100_139++;
				}
				else
					ref->Result60_99++;
			}
			else
				ref->Result0_59++;
		}
	}
}

/*##########################################################################
#
#   Name       : TQuizI::LoadPopulations
#
#   Purpose....: Load populations
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizI::LoadPopulations()
{
	TQuizRow Row;
	char ValArr[MAX_QUESTIONS];
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
			if (Row.Before[i] > Row.Now[i])
				ValArr[i] = Row.Before[i] + 1;
			else
				ValArr[i] = Row.Now[i] + 1;

			if (ValArr[i] > 3)
				 ValArr[i] = 0;
		}

		switch (Row.Diagnos)
		{
			case DX_AS:
				aspie = TRUE;
				 if (Row.ResultNow < 100)
					  LowAs.Add(Row.ResultNow, 200 - Row.ResultNow, aspie, ValArr, Row.GroupResult);

				  As.Add(Row.ResultNow, 200 - Row.ResultNow, aspie, ValArr, Row.GroupResult);
				if (Row.Gender == 1)
					AsMale.Add(Row.ResultNow, 200 - Row.ResultNow, aspie, ValArr, Row.GroupResult);
				else
					AsFemale.Add(Row.ResultNow, 200 - Row.ResultNow, aspie, ValArr, Row.GroupResult);
				break;

			case DX_ADD:
				  Add.Add(Row.ResultNow, 200 - Row.ResultNow, aspie, ValArr, Row.GroupResult);
				if (Row.Gender == 1)
					AddMale.Add(Row.ResultNow, 200 - Row.ResultNow, aspie, ValArr, Row.GroupResult);
				else
					AddFemale.Add(Row.ResultNow, 200 - Row.ResultNow, aspie, ValArr, Row.GroupResult);
				break;
		}

		All.Add(Row.ResultNow, 200 - Row.ResultNow, aspie, ValArr, Row.GroupResult);

		if (Row.Diagnos == DX_REFERER && strlen(Row.Referer) == 0)
			 Mix.Add(Row.ResultNow, 200 - Row.ResultNow, aspie, ValArr, Row.GroupResult);

		if (Row.ResultNow  < 90)
			Nt.Add(Row.ResultNow, 200 - Row.ResultNow, aspie, ValArr, Row.GroupResult);

		if (Row.ResultNow  > 110)
			Aspie.Add(Row.ResultNow, 200 - Row.ResultNow, aspie, ValArr, Row.GroupResult);
	}
}

/*##########################################################################
#
#   Name       : TQuizI::SetupControlGroups
#
#   Purpose....: Setup control-groups
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizI::SetupControlGroups()
{
	int i;
    TReferer *ref;
	int val;

	for (i = 0; i < RefCount; i++)
	{
		ref = RefArr[i];

		if (ref->Count >= 5)
		{
		    val = ref->Result0_59 * 100 / ref->Count;
			if (val >= 40)
			{
				ref->NT = TRUE;
				NTRef.Result += ref->Result;
				NTRef.Count += ref->Count;
				NTRef.Result0_59 += ref->Result0_59;
				NTRef.Result60_99 += ref->Result60_99;
				NTRef.Result100_139 += ref->Result100_139;
			    NTRef.Result140_200 += ref->Result140_200;
		    }

			val = ref->Result140_200 * 100 / ref->Count;
			if (val >= 35)
			{
			    ref->Aspie = TRUE;
				AspieRef.Result += ref->Result;
				AspieRef.Count += ref->Count;
				AspieRef.Result0_59 += ref->Result0_59;
				AspieRef.Result60_99 += ref->Result60_99;
				AspieRef.Result100_139 += ref->Result100_139;
				AspieRef.Result140_200 += ref->Result140_200;
			}
	    }
	}
}

/*##########################################################################
#
#   Name       : TQuizI::SetupCross
#
#   Purpose....: Setup cross-references
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizI::SetupCross()
{
	DefineGlobalId(0, 0);
	DefineGlobalId(1, 1);
	DefineGlobalId(2, 2);
	DefineGlobalId(3, 3);
	DefineGlobalId(4, 4);
	DefineGlobalId(5, 5);
	DefineGlobalId(6, 6);
	DefineGlobalId(7, 7);
	DefineGlobalId(8, 8);
	DefineGlobalId(9, 9);
	DefineGlobalId(10, 10);
	DefineGlobalId(11, 11);
	DefineGlobalId(12, 12);
	DefineGlobalId(13, 13);
	DefineGlobalId(14, 14);
	DefineGlobalId(15, 15);
	DefineGlobalId(16, 16);
	DefineGlobalId(17, 17);
	DefineGlobalId(18, 18);
	DefineGlobalId(19, 19);
	DefineGlobalId(20, 20);
	DefineGlobalId(21, 21);
	DefineGlobalId(22, 22);
	DefineGlobalId(23, 23);
	DefineGlobalId(24, 24);
	DefineGlobalId(25, 25);
	DefineGlobalId(26, 26);
	DefineGlobalId(27, 27);
	DefineGlobalId(28, 28);
	DefineGlobalId(29, 29);
	DefineGlobalId(30, 30);
	DefineGlobalId(31, 31);
	DefineGlobalId(32, 32);
	DefineGlobalId(33, 33);
	DefineGlobalId(34, 34);
	DefineGlobalId(35, 35);
	DefineGlobalId(36, 36);
	DefineGlobalId(37, 37);
	DefineGlobalId(38, 38);
	DefineGlobalId(39, 39);
	DefineGlobalId(40, 40);
	DefineGlobalId(41, 41);
	DefineGlobalId(42, 42);
	DefineGlobalId(43, 43);
	DefineGlobalId(44, 44);
	DefineGlobalId(45, 45);
	DefineGlobalId(46, 46);
	DefineGlobalId(47, 47);
	DefineGlobalId(48, 48);
	DefineGlobalId(49, 49);
	DefineGlobalId(50, 50);
	DefineGlobalId(51, 51);
	DefineGlobalId(52, 52);
	DefineGlobalId(53, 53);
	DefineGlobalId(54, 54);
	DefineGlobalId(55, 55);
	DefineGlobalId(56, 56);
	DefineGlobalId(57, 57);
	DefineGlobalId(58, 58);
	DefineGlobalId(59, 59);
	DefineGlobalId(60, 60);
	DefineGlobalId(61, 61);
	DefineGlobalId(62, 62);
	DefineGlobalId(63, 63);
	DefineGlobalId(64, 64);
	DefineGlobalId(65, 65);
	DefineGlobalId(66, 66);
	DefineGlobalId(67, 67);
	DefineGlobalId(68, 68);
	DefineGlobalId(69, 69);
	DefineGlobalId(70, 70);
	DefineGlobalId(71, 71);
	DefineGlobalId(72, 72);
	DefineGlobalId(73, 73);
	DefineGlobalId(74, 74);
	DefineGlobalId(75, 75);
	DefineGlobalId(76, 76);
	DefineGlobalId(77, 77);
	DefineGlobalId(78, 78);
	DefineGlobalId(79, 79);
	DefineGlobalId(80, 80);
	DefineGlobalId(81, 81);
	DefineGlobalId(82, 82);
	DefineGlobalId(83, 83);
	DefineGlobalId(84, 84);
	DefineGlobalId(85, 85);
	DefineGlobalId(86, 86);
	DefineGlobalId(87, 87);
	DefineGlobalId(88, 88);
	DefineGlobalId(89, 89);
	DefineGlobalId(90, 90);
	DefineGlobalId(91, 91);
	DefineGlobalId(92, 92);
	DefineGlobalId(93, 93);
	DefineGlobalId(94, 94);
	DefineGlobalId(95, 95);
	DefineGlobalId(96, 96);
	DefineGlobalId(97, 97);
	DefineGlobalId(98, 98);
	DefineGlobalId(99, 99);
}

/*##########################################################################
#
#   Name       : TQuizI::GetReferer
#
#   Purpose....: Get referer population
#
#   In params..: *
#   Out params.: *
#   Returns....: *
#
##########################################################################*/
void TQuizI::GetReferer(const char *referer, TPopulation *pop)
{
	int i;
	TReferer *ref;
	TQuizRow Row;
	char ValArr[MAX_QUESTIONS];

	for (i = 0; i < RefCount; i++)
	{
		ref = RefArr[i];
		if (ref->IsMatch(referer))
			break;
	}

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		if (ref->IsMatch(Row.Referer))
		{
			for (i = 0; i < N; i++)
			{
				if (Row.Before[i] > Row.Now[i])
					ValArr[i] = Row.Before[i] + 1;
				else
					ValArr[i] = Row.Now[i] + 1;
				pop->Add(Row.ResultNow, 200 - Row.ResultNow, FALSE, ValArr, Row.GroupResult);
			}
		}
	}
}

/*##################  TQuizI::ExportExcelCases ##########################
*   Purpose....: Export cases as excel-data. Make ? into 'NO' case 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizI::ExportExcelCase(const char *filename, int PcaType)
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

//        strncpy(str, Quiz[i].Text, 35);
//        str[35] = 0;
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
		sprintf(str, "\"%d\", ", Row.ResultNow);
		file.Write(str);

		sprintf(str, "\"%d\", ", Row.Diagnos);
		file.Write(str);

		for (i = 0; i < N; i++)
		{
			if (PcaType != PCA_TYPE_MIXED || Quiz[i].MyGroup == GROUP_MIXED)
			{
				if (Row.Before[i] > Row.Now[i])
					ival = Row.Before[i];
				else
					ival = Row.Now[i];

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

/*##################  TQuizI::ExportExcelAspie ##########################
*   Purpose....: Export cases as excel-data. Invert NT questions 	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizI::ExportExcelAspie(const char *filename)
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
		file.Write("\"");

		sprintf(str, "#%d", i + 1);
		file.Write(str);

		file.Write("\"");
		if (i != N - 1)
			file.Write(", ");
	}
	file.Write("\n");

	FDataFile.SetPos(0);
	while (FDataFile.Read(&Row, sizeof(Row)))
	{
		sprintf(str, "\"%d\", ", Row.ResultNow);
		file.Write(str);

		sprintf(str, "\"%d\", ", Row.Diagnos);
		file.Write(str);

		for (i = 0; i < N; i++)
		{
			if (Row.Before[i] > Row.Now[i])
				ival = Row.Before[i];
			else
				ival = Row.Now[i];

			if (ival > 2)
				ival = 0;

			sprintf(str, "\"%d\"", ival);
			file.Write(str);
			if (i != N - 1)
				file.Write(", ");
		}
		file.Write("\n");
	}
}

/*##################  TQuizI::ImportMvsp ##########################
*   Purpose....: Import MVSP loadings   	      			      	        #
*   In params..: *                                                          #
*   Out params.: *                                                          #
*   Returns....: *                                                          #
*   Created....: 96-11-20 le                                                #
*##########################################################################*/
void TQuizI::ImportMvsp(const char *filename, int PcaType)
{
	char buf[MAX_IN_ROW];
	int size;
	char *rowstr;
	char *ptr;
	long pos = 0;
	int i;
	long double d1, d2, d3, d4;
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
				if (PcaType == PCA_TYPE_MIXED)
				{
					Quiz[q - 1].MixedPca[0] = d1;
					Quiz[q - 1].MixedPca[1] = d2;
				}
				else
				{
					d2 = -d2;

					Quiz[q - 1].Pca[0] = d1;
					Quiz[q - 1].Pca[1] = d2;
				}
			}
		}
	}
}

