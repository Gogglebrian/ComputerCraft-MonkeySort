local utils = require("utils")

--settings--
useDedicatedOverflowChest = true --if false, overflow (failed deposit attempts) will be dumped to the default chest
waitAfterTick = 1
waitAfterInput = 3
waitAfterInputEmpty = 3
tagRulesFile = "tag-rules.txt"
itemRulesFile = "item-rules.txt"
limitRulesFile = "limit-rules.txt"
observationFilePrefix = "observed-contents/observation-"
lapsedObservationsFile = "lapsed-observations.txt"

sortedChests = {}
function wrapSortedChest(number, remoteName)
	chest = peripheral.wrap(remoteName)
	if (chest ~= nil) then
		sortedChests[number] = chest
	else
		print("Error: " .. peripheralRemoteName .. " could not be wrapped as sortedChest "..number)
		return false
	end
end

--Storage chests config -- 
--  Can't find a better way than to manually wrap/name them,
--  because the peripheral id names of chests/peripherals attached to wired modems
--  cannot be manually changed in a reliable way, and even breaking and replacing modem
--  irreversibly changes that id.
--  Nor is there any way to get any other data about the chest, ie block/modem coords or nametag.
--  So the best option is just to manually wrap each chest individually I guess, at least to begin with.
--  Later we could use the chests' current contents, and comparing them agaisnt previous observations, as a method for reliably guessing and re-wrapping on the fly
inChest = peripheral.wrap("minecraft:chest_90")
defaultChest = peripheral.wrap("minecraft:chest_52")
overflowChest = peripheral.wrap("minecraft:chest_79")
wrapSortedChest(1, "minecraft:chest_0")
wrapSortedChest(2, "minecraft:chest_1")
wrapSortedChest(3, "minecraft:chest_2")
wrapSortedChest(4, "minecraft:chest_3")
wrapSortedChest(5, "minecraft:chest_4")
wrapSortedChest(6, "minecraft:chest_5")
wrapSortedChest(7, "minecraft:chest_6")
wrapSortedChest(8, "minecraft:chest_7")
wrapSortedChest(9, "minecraft:chest_8")
wrapSortedChest(10,"minecraft:chest_9")
wrapSortedChest(11,"minecraft:chest_10")
wrapSortedChest(12,"minecraft:chest_11")
wrapSortedChest(13,"minecraft:chest_12")
wrapSortedChest(14,"minecraft:chest_13")
wrapSortedChest(15,"minecraft:chest_14")
wrapSortedChest(16,"minecraft:chest_15")
wrapSortedChest(17,"minecraft:chest_16")
wrapSortedChest(18,"minecraft:chest_17")
wrapSortedChest(19,"minecraft:chest_18")
wrapSortedChest(20,"minecraft:chest_19")
wrapSortedChest(21,"minecraft:chest_20")
wrapSortedChest(22,"minecraft:chest_21")
wrapSortedChest(23,"minecraft:chest_22")
wrapSortedChest(24,"minecraft:chest_23")
wrapSortedChest(25,"minecraft:chest_24")
wrapSortedChest(26,"minecraft:chest_25")
wrapSortedChest(27,"minecraft:chest_26")
wrapSortedChest(28,"minecraft:chest_27")
wrapSortedChest(29,"minecraft:chest_28")
wrapSortedChest(30,"minecraft:chest_29")
wrapSortedChest(31,"minecraft:chest_30")
wrapSortedChest(32,"minecraft:chest_31")
wrapSortedChest(33,"minecraft:chest_32")
wrapSortedChest(34,"minecraft:chest_33")
wrapSortedChest(35,"minecraft:chest_34")
wrapSortedChest(36,"minecraft:chest_35")
wrapSortedChest(37,"minecraft:chest_36")
wrapSortedChest(38,"minecraft:chest_37")
wrapSortedChest(39,"minecraft:chest_38")
wrapSortedChest(40,"minecraft:chest_39")
wrapSortedChest(41,"minecraft:chest_40")
wrapSortedChest(42,"minecraft:chest_41")
wrapSortedChest(43,"minecraft:chest_42")
wrapSortedChest(44,"minecraft:chest_43")
wrapSortedChest(45,"minecraft:chest_44")
wrapSortedChest(46,"minecraft:chest_45")
wrapSortedChest(47,"minecraft:chest_46")
wrapSortedChest(48,"minecraft:chest_47")
wrapSortedChest(49,"minecraft:chest_48")
wrapSortedChest(50,"minecraft:chest_49")
wrapSortedChest(51,"minecraft:chest_88")

