:userdoc.
:title.Open Watcom 2.0 Source Browser
:docprof toc=123456.

:h1 res=1 id=Index_of_Topics.Index of Topics
:dl break=all tsize=5.
:dt.:hp2.- A -:ehp2.
:dd.:link reftype=hd refid=Adding_a_Module_File.Adding a Module File:elink.
.br
:link reftype=hd refid=AutoMarranging_of_Graph_Views.Auto-arranging of Graph Views:elink.
.br
:link reftype=hd refid=Automatically_Saving_Options_on_Exit.Automatically Saving Options on Exit:elink.
:dt.:hp2.- B -:ehp2.
:dd.:link reftype=hd refid=Browser_Files.Browser Files:elink.
.br
:link reftype=hd refid=The_Browser_Menu_Bar.The Browser Menu Bar:elink.
:dt.:hp2.- C -:ehp2.
:dd.:link reftype=hd refid=Changing_the_Graph_Orientation.Changing the Graph Orientation:elink.
.br
:link reftype=hd refid=The_Class_Inheritance_View.The Class Inheritance View:elink.
.br
:link reftype=hd refid=Collapsing_Nodes.Collapsing Nodes:elink.
.br
:link reftype=hd refid=Configuring_the_Browser.Configuring the Browser:elink.
.br
:link reftype=hd refid=Creating_a_Browser_Database_File_from_the_Command_Line.Creating a Browser Database File from the Command Line:elink.
.br
:link reftype=hd refid=Creating_a_Browser_Database_File_within_the_Browser.Creating a Browser Database File within the Browser:elink.
:dt.:hp2.- D -:ehp2.
:dd.:link reftype=hd refid=Defining_Graph_View_Legends.Defining Graph View Legends:elink.
.br
:link reftype=hd refid=Disabling_a_Module_File.Disabling a Module File:elink.
:dt.:hp2.- E -:ehp2.
:dd.:link reftype=hd refid=Enabling_a_Module_File.Enabling a Module File:elink.
.br
:link reftype=hd refid=Enumerator_Styles.Enumerator Styles:elink.
.br
:link reftype=hd refid=Expanding_Nodes.Expanding Nodes:elink.
:dt.:hp2.- F -:ehp2.
:dd.:link reftype=hd refid=Find.Find:elink.
.br
:link reftype=hd refid=Find_Filters.Find Filters:elink.
.br
:link reftype=hd refid=Find_Pattern.Find Pattern:elink.
.br
:link reftype=hd refid=Find_Selected.Find Selected:elink.
.br
:link reftype=hd refid=The_Function_Call_Tree_View.The Function Call Tree View:elink.
:dt.:hp2.- G -:ehp2.
:dd.:link reftype=hd refid=Global_Symbol_Queries.Global Symbol Queries:elink.
.br
:link reftype=hd refid=Global_Views.Global Views:elink.
.br
:link reftype=hd refid=Goto_Definition.Goto Definition:elink.
:dt.:hp2.- I -:ehp2.
:dd.:link reftype=hd refid=Index_of_Topics.Index of Topics:elink.
:dt.:hp2.- L -:ehp2.
:dd.:link reftype=hd refid=Line_Drawing_Method_for_Graph_Views.Line Drawing Method for Graph Views:elink.
.br
:link reftype=hd refid=The_List_View.The List View:elink.
.br
:link reftype=hd refid=Loading_Options.Loading Options:elink.
.br
:link reftype=hd refid=Locating_Symbols.Locating Symbols:elink.
:dt.:hp2.- M -:ehp2.
:dd.:link reftype=hd refid=Manipulating_the_Tree_Views.Manipulating the Tree Views:elink.
.br
:link reftype=hd refid=Member_Filters_for_Classes.Member Filters for Classes:elink.
:dt.:hp2.- O -:ehp2.
:dd.:link reftype=hd refid=The_Open_Watcom_Browser.The Open Watcom Browser:elink.
.br
:link reftype=hd refid=Opening_an_Existing_Browser_Database_File.Opening an Existing Browser Database File:elink.
:dt.:hp2.- P -:ehp2.
:dd.:link reftype=hd refid=Performing_the_Find.Performing the Find:elink.
:dt.:hp2.- Q -:ehp2.
:dd.:link reftype=hd refid=Query_Filters.Query Filters:elink.
.br
:link reftype=hd refid=Query_Pattern.Query Pattern:elink.
.br
:link reftype=hd refid=Quitting_the_Browser.Quitting the Browser:elink.
:dt.:hp2.- R -:ehp2.
:dd.:link reftype=hd refid=Regular_Expressions_for_Find_and_Query.Regular Expressions for Find and Query:elink.
.br
:link reftype=hd refid=Removing_a_Module_File.Removing a Module File:elink.
:dt.:hp2.- S -:ehp2.
:dd.:link reftype=hd refid=Saving_Options.Saving Options:elink.
.br
:link reftype=hd refid=Selecting_a_Text_Editor.Selecting a Text Editor:elink.
.br
:link reftype=hd refid=Selecting_Root_Nodes.Selecting Root Nodes:elink.
.br
:link reftype=hd refid=Setting_Source_Search_Paths.Setting Source Search Paths:elink.
.br
:link reftype=hd refid=Source_References.Source References:elink.
.br
:link reftype=hd refid=Starting_the_Browser.Starting the Browser:elink.
.br
:link reftype=hd refid=Symbol_References.Symbol References:elink.
:dt.:hp2.- U -:ehp2.
:dd.:link reftype=hd refid=Using_the_Browser.Using the Browser:elink.
:dt.:hp2.- V -:ehp2.
:dd.:link reftype=hd refid=Viewing_Detail_Information.Viewing Detail Information:elink.
:dt.:hp2.- W -:ehp2.
:dd.:link reftype=hd refid=Working_with_Browser_Module_Files.Working with Browser Module Files:elink.
:edl.

:h1 res=2 id=The_Open_Watcom_Browser.The Open Watcom Browser
:i1.Browser
.br
Imagine being assigned to a project with thousands of lines of C++ source code&per.  Learning the relationship between 
the objects of such an application can be very difficult&per.  The Browser was developed to solve this very problem - to 
help developers better understand the source code they are working with&per.  Information such as the class inheritance hierarchy 
and the call tree for an application can be studied while using the Browser&per.  Once you have located a symbol, you can 
quickly view the source file that contains its definition or list all the files that reference it&per.  Viewing these relationships 
helps you understand how the program works&per.
.br
.br
This chapter describes the many tasks you can perform with the Browser, including creating and opening a Browser 
database file, configuring the Browser session, and viewing the list of all symbols in your program, the class inheritance 
hierarchy, and call structure&per.

:h2 res=3 id=Using_the_Browser.Using the Browser
.br
This section discusses the following topics&colon.
:ul compact.
:li.Starting the Browser
:li.Starting the Browser through the Open Watcom Integrated Development Environment
:li.Quitting the Browser
:li.The Browser Menu Bar
:eul.

:h3 res=4 id=Starting_the_Browser.Starting the Browser
:i1.start, Browser
:i1.Browser, start
.br
To start the Browser, double click on the Browser icon&per.  This opens the Browser window&per.  The caption bar of this 
window displays the current option file and Browser database file&per.  The message:font facename=Courier size=12x10. no 
browser file:font facename=Courier size=0x0. appears on this line if a database file is not currently selected&per.
.br
.br
The Browser is an integrated tool that you can open from the IDE so that you can browse the source code of the project 
you are working on&per.  Refer to the IDE guide for further information on the Integrated Development Environment&per.

:h3 res=5 id=Quitting_the_Browser.Quitting the Browser
:i1.leave, Browser
:i1.Browser, leave
.br
To exit the Browser, choose:hp2. Exit:ehp2. from the:hp2. File:ehp2. menu of the Browser window&per.  If you made changes 
to the options during the Browser session, a message box appears prompting you to save the changes&per.
.br
.br
Choose:hp2. No:ehp2. in the message box to close the Browser session without saving&per.  Any options changed within 
the session are lost&per.
.br
.br
Choose:hp2. Yes:ehp2. in the message box to save the current options to the current option file, if one exists, and 
exit the Browser session&per.  If no option file exists, a:hp2. Save As:ehp2. dialog appears that allows you to specify the 
option file to which you want to save the new options&per.
:dl break=all tsize=5.
:dt.:hp2.:ehp2.
:dd.:hp2. Select:ehp2.:hp2. Cancel:ehp2. to return to the main Browser window without saving the options&per.
.br
.br
or
:dt.:hp2.:ehp2.
:dd.:hp2. Select:ehp2.:hp2. OK:ehp2. to close the dialog and exit the Browser session&per.
:edl.

:h3 res=6 id=The_Browser_Menu_Bar.The Browser Menu Bar
:i1.Browser, Menu Bar
.br
The Browser's menu bar consists of the following eight menus&colon.
:dl break=all tsize=5.
:dt.:hp2.File:ehp2.
:dd.Create, open, and configure Browser files; save and load options
:dt.:hp2.View:ehp2.
:dd.Choose a global view for the current database file
:dt.:hp2.Detail:ehp2.
:dd.View detailed information for a symbol
:dt.:hp2.Tree:ehp2.
:dd.Choose the nodes to display for a tree view
:dt.:hp2.Locate:ehp2.
:dd.Find symbols within the current global view
:dt.:hp2.Options:ehp2.
:dd.Configure the Browser session
:dt.:hp2.Windows:ehp2.
:dd.Select from the list of Browser windows currently open
:dt.:hp2.Help:ehp2.
:dd.Access on-line help information
:edl.

