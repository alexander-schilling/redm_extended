-- Credits: http://lua-users.org/wiki/StringRecipes

RDX.String = {}

RDX.String.StartsWith = function(str, start)
    return str:sub(1, #start) == start
end

RDX.String.EndsWith = function(str, ending)
    return ending == "" or str:sub(-#ending) == ending
end