--runtime vars
--current contents of the in chest, and copy of previous check
inContents = {}
prevInContents = {}
--time that in chest contents were last observed to have changed
timeOfLastInput = 0
--flagged if in chest was empty on previous check
inputWasEmpty = true

--sorting rules tables
tagRules = {}
itemRules = {}
limitRules = {}
observedRules = {}
lapsedObservedRules = {}
--for each sortedChest, contains a list of itemNames it contains upon last observation
observedContentsLists = {}
--table tracking chest peripheral remote names and what sortedChest number they're wrapped to
sortedChestPeripheralNames = {}

-- checks if two chest contents list() tables are different
function haveContentsChanged(contents, previousContents)
	if (utils.tableLength(contents) ~= utils.tableLength(previousContents)) then
		print("Contents changed by number of stacks")
		return true
	end
	
	for i, itemSlot in pairs(contents) do
		oldItemSlot = previousContents[i]
		if (itemSlot["name"] ~= oldItemSlot["name"]) then
			print("Item in slot " .. tostring(i) .. " changed")
		elseif (itemSlot["count"] ~= oldItemSlot["count"]) then
			print("Count in slot " .. tostring(i) .. " changed")
			return true
		end
	end
	
	return false
end

function loadRules()
	tagRules = {}
	for line in io.lines(tagRulesFile) do
		lineValues = utils.splitString(line, ",")
		tag = lineValues[1]
		chest = lineValues[2]
		tagRules[tag] = chest
	end
	
	itemRules = {}
	for line in io.lines(itemRulesFile) do
		lineValues = utils.splitString(line, ",")
		item = lineValues[1]
		chest = lineValues[2]
		itemRules[item] = chest
	end
end

function debugPrintRules()
	print("Item Rules:")
	for k, v in pairs(itemRules) do
		print(k .. ", "..v)
	end
	print("Tag Rules:")
	for k, v in pairs(tagRules) do
		print(k .. ", "..v)
	end
end

function debugPrintObservations()
	print("Observation Rules:")
	for k, v in pairs(observedRules) do
		print(k .. ", "..v)
	end
end

function loadObservationFiles()
	lapsedObservedRules = {}
	for line in io.lines(lapsedObservationsFile) do
		lineValues = utils.splitString(line, ",")
		item = lineValues[1]
		chest = lineValues[2]
		lapsedObservedRules[item] = chest
	end
	
	observedRules = {}
	--for each sortedChest, attempt to load the associated observation file
	for i, _ in pairs(sortedChests) do
		loadObservationFile(i)
	end
end

function loadObservationFile(number)
	--iterate through lines in the file, creating new observations goodList
	goodList = {}
	local success, err = pcall(function() 
		for line in io.lines(observationFilePrefix .. number ..".txt") do
			cleanedUp = utils.trim(line)
			if not utils.isEmptyLine(cleanedUp) then
				goodList[cleanedUp] = true
			end
		end
	end)
	if (success) then
		--keep list
		observedContentsLists[number] = goodList
		--add rules for observed items to observedRules table
		for item, _ in pairs(goodList) do
			observedRules[item] = tonumber(number)
		end
	else
		print("Could not load observation file " ..number.. "at " .. observationFilePrefix ..number .. ".txt")
	end
end

function getChestByItemRule(itemName)
	if itemRules[itemName] ~= nil then
		return tonumber(itemRules[itemName])
	else
		return nil
	end
end

--returns chest number matched to items' tags in the tag rules file, nil if n/a
function getChestByTagRule(itemDetails)
	--for each of our item's tags, check for a match in our tag rules
	if itemDetails.tags == nil then
		return nil
	end
	for tag, _ in pairs(itemDetails.tags) do
		if tagRules[tag] ~= nil then
			print("Tag "..tag.." matched to chest "..tagRules[tag])
			return tonumber(tagRules[tag])
		end
	end
	return nil
end

--Observes the current contents of all sorted chests, updating records
function doObservations()
	observedRules = {}
	
	--loop through all sorted chests
	for k, chest in pairs(sortedChests) do
		observeSortedChest(k,chest)
	end
	
	--write lapsed observations to file
	io.output(lapsedObservationsFile)
	for k, v  in pairs(lapsedObservedRules) do
		io.write(k..","..v.."\n")
	end	
	io.close()
