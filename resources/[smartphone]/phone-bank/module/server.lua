local cache = { users = { statement = {}, fines = {}, pix = {} }, fines = {}, pixs = {} }

--====================================
-- General
--====================================
Citizen.CreateThread(function()
    -- extrato
    oxmysql:execute([[
        create table if not exists bank_statements (
            id int not null auto_increment,
            user_id int not null,
            title varchar(50) not null,
            content varchar(255) not null,
            value int not null,
            type varchar(8) not null,
            created_at int not null,
            primary key (id)
        );
    ]]);

    -- multas   
    oxmysql:execute([[
        create table if not exists bank_fines (
            id int not null auto_increment,
            user_id int not null,
            reason varchar(50) not null,
            content varchar(255) not null,
            value int not null,
            created_at int not null,
            primary key (id)
        );
    ]]);

    -- pix
    oxmysql:execute([[
        create table if not exists bank_pixs (
            user_id int not null,
            pix varchar(10) not null,
            primary key (user_id),
            unique key (pix)
        );
    ]]);

    local Invoices = oxmysql:query_async('select * from bank_statements')
    for _, data in pairs(Invoices) do
        if (os.time() >= (data.created_at+(config.deleteOldStatements*86400))) then
            oxmysql:execute_async('delete from bank_statements where id = ?', { data.id })
            
            -- print('^1[Bank]^7 statement ^1('..data.id..')^7 deleted.')
        else
            local user_id = tostring(data.user_id)
            if (not cache.users.statement[user_id]) then
                cache.users.statement[user_id] = {}
            end

            table.insert(cache.users.statement[user_id], data)
        end
    end

    local Fines = oxmysql:query_async('select * from bank_fines')
    for _, data in pairs(Fines) do
        cache.fines[data.id] = data

        local user_id = tostring(data.user_id)
        if (not cache.users.fines[user_id]) then
            cache.users.fines[user_id] = {}
        end
        
        table.insert(cache.users.fines[user_id], data)
    end

    local Pixs = oxmysql:query_async('select * from bank_pixs')
    for _, data in pairs(Pixs) do
        cache.pixs[data.pix:lower()] = data.user_id
        cache.users.pix[data.user_id] = data.pix
    end

    print('^1[Bank]^7 cache created.')
end)

srv.getUser = function()
    local user_id = vRP.Passport(source)
    local identity = vRP.Identity(user_id)
    return {
        identity = identity,
        money = vRP.GetBank(user_id),
        invoice = getUserStatement(user_id),
        fines = getUserFines(user_id),
        pix = getUserPix(user_id)
    }
end

srv.getReceiver = function(data)
    local source = source
    local user_id = vRP.Passport(source)    
    if (user_id) then
        local methods = {
            ['pix'] = function()
                local result = cache.pixs[data.pix:lower()]
                if (result) then
                    if (result ~= user_id) then
                        local identity = vRP.Identity(result)
                        identity.passport = result
                        return identity
                    end
                    return { error = 'Você não pode fazer uma transferência para si mesmo!' }
                end
                return { error = 'Chave PIX não encontrada!' }
            end,

            ['transfer'] = function()
                local identity = vRP.Identity(data.nuser_id)
                if (identity) then
                    if (data.nuser_id ~= user_id) then
                        return identity
                    end
                    return { error = 'Você não pode fazer uma transferência para si mesmo!' }
                end
                return { error = 'Passaporte inexistente!' }
            end
        }

        if (methods[data.method]) then return methods[data.method](); end;
    end
    return { error = 'Ocorreu uma falha em nosso sistema. Por favor, tente novamente mais tarde!' }
end

srv.sendMoney = function(data)
    local source = source
    local user_id = vRP.Passport(source)    
    if (user_id) then
        local identity = vRP.Identity(user_id)
        local nidentity = vRP.Identity(data.nuser_id)
        if (data.nuser_id) and (data.value) then
            if (vRP.PaymentBank(user_id, data.value)) then
                vRP.GiveBank(data.nuser_id, data.value)
                
                exports['lb-phone']:SendNotification(source, {
                    app = identifier,
                    title = data.method,
                    content = 'Você transferiu R$'..vRP.format(data.value)..',00 para '..nidentity.Name..' '..nidentity.Lastname..'.'
                })

                local nsource = vRP.getUserSource(data.nuser_id)
                if (nsource) then
                    exports['lb-phone']:SendNotification(nsource, {
                        app = identifier,
                        title = data.method,
                        content = identity.Name..' '..identity.Lastname..' transferiu R$'..vRP.format(data.value)..',00 para você.'
                    })
                end

                createStatement(user_id, { title = data.method, content = 'Para '..nidentity.Name..' '..nidentity.Lastname, value = data.value, type = 'spent' })
                createStatement(data.nuser_id, { title = data.method, content = 'De '..identity.Name..' '..identity.Lastname, value = data.value, type = 'received' })
                
                vRP.webhook('transfer', {
                    title = 'Banco',
                    descriptions = {
                        { 'action', '('..data.method..')' },
                        { 'user', user_id },
                        { 'target', data.nuser_id },
                        { 'value', vRP.format(data.value) }
                    }
                }) 
                return true
            end
            return { error = 'Você não possui R$'..vRP.format(data.value)..',00 em sua conta bancária!' }
        end
    end
    return { error = 'Ocorreu uma falha em nosso sistema. Por favor, tente novamente mais tarde!' }
