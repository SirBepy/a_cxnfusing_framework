return function(label : TextLabel)
	local new = label.FontFace
	new.Style = Enum.FontStyle.Italic
	label.FontFace = new
end