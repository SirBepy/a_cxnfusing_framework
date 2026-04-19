-- Bold effect (<b>...</b>). Flips the label's FontFace weight to Bold.
-- Layout.luau also swaps to a bold font variant when measuring width, so
-- word-wrap stays accurate.
-- Triggered by having "b" in a character's Effects set.
return function(label : TextLabel)
	local new = label.FontFace
	new.Weight = Enum.FontWeight.Bold
	label.FontFace = new
end