end

--Observes the chest in front of the turtle and remembers a list of contained item names
function observeSortedChest(number, chest)
	--get raw chest contents list
	contents = chest.list()
	
	--create simpler list of contents with no redundancies
	goodList = {}
	for _, item in pairs(contents) do
		if (goodList[item.name] == nil) then
			goodList[item.name] = true
		end
	end

	--if this particular chest has been previously observed, then we need to record any 
	--   previously-observed items that are no longer in the chest
	if (observedContentsLists[number] ~= nil) then
		recordLapsedObservations(number, goodList)
	end
	observedContentsLists[number] = goodList

	--add rules for observed items to observedRules table
	for item, _ in pairs(goodList) do
		observedRules[item] = tonumber(number)
	end
	
	--write to file
	io.output(observationFilePrefix..number..".txt")
	for itemName, _ in pairs(goodList) do
		io.write(itemName.."\n")
	end	
	io.close()
end

function recordLapsedObservations(chestNumber, newObservationsList)
	--for each item in the older observed list
	for item, _ in pairs(observedContentsLists[chestNumber]) do
		--If it's missing from the newly observed list, then
		if newObservationsList[item] == nil then
			lapsedObservedRules[item] = chestNumber
		end
	end
end

function doSort()
	for k, item in pairs(inChest.list()) do
		print("Sorting "..item.name)
		
		--first method: item rules
		chestByItemRule = getChestByItemRule(item.name)
		if chestByItemRule ~= nil and sortedChests[chestByItemRule] ~= nil then
			print("Item rule match for "..item.name.." at chest "..chestByItemRule)
			if depositItemIntoChest(k, sortedChests[chestByItemRule], item) then
				goto continueSorting
			else
				print("Deposit failed")
				goto failure
			end
		else
			print("No item rule for "..item.name)
		end
		
		--second method: tag rules
		chestByTagRule = getChestByTagRule(inChest.getItemDetail(k))
		if chestByTagRule ~= nil and sortedChests[chestByTagRule] ~= nil then
			print("Tag rule match for "..item.name.." at chest "..chestByTagRule)
			if depositItemIntoChest(k, sortedChests[chestByTagRule], item) then
				goto continueSorting
			else
				print("Deposit failed")
				goto failure
			end
		else
			print("No tag rule match for "..item.name)
		end
		
		--third method: match item to observed chest contents!
		chestByObservation = getChestByObservation(item.name)
		if chestByObservation ~= nil and sortedChests[chestByObservation] ~= nil then
			print("Match for "..item.name.." observed at chest "..chestByObservation)
			if depositItemIntoChest(k, sortedChests[chestByObservation], item) then
				goto continueSorting
			else
				print("Deposit failed")
				goto failure
			end
		else
			print("No match observed for "..item.name)
		end
		
		--fourff method: match item to previously observed chest contents!
		chestByLapsedObservation = getChestByLapsedObservation(item.name)
		if chestByLapsedObservation ~= nil and sortedChests[chestByLapsedObservation] ~= nil then
			print("Match for "..item.name.." has previously been observed at chest "..chestByLapsedObservation)
			if depositItemIntoChest(k, sortedChests[chestByLapsedObservation], item) then
				goto continueSorting
			else
				print("Deposit failed")
				goto failure
			end
		else
			print("No match observed for "..item.name)
		end
		
		--final option: dump in the default chest
		print("Depositing "..item.name.." in default chest")
		depositItemAtDefault(k, item)
		goto continueSorting
		
		::failure::
		if (useDedicatedOverflowChest) then
			print("Depositing "..item.name.." in overflow storage")
		else
			print("Depositing "..item.name.." in default chest")
		end
		depositItemAtOverflow(k, item)
	
		::continueSorting::
	-- end sort loop
	end
--end doSort()
end

--searches our sortedChests observations to find an item match
function getChestByObservation(item_name)
	if observedRules[item_name] ~= nil then
		return tonumber(observedRules[item_name])
	else
		return nil
	end
end
--searches our lapsed sortedChests observations to find an item match
function getChestByLapsedObservation(item_name)
	if lapsedObservedRules[item_name] ~= nil then
		return tonumber(lapsedObservedRules[item_name])
	else
		return nil
	end
end