:h2 res=7 id=Browser_Files.Browser Files
:i1 id=8.module file, in Browser
:i2 refid=8.Browser Files
:i1.Browser, files
.br
To browse your source code, you must first create a Browser module file for each source file that you wish to browse&per. 
 Currently, browsing is supported by the Open Watcom C/C++ compilers only (Open Watcom FORTRAN 77 does not support browsing)&per. 
 To create a Browser module file, specify the "db" option when you compile the source file&per.  If you are using the Open 
Watcom Integrated Development Environment, select:hp2. Emit Browser Information:ehp2. from the:hp2. Debugging Switches:ehp2. 
panel of the:hp2. Compiler Switches:ehp2. dialog&per.  The Browser module file will have the same name as the source file 
and an extension of "&per.MBR"&per.
.br
.br
Once the Browser module files have been created, these files are merged and a Browser database file is created&per. 
 This process eliminates redundant information such as duplicate definitions that occur when a header file is included by 
many source files&per.  Browser database files have the extension "&per.DBR"&per.
.br
.br
The Browser allows you to configure your session and saves this configuration to an options file&per.  Options files 
have the extension "&per.OBR"&per.  The file name:font facename=Courier size=12x10. setup&per.obr:font facename=Courier size=0x0. 
is the default name of the options file&per.  The default options file is automatically loaded by the Browser when the Browser 
is started&per.

:h3 res=8 id=Creating_a_Browser_Database_File_within_the_Browser.Creating a Browser Database File within the Browser
:i1.database file, create in Browser
:i1.Browser, create database file
:dl break=all tsize=5.
:dt.:hp2.(1):ehp2.
:dd.:hp2. Choose:ehp2.:hp2. New:ehp2. from the:hp2. File:ehp2. menu&per.
.br
.br
This opens the:hp2. New Browser File:ehp2. dialog where you enter the name of the Browser database file you are creating&per.
.br
.br
:font facename=Courier size=12x10.:artwork align=center name='brow1.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 1&per.:ehp3.:hp3.:ehp3.:hp2. Use the New Browser File dialog to create a new Browser database file&per.:ehp2.
:dt.:hp2.(2):ehp2.
:dd.:hp2. Type the name and path:ehp2. of the new Browser database file&per.
.br
.br
or
:dt.:hp2.:ehp2.
:dd.:hp2. Click on the:ehp2.:hp2. Files:ehp2. button to open a second dialog that allows you to browse the directory structure 
for an existing Browser database file&per.  Select an existing file and change its name&per.  If you do not change its name, 
a message box appears when you press:hp2. OK:ehp2. asking if you want to overwrite the existing file&per.
:dt.:hp2.(3):ehp2.
:dd.:hp2. Click on:ehp2.:hp2. OK&per.:ehp2.
.br
.br
This opens a:hp2. Module:ehp2. window that will eventually contain a list of the module files that will make up the 
database file&per.
:dt.:hp2.(4):ehp2.
:dd.:hp2. Click on the:ehp2.:hp2. Add:ehp2. button in the:hp2. Module:ehp2. window&per.
.br
.br
This opens the:hp2. Select Module File(s):ehp2. dialog where you choose the module files to add to the database file&per.
:dt.:hp2.(5):ehp2.
:dd.:hp2. Select the module files:ehp2. to add to the database file and click on:hp2. OK&per.:ehp2.
.br
.br
or
:dt.:hp2.:ehp2.
:dd.:hp2. Double click:ehp2. on the desired module file&per.
.br
.br
This closes the:hp2. Select Module File(s):ehp2. dialog and adds the selected module file to the Browser file component 
list&per.  Each module file on the components list has a check box&per.  When added, this check box is marked with an X, 
indicating that the module file is enabled&per.
:dt.:hp2.(6):ehp2.
:dd.:hp2. Continue with steps 4 and 5:ehp2. until you have added all desired module files to the component list&per.
.br
.br
:font facename=Courier size=12x10.:artwork align=center name='brow2.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 2&per.:ehp3.:hp3.:ehp3.:hp2. The Modules dialog displays the selected module files&per.:ehp2.
:dt.:hp2.(7):ehp2.
:dd.:hp2. Click on:ehp2.:hp2. OK:ehp2. on the:hp2. Module:ehp2. window&per.
.br
.br
This closes the:hp2. Module:ehp2. window and creates the database file&per.
:edl.

:h3 res=9 id=Creating_a_Browser_Database_File_from_the_Command_Line.Creating a Browser Database File from the Command Line
:i1.quiet option
:i1.merger, quiet option
:i1.CBR files
:i1.DBR files
:i1.MBR files
:i1.merger, with Browser
:i1.Browser, merger utility
:i1.database file, create from command line
:i1.Browser, create database file from command line
.br
It is also possible to create the Browser database file from the command line&per.  This allows you to make Browser database 
file creation part of your standard build procedure&per.  When you do this, the batch build procedure will automatically 
update your database file&per.  Updating the Browser database file occurs only if changes have been made to a module file 
within the database file&per.
.br
.br
A separate utility, called the merger, is used to create the database file&per.  The name of the merger program is:font facename=Courier size=12x10. 
wbrg&per.exe&per.:font facename=Courier size=0x0.  Its command line consists of the name of the database file and a list 
of the module files (&per.MBR files) to be merged&per.  The name of the database file must be preceded by a:font facename=Courier size=12x10. 
database:font facename=Courier size=0x0. command&per.  The default extension given to the database file is "&per.DBR"&per. 
 The list of module files must be preceded by a:font facename=Courier size=12x10. file:font facename=Courier size=0x0. command&per. 
 The module file names must be separated by commas or enclosed by curly braces and separated by spaces&per.  The list of 
module file names can contain wild cards&per.  The following are examples of valid merger commands&per.  In each case, the 
module files:font facename=Courier size=12x10. m1&per.mbr:font facename=Courier size=0x0. and:font facename=Courier size=12x10. 
m2&per.mbr:font facename=Courier size=0x0. will be processed and the database file:font facename=Courier size=12x10. db&per.dbr:font facename=Courier size=0x0. 
will be created&per.
.br
.br
:font facename=Courier size=12x10.      :font facename=Courier size=0x0.
.br
:font facename=Courier size=12x10.     wbrg database db file m1, m2:font facename=Courier size=0x0.
.br
:font facename=Courier size=12x10.     wbrg database db file { m1 m2 }:font facename=Courier size=0x0.
.br
:font facename=Courier size=12x10.     wbrg file m1, m2 database db:font facename=Courier size=0x0.
.br
:font facename=Courier size=12x10.     wbrg file { m1 m2 } database db:font facename=Courier size=0x0.
.br
.br
It is also possible to specify a command file that contains merger commands&per.  Command files have the extension 
"&per.CBR"&per.  Consider a command file, called:font facename=Courier size=12x10. merge&per.cbr,:font facename=Courier size=0x0. 
containing the following merger commands&per.
.br
.br
:font facename=Courier size=12x10.      :font facename=Courier size=0x0.
.br
:font facename=Courier size=12x10.     database db:font facename=Courier size=0x0.
.br
:font facename=Courier size=12x10.     file m1:font facename=Courier size=0x0.
.br
:font facename=Courier size=12x10.     file m2:font facename=Courier size=0x0.
.br
.br
The following example will achieve the same results as the previous example&per.
.br
.br
:font facename=Courier size=12x10.      :font facename=Courier size=0x0.
.br
:font facename=Courier size=12x10.     wbrg @merge:font facename=Courier size=0x0.
.br
.br
If you want to suppress the listing of file names that the merger produces as it is working, you can include the 
"quiet" option on the command line or in the command file&per.

:h3 res=10 id=Opening_an_Existing_Browser_Database_File.Opening an Existing Browser Database File
:i1.open, database file in Browser
:i1.database file, open in Browser
:i1.Browser, open database file
:dl break=all tsize=5.
:dt.:hp2.(1):ehp2.
:dd.:hp2. Choose:ehp2.:hp2. Open:ehp2. from the:hp2. File:ehp2. menu&per.
.br
.br
This opens the:hp2. Open Browser Database File:ehp2. dialog where you select the database file you want to open&per.
:dt.:hp2.(2):ehp2.
:dd.:hp2. Select a database file to open and click on:ehp2.:hp2. OK&per.:ehp2.
.br
.br
or
:dt.:hp2.:ehp2.
:dd.:hp2. Double click:ehp2. on the desired database file&per.
.br
.br
This closes the:hp2. Open Browser Database File:ehp2. dialog&per.
:dl break=all tsize=5.
:dt.:hp2.Note&colon.:ehp2.
:dd.You can have only one database file open at a time&per.  If you open a second database file, the Browser discards the first 
and displays information for the second&per.
:edl.
:edl.

:h3 res=11 id=Working_with_Browser_Module_Files.Working with Browser Module Files
:i1.Browser, working with module files
:i2 refid=8.Working with Browser Module Files
.br
Once a Browser database file is loaded, you might want to edit the list of modules originally used to create the database 
file&per.  Editing the list of modules allows you to temporarily remove modules from the database or add modules to the database&per. 
 For example, you may decide that you only want to browse a particular module or set of modules or you may have forgotten 
a module when the database was originally created&per.
.br
.br
The:hp2. Modules:ehp2. menu item in the:hp2. File:ehp2. menu allows you to view the list of module files that make 
up the current database file&per.  From this list you can perform the following functions on the module files&colon.
:ul compact.
:li.Add
:li.Remove
:li.Disable
:li.Enable
:eul.
.br
:font facename=Courier size=12x10.:artwork align=center name='brow3.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 3&per.:ehp3.:hp3.:ehp3.:hp2. On the Modules dialog, you can add, remove, disable, and enable module files&per.:ehp2.

