{
	"Name": "Example json MTM test",
	"Type": "3/4in ball",
	"Steps": [
		{
			"stepType": "Mapper",					// Mapper step (should not come last)
			"stepName": "Example mapper step",
			"tempCtrlEn": true,
			"tempCtrlProbe": "pot",					// either "pot" or "lube"
			"tempCtrlTemp": 70.0,
			"waitForTempBeforeStep": true,
			"idleSpeed": 1000.0,
			"ECRoption": "none",					// "10", "100", "1k", "10k" or "none"
			"windowLoad": 23.0
		},
		{
			"stepType": "Traction",					// Traction step (Bidirectional Traction step follows same format)
			"stepName": "Example traction step",
			"tempCtrlEn": true,
			"tempCtrlProbe": "lube",				// either "pot" or "lube"
			"tempCtrlTemp": 50.0,
			"waitForTempBeforeStep": true,
			"idleSpeed": 1000.0,
			"idleLoad": 25.0,
			"idleSRR": 30.0,
			"unloadAtEnd": true,
			"ECRoption" : "none",					// "10", "100", "1k", "10k" or "none"
			"measDiscTrackRadBeforeStep": false,	// ignored by Bidirectional Traction step
			"stepLoad": 10.0,
			"stepSpeed": 200.0,
			"SRRsteps": [
				{
					"type": "linear increments",	// linearly between startSRR and endSRR in increments of incrementSRR
					"startSRR": 1.0,
					"endSRR": 5.0,
					"incrementSRR": 1.0
				},
				{
					"type": "linear # steps",		// linearly between startSRR and endSRR in numSteps steps
					"startSRR": 1.0,
					"endSRR": 5.0,
					"numSteps": 11
				},
				{
					"type": "logarithmic",			// logarithmically between startSRR and endSRR in numSteps steps
					"startSRR": 5.0,
					"endSRR": 100.0,
					"numSteps": 5
				}
			]
		},
		{
			"stepType": "Stribeck",					// Stribeck step (Bidirectional Stribeck step follows same format)
			"stepName": "Example stribeck step",
			"tempCtrlEn": true,
			"tempCtrlProbe": "lube",				// either "pot" or "lube"
			"tempCtrlTemp": 60.0,
			"waitForTempBeforeStep": true,
			"idleSpeed": 1000.0,
			"idleLoad": 0.0,
			"idleSRR": 0.0,
			"unloadAtEnd": false,
			"ECRoption" : "none",					// "10", "100", "1k", "10k" or "none"
			"measDiscTrackRadBeforeStep": false,	// suspiciously absent in PCS profile editor for Stribeck step (ignored by Bidirectional Stribeck step)
			"stepLoad": 10.0,
			"stepSRR": 200.0,
			"speedSteps": [
				{
					"type": "linear increments",	// linearly between startSpeed and endSpeed in increments of incrementSpeed
					"startSpeed": 1.0,
					"endSpeed": 5.0,
					"incrementSpeed": 1.0
				},
				{
					"type": "linear # steps",		// linearly between startSpeed and endSpeed in numSteps steps
					"startSpeed": 1.0,
					"endSpeed": 5.0,
					"numSteps": 11
				},
				{
					"type": "logarithmic",			// logarithmically between startSpeed and endSpeed in numSteps steps
					"startSpeed": 5.0,
					"endSpeed": 100.0,
					"numSteps": 5
				}
			]
		},
		{
			"stepType": "Timed",					// Timed step
			"stepName": "Example timed step",
			"tempCtrlEn": true,
			"tempCtrlProbe": "lube",				// either "pot" or "lube"
			"startTemp": 60.0,						// tempCtrlTemp is ignored if given, and startTemp used (both are present in the *.mtmp file)
			"endTemp": 60.0,
			"waitForTempBeforeStep": true,
			"idleSpeed": 1000.0,
			"idleLoad": 0.0,
			"idleSRR": 0.0,
			"unloadAtEnd": false,
			"ECRoption" : "none",					// "10", "100", "1k", "10k" or "none"
			"stepDurationSeconds": 5.2,				// stored to a resolution of 0.1 microseconds
			"logData": false,
			"logDataIntervalSeconds": 0.65,			// limited to >1 second in PCS Profile editor but stored to a resolution of 0.1 microseconds
			"startLoad": 4.0,
			"endLoad": 6.0,
			"startSpeed": 2000.0,
			"endSpeed": 3000.0,
			"startSRR": 5.0,
			"endSRR": 7.0
		},
		{
			"stepType": "Suspend",					// Suspend step
			"tempCtrlEn": true,						// temperature control options are unavailable in PCS profile editor - it is unknown whether they are ignored by the MTM
			"tempCtrlProbe": "lube",				
			"tempCtrlTemp": 60,
			"waitForTempBeforeStep": true,
			"idleSpeed": 1000,						// speed option is unavailable in PCS profile editor - it is unknown whether it is ignored by the MTM
			"idleLoad": 0,							// load option is unavailable in PCS profile editor - it is unknown whether it is ignored by the MTM
			"idleSRR": 0,							// SRR option is unavailable in PCS profile editor - it is unknown whether it is ignored by the MTM
			"unloadAtEnd": true,					// unload at end option is unavailable in PCS profile editor - it is unknown whether it is ignored by the MTM	
			"ECRoption": "none",					// ECR option is unavailable in PCS profile editor - it is unknown whether it is ignored by the MTM
			"stepText": "Example suspend step, this text will be displayed"
		}
	]
}
