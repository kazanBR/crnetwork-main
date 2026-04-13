-- NUI callback handler: routes all Marketplace UI actions to the appropriate server callbacks
RegisterNUICallback("MarketPlace", function(data, cb)
    local action = data.action
    debugprint("MarketPlace:" .. (action or ""))

    if action == "getPosts" then
        -- Fetch posts and decode attachments JSON before returning to UI
        local posts = AwaitCallback("marketplace:getPosts", data)
        for _, post in ipairs(posts) do
            post.attachments = json.decode(post.attachments)
        end
        cb(posts)

    elseif action == "sendPost" then
        TriggerCallback("marketplace:createPost", cb, data.data)

    elseif action == "deletePost" then
        TriggerCallback("marketplace:deletePost", cb, data.id)
    end
end)


-- Net event: new post created — forward to local event bus and React UI
RegisterNetEvent("phone:marketplace:newPost")
AddEventHandler("phone:marketplace:newPost", function(postData)
    TriggerEvent("lb-phone:marketplace:newPost", postData)
    SendReactMessage("marketPlace:newPost", postData)
end)