:h4 res=12 id=Adding_a_Module_File.Adding a Module File
:i1.Module file, add in Browser
:i1.Browser, add Module file
:dl break=all tsize=5.
:dt.:hp2.(1):ehp2.
:dd.:hp2. Choose:ehp2.:hp2. Modules:ehp2. from the:hp2. File:ehp2. menu&per.
.br
.br
This opens the:hp2. Modules:ehp2. dialog for the current database file&per.  This dialog lists all module files that 
make up the database file&per.  Each module file has a check box&per.  An X in this box indicates that the module file is 
enabled&per.  The Browser browses only the enabled module files&per.
:dt.:hp2.(2):ehp2.
:dd.:hp2. Click on the:ehp2.:hp2. Add:ehp2. button in the:hp2. Modules:ehp2. dialog&per.
.br
.br
This opens the:hp2. Select Module File(s):ehp2. dialog where you choose the module files to add to the current Browser 
file&per.
:dt.:hp2.(3):ehp2.
:dd.:hp2. Select the module files:ehp2. to add to the Browser file and click on:hp2. OK&per.:ehp2.  Select multiple module files 
by holding the Shift key while you click on the desired files&per.
.br
.br
Clicking on OK closes the:hp2. Select Module File(s):ehp2. dialog and adds the selected module file to the database 
file&per.  Each module file in the module list has a check box&per.  When added, this check box is marked with an X, indicating 
that the module file is enabled&per.
:dt.:hp2.(4):ehp2.
:dd.:hp2. Continue with steps 2 and 3:ehp2. until you have added all desired module files to the component list&per.
:dt.:hp2.(5):ehp2.
:dd.:hp2. Click on:ehp2.:hp2. OK:ehp2. in the:hp2. Module:ehp2. dialog&per.
.br
.br
This closes the:hp2. Modules:ehp2. dialog and updates the database file&per.
:edl.

:h4 res=13 id=Removing_a_Module_File.Removing a Module File
:dl break=all tsize=5.
:dt.:hp2.(1):ehp2.
:dd.:hp2. Choose:ehp2.:hp2. Modules:ehp2. from the:hp2. File:ehp2. menu&per.
.br
.br
This opens the:hp2. Modules:ehp2. dialog for the current database file&per.  This dialog lists all module files that 
make up the database file&per.  Each module file has a check box&per.  An X in this box indicates that the module file is 
enabled&per.  The Browser browses only the enabled module files&per.
:dt.:hp2.(2):ehp2.
:dd.:hp2. Click once on the module file:ehp2. you want to remove from the database file&per.
.br
.br
This highlights the selected module file&per.
:dt.:hp2.(3):ehp2.
:dd.:hp2. Click on the:ehp2.:hp2. Remove:ehp2. button in the:hp2. Modules:ehp2. dialog&per.
.br
.br
This removes the selected module file from the list&per.
:dt.:hp2.(4):ehp2.
:dd.:hp2. Click on:ehp2.:hp2. OK:ehp2. in the:hp2. Modules:ehp2. dialog&per.
.br
.br
This closes the:hp2. Modules:ehp2. dialog and updates the database file&per.
:edl.

:h4 res=14 id=Disabling_a_Module_File.Disabling a Module File
:i1.Module file, disable in Browser
:i1.Browser, disable module file
:dl break=all tsize=5.
:dt.:hp2.(1):ehp2.
:dd.:hp2. Choose:ehp2.:hp2. Modules:ehp2. from the:hp2. File:ehp2. menu&per.
.br
.br
This opens the:hp2. Modules:ehp2. dialog for the current database file&per.  This dialog lists all module files that 
make up the database file&per.  Each module file has a check box&per.  An X in this box indicates that the module file is 
enabled&per.  The Browser browses only the enabled module files&per.
:dt.:hp2.(2):ehp2.
:dd.:hp2. Click in the check box:ehp2. of the module file you want to disable&per.  Alternatively, use the up and down arrow 
keys to select the module file you wish to disable&per.  Press the space bar to disable the currently selected module file&per.
.br
.br
This removes the X&per.  The blank box indicates that the module file is disabled and will not be browsed&per.
:dt.:hp2.(3):ehp2.
:dd.:hp2. Repeat step 2:ehp2. until you have disabled all desired module files&per.
:dt.:hp2.(4):ehp2.
:dd.:hp2. Click on:ehp2.:hp2. OK:ehp2. on the:hp2. Modules:ehp2. dialog&per.
.br
.br
This closes the:hp2. Modules:ehp2. dialog and updates the database file&per.
:edl.
.br
To disable all of the module files in the:hp2. Modules:ehp2. dialog, click on the:hp2. Disable All:ehp2. button&per. 
 Click on:hp2. OK:ehp2. to update the database file and close the:hp2. Modules:ehp2. dialog&per.

:h4 res=15 id=Enabling_a_Module_File.Enabling a Module File
:dl break=all tsize=5.
:dt.:hp2.(1):ehp2.
:dd.:hp2. Choose:ehp2.:hp2. Modules:ehp2. from the:hp2. File:ehp2. menu&per.
.br
.br
This opens the:hp2. Modules:ehp2. dialog for the current database file&per.  This dialog lists all module files that 
make up the database file&per.  Each module file has a check box&per.  An X in this box indicates that the module file is 
enabled&per.  The Browser browses only the enabled module files&per.
:dt.:hp2.(2):ehp2.
:dd.:hp2. Click in the check box:ehp2. of the module file you want to enable&per.  Alternatively, use the up and down arrow keys 
to select the module file you wish to enable&per.  Press the space bar to enable the currently selected module file&per.
.br
.br
This places an X in the box indicating that the module file is enabled and will be browsed&per.
:dt.:hp2.(3):ehp2.
:dd.:hp2. Repeat step 2:ehp2. until you have enabled all desired module files&per.
:dt.:hp2.(4):ehp2.
:dd.:hp2. Click on:ehp2.:hp2. OK:ehp2. on the:hp2. Module:ehp2. dialog&per.
.br
.br
This closes the:hp2. Modules:ehp2. dialog and updates the database file&per.
:edl.
.br
To enable all of the module files on the:hp2. Modules:ehp2. window, click on the:hp2. Enable All:ehp2. button&per.  Click 
on:hp2. OK:ehp2. to update the database file and close the:hp2. Modules:ehp2. window&per.

:h2 res=16 id=Global_Views.Global Views
.br
The menu items under the View menu let you display a global view of your program&per.  A global view is one that displays 
relationships between all symbols in your program&per.  The following are global views&per.
:dl break=all tsize=5.
:dt.:hp2.List:ehp2.
:dd.Displays a list of all symbols in your program
:dt.:hp2.Inheritance:ehp2.
:dd.Displays the class inheritance graph for your program
:dt.:hp2.Call:ehp2.
:dd.Displays the call graph for your program
:edl.
.br
Once a global view has been displayed, you can view detailed information for the symbols in the global view&per.  Refer 
to the section entitled :link reftype=hd refid=Viewing_Detail_Information.Viewing Detail Information:elink. for a discussion 
on displaying detail information&per.
.br
.br
It is possible to specify a query that restricts the symbols displayed in global views&per.  See the section entitled 
:link reftype=hd refid=Global_Symbol_Queries.Global Symbol Queries:elink. for more information&per.

:h3 res=17 id=The_List_View.The List View
:i1.symbols, browsing
:i1.Browser, browsing symbols
.br
Using the Browser to view the symbols in your program is much faster than searching through your source code for symbol 
information&per.  From the symbols list you can quickly access detailed information on a symbol that tells you where the 
symbol is used and where it is defined&per.
.br
.br
To view a list of all symbols in the current Browser database file, choose:hp2. List:ehp2. from the:hp2. View:ehp2. 
menu&per.  This displays a window which can list all symbols in your program&per.  The window has a vertical scroll bar that 
allows you to scroll through the list of symbols in your program&per.  Since your program may contain a very large number 
of symbols, the Browser does not load all the symbols in your program from the database&per.  Instead, only the number of 
symbols that can be displayed in the window are loaded&per.  As far as the Browser is concerned, this list is infinite&per. 
 For this reason, the scroll thumb on the vertical scroll bar is positioned in the middle of the vertical scroll bar and 
cannot be moved&per.  Click below the vertical scroll thumb to view the next page of symbols and above the vertical scroll 
thumb to view the previous page of symbols&per.
.br
.br
:font facename=Courier size=12x10.:artwork align=center name='brow4.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 4&per.:ehp3.:hp3.:ehp3.:hp2. The List window displays all symbols in the current browser database file&per.:ehp2.
.br
.br
Each symbol has a icon to its left&per.  A letter marking each icon indicates the symbol type in the source code 
as follows&colon.
:dl break=all tsize=5.
:dt.:hp2.F:ehp2.
:dd.Function
:dt.:hp2.C:ehp2.
:dd.Class
:dt.:hp2.T:ehp2.
:dd.Typedef
:dt.:hp2.V:ehp2.
:dd.Variable
:dt.:hp2.E:ehp2.
:dd.Enum
:edl.
.br
There are several ways to display the detail view of symbols&per.  When you reveal the detail view, the file folder icon 
changes to an open file folder&per.  To close the detail view dialog, click on the file folder&per.  This changes the icon 
back to a closed folder and closes the dialog&per.  To reveal the detail view of a symbol you can perform any of the following 
actions&colon.
:ul compact.
:li.The file folder icons are hot spots that display the detail view of the selected symbol&per.  To activate the hot spot, 
click once on the symbol name to select it and press ENTER to reveal the detail view&per.
:li.Click once on the file folder to reveal the detail view for that symbol&per.
:li.Click once on the symbol name to select it and choose:hp2. Detail:ehp2. from the:hp2. Detail:ehp2. menu&per.
:li.Double click on the symbol name&per.
:eul.

