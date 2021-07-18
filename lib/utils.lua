
local M = {}


local rex   = require "rex_pcre"
local https = require "ssl.https"
local http  = require "socket.http"



function M.remove_newline (str)
    str = string.gsub(str, "[\n]", "")
    return str
end



function M.remove_consecutive_newlines (str)
    str = string.gsub(str, "[\n][\n][\n][\n]", "\n\n")
    str = string.gsub(str, "[\n][\n][\n]", "\n\n")
    return str
end



function _html_links_to_gmi_links(str)

    str = string.gsub(str, "%%", "STUPIDPERCENTSIGN")

    for w, p, d, t, tw in rex.gmatch(str, "<a([\\s]+)href=\"(\\w+://)([.A-Za-z0-9?=:|;,_#^\\-/%+&~\\(\\)@!]+)\" target=\"_blank\">(.+?)</a>([\\s]*)", "is", nil) do

        local gmi_link = '\n\n=> ' .. p .. d .. '    ' .. t .. '\n\n'

        str = rex.gsub(str , '<a' .. w .. 'href="' .. p .. d .. '" target="_blank">' .. t .. '</a>' .. tw, gmi_link , nil, "is")
    end

    str = string.gsub(str, "STUPIDPERCENTSIGN", "%%")

    return str
end



function M.split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t
end


function M.trim_spaces (str)
    if (str == nil) then
        return nil
    end
   
    -- remove leading spaces 
    str = string.gsub(str, "^%s+", "")

    -- remove trailing spaces.
    str = string.gsub(str, "%s+$", "")

    return str
end


-- https://stackoverflow.com/questions/19664666/check-if-a-string-isnt-nil-or-empty-in-lua
function M.is_empty(s)
  return s == nil or s == ''

--[[
    if s==nil or s=='' then
        return true
    else
        return false
    end
]]
end


function M.remove_html (str)
    local tmp_str = rex.gsub(str, "<([^>])+>|&([^;])+;", "", nil, "sx")
    if M.is_empty(tmp_str) then
        return str
    else
        return tmp_str
    end
end


function M.table_print (tt, indent, done)
  done = done or {}
  indent = indent or 0
  if type(tt) == "table" then
    for key, value in pairs (tt) do
      io.write(string.rep (" ", indent)) -- indent it
      if type (value) == "table" and not done [value] then
        done [value] = true
        io.write(string.format("[%s] => table\n", tostring (key)));
        io.write(string.rep (" ", indent+4)) -- indent it
        io.write("(\n");
        M.table_print (value, indent + 7, done)
        io.write(string.rep (" ", indent+4)) -- indent it
        io.write(")\n");
      else
        io.write(string.format("[%s] => %s\n",
            tostring (key), tostring(value)))
      end
    end
  else
    io.write(tt .. "\n")
  end
end


function M.fetch_url(url)
    local body,code,headers,status

    body,code,headers,status = http.request(url)

    if code < 200 or code >= 300 then
        body,code,headers,status = https.request(url)
    end

    if type(code) ~= "number" then
        code = 500
        status = "url fetch failed"
    end

    return body,code,headers,status
end


-- UTC and GMT use the same time.
-- UTC is a time standard.
-- GMT is a time zone
-- Z or zulu time is a military time zone.
-- Zulu time uses the same time as UTC and GMT
function M.get_date_time()
-- time displayed for Toledo, Ohio (eastern time zone)
-- Thu, Jan 25, 2018 - 6:50 p.m.

    local time_type = "EDT"
    local epochsecs = os.time()
    local localsecs 
    local dt = os.date("*t", epochsecs)

    if ( dt.isdst ) then
        localsecs = epochsecs - (4 * 3600)
    else 
        localsecs = epochsecs - (5 * 3600)
        time_type = "EST"
    end

    -- damn hack - mar 11, 2018 - frigging isdst does not work as expected. it's always false.
    -- time_type = "EDT"
    -- localsecs = epochsecs - (4 * 3600)
    
    time_type = "GMT"

    -- local dt_str = os.date("%a, %b %d, %Y - %I:%M %p", localsecs)
    local dt_str = os.date("%a, %b %d, %Y - %I:%M %p", os.time())

    return(dt_str .. " " .. time_type)
end



function M.html_to_gmi(str)
--    str = _html_links_to_gmi_links(str)

    str = string.gsub(str, "<ul>", "")
    str = string.gsub(str, "</ul>", "\n")

    str = string.gsub(str, "<ol>", "")
    str = string.gsub(str, "</ol>", "\n")

    str = string.gsub(str, "<li>", "* ")
    str = string.gsub(str, "</li>", "\n")


    str = string.gsub(str, "<p><p>", "</p>\n<p>")

    str = string.gsub(str, "</p>\n", "\n\n")

    str = string.gsub(str, "</p>", "\n\n")
--    str = string.gsub(str, "<p>", "\n")
    str = string.gsub(str, "<p>", "")

--    str = string.gsub(str, "<hr>",   "--------------------\n")
--    str = string.gsub(str, "<hr/>",  "--------------------\n")
--    str = string.gsub(str, "<hr />", "--------------------\n")
    str = string.gsub(str, "<hr>",   "")
    str = string.gsub(str, "<hr/>",  "")
    str = string.gsub(str, "<hr />", "")

    str = string.gsub(str, "<div>", "\n")
    str = string.gsub(str, "</div>", "\n")

    local str_len = string.len(str)

    if str_len > 19000 then
        local str1 = string.sub(str, 1, 19000)
        local str2 = string.sub(str, 19001, str_len)
        str1 = M.remove_html(str1)
        str1 = M.remove_consecutive_newlines(str1)
        str2 = M.remove_html(str2)
        str2 = M.remove_consecutive_newlines(str2)
        str = str1 .. str2
    else
        str = M.remove_html(str)
        str = M.remove_consecutive_newlines(str)
    end

    return str
end




return M
