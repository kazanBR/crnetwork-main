
local PAGE_SIZE = 10

-- Callback: get a page of Yellow Pages posts with optional search/from filters
BaseCallback("yellowPages:getPosts", function(source, phoneNumber, page, filters)
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

        -- Filter by a specific phone number (poster)
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
            attachment,
            price,
            `timestamp`
        FROM
            phone_yellow_pages_posts
        {WHERE}
        ORDER BY
            `timestamp` DESC
        LIMIT ?, ?
    ]]):gsub("{WHERE}", whereClause)

    -- Append pagination params
    params[#params + 1] = page * PAGE_SIZE
    params[#params + 1] = PAGE_SIZE

    local posts = MySQL.query.await(query, params)

    -- For each post, hide the phone number from non-owners so the UI's
    -- ownership check (post.number === myNumber) fails and hides the delete button.
    -- Owners and admins still see the number so their delete button shows correctly.
    local isAdmin = false -- TEMP DISABLED: IsAdmin(source)
    if posts then
        for i = 1, #posts do
            posts[i].isOwner = (posts[i].number == phoneNumber)
            if not posts[i].isOwner and not isAdmin then
                posts[i].number = nil
            end
        end
    end

    return posts
end)


-- Callback: create a new Yellow Pages post
BaseCallback("yellowPages:createPost", function(source, phoneNumber, data)
    local title       = data and data.title
    local description = data and data.description

    -- Validate required fields and check for blacklisted words
    if not title or not description then
        return false
    end

    if ContainsBlacklistedWord(source, "Pages", title)
    or ContainsBlacklistedWord(source, "Pages", description) then
        return false
    end

    local postId = MySQL.insert.await(
        "INSERT INTO phone_yellow_pages_posts (phone_number, title, description, attachment, price) VALUES (@number, @title, @description, @attachment, @price)",
        {
            ["@number"]      = phoneNumber,
            ["@title"]       = LimitStringLength(title, 50),
            ["@description"] = LimitStringLength(description, 1000),
            ["@attachment"]  = data.attachment,
            ["@price"]       = math.clamp(tonumber(data.price) or 0, 0, 1000000000),
        }
    )

    if not postId then
        return false
    end

    -- Attach metadata and broadcast to all clients
    data.id     = postId
    data.number = phoneNumber
    data.source = source

    TriggerClientEvent("phone:yellowPages:newPost", -1, data)
    TriggerEvent("lb-phone:pages:newPost", data)

    Log("YellowPages", source, "info",
        L("BACKEND.LOGS.YELLOWPAGES_NEW_TITLE"),
        L("BACKEND.LOGS.YELLOWPAGES_NEW_DESCRIPTION", {
            title       = data.title,
            description = data.description,
            attachment  = data.attachment or "",
            id          = postId,
        })
    )

    return postId
end)


-- Callback: delete a post (admins can delete any post, others only their own)
BaseCallback("yellowPages:deletePost", function(source, phoneNumber, postId)
    local isAdmin = false -- TEMP DISABLED: IsAdmin(source)

    if not isAdmin then
        -- Double-check ownership directly from DB to prevent spoofed phone number exploits.
        -- We verify that the post's phone_number matches what the DB says belongs to this
        -- player's identifier, not just the in-memory phoneNumber which can be manipulated.
        local identifier = GetIdentifier(source)
        local dbPhoneNumber = MySQL.scalar.await(
            "SELECT phone_number FROM phone_phones WHERE owner_id = ? AND phone_number = ?",
            { identifier, phoneNumber }
        )

        if not dbPhoneNumber then
            infoprint("warning", ("Player %s (%s) tried to delete post %s but their phone number could not be verified"):format(
                GetPlayerName(source), source, tostring(postId)
            ))
            return false
        end

        -- Verify the post actually belongs to this phone number
        local postOwner = MySQL.scalar.await(
            "SELECT phone_number FROM phone_yellow_pages_posts WHERE id = ?",
            { postId }
        )

        if postOwner ~= phoneNumber then
            infoprint("warning", ("Player %s (%s) tried to delete post %s which belongs to %s"):format(
                GetPlayerName(source), source, tostring(postId), tostring(postOwner)
            ))
            return false
        end
    end

    local affected = MySQL.update.await(
        "DELETE FROM phone_yellow_pages_posts WHERE id = @id" .. (isAdmin and "" or " AND phone_number = @number"),
        { ["@id"] = postId, ["@number"] = phoneNumber }
    )

    if affected > 0 then
        Log("YellowPages", source, "error",
            L("BACKEND.LOGS.YELLOWPAGES_DELETED"),
            ("**ID**: %s"):format(postId)
        )
    end

    return affected > 0
end)