:h3 res=18 id=The_Class_Inheritance_View.The Class Inheritance View
:i1.inheritance menu item
:i1.browsing classes
:i1.Browser, browsing classes
.br
Selecting:hp2. Inheritance:ehp2. from the:hp2. View:ehp2. menu displays the inheritance hierarchy of all of the C++ classes 
in your program using a tree&per.  This allows you to see the relationships between base classes and derived classes&per. 
 In the inheritance hierarchy, each node represents a class&per.
.br
.br
:font facename=Courier size=12x10.:artwork align=center name='brow5.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 5&per.:ehp3.:hp3.:ehp3.:hp2. The Inheritance view displays the hierarchy of all C++ classes in your program 
(graph view shown)&per.:ehp2.
.br
.br
There are two different tree views you can choose from to display the class hierarchy&colon.
:dl break=all tsize=5.
:dt.:hp2.Graph view:ehp2.
:dd.The graph view displays each class in a box&per.  A box, or node, is connected to another node if one is a derived class 
of the other&per.  The root node of the tree is the base class for all nodes in the tree&per.  The tree is initially fully 
expanded&per.  See the section entitled :link reftype=hd refid=Manipulating_the_Tree_Views.Manipulating the Tree Views:elink. 
for more information on removing and expanding nodes from the tree&per.
:dt.:hp2.Outline view:ehp2.
:dd.The outline view displays the same information as the graph view but in a different way&per.  The outline view is initially 
fully collapsed&per.  That is, only the base classes are displayed&per.  In order to view the derived classes of a node, 
you must single click on the node&per.  This expands the node, displaying all its immediate derived classes&per.  See the 
section entitled :link reftype=hd refid=Manipulating_the_Tree_Views.Manipulating the Tree Views:elink. for more information 
on removing and expanding nodes from the tree&per.
:edl.

:h3 res=19 id=The_Function_Call_Tree_View.The Function Call Tree View
:i1.call menu item
:i1.browsing functions
:i1.Browser, browsing functions
.br
Selecting:hp2. Call:ehp2. from the:hp2. View:ehp2. menu displays the function call tree for all functions in your program&per. 
 This allows you to see all the functions that a given function calls and conversely all functions that call a certain function&per. 
 In the call tree, each node represents a function&per.
.br
.br
:font facename=Courier size=12x10.:artwork align=center name='brow6.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 6&per.:ehp3.:hp3.:ehp3.:hp2. The Call view displays a call tree for all functions in your program (outline 
view shown)&per.:ehp2.
.br
.br
There are two different tree views you can choose from to display the function call tree&colon.
:dl break=all tsize=5.
:dt.:hp2.Graph view:ehp2.
:dd.The graph view displays each function in a box&per.  A box, or node, is connected to another node if one function calls the 
other&per.  The tree is initially fully expanded&per.  See the section entitled :link reftype=hd refid=Manipulating_the_Tree_Views.Manipulating the Tree Views:elink. 
for more information on removing and expanding nodes from the tree&per.
:dt.:hp2.Outline view:ehp2.
:dd.The outline view displays the same information as the graph view but in a different way&per.  The outline view is initially 
fully collapsed&per.  In order to view the functions called by the function specified in the node, you must single click 
on the node&per.  This expands the node, displaying all functions it calls&per.  See the section entitled :link reftype=hd refid=Manipulating_the_Tree_Views.Manipulating the Tree Views:elink. 
for more information on removing and expanding nodes from the tree&per.
:edl.

:h3 res=20 id=Manipulating_the_Tree_Views.Manipulating the Tree Views
:i1.Browser, outline view
:i1.Browser, graph view
.br
With both the graph view and the outline view you can change the information displayed in the following ways&colon.
:ul compact.
:li.select the root nodes you want to view
:li.expand any node in the view
:li.collapse any node in the view
:eul.
.br
You expand and collapse nodes in the graph and outline views to hide and reveal descendant and ancestor nodes of the 
selected node&per.  There are two ways to expand and collapse nodes&colon.
:ul compact.
:li.choose the desired function from the:hp2. Tree:ehp2. menu
:li.click on the node (applies only to the outline view)
:eul.
.br
In addition to these functions, you can force the graph to be redrawn when a node in the tree view is collapsed&per. 
 By default, collapsed nodes will leave a gap in the graph&per.  Redrawing the graph removes these gaps&per.  This feature 
is controlled by an option&per.  See the section entitled :link reftype=hd refid=Configuring_the_Browser.Configuring the Browser:elink. 
for more information&per.
.br
.br
Clicking on the right mouse button when the mouse cursor is in a tree view will automatically display the:hp2. Tree:ehp2. 
menu&per.  This allows you to perform the actions in the:hp2. Tree:ehp2. menu without actually going to the menu bar&per.

:h4 res=21 id=Selecting_Root_Nodes.Selecting Root Nodes
:i1.Root Nodes, enable
:i1.Browser, enable root nodes
:i1.Browser, disable root nodes
:i1.Root Nodes, disable
:i1.Browser, selecting root nodes
:i1.Nodes, root
:i1.Root Nodes
.br
Select:hp2. Select Root Nodes:ehp2. from the:hp2. Tree:ehp2. menu to change the root nodes that are displayed&per.  The 
root nodes you select appear in the graph or outline view; all other root nodes are hidden&per.
.br
.br
Choosing:hp2. Select Root Nodes:ehp2. from the:hp2. Tree:ehp2. menu opens the:hp2. Select Root Nodes:ehp2. dialog&per. 
 This dialog lists all of the symbols that appear as a root node&per.  Each symbol in the:hp2. Select Root Nodes:ehp2. dialog 
has a check box&per.  When enabled, this check box is marked with an X, indicating that the symbol will appear as a root 
node in the display&per.
.br
.br
:font facename=Courier size=12x10.:artwork align=center name='brow7.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 7&per.:ehp3.:hp3.:ehp3.:hp2. On the Select Root Nodes dialog, choose the symbols you want to appear as root 
nodes&per.:ehp2.
.br
.br
:font facename=Courier size=0x0.:hp2.Disabling Root Nodes:ehp2.:font facename=Courier size=0x0.
:dl break=all tsize=5.
:dt.:hp2.(1):ehp2.
:dd.:hp2. Click in the check box:ehp2. of the root node you want to disable&per.  Alternatively, use the up and down arrow keys 
to select the root node you wish to disable&per.  Press the space bar to disable the currently selected root node&per.
.br
.br
The X disappears meaning that the root node is disabled and will not appear in the display&per.
:dt.:hp2.(2):ehp2.
:dd.:hp2. Repeat step one:ehp2. until you have disabled all desired root nodes&per.
:dt.:hp2.(3):ehp2.
:dd.:hp2. Click on:ehp2.:hp2. OK:ehp2. in the:hp2. Select Root Nodes:ehp2. dialog&per.
.br
.br
The:hp2. Select Root Nodes:ehp2. dialog closes and the display is updated&per.
:edl.
.br
To disable all of the root nodes in the:hp2. Select Root Nodes:ehp2. dialog, click on the:hp2. Disable All:ehp2. button&per. 
 This removes Xs from each box in the:hp2. Select Root Nodes:ehp2. dialog&per.  Click on:hp2. OK:ehp2. to close the dialog 
and update the display&per.
:dl break=all tsize=5.
:dt.:hp2.Note&colon.:ehp2.
:dd.This disables the selected root nodes only for the active view window&per.
:edl.
.br
:font facename=Courier size=0x0.:hp2.Enabling Root Nodes:ehp2.:font facename=Courier size=0x0.
:dl break=all tsize=5.
:dt.:hp2.(1):ehp2.
:dd.:hp2. Click in the check box:ehp2. of the root node you want to enable&per.  Alternatively, use the up and down arrow keys 
to select the root node you wish to enable&per.  Press the space bar to enable the currently selected root node&per.
.br
.br
An X appears in the box indicating that the root node is enabled and will appear in the display&per.
:dt.:hp2.(2):ehp2.
:dd.:hp2. Repeat step one:ehp2. until you have enabled all desired root nodes&per.
:dt.:hp2.(3):ehp2.
:dd.:hp2. Click on:ehp2.:hp2. OK:ehp2. in the:hp2. Select Root Nodes:ehp2. dialog&per.
.br
.br
The:hp2. Select Root Nodes:ehp2. dialog closes and the display is updated&per.
:edl.
.br
To enable all of the root nodes in the:hp2. Select Root Nodes:ehp2. dialog, click on the:hp2. Enable All:ehp2. button&per. 
 An X appears in each box on the:hp2. Select Root Nodes:ehp2. dialog&per.  Click on:hp2. OK:ehp2. to close the dialog and 
update the display&per.
:dl break=all tsize=5.
:dt.:hp2.Note&colon.:ehp2.
:dd.This enables the selected root nodes only for the active view window&per.
:edl.

:h4 res=22 id=Expanding_Nodes.Expanding Nodes
:i1.Browser, expanding nodes
:i1.Nodes, expanding
.br
You can expand the display all at once, one level at a time, or one branch at a time&per.  To expand by levels and branches, 
you must first select the node you want to expand&per.  Do this by clicking once on the desired node&per.
:dl break=all tsize=5.
:dt.:hp2.Expand One Level:ehp2.
:dd.Choose:hp2. Expand One Level:ehp2. from the:hp2. Tree:ehp2. menu to display all of the immediate children for the selected 
node&per.
:dt.:hp2.Expand Branch:ehp2.
:dd.Choose:hp2. Expand Branch:ehp2. from the:hp2. Tree:ehp2. menu to display all descendants of the selected node&per.
:dt.:hp2.Expand All:ehp2.
:dd.Choose:hp2. Expand All:ehp2. from the:hp2. Tree:ehp2. menu to fully expand all of the enabled root nodes&per.  Disabled root 
nodes do not appear in the display&per.
:edl.

