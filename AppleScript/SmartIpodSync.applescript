-- This script turns off the "Live updating" property of each smart playlist
-- that is sync'ed to a currently connected iPod and that currently has "Live
-- updating" enabled.  Then it sync's all iPods and ejects them.  Finally, it 
-- turns "Live updating" back on for each playlist for which it turned it off.
-- A property (Access for assistive devices) in Universal Access must be enabled 
-- for the script to set the "Live updating" property of smart playlists.  The 
-- script walks the user through enabling this property if it is 
-- not set.

property livePlaylists : {}
property editable : true

-- Get list of connected iPods
set ipodList to {}
tell application "iTunes"
	-- Get list of connected iPods
	try -- Avoid error if there are no iPods connected
		set ipodList to (name of every source whose kind is iPod)
	end try
end tell
if (count of ipodList) is 0 then
	return 0 -- No iPods connected
end if

-- Check if UI scripting is enabled
-- If not, then show a dialog explaining that it must be enabled
-- and open the window in which it can be enabled.
tell application "System Events" to set isUIScriptingEnabled to UI elements enabled
if isUIScriptingEnabled = false then
	tell application "System Preferences"
		activate
		set current pane to pane "com.apple.preference.universalaccess"
		display dialog "Your system is not properly configured to run this script. 

Please select the \"Enable access for assistive devices\" checkbox and trigger the script again to proceed."
		return 0
	end tell
end if

tell application "iTunes"
	--First delete played podcasts so they are not sync'ed below
	set podcastList to file tracks of user playlist "Podcasts"
	repeat with tempPodcast in podcastList
		if played count of tempPodcast > 0 then
			set fileLocation to location of tempPodcast
			tell application "Finder"
				delete file fileLocation
			end tell
			delete tempPodcast
		end if
	end repeat
	
	-- Loop through
	repeat with ipodName in ipodList
		set smartPlaylists to (name of user playlists in source ipodName whose smart is true and special kind is none)
		repeat with smartName in smartPlaylists
			reveal user playlist smartName
			activate
			tell application "System Events" to tell process "iTunes"
				tell menu item "Edit Smart Playlist" of menu 1 of menu bar item 3 of menu bar 1
					try
						if not enabled then
							set editable to false
							error 0
						end if
						click
					end try
				end tell
				tell window smartName
					if value of checkbox "Live updating" is 1 then
						click checkbox "Live updating"
					end if
					if smartName is not in livePlaylists then
						set end of livePlaylists to smartName
					end if
					click button "OK"
				end tell
			end tell
		end repeat
	end repeat
	
	repeat with ipodName in ipodList
		update ipodName
		tell me to waitForSync()
	end repeat
	
	repeat with ipodName in ipodList
		eject ipodName
	end repeat
	
	(* Reverse order because the last playlist dealt with will be left selected and usually the top playlist is the most prominent one *)
	set livePlaylists to reverse of livePlaylists
	set counter to 0
	repeat with smartName in livePlaylists
		--counter shouldn't be necessary but stops script from doing extra loops over list contents....
		set counter to (counter + 1)
		reveal user playlist smartName
		activate
		tell application "System Events" to tell process "iTunes"
			tell menu item "Edit Smart Playlist" of menu 1 of menu bar item 3 of menu bar 1
				try
					if not enabled then
						set editable to false
						error 0
					end if
					click
				end try
			end tell
			tell window smartName
				if value of checkbox "Live updating" is 0 then
					click checkbox "Live updating"
				end if
				click button "OK"
			end tell
		end tell
	end repeat
end tell

tell application "Finder"
	set visible of process "iTunes" to false
end tell

return counter


on waitForSync()
	tell application "System Events" to tell application process "iTunes"
		set theStatusText to ""
		repeat until theStatusText is "iPod sync is complete."
			--With iTunes 11, the sync is complete message is hidden in the status window
			--and has to be scrolled to.  Just loop through status window views here so that the script 
			--isn't dependent on the window's status.
			click ((buttons of scroll area 1 of window "iTunes") whose description is "show next view")
			set theStatusText to value of static text 1 of scroll area 1 of window "iTunes"
			delay 1
		end repeat
	end tell
end waitForSync
(*
on waitForEject(ipodName)
	tell application "iTunes"
		set ejected to false
		set ipodList to {}
		repeat until ejected is true
			try -- Avoid error if there are no iPods connected
				set ipodList to (name of every source whose kind is iPod)
			end try
			if ipodName is not in ipodList then
				set ejected to true
			end if
			delay 1
		end repeat
	end tell
end waitForEject

-- This function did help....
on remountIpods()
	set ipodList to {}
	
	tell application "Finder"
		set currentDisks to the name of every disk
	end tell
	
	set mediaTypes to {}
	repeat with tempDisk in currentDisks
		set mediaType to do shell script "diskutil info '" & tempDisk & "' | grep \"Media Type:\" | awk '{print $3}'"
		set mediaTypes to mediaTypes & mediaType
	end repeat
	
	tell application "iTunes"
		-- Get list of connected iPods
		try -- Avoid error if there are no iPods connected
			set ipodList to (name of every source whose kind is iPod)
		end try
	end tell
	
	repeat with i from 1 to count of currentDisks
		if (item i of mediaTypes is "iPod") then
			set tempDisk to item i of currentDisks
			if (tempDisk is not in ipodList) then
				do shell script "diskutil unmountDisk \"" & tempDisk & "\""
				do shell script "diskutil mountDisk \"" & tempDisk & "\""
			end if
		end if
	end repeat
	
	tell application "iTunes"
		-- Get list of connected iPods
		try -- Avoid error if there are no iPods connected
			set ipodList to (name of every source whose kind is iPod)
		end try
	end tell
	
	return ipodList
end remountIpods
*)