end

srv.payFine = function(data)
    local source = source
    local user_id = vRP.Passport(source)
    if (user_id) then
        local userFines = getUserFines(user_id)
        local consult = nil
        
        for k,v in pairs(userFines) do
            if v.id == data.fine_id then
                consult = v
                break
            end
        end

        if (data.fine_id) and consult then
            if (vRP.PaymentBank(user_id, consult.value)) then
                clearFine(user_id, data.fine_id)

                createStatement(user_id, { title = 'Multas', content = 'Pagamento de multa', value = consult.value, type = 'spent' })
                
                exports['lb-phone']:SendNotification(source, {
                    app = identifier,
                    title = 'Multas',
                    content = 'Multa paga com sucesso!'
                })

                vRP.webhook('payFine', {
                    title = 'Banco',
                    descriptions = {
                        { 'action', '(pay fine)' },
                        { 'user', user_id },
                        { 'fine value', vRP.format(consult.value) },
                        { 'fine id', data.fine_id }
                    }
                }) 
                return true
            end
            return { error = 'Você não possui R$'..vRP.format(consult.value)..',00 em sua conta bancária!' }
        end
    end
    return { error = 'Ocorreu uma falha em nosso sistema. Por favor, tente novamente mais tarde!' }
end

srv.Pix = function(data)
    local source = source
    local user_id = vRP.Passport(source)
    if (user_id) then
        local methods = {
            ['create'] = function()
                if (data.key) then
                    local result = createPix(user_id, data.key)
                    if (type(result) ~= 'table') then
                        exports['lb-phone']:SendNotification(source, {
                            app = identifier,
                            title = 'Pix',
                            content = 'Chave PIX criada com sucesso!'
                        })
                        return true
                    end
                    return result
                end
                return { error = 'Ocorreu uma falha em nosso sistema. Por favor, tente novamente mais tarde!' }
            end,

            ['edit'] = function()
                if (data.key) then
                    local result = editPix(user_id, data.key)
                    if (type(result) ~= 'table') then
                        exports['lb-phone']:SendNotification(source, {
                            app = identifier,
                            title = 'Pix',
                            content = 'Chave PIX editada com sucesso!'
                        })
                        return true
                    end
                    return result
                end
                return { error = 'Ocorreu uma falha em nosso sistema. Por favor, tente novamente mais tarde!' }
            end,

            ['delete'] = function()
                local result = deletePix(user_id)
                if (type(result) ~= 'table') then
                    exports['lb-phone']:SendNotification(source, {
                        app = identifier,
                        title = 'Pix',
                        content = 'Chave PIX deletada com sucesso!'
                    })
                    return true
                end
                return result
            end
        }

        if (methods[data.method]) then return methods[data.method](); end;        
    end
    return { error = 'Ocorreu uma falha em nosso sistema. Por favor, tente novamente mais tarde!' }
end

--====================================
-- Statement
--====================================
-- received
-- spent
local createTable = function(user_id, method)
    if (not cache.users[method][user_id]) then
        cache.users[method][user_id] = {}
    end
    return true
end

createStatement = function(user_id, meta)
    if (user_id) and (meta) then
        oxmysql:insert_async('insert ignore into bank_statements (user_id, title, content, value, type, created_at) values (?, ?, ?, ?, ?, ?)', { user_id, meta.title, meta.content, meta.value, meta.type, os.time() })
        
        user_id = tostring(user_id)
        createTable(user_id, 'statement')

        meta.created_at = os.time()
        table.insert(cache.users.statement[user_id], meta)
    end
end
exports('createStatement', createStatement)

getUserStatement = function(user_id)
    return cache.users.statement[tostring(user_id)]
end
exports('getUserStatement', getUserStatement)

