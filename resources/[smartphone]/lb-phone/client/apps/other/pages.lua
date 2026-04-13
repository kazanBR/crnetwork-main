-- Track which post IDs belong to the current player (set when getPosts returns)
local ownedPostIds = {}

-- NUI callback handler: routes all Yellow Pages UI actions to the appropriate server callbacks
RegisterNUICallback("YellowPages", function(data, cb)
    local action = data.action
    debugprint("Pages:" .. (action or ""))

    if action == "getPosts" then
        TriggerCallback("yellowPages:getPosts", function(posts)
            -- Cache which posts belong to this player
            if posts then
                for i = 1, #posts do
                    if posts[i].isOwner then
                        ownedPostIds[posts[i].id] = true
                    end
                end
            end
            cb(posts)
        end, data.page, { search = data.query })

    elseif action == "sendPost" then
        TriggerCallback("yellowPages:createPost", cb, data.data)

    elseif action == "deletePost" then
        -- Block delete attempt if post is not owned by this player
        if not ownedPostIds[data.id] then
            debugprint("YellowPages: blocked delete attempt on non-owned post", data.id)
            return cb(false)
        end
        TriggerCallback("yellowPages:deletePost", function(result)
            if result then
                ownedPostIds[data.id] = nil
            end
            cb(result)
        end, data.id)
    end
end)


-- Net event: new post created — forward to local event bus and React UI
RegisterNetEvent("phone:yellowPages:newPost")
AddEventHandler("phone:yellowPages:newPost", function(postData)
    TriggerEvent("lb-phone:pages:newPost", postData)
    SendReactMessage("yellowPages:newPost", postData)
end)

-- ─── Browser URL Proxy ──────────────────────────────────────────────────────
-- When a website blocks iframes via X-Frame-Options or CSP, the browser app
-- detects a chrome-error:// URL and calls this proxy callback. We fetch the
-- page server-side (bypassing browser security headers) and return the HTML
-- so the browser can render it via srcdoc instead of src.
RegisterNUICallback("browser:proxy", function(data, cb)
    local url = data and data.url
    if not url or url == "" then
        return cb({ error = "No URL provided" })
    end

    debugprint("browser:proxy fetching:", url)

    PerformHttpRequest(url, function(statusCode, responseBody, headers)
        if statusCode == 200 and responseBody and responseBody ~= "" then
            -- Inject <base> tag so relative URLs resolve correctly
            local base = url:match("(https?://[^/]+)") or ""
            local html = responseBody

            -- Try to inject base tag into <head>
            if base ~= "" then
                local injected = html:gsub("(<head[^>]*>)", "%1<base href='" .. base .. "/' target='_blank'>", 1)
                if injected ~= html then
                    html = injected
                else
                    -- No <head> found, prepend base tag
                    html = "<base href='" .. base .. "/' target='_blank'>" .. html
                end
            end

            cb({ html = html, url = url })
        else
            cb({ error = "Failed to fetch: HTTP " .. tostring(statusCode) })
        end
    end, "GET", "", {
        ["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
        ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
        ["Accept-Language"] = "en-US,en;q=0.5",
    })
end)