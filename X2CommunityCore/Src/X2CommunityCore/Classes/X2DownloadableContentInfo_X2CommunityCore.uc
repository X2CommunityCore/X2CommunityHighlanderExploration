class X2DownloadableContentInfo_X2CommunityCore extends X2DownloadableContentInfo;

static event InstallNewCampaign(XComGameState StartState) {
	class'Grimy_Utility_TrainingRoulette'.static.PopulateModSkills();
}