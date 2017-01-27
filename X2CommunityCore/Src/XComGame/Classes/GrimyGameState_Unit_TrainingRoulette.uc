class GrimyGameState_Unit_TrainingRoulette extends XComGameState_BaseObject config(GrimyTrainingRoulette);

var config array<name> PrimaryWeaponNames, SecondaryWeaponNames;
var config array<int> HighOffense, MedOffense, LowOffense, HighHP, MedHP, HighHacking, MedHacking, HighPsiOffense;
var config int TreeHeight, TreeWidth;
var config bool RandomizeSquaddieClass;

var config array<GrimySkill> RouletteSkills, SquaddieRouletteSkills;

var array<SoldierClassRank>			SoldierRanks;
var array<SoldierClassWeaponType>	AllowedWeapons;
var name							SquaddieLoadout;
var string							IconImage;
var int                  KillAssistsPerKill;     //  Number of kill assists that count as a kill for ranking up

var config int					ClassPoints;    // Number of "points" associated with using this class type, i.e. Multiplayer or Daily Challenge
var config int                  PsiCreditsPerKill;      //  Number of psi credits that count as a kill for ranking up
var config protectedwrite bool  bMultiplayerOnly; 

var localized string			DisplayName;
var localized string			ClassSummary;
var localized string			LeftAbilityTreeTitle;
var localized string			RightAbilityTreeTitle;
var localized array<String>     RandomNickNames;        //  Selected randomly when the soldier hits a certain rank, if the player has not set one already.
var localized array<String>     RandomNickNames_Female; //  Female only nicknames.
var localized array<String>     RandomNickNames_Male;   //  Male only nicknames.

// This function generates a new set of SoldierRanks and AllowedWeapons
function RandomizeWeaponsAndPerks() {
	local X2SoldierClassTemplate			SquaddieTemplate;
	local SoldierClassWeaponType			ClassWeaponType;
	local SoldierClassRank					ClassRank;
	local array<SoldierClassAbilityType>	AbilityList, ForceSkills;
	local name								PrimaryWeapon, SecondaryWeapon;
	local int i, j, k;

	// clear previous list
	AllowedWeapons.length = 0;
	
	if ( default.RandomizeSquaddieClass ) {
		// Pick a random primary weapon
		ClassWeaponType.SlotType = eInvSlot_PrimaryWeapon;
		PrimaryWeapon = default.PrimaryWeaponNames[`SYNC_RAND(default.PrimaryWeaponNames.length)];
		ClassWeaponType.WeaponType = PrimaryWeapon;
		AllowedWeapons.additem(ClassWeaponType);

		// Pick a random secondary weapon
		ClassWeaponType.SlotType = eInvSlot_SecondaryWeapon;
		SecondaryWeapon = default.SecondaryWeaponNames[`SYNC_RAND(default.SecondaryWeaponNames.length)];
		ClassWeaponType.WeaponType = SecondaryWeapon;
		AllowedWeapons.additem(ClassWeaponType);

		// Select SquaddieLoadout
		SquaddieLoadout = GetSquaddieLoadoutName(PrimaryWeapon, SecondaryWeapon);
		ForceSkills = GetForceAbilities(PrimaryWeapon, SecondaryWeapon);
		IconImage = "img:///GrimyHighlanderPackage.class_roulette";
		KillAssistsPerKill=4;
	}
	else {
		SquaddieTemplate = GetSoldierTemplate(class'UIUtilities_Strategy'.static.GetXComHQ().SelectNextSoldierClass());
		AllowedWeapons = SquaddieTemplate.AllowedWeapons;
		
		SquaddieLoadout = SquaddieTemplate.SquaddieLoadout;
		ForceSkills = SquaddieTemplate.GetAbilityTree(0);
		IconImage = SquaddieTemplate.IconImage;
		KillAssistsPerKill= SquaddieTemplate.KillAssistsPerKill;
	}

	// Generate the list of abilities
	AbilityList = ShuffleList(GetNewAbilities(PrimaryWeapon, SecondaryWeapon));

	//clear previous entries before adding a new set of items
	ClassRank.aStatProgression.length = 0;
	ClassRank.aAbilityTree.length = 0;

	ClassRank.aStatProgression.addItem(GetCombatSimStat());
	ClassRank.aStatProgression.addItem(GetOffenseStat(PrimaryWeapon, SecondaryWeapon, 0));
	ClassRank.aStatProgression.addItem(GetHPStat(PrimaryWeapon, SecondaryWeapon, 0));
	ClassRank.aStatProgression.addItem(GetHackingStat(SecondaryWeapon, 0));
	ClassRank.aStatProgression.addItem(GetPsiStat(SecondaryWeapon, 0));
	for ( i = 0; i < ForceSkills.length; i++ ) {
		ClassRank.aAbilityTree.addItem(ForceSkills[i]);
	}
	// provide a free skill when appropriate
	if ( SecondaryWeapon == 'pistol' || ClassRank.aAbilityTree.length == 0 ) {
		ClassRank.aAbilityTree.addItem(AbilityList[0]);
	}
	SoldierRanks.additem(ClassRank);

	k = 1;
	for ( i = 1; i < default.TreeHeight; i++ ) {
		//clear previous entries before adding a new set of items
		ClassRank.aStatProgression.length = 0;
		ClassRank.aAbilityTree.length = 0;
		ClassRank.aStatProgression.addItem(GetOffenseStat(PrimaryWeapon, SecondaryWeapon, i));
		ClassRank.aStatProgression.addItem(GetHPStat(PrimaryWeapon, SecondaryWeapon, i));
		ClassRank.aStatProgression.addItem(GetHackingStat(SecondaryWeapon, i));
		ClassRank.aStatProgression.addItem(GetPsiStat(SecondaryWeapon, i));
		for ( j = 0; j < default.TreeWidth; j++ ) {
			ClassRank.aAbilityTree.addItem(AbilityList[k++]);
		}
		//ClassRank.aAbilityTree.addItem();
		SoldierRanks.additem(ClassRank);
		
	}
}

