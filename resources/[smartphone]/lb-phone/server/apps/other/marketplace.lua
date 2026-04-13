local PAGE_SIZE = 15

-- Internal: query marketplace posts with optional filtering and pagination
local function GetPosts(page, filters)
    if not page then page = 0 end

    local params     = {}
    local conditions = {}

    if filters then
        -- Full-text search across title, description, and optionally phone number
        if filters.search then
            local pattern = "%" .. filters.search .. "%"
            conditions[#conditions + 1] = "(title LIKE ? OR description LIKE ?)"
            params[#params + 1] = pattern
            params[#params + 1] = pattern

            -- Also search by phone number unless a specific 'from' filter is set
            if not filters.from then
                conditions[#conditions + 1] = "OR phone_number LIKE ?"
                params[#params + 1] = pattern
            end
        end

        -- Filter by a specific phone number (seller)
        if filters.from then
            local prefix = #conditions > 0 and "AND " or ""
            conditions[#conditions + 1] = prefix .. "phone_number = ?"
            params[#params + 1] = filters.from
        end
    end

    -- Build WHERE clause if any conditions exist
    local whereClause = ""
    if #conditions > 0 then
        whereClause = "WHERE " .. table.concat(conditions, " ")
    end

    local query = ([[
        SELECT
            id,
            phone_number AS `number`,
            title,
            description,
            attachments,
            price,
            `timestamp`
        FROM
            phone_marketplace_posts
        {WHERE}
        ORDER BY
            `timestamp` DESC
        LIMIT ?, ?
    ]]):gsub("{WHERE}", whereClause)

    -- Append pagination params
    params[#params + 1] = page * PAGE_SIZE
    params[#params + 1] = PAGE_SIZE

    return MySQL.query.await(query, params)
end


-- Callback: get a page of marketplace posts
BaseCallback("marketplace:getPosts", function(source, phoneNumber, data)
    return GetPosts(data.page, { from = data.from, search = data.query })
end)


-- Callback: create a new marketplace post
BaseCallback("marketplace:createPost", function(source, phoneNumber, data)
    local title       = data.title
    local description = data.description
    local attachments = data.attachments
    local price       = data.price

    -- Validate required fields and price
    if not (title and description and attachments and price) or price < 0 then
        return false
    end

    -- Check for blacklisted words in title and description
    if ContainsBlacklistedWord(source, "MarketPlace", title)
    or ContainsBlacklistedWord(source, "MarketPlace", description) then
        return false
    end

    local postId = MySQL.insert.await(
        "INSERT INTO phone_marketplace_posts (phone_number, title, description, attachments, price) VALUES (?, ?, ?, ?, ?)",
        {
            phoneNumber,
            LimitStringLength(title, 50),
            LimitStringLength(description, 1000),
            json.encode(attachments),
            math.clamp(price, 0, 1000000000),
        }
    )

    if not postId then
        return false
    end

    -- Attach metadata and broadcast to all clients
    data.number = phoneNumber
    data.id     = postId
    data.source = source

    TriggerClientEvent("phone:marketplace:newPost", -1, data)
    TriggerEvent("lb-phone:marketplace:newPost", data)

    Log("Marketplace", source, "info",
        L("BACKEND.LOGS.MARKETPLACE_NEW_TITLE"),
        L("BACKEND.LOGS.MARKETPLACE_NEW_DESCRIPTION", {
            seller      = FormatNumber(phoneNumber),
            title       = title,
            price       = price,
            description = description,
            attachments = json.encode(attachments),
            id          = postId,
        })
    )

    return postId
end)


-- Callback: delete a marketplace post (admins can delete any post, others only their own)
BaseCallback("marketplace:deletePost", function(source, phoneNumber, postId)
    local isAdmin = IsAdmin(source)
    local params  = { postId }

    local query = "DELETE FROM phone_marketplace_posts WHERE id = ?"
    if not isAdmin then
        query         = query .. " AND phone_number = ?"
        params[#params + 1] = phoneNumber
    end

    local affected = MySQL.update.await(query, params)

    if affected > 0 then
        Log("Marketplace", source, "error",
            L("BACKEND.LOGS.MARKETPLACE_DELETED"),
            ("**ID**: %s"):format(postId)
        )
        return true
    end

    return false
end)