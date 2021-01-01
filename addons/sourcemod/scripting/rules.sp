#include <sourcemod>

ArrayList g_Rules = null;
ArrayList g_Desc = null;

int g_iChosen[MAXPLAYERS+1];

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Daves rule menu",
	author = "Dave",
	description = "Simple rule plugin that desplays the server rules in a menu",
	version = "1.0.0",
	url = "https://daveskz.com/"
};

public void OnPluginStart()
{
	g_Rules = new ArrayList(ByteCountToCells(256));
	g_Desc = new ArrayList(ByteCountToCells(256));
	
	RegConsoleCmd("sm_rules", RuleMenu);
}

//Reads config file and gets correct values
void ParseRules() {
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/rules.cfg");

	g_Desc.Clear();
	g_Rules.Clear();

	char SectionName[100];
	char Rules[64];
	char Desc[512];
	
	if(!FileExists(path)) {
		SetFailState("CFG file %s is not found", path);
		return;
	}
	
	KeyValues kv = new KeyValues("Rules");
	if(!kv.ImportFromFile(path)) {
		SetFailState("CFG file %s not found", path);

		delete kv;
		return;
	}
	
	if(!kv.GotoFirstSubKey()) {
		SetFailState("CFG file %s not found", path);
		delete kv;
		return;
	}
	
	do {
		
		kv.GetSectionName(SectionName, sizeof(SectionName));
		kv.GetString("name", Rules, sizeof(Rules));
		kv.GetString("def", Desc, sizeof(Desc));

		g_Rules.PushString(Rules);
		g_Desc.PushString(Desc);
		
	} while (kv.GotoNextKey());
	
	delete kv;
	return;
}

//main command
public Action Command_Rules(int client, int args) {
	if(args < 1) {
		return Plugin_Handled;
	} else {
		RuleMenu(client, 0);
		return Plugin_Handled;
	}
}

//main menu
public Action RuleMenu(int client, int args) {
	Menu menu = new Menu(RuleHandler);
	ParseRules();
	
	menu.SetTitle("Rules: ");

	char Option[256],Rule[32], Desc[128], Index[16];
	for(int i = 0; i < g_Rules.Length; i++) {
		g_Rules.GetString(i, Rule, sizeof(Rule));
		g_Desc.GetString(i, Desc, sizeof(Desc));
		
		FormatEx(Option, sizeof(Option), "%s\n", Rule);
		IntToString(i, Index, sizeof(Index));
		menu.AddItem(Index, Option);
		
	}
	
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

//main menu handler
public int RuleHandler(Menu menu, MenuAction action, int client, int option) {
	if( action == MenuAction_Select) {
		char Desc[128];
		g_Desc.GetString(option, Desc, sizeof(Desc));

		g_iChosen[client] = option;
		DescMenu(client, 0);
	} else if(action == MenuAction_End) {
		delete menu;
	}
}

//description menu
public Action DescMenu(int client, int args) {
	Menu menu = new Menu(DescHandler);

	char Option[256], Rule[32], Desc[128];

	ParseRules();

	g_Rules.GetString(g_iChosen[client], Rule, sizeof(Rule));
	g_Desc.GetString(g_iChosen[client], Desc, sizeof(Desc));

	FormatEx(Option, sizeof(Option), "Rule:               %s\n \nDescription:    %s\n", Rule, Desc);
	menu.SetTitle(Option);

	menu.AddItem("#0", "Back");

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

//description menu
public int DescHandler(Menu menu, MenuAction action, int client, int option) {
	if(action == MenuAction_Select) {
		RuleMenu(client, 0);
	} else if(action == MenuAction_End) {
		delete menu;
	}
}