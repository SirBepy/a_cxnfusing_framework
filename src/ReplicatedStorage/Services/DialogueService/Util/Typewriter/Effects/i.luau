-- Italic effect (<i>...</i>). Flips the FontFace style to Italic.
-- Purely cosmetic; doesn't adjust layout width (italic glyph widths are
-- close enough to regular that it usually looks fine).
return function(label : TextLabel)
	local new = label.FontFace
	new.Style = Enum.FontStyle.Italic
	label.FontFace = new
end