--returns the first slot of matching item, nil if none
function getFirstSlotMatchingItem(targetChest, item)
	contents = targetChest.list()
	foundPos = nil
	-- loop through contents of target chest
	for i, itemSlot in pairs(contents) do
		if itemSlot.name == item.name then
			foundPos = i
			break
		end
	end
	if foundPos == nil then
		return nil
	end
	
	return foundPos
end

function depositItemIntoChest(inSlot, targetChest, item)
	targetSlot = getFirstSlotMatchingItem(targetChest, item)
	
	--if no target slot is found, then just dump
	if (targetSlot == nil) then
		print("target slot not found, dumpin")
		return dumpItemIntoChest(inSlot, targetChest, item)
	end
	
	--otherwise, pullitems from the turtle to the target slot
	print("target slot found at ".. targetSlot ..", depositing cleverly")
	return depositItemAtOrAfterSlot(targetChest,targetSlot,inSlot,item)
end

--Deposits item from turtleSlot into current chest at or after the target position if possible
function depositItemAtOrAfterSlot(targetChest, targetSlot, inSlot, item)
	itemRemaining = item.count
	i = targetSlot
	
	--Loop through remaining slots to find a good place
	while i <= 54 and itemRemaining > 0 do
		--if slot is empty
		slot = targetChest.getItemDetail(i)
		if (slot == nil) then
			inChest.pushItems(peripheral.getName(targetChest),inSlot,64,i)
			return true
		--if slot is a match
		elseif (slot.name == item.name) then
			slotSpace = targetChest.getItemLimit(i) - slot.count
			--and if slot has room for more drops then
			if (slotSpace > 0) then
				itemsDropped = inChest.pushItems(peripheral.getName(targetChest),inSlot,64,i)
				itemRemaining = itemRemaining - itemsDropped
			end
		end
		i = i + 1
	end
	
	--if any items remaining by the end of the chest, then just dump
	if (itemRemaining > 0) then
		print("Items leftover, dumping haphazardly")
		return dumpItemIntoChest(inSlot, targetChest, item)
	else
		return true
	end
end

--Dumps item into the first empty slot in the chest
function dumpItemIntoChest(inSlot, targetChest, item)
	--Loop through all slots to find an empty one
	i = 1
	while i <= 54 do
		--if slot is empty
		slot = targetChest.getItemDetail(i)
		if (slot == nil) then
			inChest.pushItems(peripheral.getName(targetChest),inSlot,64,i)
			return true
		end
		i = i + 1
	end
	
	-- if no empty slot...
	print("Chest is full")
	return false
end

function depositItemAtDefault(inSlot, item)
	depositItemIntoChest(inSlot, defaultChest, item)
end

function depositItemAtOverflow(inSlot, item)
	if (useDedicatedOverflowChest) then
		depositItemIntoChest(inSlot, overflowChest, item)
	else
		depositItemIntoChest(inSlot, defaultChest, item)
	end
end

--Main program starts here
if (inChest == nil) then
	print("Input chest not connected")
	return
end

loadObservationFiles()
print("Ready")

--Start sorter loop
while true do
	--Get the input chest contents and save the prior state
	prevInContents = inContents
	inContents = inChest.list()
	
	--skip to the end of the loop if chest is empty
	if (inContents == nil or utils.tableLength(inContents) == 0) then
		inputWasEmpty = true
		--print("Input chest is empty")
		os.sleep(waitAfterInputEmpty)
		goto continue
	end
	
	--now we can assume we got a chest with something in it
	--if the chest was previously empty or contents have changed since last check, then record the time and don't do anything right now
	if (inputWasEmpty or haveContentsChanged(inContents, prevInContents)) then
		inputWasEmpty = false
		timeOfLastInput = os.clock()
		print("Input has changed, waiting for waitAfterInput duration to pass...")
		goto continue
	--If it's been less than the waitAfterInput duration since the last input change, don't do anything right now
	elseif ((os.clock() - timeOfLastInput) < waitAfterInput) then
		print("Waiting for waitAfterInput duration to pass...")
		goto continue
	end
	
	print("Reloading sorting rules")
	loadRules()
	--debugPrintRules()
	
	print("Scanning current sortedChests contents")
	doObservations()
	--debugPrintObservations()
	
	print("Running sort")
	doSort()
	--os.sleep(15)
	
	::continue::
	os.sleep(waitAfterTick)
end
