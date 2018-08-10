// base grab code taken from http://forums.alliedmods.net/showthread.php?t=157075

#pragma semicolon 1
#include <morecolors>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define SOUND_THROW_TF "shout/fusrodah.wav" 
#define THROW_FORCE 10000.0
#define GRAB_DISTANCE 150.0

#define PLUGIN_NAME     "FusRoDah"
#define PLUGIN_AUTHOR   "Tonybear5 "
#define PLUGIN_VERSION  "1.0.5"
#define PLUGIN_DESCRIP  "Allows to force stuff"
#define PLUGIN_CONTACT  "http://steamcommunity.com/groups/veteran-giveaways"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIP,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
};
new bool:g_access[MAXPLAYERS+1];

//////////////////////////////////////////////////////////////////////
/////////////                    Setup                   /////////////
//////////////////////////////////////////////////////////////////////

public OnPluginStart()
{
	CreateConVar("admingrab_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	RegAdminCmd("sm_toss", Command_Toss, ADMFLAG_SLAY, "Throw Stuff");
}


public OnMapStart()
{
	PrecacheSound(SOUND_THROW_TF, true);
	AddFileToDownloadsTable("sound/shout/fusrodah.wav");
}

public OnClientPostAdminCheck(client)
{
	if(CheckCommandAccess(client, "admin_grab", ADMFLAG_SLAY))
	{
		g_access[client] = true;
	}
}

public OnClientPutInServer(client)
{
	g_access[client] = false;
}

//Function stuff

stock bool:IsTargetInSightRange(client, target, Float:angle=128.0, Float:distance=0.0, bool:heightcheck=false, bool:negativeangle=false)
{
	decl Float:clientpos[3], Float:targetpos[3], Float:anglevector[3], Float:targetvector[3], Float:resultangle, Float:resultdistance;
	
	GetClientEyeAngles(client, anglevector);
	anglevector[0] = anglevector[2] = 0.0;
	GetAngleVectors(anglevector, anglevector, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(anglevector, anglevector);
	if(negativeangle)
		NegateVector(anglevector);

	GetClientAbsOrigin(client, clientpos);
	GetClientAbsOrigin(target, targetpos);
	if(heightcheck && distance > 0)
		resultdistance = GetVectorDistance(clientpos, targetpos);
	clientpos[2] = targetpos[2] = 0.0;
	MakeVectorFromPoints(clientpos, targetpos, targetvector);
	NormalizeVector(targetvector, targetvector);
	
	resultangle = RadToDeg(ArcCosine(GetVectorDotProduct(targetvector, anglevector)));
	
	if(resultangle <= angle/2)	
	{
		if(distance > 0)
		{
			if(!heightcheck)
				resultdistance = GetVectorDistance(clientpos, targetpos);
			if(distance >= resultdistance)
				return true;
			else
				return false;
		}
		else
			return true;
	}
	else
		return false;
}

//////////////////////////////////////////////////////////////////////
/////////////                  Commands                  /////////////
//////////////////////////////////////////////////////////////////////
//New Code
public Action:Command_Toss(client, args)
{
	EmitSoundToAll(SOUND_THROW_TF);
	new entity = -1;
	while ((entity = FindEntityByClassname(entity, "player")) != INVALID_ENT_REFERENCE) 
	{
		if (IsTargetInSightRange(client, entity))
		{
			TossObject(client, entity, true);			
		}
	}
	while ((entity = FindEntityByClassname(entity, "prop_dynamic_override")) != INVALID_ENT_REFERENCE)
	{
		if (IsTargetInSightRange(client, entity))
		{
			TossObject(client, entity, true);			
		}
	}
	if ((entity = FindEntityByClassname(entity, "prop_dynamic")) != INVALID_ENT_REFERENCE)
	{
		if (IsTargetInSightRange(client, entity))
		{
			TossObject(client, entity, true);
		}
	}
	
	return Plugin_Handled;
}

TossObject(client, entity, bool:toss)
{
	if(toss)
	{
		new Float:vecView[3], Float:vecFwd[3], Float:vecPos[3], Float:vecVel[3];

		GetClientEyeAngles(client, vecView);
		GetAngleVectors(vecView, vecFwd, NULL_VECTOR, NULL_VECTOR);
		GetClientEyePosition(client, vecPos);

		vecPos[0]+=vecFwd[0]*THROW_FORCE;
		vecPos[1]+=vecFwd[2]*THROW_FORCE;
		vecPos[2]+=vecFwd[1]*THROW_FORCE;

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecFwd);

		SubtractVectors(vecPos, vecFwd, vecVel);
		ScaleVector(vecVel, 10.0);

		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vecVel);
	}

	if(entity > MaxClients)
	{
		decl String:classname[13];
		GetEntityClassname(entity, classname, 13);
		if(StrEqual(classname, "prop_physics"))
		{
			SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", 0);
		}
	}
}