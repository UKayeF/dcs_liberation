-------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Mission configuration file for the Skynet-IADS framework
-- see https://github.com/walder/Skynet-IADS
--
-- This configuration is tailored for a mission generated by DCS Liberation
-- see https://github.com/Khopa/dcs_liberation
-------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Skynet-IADS plugin - configuration
env.info("DCSLiberation|Skynet-IADS plugin - configuration")

if dcsLiberation and SkynetIADS then

    -- specific options
	local createRedIADS = false
	local createBlueIADS = false
	local actAsEwrRED = false
	local actAsEwrBLUE = false
	local includeRedInRadio = false
	local includeBlueInRadio = false
	local debugRED = false
	local debugBLUE = false
	
    -- retrieve specific options values
    if dcsLiberation.plugins then
        if dcsLiberation.plugins.skynetiads then
			createRedIADS = dcsLiberation.plugins.skynetiads.createRedIADS
			createBlueIADS = dcsLiberation.plugins.skynetiads.createBlueIADS
			actAsEwrRED = dcsLiberation.plugins.skynetiads.actAsEwrRED
			actAsEwrBLUE = dcsLiberation.plugins.skynetiads.actAsEwrBLUE
			includeRedInRadio = dcsLiberation.plugins.skynetiads.includeRedInRadio
			includeBlueInRadio = dcsLiberation.plugins.skynetiads.includeBlueInRadio
			debugRED = dcsLiberation.plugins.skynetiads.debugRED
			debugBLUE = dcsLiberation.plugins.skynetiads.debugBLUE
		end
    end
	
	env.info(string.format("DCSLiberation|Skynet-IADS plugin - createRedIADS=%s",tostring(createRedIADS)))
	env.info(string.format("DCSLiberation|Skynet-IADS plugin - createBlueIADS=%s",tostring(createBlueIADS)))
	env.info(string.format("DCSLiberation|Skynet-IADS plugin - actAsEwrRED=%s",tostring(actAsEwrRED)))
	env.info(string.format("DCSLiberation|Skynet-IADS plugin - actAsEwrBLUE=%s",tostring(actAsEwrBLUE)))
	env.info(string.format("DCSLiberation|Skynet-IADS plugin - includeRedInRadio=%s",tostring(includeRedInRadio)))
	env.info(string.format("DCSLiberation|Skynet-IADS plugin - includeBlueInRadio=%s",tostring(includeBlueInRadio)))
	env.info(string.format("DCSLiberation|Skynet-IADS plugin - debugRED=%s",tostring(debugRED)))
	env.info(string.format("DCSLiberation|Skynet-IADS plugin - debugBLUE=%s",tostring(debugBLUE)))

    -- actual configuration code    

	local function initializeIADS(iads, coalition, actAsEwr, inRadio, debug)

		local coalitionPrefix = "BLUE"
		if coalition == 1 then 
			coalitionPrefix = "RED"
		end

		if debug then
			env.info("adding debug information")
			local iadsDebug = iads:getDebugSettings()
			iadsDebug.IADSStatus = true
			iadsDebug.samWentDark = true
			iadsDebug.contacts = true
			iadsDebug.radarWentLive = true
			iadsDebug.noWorkingCommmandCenter = false
			iadsDebug.ewRadarNoConnection = false
			iadsDebug.samNoConnection = false
			iadsDebug.jammerProbability = true
			iadsDebug.addedEWRadar = false
			iadsDebug.hasNoPower = false
			iadsDebug.harmDefence = true
			iadsDebug.samSiteStatusEnvOutput = true
			iadsDebug.earlyWarningRadarStatusEnvOutput = true
		end

		--add EW units to the IADS:
		iads:addEarlyWarningRadarsByPrefix(coalitionPrefix .. " EW")

		--add SAM groups to the IADS:
		iads:addSAMSitesByPrefix(coalitionPrefix .. " SAM")

		-- specific configurations, for each SAM type
		if actAsEwr then
			iads:getSAMSitesByNatoName('SA-10'):setActAsEW(true)
			iads:getSAMSitesByNatoName('SA-6'):setActAsEW(true)
			iads:getSAMSitesByNatoName('Patriot'):setActAsEW(true)
		end

		-- add the AWACS
		if dcsLiberation.AWACs then
			for _, data in pairs(dcsLiberation.AWACs) do
				env.info(string.format("DCSLiberation|Skynet-IADS plugin - processing AWACS %s", data.dcsGroupName))
				local group = Group.getByName(data.dcsGroupName)
				if group then
					if group:getCoalition() == coalition then
						local unit = group:getUnit(1)
						if unit then 
							local unitName = unit:getName()
							env.info(string.format("DCSLiberation|Skynet-IADS plugin - adding AWACS %s", unitName))
							iads:addEarlyWarningRadar(unitName)
						end
					end
				end
			end
		end

		if inRadio then
			--activate the radio menu to toggle IADS Status output
			env.info("DCSLiberation|Skynet-IADS plugin - adding in radio menu")
			iads:addRadioMenu()
		end

		--activate the IADS
		iads:activate()
	end

	------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- create the IADS networks
	-------------------------------------------------------------------------------------------------------------------------------------------------------------
	if createRedIADS then
		env.info("DCSLiberation|Skynet-IADS plugin - creating red IADS")
		redIADS = SkynetIADS:create("IADS")
		initializeIADS(redIADS, 1, actAsEwrRED, includeRedInRadio, debugRED) -- RED
	end

	if createBlueIADS then
		env.info("DCSLiberation|Skynet-IADS plugin - creating blue IADS")
		blueIADS = SkynetIADS:create("IADS")
		initializeIADS(blueIADS, 2, actAsEwrBLUE, includeBlueInRadio, debugBLUE) -- BLUE
	end
	
end