:h4 res=23 id=Collapsing_Nodes.Collapsing Nodes
:i1.using the keyboard, to expand and collapse nodes
:i1.expanding and collapsing nodes, using the keyboard
:i1.Browser, collapsing nodes
:i1.Nodes, collapsing
.br
You can collapse the display all at once or one branch at a time&per.  To collapse by branches, you must first select 
the node you want to collapse&per.  Do this by clicking once on the desired node&per.
:dl break=all tsize=5.
:dt.:hp2.Collapse Branch:ehp2.
:dd.Choose:hp2. Collapse Branch:ehp2. from the:hp2. Tree:ehp2. menu to hide all descendants of the selected node&per.
:dt.:hp2.Collapse All:ehp2.
:dd.Choose:hp2. Collapse All:ehp2. from the:hp2. Tree:ehp2. menu to collapse all of the nodes and display only the root nodes&per.
:edl.
.br
:font facename=Courier size=0x0.:hp2.Using the Keyboard:ehp2.:font facename=Courier size=0x0.
.br
You can expand and collapse the symbols using key sequences&per.  Click once on the symbol name to highlight it and press 
one of the following keys&colon.
:dl break=all tsize=5.
:dt.:hp2.+:ehp2.
:dd.Expand the symbol one level
:dt.:hp2.-:ehp2.
:dd.Collapse the symbol one level
:dt.:hp2.*:ehp2.
:dd.Expand all descendants of the selected node&per.  This is the same as choosing:hp2. Expand Branch:ehp2. from the:hp2. Tree:ehp2. 
menu&per.
:dt.:hp2.CTRL *:ehp2.
:dd.Expands all of the enabled root nodes&per.  This is the same as choosing:hp2. Expand All:ehp2. from the:hp2. Tree:ehp2. menu&per.
:dt.:hp2.CTRL -:ehp2.
:dd.Collapses all of the symbols and displays only the root nodes&per.  This is the same as choosing:hp2. Collapse All:ehp2. 
from the:hp2. Tree:ehp2. menu&per.
:edl.

:h2 res=24 id=Viewing_Detail_Information.Viewing Detail Information
:i1.Browser, view detail information
.br
Once a global view is displayed, you can view detailed information for a symbol in the global view in several ways&colon.
:ul compact.
:li.Double click on the desired symbol&per.
:li.Click once on the desired symbol to select it; then choose:hp2. Detail:ehp2. from the:hp2. Detail:ehp2. menu&per.
:li.Click once on the desired symbol to select it then press ENTER&per.
:eul.
.br
From the list view, you can reveal the detail view if you&colon.
:ul compact.
:li.Click once on the icon to the left of the symbol&per.
:eul.
.br
Performing any of these actions reveals a detail view window for the selected symbol&per.  The same information appears 
in this window regardless of the method used to access it&per.
.br
.br
:font facename=Courier size=12x10.:artwork align=center name='brow8.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 8&per.:ehp3.:hp3.:ehp3.:hp2. The detail view displays detailed information for the selected symbol&per.:ehp2.
.br
.br
The detail view window displays the source file where the symbol is defined or declared and it shows you what the 
symbol looks like in your source code&per.
.br
.br
A list box appears in the detail view window when you select a symbol whose type is a function, class, or enum&per. 
 The list box contains information specific to the symbol type, as follows&per.
:dl break=all tsize=5.
:dt.:hp2.Functions:ehp2.
:dd.The list box displays, where applicable, local variables for the function&per.
:dt.:hp2.Classes:ehp2.
:dd.The list box displays member variables and member functions for the selected class and any inherited classes&per.  The Browser 
divides this information into three categories&colon.
:ul compact.
:li.Public
:li.Private
:li.Protected
:eul.
:dt.:hp2.Enums:ehp2.
:dd.The list box displays enumerator values for the selected enumerator&per.
:edl.
.br
You can view detailed information for symbols in the list box by double-clicking on the symbol&per.  Other symbols in 
the header information for the detail view are highlighted&per.  Double-clicking on these symbols also displays a detail 
view&per.

:h3 res=25 id=Goto_Definition.Goto Definition
:i1.Goto Definition function
:i1.Browser, Goto Definition function
.br
From a detail view,:hp2. Goto Definition:ehp2. in the:hp2. Detail:ehp2. menu allows you to edit the file that contains 
the symbol's definition&per.  The editor is positioned on the line and column containing the symbols definition&per.  This 
allows you to make edits to your source code while you are browsing&per.  When you are done, save any changes made and exit 
the editor to return to the Browser session&per.
.br
.br
Note that any changes to your source code will make the Browser database out-of-date&per.

:h3 res=26 id=Source_References.Source References
:i1.Source References
:i1.Browser, source references
.br
Selecting:hp2. Source References:ehp2. from the:hp2. Detail:ehp2. menu displays all locations in the source code where 
a symbol is referenced&per.  This allows you to analyze all uses of a particular symbol&per.
.br
.br
When modifying a symbol, you can use this feature to locate all occurrences of the symbol in the source code so you 
can update them&per.
:dl break=all tsize=5.
:dt.:hp2.To view the source references for a symbol&colon.:ehp2.
:dd.
:dt.:hp2.(1):ehp2.
:dd.:hp2. Position yourself at the detail view of the symbol:ehp2. whose source references you want to view&per.
:dt.:hp2.(2):ehp2.
:dd.:hp2. Choose:ehp2.:hp2. Source References:ehp2. from the:hp2. Detail:ehp2. menu&per.
.br
.br
This opens the:hp2. Source References:ehp2. window for the selected symbol&per.  This window displays the filename, 
line number, and column number of each occurrence of the selected symbol in the source code&per.
:edl.
.br
:font facename=Courier size=12x10.:artwork align=center name='brow9.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 9&per.:ehp3.:hp3.:ehp3.:hp2. Use the Source References window to view all the occurrences of the selected 
symbol in the source code&per.:ehp2.

:h3 res=27 id=Symbol_References.Symbol References
:i1.Browser, symbol references
:i1.Symbol references
.br
:hp2. Symbol References:ehp2. allows you to view a list of all symbols that use a particular symbol&per.  When modifying 
a symbol you can use this feature to locate all symbols using the modified symbol&per.  This allows you to determine if all 
referencing symbols need to be updated&per.
:dl break=all tsize=5.
:dt.:hp2.To view the symbol references for a symbol&colon.:ehp2.
:dd.
:dt.:hp2.(1):ehp2.
:dd.:hp2. Position yourself at the detail view of the symbol:ehp2. whose symbol references you want to view&per.
:dt.:hp2.(2):ehp2.
:dd.:hp2. Choose:ehp2.:hp2. Symbol References:ehp2. from the:hp2. Detail:ehp2. menu&per.
.br
.br
This opens the:hp2. Symbol Referencing:ehp2. window for the selected symbol&per.  This window displays a list of 
all symbols that use the selected symbol&per.  The display is the same as the list view of symbols&per.  Each symbol has 
a icon indicating its symbol type&per.
.br
.br
:font facename=Courier size=12x10.:artwork align=center name='brow10.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 10&per.:ehp3.:hp3.:ehp3.:hp2. Use the Symbols window to view a list of all symbols that use the selected 
symbol&per.:ehp2.
.br
.br
You can perform the same actions in this window as from the:hp2. List:ehp2. window&per.  Refer to the section entitled 
:link reftype=hd refid=The_List_View.The List View:elink. for more information&per.
:edl.
.br
From this window you can invoke the editor to make changes to the source code that contains the symbols that reference 
a particular symbol&per.  Select the reference you want to edit in one of two ways&colon.
:ul compact.
:li.Double click on the desired reference&per.
:li.Click once on the desired reference to select it and press ENTER&per.
:eul.
.br
This invokes the editor and positions the cursor at the line that contains the selected reference&per.

:h2 res=28 id=Locating_Symbols.Locating Symbols
:i1.Browser, locating symbols
:i1.Symbols, locating
.br
When a global view is displayed and your program contains many symbols, it can be difficult to scroll through the global 
view to locate a particular symbol&per.  There are two functions that can help you locate a symbol in a global view&colon.
:ul compact.
:li.Find
:li.Find Selected
:eul.

:h3 res=29 id=Find.Find
.br
Choose:hp2. Find:ehp2. from the:hp2. Locate:ehp2. menu to open the:hp2. Find:ehp2. dialog&per.  Use this dialog to specify 
the criteria to be used to locate a symbol&per.  For example, you can search for a particular symbol or a set of symbols 
with common characteristics&per.
.br
.br
:font facename=Courier size=12x10.:artwork align=center name='brow11.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 11&per.:ehp3.:hp3.:ehp3.:hp2. Use the Find dialog to locate one symbol or a set of symbols&per.:ehp2.

:h4 res=30 id=Find_Pattern.Find Pattern
:i1.find pattern
:i1.Browser, find pattern
.br
In the:hp2. Pattern:ehp2. field of the:hp2. Find:ehp2. dialog, enter a pattern for the symbol(s) you wish to locate&per. 
 The matching behaviour depends on the switches set in this dialog&per.
:dl break=all tsize=5.
:dt.:hp2.Match Case:ehp2.
:dd.When enabled, the Browser performs a case sensitive compare when attempting to find a match&per.
:dt.:hp2.Match Whole Symbols Only:ehp2.
:dd.When enabled, the Browser locates symbols that exactly match the specified pattern&per.  This switch only applies when the:hp2. 
Use Regular Expressions:ehp2. switch is disabled&per.
:dt.:hp2.Use Regular Expressions:ehp2.
:dd.When enabled, the Browser interprets the pattern specified as a regular expression&per.  The:hp2. Edit:ehp2. button, when 
pressed, displays the:hp2. Regular Expression Options:ehp2. dialog&per.  This dialog allows you to specify the regular expression&per.
:edl.
.br
Dropping the combo box of the:hp2. Pattern:ehp2. field displays a list of previous patterns entered&per.  You can select 
a pattern from this list instead of entering a new one&per.

