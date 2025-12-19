#DATAPORT input "data" 0 "Enable"
#DATAPORT input "data" 1 "Push Items (.itemName{}.properties{}.count{})"
#DATAPORT input "data" 2 "Pull Items (.itemName{}[.maxCount{}|.maxMass{}])"

#DATAPORT output "data" 0 "Items sent"
#DATAPORT output "data" 1 "Items received"

#INFO checkbox "enable" 1 "Enable"
#INFO checkbox "enable_data" 0 "Allow dataport configuration"
#INFO checkbox "pull" 0 "Pull items"
#INFO text "itemname" "" "Item name / filter"
#INFO text "count" "0" "Item count"
#INFO text_info "stats" "---"
#INFO button "reset_stats" "Reset statistics"


var $g_enable :number
var $info_enable :number
var $g_pull :number
var $info_pull :number
var $g_item_name :text
var $info_item_name :text
var $g_item_count :number
var $info_item_count :text
var $input_item_acc :number
var $output_item_acc :number

var $g_send_items :text
var $g_pull_items :text
var $g_data_mode :number


function @valid_itemname($name :text) :number
	return 1

input.0 ($enable :text, $send_items :text, $pull_items :text)
	if get_info("enable_data") == 0
		return

	if $enable != ""
		$g_enable = !(!$enable)
	if $send_items != ""
		$g_send_items = $send_items
		$g_data_mode = 1
	if $pull_items != ""
		$g_pull_items = $pull_items
		$g_data_mode = 1

	$enable = ""
	$send_items = ""
	$pull_items = ""


tick
	; update info when changed
	var $new_info_enable = get_info("enable")
	if $new_info_enable != $info_enable
		$g_enable = $new_info_enable
	$info_enable = $new_info_enable

	var $new_info_pull = get_info("pull")
	if $new_info_pull != $info_pull
		$g_pull = $new_info_pull
		$g_data_mode = 0
	$info_pull = $new_info_pull

	var $new_info_item_name = get_info_text("itemname")
	if $new_info_item_name != $info_item_name
		if @valid_itemname($new_info_item_name)
			$g_item_name = $new_info_item_name
			$g_data_mode = 0
		else
			set_info("itemname", $info_item_name)
			$new_info_item_name = $info_item_name
	$info_item_name = $new_info_item_name

	var $new_info_item_count = get_info_text("count")
	if $new_info_item_count != $info_item_count
		if isnumeric($new_info_item_count)
			$g_item_count = $new_info_item_count
			$g_data_mode = 0
		else
			set_info("count", $info_item_count)
			$new_info_item_count = $info_item_count
	$info_item_count = $new_info_item_count

	var $pushed = 0
	var $pulled = ""

	if $g_enable
		; push and pull items
		if $g_data_mode
			$pushed = push_item("item", $g_send_items.itemName, $g_send_items.properties, $g_send_items.count:number)
			var $has_pull_count = 0
			foreach $g_pull_items ($k, $v)
				if $k == "maxCount"
					$has_pull_count = 1
					break
			if $has_pull_count
				$pulled = pull_item("item", $g_pull_items.itemName, $g_pull_items.maxCount:number, $g_pull_items.maxMass:number)

		else
			if $g_pull
				$pulled = pull_item("item", $g_item_name, $g_item_count, 0)
			else
				if $g_item_name != ""
					$pushed = push_item("item", $g_item_name, "", $g_item_count)

	output.0($pushed, $pulled)

	; V menu stats
	if get_info("reset_stats")
		$output_item_acc = 0
		$input_item_acc = 0
	$output_item_acc += $pushed
	$input_item_acc += $pulled.count:number
	set_info("stats", text("Items output: {} Items input: {}", $output_item_acc, $input_item_acc))

