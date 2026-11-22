-- Closeread renders to HTML, not Reveal. Inline the finished page in a
-- srcdoc frame so the lecture still works offline and avoids data URL limits.
function Div(div)
  if not div.classes:includes('history-embed') then return nil end

  local directory = pandoc.path.directory(quarto.doc.input_file)
  local path = pandoc.path.join({directory, 'history.html'})
  local file = assert(io.open(path, 'r'), 'Build the timeline first: quarto render deck/history.qmd')
  local story = file:read('*a')
  file:close()

  story = story:gsub('&', '&amp;'):gsub('"', '&quot;'):gsub('<', '&lt;'):gsub('>', '&gt;')
  return pandoc.RawBlock('html', '<iframe class="history-frame" '
    .. 'title="Interactive history of Ukraine, 1991 to 2022" '
    .. 'srcdoc="' .. story .. '"></iframe>')
end