:h4 res=31 id=Find_Filters.Find Filters
:i1.Browser, find filters
:i1.find filters
.br
Clicking on the:hp2. Filters:ehp2. button on the:hp2. Find:ehp2. dialog opens the:hp2. Find Filters:ehp2. dialog&per. 
 This dialog allows you to specify the characteristics of the symbol(s) to be located&per.
.br
.br
:font facename=Courier size=12x10.:artwork align=center name='brow12.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 12&per.:ehp3.:hp3.:ehp3.:hp2. Use the Find Filters dialog to specify characteristics of the symbol(s) you 
want to locate&per.:ehp2.
.br
.br
In the:hp2. Symbol Type:ehp2. section of the dialog click on the symbol types you want to view&per.  To search for 
all symbol types, select the:hp2. All:ehp2. button&per.
.br
.br
In the:hp2. Symbol Scope:ehp2. section, you can specify the scope for locating symbols&per.
:dl break=all tsize=5.
:dt.:hp2.Member of Class&colon.:ehp2.
:dd.Specify the class that the symbol must be a member of in order to be located&per.
:dt.:hp2.Local Symbols of Function&colon.:ehp2.
:dd.Specify the function that the symbol must be local to in order to be located&per.
:edl.
.br
:font facename=Courier size=0x0.:hp2.Find File Filters:ehp2.:font facename=Courier size=0x0.
.br
The:hp2. Source Files:ehp2. button, when pressed, displays the:hp2. Source Files:ehp2. dialog that allows you to specify 
the files to be searched when attempting to locate a symbol&per.  This dialog lists all source files that make up the database 
file&per.  Each source file in the list has a check box&per.  An X in this box indicates that the source file is searched 
when trying to locate a symbol&per.  Click in the check box of the source file you want to disable&per.  This removes the 
X&per.  The blank box indicates that the source file will not be searched when trying to locate a symbol&per.  To re-enable 
the source file, click in the check box again&per.  This places an X in the box indicating that the source file will be searched&per.
.br
.br
:font facename=Courier size=12x10.:artwork align=center name='brow13.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 13&per.:ehp3.:hp3.:ehp3.:hp2. Choose the source files to be searched using the Source Files dialog&per.:ehp2.
.br
.br
The:hp2. Pattern:ehp2. section of the dialog, allows you to specify wild card directory specifications for files 
that are to be included or excluded in the search&per.  For example, specifying "d&colon.\watcom\h\*&per.h" and pressing 
the:hp2. Exclude:ehp2. button, will prevent any file in the "d&colon.\watcom\h" directory with extension "&per.h" from being 
searched&per.  To include these files in the search again, specify the same pattern and press the:hp2. Include:ehp2. button&per.
.br
.br
Pressing the:hp2. Set All:ehp2. button includes all files in the search&per.
.br
.br
Pressing the:hp2. Clear All:ehp2. button excludes all files in the search&per.  This is useful, for example, if you 
wish to only search files in the current directory&per.  Simply press the:hp2. Clear All:ehp2. button, specify "*&per.*" 
in the Pattern section, and press the:hp2. Include:ehp2. button&per.

:h4 res=32 id=Performing_the_Find.Performing the Find
.br
Once the filter criteria are set, perform the find operation by clicking on the:hp2. OK:ehp2. button on the:hp2. Find:ehp2. 
dialog&per.  This closes the dialog and performs the search&per.  The Browser examines the symbols in the current global 
view and selects the first symbol that matches the search criteria&per.
.br
.br
To find the next symbol that matches the search criteria, choose:hp2. Find Next:ehp2. from the:hp2. Locate:ehp2. 
menu&per.

:h3 res=33 id=Find_Selected.Find Selected
:i1.Browser, find selected
.br
Because the symbols displayed in a global view are often many, only a portion of the display is visible in the window 
at any time&per.  When you temporarily scroll away from the selected symbol or node, a quick method of locating that symbol 
is to select:hp2. Find Selected:ehp2. from the:hp2. Locate:ehp2. menu&per.  This will immediately locate and display the 
currently selected symbol in the global view&per.

:h2 res=34 id=Configuring_the_Browser.Configuring the Browser
:i1.Browser, configure
.br
There are several options in the Browser that you can configure&colon.
:ul compact.
:li.Regular expression processing for find and query
:li.Global Symbol Queries
:li.Enumerator styles for detail views of enumeration constants
:li.Member filters for detail views of classes
:li.Auto-arranging of graph views
:li.Line drawing method for graph views
:li.Orientation of graph views
:li.Line styles and colors for inheritance graphs
:li.Line styles and colors for call graphs
:li.Selection of text editor
:li.Automatic saving of options on exit
:eul.
.br
This section describes each configuration option&per.

:h3 res=35 id=Regular_Expressions_for_Find_and_Query.Regular Expressions for Find and Query
:i1.regular expressions, in Browser
:i1.Browser, set regular expressions for queries
:i1.Browser, set regular expressions for find
.br
:hp2. Regular Expressions:ehp2. in the:hp2. Options:ehp2. menu allows you to configure the regular expression used to 
find a symbol and specify a query&per.
.br
.br
:font facename=Courier size=12x10.:artwork align=center name='brow14.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 14&per.:ehp3.:hp3.:ehp3.:hp2. Use the Regular Expressions Options dialog to configure a regular expression 
for Find and Query&per.:ehp2.
.br
.br
Choose:hp2. Regular Expressions:ehp2. from the:hp2. Options:ehp2. menu to open the:hp2. Regular Expressions Options:ehp2. 
dialog&per.  In the:hp2. Search String Meaning:ehp2. section of the dialog you select the anchoring method used to find a 
match&per.
:dl break=all tsize=5.
:dt.:hp2.Starts With:ehp2.
:dd.Matches only if the pattern is found at the beginning of the symbol
:dt.:hp2.Contains:ehp2.
:dd.Matches if it occurs anywhere in the symbol
:edl.
.br
In the:hp2. Regular Expression Characters:ehp2. section of the dialog you select the characters you want the Browser 
to interpret as meta-characters&per.
.br
.br
Select the desired characters by clicking once in the corresponding check box&per.  An X in the check box indicates 
that the character will be interpreted as a meta-character&per.  Unchecked characters are matched as standard keyboard characters&per. 
 To de-select a character, click again on its check box&per.
.br
.br
The other buttons on this dialog are&colon.
:dl break=all tsize=5.
:dt.:hp2.Set All:ehp2.
:dd.Click on Set All to enable all of the characters&per.
:dt.:hp2.Clear All:ehp2.
:dd.Click on Clear All to disable all of the characters&per.
:dt.:hp2.Defaults:ehp2.
:dd.Click on Defaults to discard the current settings in this dialog and replace them with the settings configured at the start 
of the Browser session&per.
:dt.:hp2.OK:ehp2.
:dd.Click on:hp2. OK:ehp2. to close this dialog&per.  This changes the configuration for the current Browser session&per.
:edl.

:h3 res=36 id=Global_Symbol_Queries.Global Symbol Queries
.br
Choose:hp2. Query:ehp2. from the:hp2. Options:ehp2. menu to open the:hp2. Query:ehp2. dialog&per.  Use this dialog to 
specify the criteria to be used to display symbols in a global view&per.
.br
.br
:font facename=Courier size=12x10.:artwork align=center name='brow15.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 15&per.:ehp3.:hp3.:ehp3.:hp2. Use the Query dialog to configure global view symbol queries&per.:ehp2.

:h4 res=37 id=Query_Pattern.Query Pattern
:i1.query pattern
:i1.Browser, specifying the query pattern
.br
In the:hp2. Pattern:ehp2. field of the:hp2. Query:ehp2. dialog, enter a pattern for the symbol(s) you wish to display 
in the global views&per.  The matching behaviour depends on the switches set in this dialog&per.
:dl break=all tsize=5.
:dt.:hp2.Match Case:ehp2.
:dd.When enabled, the Browser performs a case sensitive compare when attempting to find a match&per.
:dt.:hp2.Match Whole Symbols Only:ehp2.
:dd.When enabled, the Browser includes symbols that exactly match the specified pattern&per.  This switch only applies when the:hp2. 
Use Regular Expressions:ehp2. switch is disabled&per.
:dt.:hp2.Use Regular Expressions:ehp2.
:dd.When enabled, the Browser interprets the pattern specified as a regular expression&per.  The:hp2. Edit:ehp2. button is enables 
and, when pressed, displays the:hp2. Regular Expression Options:ehp2. dialog&per.  This dialog allows you to specify the 
regular expression&per.
:edl.
.br
Dropping the combo box of the:hp2. Pattern:ehp2. field displays a list of previous patterns entered&per.  You can select 
a pattern from this list instead of entering a new one&per.

:h4 res=38 id=Query_Filters.Query Filters
:i1.Browser, query filters
:i1.query filters
.br
Clicking on the:hp2. Filters:ehp2. button on the:hp2. Query:ehp2. dialog opens the:hp2. Query Filters:ehp2. dialog&per. 
 This dialog allows you to specify the characteristics of the symbol(s) to be displayed in the global views&per.
.br
.br
In the:hp2. Symbol Type:ehp2. section of the dialog click on the symbol types you want to view&per.  To display symbols 
of all types, click on the:hp2. All:ehp2. button&per.
.br
.br
In the:hp2. Symbol Scope:ehp2. section, you can specify the scope of the symbols to be displayed&per.
:dl break=all tsize=5.
:dt.:hp2.Member of Class&colon.:ehp2.
:dd.Specify the class that the symbol must be a member of in order to be displayed&per.
:dt.:hp2.Local Symbols of Function&colon.:ehp2.
:dd.Specify the function that the symbol must be local to in order to be displayed&per.
:edl.
.br
In the:hp2. Symbol Attributes:ehp2. section, you can specify the attributes of the symbols to be displayed&per.  Selecting:hp2. 
Artificial:ehp2. will cause compiler-generated symbols to be displayed&per.  Selecting:hp2. Anonymous:ehp2. will cause unnamed 
types to be displayed&per.  Unnamed types will be displayed as square brackets enclosing the symbols whose type they define&per. 
 Selecting:hp2. Declared Only:ehp2. will cause only symbols that have been defined to be displayed&per.  For example, a function 