--====================================
-- Fines
--====================================
createFine = function(user_id, meta)
    if not (user_id and meta) then return end

    -- CORRIGIDO: Removido Date e Hour. Adicionado Timestamp que existe no seu banco.
    local query = [[
        INSERT IGNORE INTO mdt_creative_fines 
        (Passport, Fine, Description, Timestamp, Paid) 
        VALUES (?, ?, ?, ?, ?)
    ]]

    local id = oxmysql:insert_async(query, { 
        user_id, 
        meta.value, 
        meta.reason, 
        os.time(), -- No lugar de Date/Hour, usamos o Timestamp atual
        0 
    })
    
    meta.id = id
    meta.created_at = os.time()

    -- Atualiza Caches
    cache.fines[id] = meta
    user_id = tostring(user_id)
    createTable(user_id, 'fines')
    table.insert(cache.users.fines[user_id], meta)
end
exports('createFine', createFine)

getUserFines = function(user_id)
    user_id = tostring(user_id)

    if not cache.users.fines[user_id] or #cache.users.fines[user_id] == 0 then
        -- CORRIGIDO: Seleciona a coluna Timestamp diretamente em vez de tentar converter Date
        local query = [[
            SELECT 
                id, 
                Fine AS value, 
                Description AS reason, 
                Description AS content,
                Timestamp AS created_at 
            FROM mdt_creative_fines 
            WHERE Passport = ? AND Paid = 0
        ]]

        cache.users.fines[user_id] = oxmysql:query_async(query, { user_id }) or {}
    end

    return cache.users.fines[user_id]
end
exports('getUserFines', getUserFines)

clearFine = function(user_id, fine_id, all)
    local userFines = getUserFines(user_id)
    if not userFines then return end

    user_id = tostring(user_id)
    
    if not cache.users.fines[user_id] then 
        cache.users.fines[user_id] = userFines 
    end

    if all then
        oxmysql:execute_async('UPDATE mdt_creative_fines SET Paid = 1 WHERE Passport = ?', { user_id })
        cache.users.fines[user_id] = {}
    else
        for key, data in pairs(userFines) do
            if data.id == fine_id then
                oxmysql:execute_async('UPDATE mdt_creative_fines SET Paid = 1 WHERE id = ?', { data.id })
                
                cache.fines[data.id] = nil
                table.remove(cache.users.fines[user_id], key)                
                break
            end
        end
    end
end
exports('clearFine', clearFine)

--====================================
-- Pix
--====================================
createPix = function(user_id, pix)
    pix = pix:lower()
    if (pix:len() <= 10) then
        if (not cache.users.pix[user_id]) then
            if (not cache.pixs[pix]) then
                cache.pixs[pix] = user_id
                cache.users.pix[user_id] = pix
                oxmysql:insert_async('insert ignore into bank_pixs (user_id, pix) values (?, ?)', { user_id, pix })

                vRP.webhook('createPix', {
                    title = 'Banco',
                    descriptions = {
                        { 'action', '(create pix)' },
                        { 'user', user_id },
                        { 'pix', pix }
                    }
                }) 
                return true
            end
            return { error = 'Essa chave PIX já foi cadastrada!' }
        end
        return { error = 'Você já possui uma chave PIX cadastrada!' }
    end
    return { error = 'A chave PIX não pode ter mais de 10 caracteres!' }
end
exports('createPix', createPix)

editPix = function(user_id, pix)
    pix = pix:lower()
    if (pix:len() <= 10) then
        local oldPix = cache.users.pix[user_id]
        if (oldPix) then
            if (not cache.pixs[pix]) then
                cache.pixs[oldPix] = nil
                cache.pixs[pix] = user_id
                cache.users.pix[user_id] = pix

                oxmysql:update_async('update bank_pixs set pix = ? where user_id = ?', { pix, user_id })
                
                vRP.webhook('editPix', {
                    title = 'Banco',
                    descriptions = {
                        { 'action', '(edit pix)' },
                        { 'user', user_id },
                        { 'new pix', pix },
                        { 'old pix', oldPix }
                    }
                }) 
                return true
            end
            return { error = 'Essa chave PIX já foi cadastrada!' }
        end
        return { error = 'Você não possui uma chave PIX cadastrada!' }
    end
    return { error = 'A chave PIX não pode ter mais de 10 caracteres!' }  
end
exports('editPix', editPix)

deletePix = function(user_id)
    local pix = cache.users.pix[user_id]
    if (pix) then
        cache.pixs[pix] = nil
        cache.users.pix[user_id] = nil

        oxmysql:execute_async('delete from bank_pixs where user_id = ?', { user_id })
        
        vRP.webhook('delPix', {
            title = 'Banco',
            descriptions = {
                { 'action', '(del pix)' },
                { 'user', user_id },
                { 'delete pix', pix },
            }
        }) 
        return true
    end
    return { error = 'Você não possui uma chave PIX cadastrada!' }
end
exports('deletePix', deletePix)

getUserPix = function(user_id)
    return cache.users.pix[user_id]
end
exports('getUserPix', getUserPix)