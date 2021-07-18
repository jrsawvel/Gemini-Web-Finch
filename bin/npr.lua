#!/usr/local/bin/lua


package.path = package.path .. ';/home/gemini/finch/GeminiWebFinch/lib/?.lua'

local feedparser  = require "feedparser"
local rex         = require "rex_pcre"


local utils  = require "utils"
local page   = require "page"
local finch  = require "finch"


function _fetch_text_npr_article(link)

    local text_npr_content = "" -- won't use only the summary that exists in the npr feed. 
                 -- need to fetch the html page from text.npr.org and parse
                 -- out the article body text.
    -- sample link from the main npr news feed:
    --   https://www.npr.org/2021/07/14/1016136203/the-best-meteor-shower-of-the-year-is-happening-heres-how-you-can-see-it
    -- the text.npr.org equivelant would be:
    --   https://text.npr.org/1016136203

--    local protocol, domain, yr, mo, da, article_id = rex.match(link, "(\\w+://)([.A-Za-z0-9\\-]+)/([0-9]+)/([0-9]+)/([0-9]+)/([0-9]+)/", 1)
    local crap, mo, da, article_id = rex.match(link, "(.*)/2021/([0-9]+)/([0-9]+)/([0-9]+)/", 1)

    local text_url = "https://text.npr.org/" .. article_id

    local body, code, headers, status = utils.fetch_url(text_url)

    if code >= 300 then
        print("Error: Could not fetch " .. text_url .. ". Status: " .. status)
    else
        body = utils.trim_spaces(body)

        if body == nil or string.len(body) < 1 then
            print("Error: Nothing returned to parse for URL " .. text_url)
        else
            -- text_npr_content = rex.match(body, "<main>(.*)</main>", 1, "si")
            -- text_npr_content = rex.match(body, "<h1 class=\"story-title\">(.*)</main>", 1, "si")
            text_npr_content = rex.match(body, "<div class=\"paragraphs-container\">(.*)</main>", 1, "si")
        end
    end

    return article_id, utils.trim_spaces(text_npr_content)
end



local url = "https://feeds.npr.org/1001/rss.xml"

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

        page.set_template_name("npr")
        page.set_template_variable("feedurl", url)
        page.set_template_variable("feedtitle", parsed.feed.title)

        local feed_items_array = {}

        for i=1,#a_entries do
            local item_hash = {}

            local title   = a_entries[i].title

            local updated  = a_entries[i].updated
            local content  = a_entries[i].content
            local link     = a_entries[i].links[1].href

            item_hash.itemlink    = "/npr/" .. i .. ".txt"
            item_hash.itemtitle   = title

            feed_items_array[i] = item_hash

            if i == 1 then 
                page.set_template_variable("feeddate", updated)
            end

            local article_id, content = _fetch_text_npr_article(link)

            content = string.gsub(content, '<h3>', "\n# ")
            content = string.gsub(content, '<hr><p><h3>', "\n# ")
            content = string.gsub(content, '<hr><p>', "\n\n")
            content = string.gsub(content, '</h3>', "\n\n")

            content = utils.html_to_gmi(content)
            content = utils.trim_spaces(content)
            finch.create_npr_article_file(i, title, content, updated, article_id)
        end

        page.set_template_variable("itemsloop", feed_items_array)           

        local content = page.get_output(parsed.feed.title) 

        finch.create_npr_feed_file(content)
    end
    end
end