prototype for an unreferenced function will not be displayed when:hp2. Declared Only:ehp2. is selected&per.
.br
.br
:font facename=Courier size=0x0.:hp2.Query File Filters:ehp2.:font facename=Courier size=0x0.
.br
The:hp2. Source Files:ehp2. button, when pressed, displays the:hp2. Source Files:ehp2. dialog that allows you to specify 
the files that a symbol must be defined in in order to be displayed&per.  This dialog lists all source files that make up 
the database file&per.  Each source file in the list has a check box&per.  An X in this box indicates that all symbols defined 
in the source file will be displayed&per.  Click in the check box of the source file you want to disable&per.  This removes 
the X&per.  The blank box indicates that any symbols defined in the source file will not be displayed&per.  Alternatively, 
use the up and down arrow keys to select the source file you wish to disable&per.  Press the space bar to disable the currently 
selected source file&per.  To re-enable the source file, click in the check box again or press the space bar&per.  This places 
an X in the box again&per.
.br
.br
The:hp2. Pattern:ehp2. section of the dialog, allows you to specify wild card directory specifications for files&per. 
 Any symbols defined in these files will be displayed in the global views&per.  For example, specifying:font facename=Courier size=12x10. 
d&colon.\watcom\h\*&per.h:font facename=Courier size=0x0. and pressing the:hp2. Exclude:ehp2. button, will prevent any symbol 
defined in any file in the:font facename=Courier size=12x10. d&colon.\watcom\h:font facename=Courier size=0x0. directory 
with extension "&per.h" from being displayed&per.  To display symbols from these files again, specify the same pattern and 
press the:hp2. Include:ehp2. button&per.
.br
.br
Pressing the:hp2. Set All:ehp2. button displays all symbols in all files&per.
.br
.br
Pressing the:hp2. Clear All:ehp2. button causes no symbols to be displayed&per.  This is useful, for example, if 
you wish to only display symbols defined in files in the current directory&per.  Simply press the:hp2. Clear All:ehp2. button, 
specify:font facename=Courier size=12x10. *&per.*:font facename=Courier size=0x0. in the Pattern section, and press the:hp2. 
Include:ehp2. button&per.

:h3 res=39 id=Enumerator_Styles.Enumerator Styles
:i1.Browser, enumeration styles
:i1.enumeration styles
.br
Selecting:hp2. Enumeration Styles:ehp2. from the:hp2. Options:ehp2. menu displays the:hp2. Enumeration Styles:ehp2. dialog&per. 
 This dialog allows you to specify the format for displaying enumeration constants in the detail views for enumeration constants&per.
.br
.br
:font facename=Courier size=12x10.:artwork align=center name='brow16.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 16&per.:ehp3.:hp3.:ehp3.:hp2. Specify enumerator styles for detail views of enumerator constants using the 
Enumeration Styles dialog&per.:ehp2.

:h3 res=40 id=Member_Filters_for_Classes.Member Filters for Classes
:i1.class details, member filters
:i1.Browser, member filters for class details
.br
:hp2. Member Filters:ehp2. in the:hp2. Options:ehp2. menu allows you to specify the members you want to appear in the 
detail view of a class&per.  For example, you may not want the detail class to contain private members&per.  Alternatively, 
you may only wish to see function members and not data members&per.
:dl break=all tsize=5.
:dt.:hp2.(1):ehp2.
:dd.:hp2. Choose:ehp2.:hp2. Member Filters:ehp2. from the:hp2. Options:ehp2. menu&per.
.br
.br
This opens the:hp2. Member Filters:ehp2. dialog where you specify the information you want to appear in detail views 
for classes&per.
.br
.br
:font facename=Courier size=12x10.:artwork align=center name='brow17.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 17&per.:ehp3.:hp3.:ehp3.:hp2. Use the Member Filters dialog to select the information to appear in detail 
views for classes&per.:ehp2.
:dt.:hp2.(2):ehp2.
:dd.:hp2. Choose the inheritance level:ehp2. from the:hp2. Inherited Members:ehp2. section of the dialog&per.
.br
.br
The options are&colon.
:dl break=all tsize=5.
:dt.:hp2.None:ehp2.
:dd.Do not show inherited members&per.
:dt.:hp2.Visible:ehp2.
:dd.Show the local members of a class and visible members of inherited classes&per.
:dt.:hp2.All:ehp2.
:dd.Show all local and inherited members of a class&per.
:edl.
:dt.:hp2.(3):ehp2.
:dd.:hp2. Click on the check boxes:ehp2. in the:hp2. Access Level:ehp2. section of the dialog to select the desired access levels&per.
.br
.br
The options are Public, Protected, and Private&per.  Only members with the selected attributes will appear in the 
detail view for a class&per.
:dt.:hp2.(4):ehp2.
:dd.:hp2. Select the desired members:ehp2. in the:hp2. Members:ehp2. section of the dialog&per.
.br
.br
Show data members in a class by enabling the:hp2. variables:ehp2. check box&per.  When the:hp2. variables:ehp2. check 
box is enabled, you may also enable or disable static data members by clicking on the:hp2. static:ehp2. check box&per.
.br
.br
Show function members in a class by enabling the:hp2. functions:ehp2. check box&per.  When the:hp2. functions:ehp2. 
check box is enabled, you may also enable or disable static and virtual function members by clicking on the:hp2. static:ehp2. 
and:hp2. virtual:ehp2. check boxes&per.
:dt.:hp2.(5):ehp2.
:dd.:hp2. Click on OK:ehp2. to accept the member filter query&per.
.br
.br
This closes the dialog and returns you to the active window&per.
:edl.
:dl break=all tsize=5.
:dt.:hp2.Note&colon.:ehp2.
:dd.The Default button on the Member Filter dialog resets the query to the default settings&per.
:edl.

:h3 res=41 id=AutoMarranging_of_Graph_Views.Auto-arranging of Graph Views
:i1.graph views, auto-arranging
:i1.Browser, auto-arranging the graph view
.br
When collapsing a graph view, nodes that become hidden are replaced by gaps in the graph&per.:hp2.  Arrange Graph:ehp2. 
in the:hp2. Tree:ehp2. menu compacts the graph view to remove the spaces left vacant by hidden nodes&per.
.br
.br
When enabled,:hp2. Graph Auto-arrange:ehp2. of the:hp2. Options:ehp2. menu causes the Browser to automatically compact 
the graph view each time you perform a collapse operation&per.  To enable the automatic compaction of the graph view after 
a collapse operation, select:hp2. Graph Auto-arrange:ehp2. from the:hp2. Options:ehp2. menu&per.  A check mark appears beside 
the menu item when it is enabled&per.  Select the menu item again to disable it&per.

:h3 res=42 id=Line_Drawing_Method_for_Graph_Views.Line Drawing Method for Graph Views
.br
:hp2.Graph Square Lines:ehp2. in the:hp2. Options:ehp2. menu allows you to select the type of line that connects the 
nodes in a graph view&per.  The default is to connect nodes of the graph using diagonal lines&per.  Choosing:hp2. Graph Square 
Lines:ehp2. from the:hp2. Options:ehp2. menu causes nodes to be connected using square lines (combinations of vertical and 
horizontal lines)&per.  A check mark beside the menu item indicates this method of drawing lines is enabled&per.  To disable 
this option, select it again&per.
.br
.br
:font facename=Courier size=12x10.:artwork align=center name='brow18.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 18&per.:ehp3.:hp3.:ehp3.:hp2. The Graph Square Lines option changes the connecting lines from diagonal to 
square&per.:ehp2.

:h3 res=43 id=Changing_the_Graph_Orientation.Changing the Graph Orientation
:i1.Browser, change graph orientation
.br
In the:hp2. Options:ehp2. menu you can select whether the trees on the graph view grow horizontally or vertically&per. 
 A graph view that grows horizontally is one where the root node is at the left and the leaf nodes at the right&per.  A graph 
view that grows vertically is one where the root node is at the top and the leaf nodes at the bottom&per.  By default, graphs 
grow vertically&per.
.br
.br
Select:hp2. Graph Horizontal:ehp2. from the:hp2. Options:ehp2. menu to change the graph orientation to horizontal&per. 
 Selecting this option changes the menu item name to:hp2. Graph Horizontal:ehp2. in the:hp2. Options:ehp2. menu&per.  Select 
this menu item to change the graph orientation back to vertical&per.
.br
.br
:font facename=Courier size=12x10.:artwork align=center name='brow19.bmp'.:font facename=Courier size=0x0.
.br
:hp3.Figure 19&per.:ehp3.:hp3.:ehp3.:hp2. The Graph Horizontal option displays the graph with the root node at the left&per.:ehp2.

