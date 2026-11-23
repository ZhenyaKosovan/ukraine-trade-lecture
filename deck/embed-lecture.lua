-- Bundle the existing chart runtime and frozen data at render time.
-- No Python/R execution or HTTP server is required to view the resulting HTML.
local base = pandoc.path.directory(PANDOC_SCRIPT_FILE)
local function read(relative)
  local path = pandoc.path.join({base, relative})
  local handle, err = io.open(path, "rb")
  if not handle then error("Cannot bundle lecture asset: " .. tostring(err)) end
  local content = handle:read("*a")
  handle:close()
  return content
end
local function script(content)
  -- Prevent source content from terminating the HTML script element.
  return '<script>' .. content:gsub('</', '<\\/') .. '</script>'
end
function Pandoc(doc)
  if not FORMAT:match('revealjs') and not FORMAT:match('html') then return doc end
  local runtime = read('quarto-runtime.html')
  runtime = runtime:gsub('<script src="%.%./prototype/vendor/d3%.v7%.min%.js"></script>', function()
    return script(read('../prototype/vendor/d3.v7.min.js'))
  end)
  runtime = runtime:gsub('<script src="deck%.js"></script>', function()
    return script('window.LECTURE_BUNDLE = {data:' .. read('data.json') ..
      ',geography:' .. read('../raw/geography/CNTR_RG_20M_2024_4326.geojson') .. '};') ..
      script(read('deck.js'))
  end)
  doc.blocks:insert(pandoc.RawBlock('html', runtime))
  return doc
end
