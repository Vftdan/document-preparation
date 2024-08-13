local function proof(el)
	if not (el.t == 'Div' or el.t == 'Span') or el.classes[1] ~= 'proof' then
		return
	end
	return {pandoc.RawInline('latex', '\\begin{proof}'), el, pandoc.RawInline('latex', '\\end{proof}')}
end

return {
	{Div = proof, Span = proof}
}
