
accept_push_fluid($port :text, $molecule :text, $mass :number, $temperature :number)
	if $port == "fluidin"
		var $accepted = push_fluid("fluidout", $molecule, $mass, $temperature)
		$mass -= $accepted

accept_pull_fluid($port :text, $maxMass :number, $compositionOut :text, $temperatureOut :number)
	if $port == "fluidout"
		var $received = pull_fluid("fluidin", $maxMass)
		$compositionOut = $received.composition
		$temperatureOut = $received.temperature


accept_pull_fluid_potential($port :text, $potentialOut :number)
	if $port == "fluidin"
		$potentialOut = 0
	else
		$potentialOut = pull_fluid_potential("fluidin")

accept_push_fluid_potential($port :text, $potentialOut :number)
	if $port == "fluidout"
		$potentialOut = 0
	else
		$potentialOut = push_fluid_potential("fluidout")
