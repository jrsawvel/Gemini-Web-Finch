
local M = {}

local rex   = require "rex_pcre"

local config = require "config"
local utils  = require "utils"



function M.create_homepage_html_file(html)

    local doc_root = config.get_value_for("default_doc_root")

    local html_filename = doc_root .. "/index.gmi"

    local f = io.open(html_filename, "w")
    if f == nil then
        error("Could create output file for write for " .. html_filename .. ".")
    else
        f:write(html)
        f:close()
    end
end


function M.create_feed_html_file(feedurl, html, homepageurl)

    homepageurl = feedurl -- jrs 08Mar2019 addition

    if homepageurl ~= nil then
        homepageurl =  rex.gsub(homepageurl, "[^a-zA-Z0-9]","")
    end

    local protocol, domain = rex.match(feedurl, "(\\w+://)([.A-Za-z0-9\\-]+)/", 1)

    local d = rex.gsub(domain, "\\.", "", nil, "is")

    local doc_root = config.get_value_for("default_doc_root")

    local html_filename

    local html_page

    if homepageurl ~= nil then
        html_page = homepageurl .. "feed.gmi"
        html_filename = doc_root .. "/" .. html_page
    else
        html_page = d .. "feed.gmi"
        html_filename = doc_root .. "/" .. html_page
    end

    local f = io.open(html_filename, "w")
    if f == nil then
        error("Could create output file for write for " .. html_filename .. ".")
    else
        f:write(html)
        f:close()
    end

    return domain, html_page
end


function M.create_axios_article_file(file_ctr, title, content, date, link)
    local doc_root = config.get_value_for("axios_default_doc_root")

    local axios_page     = file_ctr .. ".txt"
    local axios_filename = doc_root .. "/" .. axios_page

    local f = io.open(axios_filename, "w")
    if f == nil then
        error("Could create output file for write for " .. axios_filename .. ".")
    else
        local page_content = "# " .. title .. "\n\n"
        local page_content = page_content .. date .. "\n\n"
        local page_content = page_content .. content .. "\n"
        local page_content = page_content .. "=> " .. link .. "\n"
        f:write(page_content)
        f:close()
    end
end


function M.create_axios_feed_file(content)
    local doc_root = config.get_value_for("axios_default_doc_root")

    local axios_page     = "index.gmi"
    local axios_filename = doc_root .. "/" .. axios_page

    local f = io.open(axios_filename, "w")
    if f == nil then
        error("Could create output file for write for " .. axios_filename .. ".")
    else
        f:write(content)
        f:close()
    end
end


function M.create_npr_article_file(file_ctr, title, content, date, article_id)
    local link = "https://text.npr.org/" .. article_id

    local doc_root = config.get_value_for("npr_default_doc_root")

    local npr_page     = file_ctr .. ".txt"
    local npr_filename = doc_root .. "/" .. npr_page

    local f = io.open(npr_filename, "w")
    if f == nil then
        error("Could create output file for write for " .. npr_filename .. ".")
    else
        local page_content = "# " .. title .. "\n\n"
        local page_content = page_content .. date .. "\n\n"
        local page_content = page_content .. content .. "\n"
        local page_content = page_content .. "\n\n=> " .. link .. "\n"
        f:write(page_content)
        f:close()
    end
end


function M.create_npr_feed_file(content)
    local doc_root = config.get_value_for("npr_default_doc_root")

    local npr_page     = "index.gmi"
    local npr_filename = doc_root .. "/" .. npr_page

    local f = io.open(npr_filename, "w")
    if f == nil then
        error("Could create output file for write for " .. npr_filename .. ".")
    else
        f:write(content)
        f:close()
    end
end


function M.read_file(filename)
    local f = io.open(filename, "r")
    if f == nil then
        error("Could not open " .. filename .. " for reading.")
    end

    local urls = {}

    local i = 1
 
    for line in f:lines() do
        if string.len(line) > 12 then
            urls[i] = line
            i = i + 1
        end
    end

    f:close()

    return urls
end


return M

