return function(label : TextLabel)
	local new = label.FontFace
	new.Weight = Enum.FontWeight.Bold
	label.FontFace = new
end