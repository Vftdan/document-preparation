--[[
dot2tex — convert "dot2tex" code blocks to "tikz" code blocks

Should be followed by diagram-generator.lua or diagram.lua in the filter chain.
"dot2tex" must be installed into $PATH or it's executable filename should be
provided in $DOT2TEX or dot2tex_path option.

Copyright: (c) 2024 vftdan (https://github.com/Vftdan)
License: MIT
]]
local pandoc = require 'pandoc'

local dot2tex_path = os.getenv('DOT2TEX') or 'dot2tex'

local tex_fixes = [[
\renewcommand\enlargethispage[1]{}
]]

local function dot2tex(code, args)
	return pandoc.pipe(dot2tex_path, {'--tikzedgelabels', table.unpack(args)}, code)
end

function Meta(meta)
	dot2tex_path = pandoc.utils.stringify(
		meta.dot2tex_path or meta.dot2texPath or dot2tex_path
	)
end

function CodeBlock(block)
	if block.classes[1] ~= 'dot2tex' then
		return nil
	end

	local args = {
		'-t', block.attributes.texmode or 'raw',
		'-f', block.attributes.d2tformat or 'tikz',
		'--valignmode', block.attributes.d2tvalignmode or 'dot',
	}
	if block.attributes.d2tprog then
		table.insert(args, '--prog')
		table.insert(args, block.attributes.d2tprog)
	end
	if block.attributes.d2talignstr then
		table.insert(args, '--alignstr')
		table.insert(args, block.attributes.d2talignstr)
	end
	if block.attributes.d2tnodeoptions then
		table.insert(args, '--nodeoptions')
		table.insert(args, block.attributes.d2tnodeoptions)
	end
	if block.attributes.d2tedgeoptions then
		table.insert(args, '--edgeoptions')
		table.insert(args, block.attributes.d2tedgeoptions)
	end

	local success, tikzcode = pcall(dot2tex, block.text, args)
	if not success then
		error 'Failed to convert dot to tikztex'
		return nil
	end
	local additionalPackages = block.attributes.additionalPackages or block.attributes['opt-additional-packages']  or ''
	local packagesEnd, documentStart = tikzcode:find('\n\\begin{document}\n')
	local documentEnd, _ = tikzcode:find('\n\\end{document}\n')
	local dot2tex_packages = pandoc.text.sub(tikzcode, 1, packagesEnd)
	dot2tex_packages = dot2tex_packages:gsub("\\documentclass{%w*}", "")
	dot2tex_packages = dot2tex_packages:gsub("\\usepackage%[[^%]]+%]{xcolor}", "")
	dot2tex_packages = tex_fixes .. dot2tex_packages
	additionalPackages = dot2tex_packages .. additionalPackages
	local tikzbody = pandoc.text.sub(tikzcode, documentStart, documentEnd)

	block.classes[1] = 'tikz'
	block.attributes.additionalPackages = additionalPackages
	block.attributes['opt-additional-packages'] = additionalPackages
	block.text = tikzbody
	return block
end

return {
	{Meta = Meta},
	{CodeBlock = CodeBlock},
}