function X2SoldierClassTemplate GetSoldierTemplate(name ClassName) {
	local X2SoldierClassTemplateManager SoldierManager;

	SoldierManager = class'X2SoldierClassTemplateManager'.Static.GetSoldierClassTemplateManager();
	return SoldierManager.FindSoldierClassTemplate(ClassName);
}

// This function creates a new class template based on this component, then adds it to the manager
function name AddToManager() {
	local X2SoldierClassTemplateManager ClassManager;
	local X2SoldierClassTemplate ClassTemplate;

	ClassManager = class'X2SoldierClassTemplateManager'.static.GetSoldierClassTemplateManager();

	`CREATE_X2TEMPLATE(class'X2SoldierClassTemplate', ClassTemplate, GenerateTemplateName());
	ClassTemplate.SoldierRanks = SoldierRanks;
	ClassTemplate.AllowedWeapons = AllowedWeapons;
	ClassTemplate.AllowedArmors.AddItem('soldier');
	//ClassTemplate.ExcludedAbilities;
	ClassTemplate.SquaddieLoadout = SquaddieLoadout;
	ClassTemplate.IconImage = IconImage;
	ClassTemplate.NumInForcedDeck = 0;
	ClassTemplate.NumInDeck = 0;
	ClassTemplate.ClassPoints = ClassPoints;    // Number of "points" associated with using this class type, i.e. Multiplayer or Daily Challenge
	ClassTemplate.KillAssistsPerKill = KillAssistsPerKill;     //  Number of kill assists that count as a kill for ranking up
	ClassTemplate.PsiCreditsPerKill = PsiCreditsPerKill;      //  Number of psi credits that count as a kill for ranking up
	ClassTemplate.bAllowAWCAbilities = true;
//	ClassTemplate.bMultiplayerOnly = bMultiplayerOnly; don't edit this, it's write only

	ClassTemplate.DisplayName = DisplayName;
	ClassTemplate.ClassSummary = ClassSummary;
	ClassTemplate.LeftAbilityTreeTitle = LeftAbilityTreeTitle;
	ClassTemplate.RightAbilityTreeTitle = RightAbilityTreeTitle;
	ClassTemplate.RandomNickNames = RandomNickNames;        //  Selected randomly when the soldier hits a certain rank, if the player has not set one already.
	ClassTemplate.RandomNickNames_Female = RandomNickNames_Female; //  Female only nicknames.
	ClassTemplate.RandomNickNames_Male = RandomNickNames_Male;   //  Male only nicknames.

	ClassManager.AddSoldierCLassTemplate(ClassTemplate,true);
	return ClassTemplate.DataName;
}

// UTILITY FUNCTIONS

function array<SoldierClassAbilityType> ShuffleList(array<SoldierClassAbilityType> InputList) {
	local array<SoldierClassAbilityType>	OutputList;
	local int randIndex;

	OutputList.length = 0;
	while ( InputList.length > 0 ) {
		randIndex = `SYNC_RAND(InputList.length);
		OutputList.AddItem(InputList[randIndex]);
		InputList.Remove(randIndex,1);
	}

	//`REDSCREEN("SHUFFLE LIST STARTS HERE");
	for ( randIndex=0; randIndex<OutputList.length; randIndex++ ) {
		//`REDSCREEN("SHUFFLE LIST OUTPUT - " $ OutputList[randIndex].AbilityName);
	}

	return OutputList;
}

function name GetSquaddieLoadoutName(name WeaponType, name SecondaryType) {
	return name("Roulette_" $ WeaponType $ "_" $ SecondaryType);
}

