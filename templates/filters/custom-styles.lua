-- filters/custom-styles.lua
-- Filtre Pandoc pour les styles personnalisés du cours

-- Fonction pour échapper les caractères spéciaux LaTeX
local function escape_latex(text)
  -- Échapper les caractères spéciaux LaTeX
  text = text:gsub("\\", "\\textbackslash{}")
  text = text:gsub("([#$%%&_{}])", "\\%1")
  text = text:gsub("~", "\\textasciitilde{}")
  text = text:gsub("%^", "\\textasciicircum{}")
  return text
end

-- Fonction utilitaire pour convertir le contenu d'un span en texte
-- Compatible avec toutes les versions de Pandoc
local function inlines_to_text(inlines)
  local text = pandoc.utils.stringify(inlines)
  return escape_latex(text)
end

-- Traitement des spans personnalisés
function Span(el)
  -- Texte attendu (résultats en bleu italique)
  if el.classes:includes("expected") then
    local content = inlines_to_text(el.content)
    return pandoc.RawInline("latex",
      "\\expected{" .. content .. "}")
  end

  -- Clef primaire (souligné)
  if el.classes:includes("pk") then
    local content = inlines_to_text(el.content)
    return pandoc.RawInline("latex",
      "\\underline{" .. content .. "}")
  end

  -- Clef étrangère (italique)
  if el.classes:includes("fk") then
    local content = inlines_to_text(el.content)
    return pandoc.RawInline("latex",
      "\\textit{" .. content .. "}")
  end

  -- Clef primaire + étrangère (souligné + italique)
  if el.classes:includes("pkfk") then
    local content = inlines_to_text(el.content)
    return pandoc.RawInline("latex",
      "\\underline{\\textit{" .. content .. "}}")
  end

  return el
end

-- Traitement des divs personnalisés
function Div(el)
  -- Bloc remarques
  if el.classes:includes("remarques") then
    local result = {}
    table.insert(result, pandoc.RawBlock("latex", "\\begin{remarques}"))
    for _, block in ipairs(el.content) do
      table.insert(result, block)
    end
    table.insert(result, pandoc.RawBlock("latex", "\\end{remarques}"))
    return result
  end

  -- Bloc remarques enseignant
  if el.classes:includes("remarques-enseignant") then
    local result = {}
    table.insert(result, pandoc.RawBlock("latex", "\\begin{remarques-enseignant}"))
    for _, block in ipairs(el.content) do
      table.insert(result, block)
    end
    table.insert(result, pandoc.RawBlock("latex", "\\end{remarques-enseignant}"))
    return result
  end

  -- Bloc schéma relationnel
  if el.classes:includes("schema-relationnel") then
    local result = {}
    table.insert(result, pandoc.RawBlock("latex", "\\begin{schema-relationnel}"))
    for _, block in ipairs(el.content) do
      table.insert(result, block)
    end
    table.insert(result, pandoc.RawBlock("latex", "\\end{schema-relationnel}"))
    return result
  end

  return el
end
