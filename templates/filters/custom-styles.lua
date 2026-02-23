-- filters/custom-styles.lua
-- Filtre Pandoc pour les styles personnalisés du cours

-- Fonction utilitaire pour convertir le contenu d'un span en LaTeX
local function inlines_to_latex(inlines)
  return pandoc.write(pandoc.Pandoc({pandoc.Plain(inlines)}), "latex")
end

-- Traitement des spans personnalisés
function Span(el)
  -- Texte attendu (résultats en bleu italique)
  if el.classes:includes("expected") then
    local content = inlines_to_latex(el.content)
    return pandoc.RawInline("latex",
      "\\expected{" .. content .. "}")
  end

  -- Clef primaire (souligné)
  if el.classes:includes("pk") then
    local content = inlines_to_latex(el.content)
    return pandoc.RawInline("latex",
      "\\underline{" .. content .. "}")
  end

  -- Clef étrangère (italique)
  if el.classes:includes("fk") then
    local content = inlines_to_latex(el.content)
    return pandoc.RawInline("latex",
      "\\textit{" .. content .. "}")
  end

  -- Clef primaire + étrangère (souligné + italique)
  if el.classes:includes("pkfk") then
    local content = inlines_to_latex(el.content)
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