function name GenerateTemplateName() {
	return name("GrimyRoulette" $ ObjectID);
}

function array<SoldierClassAbilityType> GetNewAbilities(name WeaponType, name SecondaryType) {
	local array<SoldierClassAbilityType>	AbilityList;
	local SoldierClassAbilityType			AbilityType;
	local GrimySkill						GrimySkillStruct;

	AbilityList.length = 0;

	//`REDSCREEN("Grimy Log - Start of Abilities");
	foreach default.RouletteSkills(GrimySkillStruct) {
		//`REDSCREEN("Grimy Basic Skill Log - " $ string(GrimySkillStruct.AbilityName));
		if ( GrimySkillStruct.WeaponCat == WeaponType || GrimySkillStruct.WeaponCat == SecondaryType || GrimySkillStruct.WeaponCat == '' ) {
			AbilityType.AbilityName = GrimySkillStruct.AbilityName;
			AbilityType.ApplyToWeaponSlot = GrimySkillStruct.ApplyToWeaponSlot;
			AbilityType.UtilityCat = GrimySkillStruct.UtilityCat;
			AbilityList.additem(AbilityType);
		}
	}

	foreach class'Grimy_Utility_TrainingRoulette'.default.ModRouletteSkills(GrimySkillStruct) {
		//`REDSCREEN("Grimy ModRoulette Skill Log - " $ string(GrimySkillStruct.AbilityName));
		if ( GrimySkillStruct.WeaponCat == WeaponType || GrimySkillStruct.WeaponCat == SecondaryType || GrimySkillStruct.WeaponCat == '' ) {
			AbilityType.AbilityName = GrimySkillStruct.AbilityName;
			AbilityType.ApplyToWeaponSlot = GrimySkillStruct.ApplyToWeaponSlot;
			AbilityType.UtilityCat = GrimySkillStruct.UtilityCat;
			AbilityList.additem(AbilityType);
		}
	}

	return AbilityList;
}

function array<SoldierClassAbilityType> GetForceAbilities(name WeaponType, name SecondaryType) {
	local array<SoldierClassAbilityType>	ForceSkills;
	local SoldierClassAbilityType			AbilityType;
	local GrimySkill						GrimySkillStruct;

	ForceSkills.length = 0;

	foreach default.SquaddieRouletteSkills(GrimySkillStruct) {
		if ( GrimySkillStruct.WeaponCat == WeaponType || GrimySkillStruct.WeaponCat == SecondaryType || GrimySkillStruct.WeaponCat == '' ) {
			AbilityType.AbilityName = GrimySkillStruct.AbilityName;
			AbilityType.ApplyToWeaponSlot = GrimySkillStruct.ApplyToWeaponSlot;
			AbilityType.UtilityCat = GrimySkillStruct.UtilityCat;
			ForceSkills.additem(AbilityType);
		}
	}

	return ForceSkills;
}

function SoldierClassStatType GetCombatSimStat() {
	local SoldierClassStatType		ClassStatType;

	classStatType.StatType = eStat_CombatSims;
	classStatType.StatAmount = 1;

	return ClassStatType;
}

function SoldierClassStatType GetOffenseStat(name WeaponName, name SecondaryName, int rank) {
	local SoldierClassStatType		ClassStatType;
	classStatType.StatType = eStat_Offense;

	if ( WeaponName == 'sniper_rifle' ) { classStatType.StatAmount = HighOffense[rank]; }
	else if ( WeaponName == 'cannon' || SecondaryName == 'psiamp' ) { classStatType.StatAmount = LowOffense[rank]; }
	else { classStatType.StatAmount = MedOffense[rank]; } 

	return classStatType;
}

function SoldierClassStatType GetHPStat(name WeaponName, name SecondaryName, int rank) {
	local SoldierClassStatType		ClassStatType;
	classStatType.StatType = eStat_HP;

	if ( WeaponName == 'sniper_rifle' || SecondaryName == 'psiamp' ) { classStatType.StatAmount = MedHP[rank]; }
	else { classStatType.StatAmount = HighHP[rank]; } 

	return classStatType;
}

function SoldierClassStatType GetHackingStat(name SecondaryName, int rank) {
	local SoldierClassStatType		ClassStatType;
	classStatType.StatType = eStat_Hacking;

	if ( SecondaryName == 'gremlin' ) { classStatType.StatAmount = HighHacking[rank]; }
	else { classStatType.StatAmount = MedHacking[rank]; } 

	return classStatType;
}

function SoldierClassStatType GetPsiStat(name SecondaryName, int rank) {
	local SoldierClassStatType		ClassStatType;
	classStatType.StatType = eStat_PsiOffense;

	if ( SecondaryName == 'psiamp' ) { classStatType.StatAmount = HighPsiOffense[rank]; }
	else { classStatType.StatAmount = 0; } 

	return classStatType;
}