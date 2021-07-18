#!/usr/local/bin/lua


package.path = package.path .. ';/home/gemini/finch/GeminiWebFinch/lib/?.lua'

local feedparser  = require "feedparser"
local rex         = require "rex_pcre"


local utils  = require "utils"
local page   = require "page"
local finch  = require "finch"


local url = "https://api.axios.com/feed/top"

local body, code, headers, status = utils.fetch_url(url)

if code >= 300 then
    print("Error: Could not fetch " .. url .. ". Status: " .. status)
else
    body = utils.trim_spaces(body)

    if body == nil or string.len(body) < 1 then
        print("Error: Nothing returned to parse for URL " .. url)
    else
        local parsed, errmsg = feedparser.parse(body, url)

    -- utils.table_print(parsed)

    if parsed == nil then
        print("Error: " .. errmsg .. " for URL " .. url)
    else
        local a_entries = parsed.entries -- rss/atom items

        page.set_template_name("axios")
        page.set_template_variable("feedurl", url)
        page.set_template_variable("feedtitle", parsed.feed.title)

        local feed_items_array = {}

        for i=1,#a_entries do
            local item_hash = {}

            local title   = a_entries[i].title

            local updated  = a_entries[i].updated
            local content  = a_entries[i].content
            local link     = a_entries[i].links[1].href

            item_hash.itemlink    = "/axios/" .. i .. ".txt"
            item_hash.itemtitle   = title

            feed_items_array[i] = item_hash

            if i == 1 then 
                page.set_template_variable("feeddate", updated)
            end

            finch.create_axios_article_file(i, title, utils.html_to_gmi(content), updated, link)
        end

        page.set_template_variable("itemsloop", feed_items_array)           

        local content = page.get_output(parsed.feed.title) 

        finch.create_axios_feed_file(content)
    end
    end
end


