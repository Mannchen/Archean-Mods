; Functions for strings / text

; pad text to width
; $text: text
; $size: desired width
; $alignment: "L" for left, "C" for center, "R" for right
; $o_padding: padding character. must be one character default is space
function @text_pad($text :text, $size :number, $align :text, $o_padding :text) :text
	if $o_padding == ""
		$o_padding = " "
	var $text_size = size($text)
	var $return = ""
	if $text_size < $size
		var $diff = $size - $text_size
		var $s = ""
		if $align == "R"
			repeat $diff ($_)
				$s &= $o_padding
			$return = $s & $text
		elseif $align == "C"
			var $diffl = floor($diff/2)
			repeat $diffl ($_)
				$s &= $o_padding
			$s &= $text
			var $diffr = $size - $text_size - $diffl
			repeat $diffr ($_)
				$s &= $o_padding
			$return = $s
		else ;$align == "L"
			repeat $diff ($_)
				$text &= $o_padding
			$return = $text
	else
		$return = $text

	$o_padding = ""
	return $return


;
; Formatting
;

; get si prefix for base 10 exponent
function @get_si_prefix($e :number) :text
	array $units :text
	var $e3 = $e/3
	if $e >= 0
		$units.from(",k,M,G,T,P,E,Z,Y,R,Q", ",")
		if $e3 >= size($units) || $e % 3 != 0
			return text("e{}", $e)
		else
			return $units.$e3
	else 
		$e = abs($e)
		$e3 = abs($e3)
		$units.from(",m,u,n,p,f,a,z,y,r,q", ",")
		if $e == 1
			return "d"
		elseif $e == 2
			return "c"
		else
			if $e3 >= size($units) || $e % 3 != 0
				return text("e-{}", $e)
			else
				return $units.$e3


; format number with si prefix and optional unit
function @format_unit($number :number, $o_unit :text, $o_suffix_len :number) :text
	var $exp = if($number == 0, 0, log(abs($number), 10))
	if $o_unit == "g" and $exp >= 6
		$o_unit = "t"
		$number /= 1000000
		$exp -= 6
	var $exp3 = floor($exp / 3)
	var $expf = floor($exp)
	var $return = ""
	if $expf == 3
		var $n = $number - ($number % 1)
		var $padding = @text_pad("", max(0, $o_suffix_len - size($o_unit)), "R")
		$return = text("{0}{}{}", $n, $padding, $o_unit)
	else
		var $prefix = @get_si_prefix($exp3*3)
		var $n = ($number -  ($number - floor($number / pow(10, $expf-2))*pow(10, $expf-2)))  / pow(10, $exp3*3) ; ($number -  $number % pow(10, $expf-2))  / pow(10, $exp3*3) ; doing % ourselves because std::fmod is strange
		var $padding = @text_pad("", max(0, $o_suffix_len - size($o_unit) - size($prefix)), "R")
		$return = text("{}{}{}{}", $n, $padding, $prefix, $o_unit)

	$o_unit = ""
	$o_suffix_len = 0
	return $return

