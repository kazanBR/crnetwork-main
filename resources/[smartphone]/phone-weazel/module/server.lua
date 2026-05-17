local cache = {}
local function sendDiscordWebhook(url, payload)
    if (not url) or (url == '') then return end
    PerformHttpRequest(url, function() end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end
local function vRPWebhook(url, data)
    local lines = {}
    if data and data.descriptions then
        for _, v in ipairs(data.descriptions) do
            local k, val = v[1], v[2]
            lines[#lines+1] = ('**%s:** %s'):format(tostring(k), tostring(val))
        end
    end
    sendDiscordWebhook(url, {
        username = data and data.title or 'Weazel',
        embeds = {
            {
                title = data and data.title or 'Weazel',
                description = table.concat(lines, '\n'),
            }
        }
    })
end

Citizen.CreateThread(function()
    oxmysql:execute([[
        create table if not exists weazel (
            id int not null auto_increment,
            title longtext not null,
            description longtext not null,
            author varchar(255) not null,
            category varchar(60) not null default 'Notícia',
            featured tinyint(1) not null default 0,
            video longtext not null,
            img longtext not null,
            visualizations int not null default 0,
            created_at int not null,
            primary key (id)
        );
    ]]);
    oxmysql:execute('ALTER TABLE weazel ADD COLUMN IF NOT EXISTS category varchar(60) not null default \'Notícia\'')
    oxmysql:execute('ALTER TABLE weazel ADD COLUMN IF NOT EXISTS featured tinyint(1) not null default 0')
    Citizen.Wait(1000)
    local result = oxmysql:query_async('select * from weazel')
    for _, v in pairs(result) do
        cache[#cache+1] = { id = v.id, title = v.title, description = v.description, author = v.author, category = v.category or 'Notícia', featured = tonumber(v.featured) == 1, img = v.img, video = v.video, day = os.date('%d/%m/%Y', v.created_at), visualizations = v.visualizations, created_at = v.created_at }
    end
end)

srv.createPost = function(_data)
    local Passport = vRP.Passport(source)
    local data = RemoveHTMLtags(_data)
    local ostime = os.time()
    local category = (data.category and tostring(data.category) ~= '' and tostring(data.category)) or 'Notícia'
    local featured = data.featured and 1 or 0
    local id = oxmysql:insert_async('insert ignore into weazel (title, description, author, category, featured, video, img, created_at) values (?, ?, ?, ?, ?, ?, ?, ?)', { data.title, data.description, data.author, category, featured, data.video, data.photo, ostime })
    cache[#cache+1] = { id = id, title = data.title, description = data.description, author = data.author, category = category, featured = featured == 1, img = data.photo, video = data.video, day = os.date('%d/%m/%Y', ostime), visualizations = 0, created_at = ostime }
    if GetResourceState("lb-phone") == "started" then
        for passport, src in pairs(vRP.Players()) do
            if passport and src then
                local phoneNumber = nil
                pcall(function()
                    phoneNumber = exports["lb-phone"]:GetEquippedPhoneNumber(src)
                end)
                local target = phoneNumber or src

                exports["lb-phone"]:SendNotification(target, {
                    app = identifier,
                    title = featured == 1 and "Plantão Weazel" or "Weazel News",
                    content = data.title,
                    icon = "https://cfx-nui-" .. GetCurrentResourceName() .. "/web/assets/icon.png",
                    vibrate = true
                })
            end
        end
    end
    vRPWebhook(config.webhooks.create, {
        title = 'Weazel',
        descriptions = {
            { 'action', 'create news' },
            { 'passport', Passport or 'unknown' },
            { 'news id', id },
            { 'informations', json.encode(data, { indent = true }) }
        }
    })
    
    return true
end


srv.deletePost = function(data)
    local Passport = vRP.Passport(source)
    local newsId = cache[data.id].id
    oxmysql:execute_async('delete from weazel where id = ?', { newsId })
    table.remove(cache, data.id)
    vRPWebhook(config.webhooks.delete, {
        title = 'Weazel',
        descriptions = {
            { 'action', 'delete news' },
            { 'passport', Passport or 'unknown' },
            { 'news id', newsId },
        }
    })

    return true
end

srv.editPost = function(_data)
    local Passport = vRP.Passport(source)
    local data = RemoveHTMLtags(_data)
    oxmysql:update_async('update weazel set title = ?, description = ?, author = ?, video = ?, img = ? where id = ?', { data.title, data.description, data.author, data.video, data.photo, cache[data.id].id })
    oxmysql:update_async('update weazel set category = ?, featured = ? where id = ?', { data.category or 'Notícia', data.featured and 1 or 0, cache[data.id].id })
    vRPWebhook(config.webhooks.edit, {
        title = 'Weazel',
        descriptions = {
            { 'action', 'edit news' },
            { 'passport', Passport or 'unknown' },
            { 'old informations', json.encode(cache[data.id], { indent = true }) },
            { 'new informations', json.encode(data, { indent = true }) },
        }
    })
    cache[data.id].title = data.title
    cache[data.id].description = data.description
    cache[data.id].author = data.author
    cache[data.id].category = data.category or 'Notícia'
    cache[data.id].featured = data.featured == true
    cache[data.id].video = data.video
    cache[data.id].img = data.photo

    return true
end

srv.getNews = function()
    table.sort(cache, function(r, r2) 
        if (r.featured or false) ~= (r2.featured or false) then
            return (r.featured or false) and not (r2.featured or false)
        end
        return (r.created_at > r2.created_at) 
    end)
    return cache
end

srv.setVisualization = function(id)
    cache[id].unsaved = true;
    cache[id].visualizations = (cache[id].visualizations+1) 
end

srv.hasPermission = function()
    local Passport = vRP.Passport(source)
    if not Passport then return false end
    return (vRP.HasTable(Passport, config.permissions) ~= false)
end

Citizen.CreateThread(function()
    while (true) do
        for k, v in pairs(cache) do
            if (v.unsaved) then
                oxmysql:update_async('update weazel set visualizations = ? where id = ?', { v.visualizations, v.id })
                cache[k].unsaved = nil
            end
        end
        Citizen.Wait(5000)
    end
end)

function RemoveHTMLtags(inputs)
    local cb = {}
    for k,v in pairs(inputs) do
        if (type(v) == 'string') then
            cb[k] = removeHTMLTagsExceptAllowed(v)
        else
            cb[k] = v
        end
    end
    return cb
end

function removeHTMLTagsExceptAllowed(input)
    local allowed_tags = {
        ["<b>"] = true,
        ["</b>"] = true,
        ["<br>"] = true
    }
    local result = input:gsub("</?[^>]+>", function(tag)
        if allowed_tags[tag] then
            return tag
        else
            return ""
        end
    end)
    return result
end