:h3 res=44 id=Defining_Graph_View_Legends.Defining Graph View Legends
:i1.Browser, defining graph view legends
:i1.call legend menu item
:i1.inheritance legend menu item
:i1.graph view legends, in Browser
.br
The:hp2. Inheritance Legend:ehp2. and:hp2. Call Legend:ehp2. menu items in the:hp2. Options:ehp2. menu allow you to change 
the colors, line styles, and node styles used in the graph views&per.  Changing the styles updates all open graph views in 
the current session, as well as any new ones you open&per.  Saving the session configuration to an option file saves changes 
made to the colors and the lines and node styles&per.
.br
.br
The:hp2. Inheritance Legend:ehp2. and:hp2. Call Legend:ehp2. dialogs are designed differently, but the procedures 
for changing the graph styles are identical&per.
.br
.br
To change the line and node styles for inheritance graphs, choose:hp2. Inheritance Legend:ehp2. from the:hp2. Options:ehp2. 
menu&per.  The:hp2. Inheritance Legend:ehp2. dialog appears&per.
.br
.br
To change the line and node styles for call graphs, choose:hp2. Call Legend:ehp2. from the:hp2. Options:ehp2. menu&per. 
 The:hp2. Call Legend:ehp2. dialog appears&per.
:dl break=all tsize=5.
:dt.:hp2.(1):ehp2.
:dd.:hp2. Click once on the line or node style:ehp2. or use the up, down, right and left arrow keys to select the line or node 
style you want to change&per.
.br
.br
A box appears around the selected line&per.
:dt.:hp2.(2):ehp2.
:dd.:hp2. Click on the Modify button&per.:ehp2.
.br
.br
This opens the:hp2. Draw Style:ehp2. dialog for the selected line or node style&per.
:dt.:hp2.(3):ehp2.
:dd.:hp2. Click once on the desired line or node style:ehp2.
.br
.br
or
:dt.:hp2.:ehp2.
:dd.:hp2. use the up and down arrow keys:ehp2. to select the desired line or node style&per.
.br
.br
The sample appearing in the:hp2. Example:ehp2. field at the top of the dialog now reflects the currently selected 
line or node style&per.
:dt.:hp2.(4):ehp2.
:dd.:hp2. Click once on the desired color or use the up and down:ehp2. arrow keys to select the desired color&per.
.br
.br
The sample appearing in the:hp2. Example:ehp2. field at the top of the dialog now reflects the currently selected 
color&per.
:dt.:hp2.(5):ehp2.
:dd.:hp2. Click on OK:ehp2. to accept the new style and color setting&per.
.br
.br
The:hp2. Draw Style:ehp2. dialog closes, returning you to the:hp2. Inheritance Legend:ehp2. or:hp2. Call Legend:ehp2. 
dialog&per.  Select another line or node style to change and repeat this procedure&per.
:dt.:hp2.(6):ehp2.
:dd.:hp2. Click on OK in the:ehp2.:hp2. Inheritance Legend:ehp2. or:hp2. Call Legend:ehp2. dialog when you have changed all desired 
colors and styles for lines and nodes&per.
.br
.br
Clicking:hp2. OK:ehp2. closes the dialog and updates all open inheritance or call graph views with the selected colors 
and line and node styles&per.
:edl.

:h3 res=45 id=Selecting_a_Text_Editor.Selecting a Text Editor
:i1.set text editor
:i1.Browser, selecting a text editor
.br
You can use your own favourite text editor from within the Browser&per.
:dl break=all tsize=5.
:dt.:hp2.To select your own text editor&colon.:ehp2.
:dd.
:dt.:hp2.(1):ehp2.
:dd.:hp2. Choose Set Text Editor:ehp2. from the Options menu&per.
.br
.br
The Set Text Editor dialog appears&per.  You can enter the name of the text editor in the first field&per.  You must 
also indicate whether the text editor is an executable file or a Dynamic Link Library (DLL)&per.  If the editor is an executable 
file (rather than a DLL), then you can enter an argument line in the second field&per.  The argument line will be supplied 
to the editor whenever it is started by the Browser&per.  The argument line can include any of three different macros which 
will be filled in by the Browser&per.  The macros are&colon.
:dl break=all tsize=5.
:dt.:hp2.%f:ehp2.
:dd.The name of the file to be edited&per.
:dt.:hp2.%r:ehp2.
:dd.The row in the file at which to position the cursor&per.  If the editor is invoked from a diagnostic message which contains 
a line number then the row value is extracted from the message; otherwise the row value is 1&per.
:dt.:hp2.%c:ehp2.
:dd.The column in the file at which to position the cursor&per.  If the editor is invoked from a diagnostic message which contains 
a column number then the column value is extracted from the message; otherwise the column value is 1&per.
:edl.
.br
For example, if the editor argument line that you specified was&colon.
.br
.br
:font facename=Courier size=12x10.      :font facename=Courier size=0x0.
.br
:font facename=Courier size=12x10.     file&eq.'%f' row&eq.'%r' col&eq.'%c':font facename=Courier size=0x0.
.br
.br
and you double click on an error message in the Log window that names the file:font facename=Courier size=12x10. 
foobar&per.c:font facename=Courier size=0x0. with an error at line 215 and column 31, then the argument line that is passed 
to your editor is&colon.
.br
.br
:font facename=Courier size=12x10.      :font facename=Courier size=0x0.
.br
:font facename=Courier size=12x10.     file&eq.'foobar&per.c' row&eq.'215' col&eq.'31':font facename=Courier size=0x0.
.br
.br
This flexibility allows you to specify the name of the file to edit and the row and/or column at which to position 
the text cursor&per.  If no row or column is available, then the Browser will supply the value of 1 as a default&per.
:dt.:hp2.(2):ehp2.
:dd.:hp2. Select OK:ehp2. when you wish to confirm the selection of a new editor&per.
.br
.br
or
:dt.:hp2.:ehp2.
:dd.:hp2. Select Cancel:ehp2. when you wish to cancel the selection of a new editor&per.
.br
.br
or
:dt.:hp2.:ehp2.
:dd.:hp2. Select Default:ehp2. when you wish to restore the default editor selection and then select OK or Cancel&per.
:edl.

:h3 res=46 id=Automatically_Saving_Options_on_Exit.Automatically Saving Options on Exit
:i1.Browser, saving options on exit
.br
:hp2. Save Options on Exit:ehp2. in the:hp2. Options:ehp2. menu instructs the Browser to automatically save the current 
options to an options file&per.  To enable the automatic saving of options, select:hp2. Save Options on Exit:ehp2. from the:hp2. 
Options:ehp2. menu&per.  A check mark beside the menu item indicates that it is enabled&per.  To disable this option, select 
it again&per.
.br
.br
See the section entitled :link reftype=hd refid=Saving_Options.Saving Options:elink. for more information on saving 
options to a file&per.

:h2 res=47 id=Loading_Options.Loading Options
:i1.options, loading
:i1.Browser, loading options
.br
Use the:hp2. Load Options:ehp2. menu to load an option file into your Browser session&per.
.br
.br
Choose:hp2. Load Options:ehp2. from the:hp2. File menu&per.:ehp2.  The:hp2. Load Options File:ehp2. dialog appears 
where you select the option file you want to load for the current Browser session&per.

:h2 res=48 id=Saving_Options.Saving Options
:i1.Browser, save options
:i1.Browser, saving options
.br
There are three ways to save the current options to an option file&colon.
:ul compact.
:li.Save Options
:li.Save Options As
:li.Save Options on Exit
:eul.
.br
An asterisk beside the option file name in the caption bar indicates that changes were made to the options during the 
Browser session and should be saved&per.  This section describes each method for saving options to a file&per.
:dl break=all tsize=5.
:dt.:hp2.Note&colon.:ehp2.
:dd.If you have made option changes during the Browser session and you choose:hp2. Exit:ehp2. from the:hp2. File:ehp2. menu without 
first saving the options, the Browser prompts you to save the options to a file&per.  Refer to the section entitled :link reftype=hd refid=Quitting_the_Browser.Quitting the Browser:elink. 
for more information&per.
:edl.
:dl break=all tsize=5.
:dt.:hp2.Save Options:ehp2.
:dd.Selecting:hp2. Save Options:ehp2. from the:hp2. File:ehp2. menu saves the updated options information to the current options 
file&per.  To save options in this way, an options file must be specified in the caption bar&per.  
:dt.:hp2.Save Options As:ehp2.
:dd.:hp2. Save Options As:ehp2. in the:hp2. File:ehp2. menu opens the:hp2. Save Options As:ehp2. dialog&per.  Specify the filename 
of the option file to which you want to save the current options&per.  Click on:hp2. OK:ehp2. to close the dialog and save 
the options&per.
:dt.:hp2.Save Options on Exit:ehp2.
:dd.:hp2. Save Options on Exit:ehp2. in the:hp2. Options:ehp2. menu allows you to specify that the Browser is to automatically 
save the current options to an options file, if one exists&per.  When enabled, a check mark appears beside this menu item&per.
.br
.br
When enabled and an option file exists, the Browser saves the changes without prompting when you close the session&per.
.br
.br
When enabled and no option file exists, the Browser displays a message box prompting you to save the new options&per. 
 Choose:hp2. No:ehp2. in this box to close the Browser session without saving&per.  Choose:hp2. Yes:ehp2. in this box to 
display a:hp2. Save As:ehp2. dialog where you specify the option file to which you want to save the new options&per.
:edl.

:h2 res=49 id=Setting_Source_Search_Paths.Setting Source Search Paths
:i1.path search
:i1.search path
:i1.source search path
:i1.Browser, path option
:i1.path option
.br
You can specify a command line option to the Browser that allows you to specify alternate source file search paths&per. 
 This option is useful when a database file is created on a system different from the one that is used to browse the application 
source code&per.  The syntax of the command line option is&colon.
.br
.br
:font facename=Courier size=12x10.      :font facename=Courier size=0x0.
.br
:font facename=Courier size=12x10.     path path_spec1;path_spec2;&per.&per.&per.:font facename=Courier size=0x0.
.br
.br
Since the database files record explicit paths to source files, it is likely that the path will no longer be valid 
once the software is moved to another system&per.
.br
.br
When the Browser cannot locate the specified file using its explicit path, it will search the paths listed in the 
path option&per.

:euserdoc.
