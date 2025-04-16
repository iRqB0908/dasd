error = function(...) end



KashCharacters  = {}

KashPlayers     = {}



Config = (Config or {

  StockStolenPedVehicles    = false,

  StockStolenPlayerVehicles = false, 

})



Warehouse = (Warehouse or {  

  entry = vector4(-281.71,-2656.73,6.41, 46.00),

  exit  = vector4(-1243.92,-3023.24,-48.48, 90.00),



  defaults = {

    gridStart   = vector3(-1281.30,-3042.80,-48.48),

    gridHead    = 0.0,



    gridWidth   = 7,

    gridLength  = 6,



    gridSpacingX = 4.98,

    gridSpacingY = 8.00,



    randomPriceVariation = 10, -- % random variation

  },



  purchasedSpawns = {

    vector4(-283.40,-2647.91,6.0,46.0),

    vector4(-286.43,-2649.76,6.0,46.0),

    vector4(-288.64,-2652.12,6.0,46.0),

    vector4(-290.94,-2654.26,6.0,46.0),

    vector4(-293.12,-2656.53,6.0,46.0),

  },

})



KashChosen = function(charId)

  local _source = source

  KashCharacters[_source] = charId



  local xPlayer = ESX.GetPlayerFromId(_source)

  while not xPlayer do xPlayer = ESX.GetPlayerFromId(_source); Wait(0); end

  local identifier = (KashCharacters[_source] and KashCharacters[_source]..":" or '')..xPlayer.getIdentifier()

  KashPlayers[identifier] = {src = _source, id = xPlayer.getIdentifier()}

end



GetDatabaseName = function()

  local dbconvar = GetConvar('mysql_connection_string', 'Empty')



  if not dbconvar or dbconvar == "Empty" then 

    error("Local dbconvar is empty."); 

    return false

  else

    local strStart,strEnd = string.find(dbconvar, "database=")

    if not strStart or not strEnd then

      local oStart,oEnd = string.find(dbconvar,"mysql://")

      if not oStart or not oEnd then

        error("Incorrect mysql_connection_string.")

        return false

      else

        local hostStart,hostEnd = string.find(dbconvar,"@",oEnd)

        local dbStart,dbEnd = string.find(dbconvar,"/",hostEnd+1)

        local eStart,eEnd = string.find(dbconvar,"?")

        local _end = (eEnd and eEnd-1 or dbconvar:len())

        local dbName = string.sub(dbconvar, dbEnd + 1, _end) 

        return dbName

      end

    else

      local dbStart,dbEnd = string.find(dbconvar,";",strEnd)

      local dbName = string.sub(dbconvar, strEnd + 1, (dbEnd and dbEnd-1 or dbconvar:len())) 

      return dbName

    end    

  end

end





Init = function()

  VehicleShops = {}

  WarehouseVehicles = {}



  local dbName = GetDatabaseName()

  if dbName then

    SqlFetch("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA=@table AND TABLE_NAME=@name",{['@table'] = dbName,['@name']  = (Config and Config.VehiclesTable or "owned_vehicles")},function(r0)

      if type(r0) == "table" and r0[1] and r0[1].TABLE_NAME == (Config and Config.VehiclesTable or "owned_vehicles") then

        SqlFetch("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA=@table AND TABLE_NAME=@name",{['@table'] = dbName,['@name']  = (Config and Config.ShopTable or "vehicle_shops")},function(r1)

          if type(r1) == "table" and r1[1] and r1[1].TABLE_NAME == (Config and Config.ShopTable or "vehicle_shops") then

            SqlFetch("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA=@table AND TABLE_NAME=@name",{['@table'] = dbName,['@name']  = (Config and Config.WarehouseTable or "vehicles")},function(r2)  

              if type(r2) == "table" and r2[1] and r2[1].TABLE_NAME == (Config and Config.WarehouseTable or "vehicles") then

                SqlFetch("SELECT * FROM "..(Config and Config.ShopTable or "vehicle_shops"),{},function(shopData)

                  for k,v in pairs(shopData) do

                    if v and v.locations and v.locations ~= '' and v.employees and v.employees ~= '' and v.stock and v.displays and v.displays ~= '' then

                      VehicleShops[v.name] = {

                        owner = (v.owner ~= "none" and v.owner or false),

                        charid = v.charid,

                        name = v.name,

                        locations = json.decode(v.locations),

                        employees = json.decode(v.employees),

                        stock     = json.decode(v.stock),

                        displays  = json.decode(v.displays),

                        funds     = v.funds,

                        price     = v.price,

                      }

                    end

                  end



                  SqlFetch("SELECT * FROM "..(Config and Config.WarehouseTable or "vehicles"),{},function(vehData)

                    for k,v in pairs(vehData) do

                      table.insert(WarehouseVehicles,{name = v.name,model = v.model,price = v.price})

                    end

                    ModReady = true

                    print("Ready.")

                    RefreshVehicles()

                  end)

                end)  

              else

                print("Failed to find vehicles table.")    

              end

            end)

          else

            print("Failed to find vehicle_shops table.")  

          end      

        end)

      else

        print("Failed to find owned_vehicles table.")  

      end

    end)

  end

end



RefreshVehicles = function()

  local randomDefault = function(curPicked)

    local vehicle = WarehouseVehicles[math.random(#WarehouseVehicles)]

    while curPicked[vehicle] do vehicle = WarehouseVehicles[math.random(#WarehouseVehicles)]; Wait(0); end

    return vehicle

  end



  if type(Warehouse) ~= "table" or type(Warehouse.defaults) ~= "table" or 

  not Warehouse.defaults.gridLength or 

  not Warehouse.defaults.gridWidth  or

  not Warehouse.defaults.gridStart  then

    print("Error finding Warehouse.defaults value.")

    return

  end



  PickedVehicles = {}

  ShopVehicles = {}

  for x=Warehouse.defaults.gridStart.x,Warehouse.defaults.gridStart.x+(Warehouse.defaults.gridWidth * Warehouse.defaults.gridSpacingX),Warehouse.defaults.gridSpacingX do

    for y=Warehouse.defaults.gridStart.y,Warehouse.defaults.gridStart.y+(Warehouse.defaults.gridLength * Warehouse.defaults.gridSpacingY),Warehouse.defaults.gridSpacingY do

      local here = vector4(x,y,Warehouse.defaults.gridStart.z,Warehouse.defaults.gridHead)

      local vehicle = randomDefault(PickedVehicles)

      local price = vehicle.price + (vehicle.price * math.floor((math.random(Warehouse.defaults.randomPriceVariation) / 100)))

      table.insert(ShopVehicles,{model = vehicle.model,name = vehicle.name,price = price,pos = here})

      PickedVehicles[vehicle] = true

    end

  end



  TriggerClientEvent("VehicleShops:WarehouseRefresh",-1,ShopVehicles)

  Wait( (Config and type(Config.RefreshTimer) == "number" and Config.RefreshTimer or (24 * 60 * 60 * 1000)) )

  print("Refreshing warehouse vehicles.")

  RefreshVehicles()

end



WaitForReady = function()

  while not ModReady do Wait(0); end

end



GetVehicleShops = function(source,callback)

  WaitForReady()

  callback({shops = VehicleShops, vehicles = ShopVehicles},KashCharacters[source])

end



CreateShop = function(name,locations,price)

  VehicleShops[#VehicleShops+1] = {

    owner = false,

    name = name,

    locations = locations,

    employees = {},

    stock = {},

    displays = {},

    funds = 0,

    price = math.max(1,tonumber(price))

  }

  TriggerClientEvent("VehicleShops:Sync",-1,VehicleShops)

  SqlExecute("INSERT INTO "..(Config and Config.ShopTable or "vehicle_shops").." SET owner='none',name=@name,locations=@locations,employees='{}',stock='{}',displays='{}',funds=0,price=@price",{['@name'] = name, ['@locations'] = json.encode(locations),['@price'] = math.max(1,tonumber(price))})

end



PurchaseShop = function(source,callback,shop)

  local _source = source

  local xPlayer = ESX.GetPlayerFromId(_source)

  local can_buy = false

  if (xPlayer.getMoney and xPlayer.getMoney() or xPlayer.getAccount((Config and Config.CashAccountName or "cash")).money) >= VehicleShops[shop].price then

    if xPlayer.removeMoney then xPlayer.removeMoney(VehicleShops[shop].price) else xPlayer.removeAccountMoney((Config and Config.CashAccountName or "cash"),VehicleShops[shop].price) end

    can_buy = true

  elseif xPlayer.getAccount((Config and Config.BankAccountName or "bank")).money >= VehicleShops[shop].price then

    xPlayer.removeAccountMoney((Config and Config.BankAccountName or "bank"),VehicleShops[shop].price)

    can_buy = true

  end



  if can_buy then

    local identifier = (KashCharacters[source] and KashCharacters[source]..":" or '')..xPlayer.getIdentifier()



    VehicleShops[shop].owner = identifier



    TriggerClientEvent("VehicleShops:Sync",-1,VehicleShops)

    SqlExecute("UPDATE "..(Config and Config.ShopTable or "vehicle_shops").." SET owner=@owner WHERE name=@name",{['@name'] = VehicleShops[shop].name, ['@owner'] = identifier})

    callback(true)

  else

    callback(false)

  end

end



GetVehicleOwner = function(source,callback,plate)

  SqlFetch('SELECT * FROM owned_vehicles WHERE plate=@plate',{['@plate'] = plate},function(data)

    local owner = false

    if data and data[1] and (data[1].plate == plate or plate:match(data[1].plate)) then

      owner = data[1].owner

    end

    callback(owner)

  end)

end



StockedVehicle = function(vehProps,shopId,doDelete)

  if doDelete then

    SqlExecute("DELETE FROM owned_vehicles WHERE plate=@plate",{['@plate'] = vehProps.plate})

  end

  table.insert(VehicleShops[shopId].stock,{vehicle = vehProps})

  TriggerClientEvent("VehicleShops:Sync",-1,VehicleShops)

  SqlExecute("UPDATE "..(Config and Config.ShopTable or "vehicle_shops").." SET stock=@stock WHERE name=@name",{['@stock'] = json.encode(VehicleShops[shopId].stock), ['@name'] = VehicleShops[shopId].name})

end



VehiclePurchased = function(shopId,vehId,props)

  VehicleShops[shopId].funds = VehicleShops[shopId].funds - ShopVehicles[vehId].price

  TriggerClientEvent("VehicleShops:Sync",-1,VehicleShops)

  SqlExecute("UPDATE "..(Config and Config.ShopTable or "vehicle_shops").." SET funds=@funds WHERE name=@name",{['@funds'] = VehicleShops[shopId].funds, ['@name'] = VehicleShops[shopId].name})

  SqlExecute("INSERT INTO owned_vehicles SET owner=@owner,plate=@plate,vehicle=@vehicle",{['@owner'] = VehicleShops[shopId].owner,['@plate'] = props.plate,['@vehicle'] = json.encode(props)})

end



CopyTable = function(tab)

  local r = {}

  for k,v in pairs(tab) do

    if type(v) == "table" then

      r[k] = CopyTable(v)

    else

      r[k] = v

    end

  end

  return r

end



SetDisplayed = function(shop,veh,pos)

  local vehData = CopyTable(VehicleShops[shop].stock[veh])

  vehData.location = pos

  VehicleShops[shop].displays[vehData.vehicle.plate] = vehData

  for k,v in pairs(VehicleShops[shop].stock) do

    if v.vehicle.plate == vehData.vehicle.plate then

      table.remove(VehicleShops[shop].stock,k)

      break

    end

  end



  SqlExecute("UPDATE "..(Config and Config.ShopTable or "vehicle_shops").." SET stock=@stock,displays=@displays WHERE name=@name",{['@stock'] = json.encode(VehicleShops[shop].stock), ['@displays'] = json.encode(VehicleShops[shop].displays), ['@name'] = VehicleShops[shop].name})

  TriggerClientEvent("VehicleShops:Sync",-1,VehicleShops)

end



RemoveDisplay = function(shop,veh)

  local vehData = CopyTable(VehicleShops[shop].displays[veh])

  vehData.price = nil

  table.insert(VehicleShops[shop].stock,vehData)

  for k,v in pairs(VehicleShops[shop].displays) do

    if vehData.vehicle.plate == v.vehicle.plate then

      VehicleShops[shop].displays[k] = nil

    end

  end



  SqlExecute("UPDATE "..(Config and Config.ShopTable or "vehicle_shops").." SET stock=@stock,displays=@displays WHERE name=@name",{['@stock'] = json.encode(VehicleShops[shop].stock), ['@displays'] = json.encode(VehicleShops[shop].displays), ['@name'] = VehicleShops[shop].name})

  TriggerClientEvent("VehicleShops:RemoveDisplay",-1,shop,veh,VehicleShops)

end



SetPrice = function(veh,shop,price)

  VehicleShops[shop].displays[veh].price = price  

  TriggerClientEvent("VehicleShops:Sync",-1,VehicleShops)

  SqlExecute("UPDATE "..(Config and Config.ShopTable or "vehicle_shops").." SET displays=@displays WHERE name=@name",{['@displays'] = json.encode(VehicleShops[shop].displays), ['@name'] = VehicleShops[shop].name})

end



TryBuy = function(source,callback,shop,veh,plate,class)

  local xPlayer = ESX.GetPlayerFromId(source)

  local vehicle = VehicleShops[shop].displays[veh]

  local can_purchase = false

  if (xPlayer.getMoney and xPlayer.getMoney() or xPlayer.getAccount((Config and Config.CashAccountName or "cash")).money) >= vehicle.price then

    can_purchase = true  

    if xPlayer.removeMoney then xPlayer.removeMoney(vehicle.price) else xPlayer.removeAccountMoney((Config and Config.CashAccountName or "cash"),vehicle.price); end

  elseif (xPlayer.getBank and xPlayer.getBank() or xPlayer.getAccount((Config and Config.BankAccountName or "bank")).money) >= vehicle.price then     

    can_purchase = true

    if xPlayer.removeBank then xPlayer.removeBank(vehicle.price) else xPlayer.removeAccountMoney((Config and Config.BankAccountName or "bank"),vehicle.price); end

  end



  if can_purchase then

    local identifier = (KashCharacters[source] and KashCharacters[source]..":" or '')..xPlayer.getIdentifier()



    VehicleShops[shop].funds = VehicleShops[shop].funds + vehicle.price

    TriggerEvent("VehicleShops:PurchaseComplete",identifier,VehicleShops[shop].displays[veh].vehicle.plate)

    SqlExecute("INSERT INTO owned_vehicles SET owner=@owner,plate=@plate,vehicle=@vehicle",{

      ['@owner'] = xPlayer.getIdentifier(),

      ['@plate'] = VehicleShops[shop].displays[veh].vehicle.plate,

      ['@vehicle'] = json.encode(VehicleShops[shop].displays[veh].vehicle)

    })



    VehicleShops[shop].displays[veh] = nil  

    SqlExecute("UPDATE "..(Config and Config.ShopTable or "vehicle_shops").." SET stock=@stock,displays=@displays,funds=@funds WHERE name=@name",{

      ['@stock'] = json.encode(VehicleShops[shop].stock), 

      ['@displays'] = json.encode(VehicleShops[shop].displays), 

      ['@funds'] = VehicleShops[shop].funds, 

      ['@name'] = VehicleShops[shop].name

    })

    TriggerClientEvent("VehicleShops:RemoveDisplay",-1,shop,veh,VehicleShops)

    TriggerEvent("VehicleShops:PurchasedVehicle",plate,class)

    callback(true)

  else

    callback(false,"You can't afford that.")

  end

end



DriveVehicle = function(source,callback,shop,veh)

  local vehData = CopyTable(VehicleShops[shop].stock[veh])

  for k,v in pairs(VehicleShops[shop].stock) do

    if v.vehicle.plate == vehData.vehicle.plate then

      table.remove(VehicleShops[shop].stock,k)

      break

    end

  end



  SqlExecute("INSERT INTO owned_vehicles SET owner=@owner,plate=@plate,vehicle=@vehicle",{['@owner'] = VehicleShops[shop].owner,['@plate'] = vehData.vehicle.plate,['@vehicle'] = json.encode(vehData.vehicle)})

  TriggerClientEvent("VehicleShops:Sync",-1,VehicleShops)



  callback(true)

end



local NumberCharset = {}

local Charset = {}



for i = 48,  57 do table.insert(NumberCharset, string.char(i)) end

for i = 65,  90 do table.insert(Charset, string.char(i)) end

for i = 97, 122 do table.insert(Charset, string.char(i)) end



GeneratePlate = function(plates)

  while true do

    math.randomseed(GetGameTimer())

    local generatedPlate = string.upper(GetRandomLetter(3) .. ' ' .. GetRandomNumber(3))    

    if not plates[generatedPlate] then 

      return generatedPlate

    end

    Wait(0)

  end  

end



GetRandomNumber = function(length)

  math.randomseed(GetGameTimer())

  if length > 0 then

    return GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]

  else

    return ''

  end

end



GetRandomLetter = function(length)

  math.randomseed(GetGameTimer())

  if length > 0 then

    return GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)]

  else

    return ''

  end

end



GenerateNewPlate = function(source,callback)

  SqlExecute("SELECT * FROM owned_vehicles",{},function(data)    

    local plates = {}

    if data and type(data) == "table" then

      for k,v in pairs(data) do plates[v.plate] = true; end

    end

    local newPlate = GeneratePlate(plates)

    callback(newPlate)

  end)

end



AddFunds = function(shop_key,amount)

  local _source = source

  local xPlayer = ESX.GetPlayerFromId(_source)

  local can_purchase = false

  if (xPlayer.getMoney and xPlayer.getMoney() or xPlayer.getAccount((Config and Config.CashAccountName or "cash")).money) >= amount then

    can_purchase = true  

    if xPlayer.removeMoney then xPlayer.removeMoney(amount) else xPlayer.removeAccountMoney((Config and Config.CashAccountName or "cash"),amount); end

  elseif (xPlayer.getBank and xPlayer.getBank() or xPlayer.getAccount((Config and Config.BankAccountName or "bank")).money) >= amount then     

    can_purchase = true

    if xPlayer.removeBank then xPlayer.removeBank(amount) else xPlayer.removeAccountMoney((Config and Config.BankAccountName or "bank"),amount); end

  end



  if can_purchase then      

    VehicleShops[shop_key].funds = VehicleShops[shop_key].funds + amount

    SqlExecute("UPDATE "..(Config and Config.ShopTable or "vehicle_shops").." SET funds=funds + @amount WHERE name=@name",{['@amount'] = amount, ['@name'] = VehicleShops[shop_key].name})

    TriggerClientEvent("VehicleShops:Sync",-1,VehicleShops)

    TriggerClientEvent("esx:showNotification",_source,"You added $~g~"..amount.."~s~ to the shops funds.")

  else

    TriggerClientEvent("esx:showNotification",_source,"You can't afford that.")

  end

end



TakeFunds = function(shop_key,amount)

  local _source = source

  if VehicleShops[shop_key].funds >= amount then

    local xPlayer = ESX.GetPlayerFromId(_source)

    local identifier = (KashCharacters[source] and KashCharacters[source]..":" or '')..xPlayer.getIdentifier()

    if identifier == VehicleShops[shop_key].owner then

      if xPlayer.addBank then

        xPlayer.addBank(amount)

      else

        xPlayer.AddAccountMoney((Config and Config.BankAccountName or "bank"),amount)

      end

      VehicleShops[shop_key].funds = VehicleShops[shop_key].funds - amount

      SqlExecute("UPDATE "..(Config and Config.ShopTable or "vehicle_shops").." SET funds=funds - @amount WHERE name=@name",{['@amount'] = amount, ['@name'] = VehicleShops[shop_key].name})

      TriggerClientEvent("VehicleShops:Sync",-1,VehicleShops)

      TriggerClientEvent("esx:showNotification",_source,"You took $~r~"..amount.."~s~ from the shops funds.")

    end

  else

    TriggerClientEvent("esx:showNotification",_source,"The shop doesn't have that many funds.")

  end

end



HirePlayer = function(shop_key,target_id)

  local mPlayer = ESX.GetPlayerFromId(source)

  local mIdentifier = (KashCharacters[source] and KashCharacters[source]..":" or '')..mPlayer.getIdentifier()

  local shop = VehicleShops[shop_key]

  if shop and shop.owner and shop.owner == mIdentifier then

    local xPlayer = ESX.GetPlayerFromId(target_id)

    SqlFetch('SELECT firstname, lastname FROM `users` WHERE `identifier` = @identifier', {['@identifier'] = xPlayer.getIdentifier()}, function(result)  

      local identifier = (KashCharacters[target_id] and KashCharacters[target_id]..":" or '')..xPlayer.getIdentifier()

      table.insert(VehicleShops[shop_key].employees,{

        identifier = identifier,

        identity   = {firstname = result[1].firstname, lastname = result[1].lastname}

      })

      SqlExecute("UPDATE "..(Config and Config.ShopTable or "vehicle_shops").." SET employees=@employees WHERE name=@name",{['@employees'] = json.encode(VehicleShops[shop_key].employees), ['@name'] = VehicleShops[shop_key].name})

      TriggerClientEvent("VehicleShops:Sync",-1,VehicleShops)

    end)

  end

end



FirePlayer = function(shop_key,target_id)

  local mPlayer = ESX.GetPlayerFromId(source)

  local mIdentifier = (KashCharacters[source] and KashCharacters[source]..":" or '')..mPlayer.getIdentifier()

  local shop = VehicleShops[shop_key]

  if shop and shop.owner and shop.owner == mIdentifier then

    for k,v in pairs(VehicleShops[shop_key].employees) do

      if v.identifier == target_id then

        table.remove(VehicleShops[shop_key].employees,k)

        break

      end

    end

    SqlExecute("UPDATE "..(Config and Config.ShopTable or "vehicle_shops").." SET employees=@employees WHERE name=@name",{['@employees'] = json.encode(VehicleShops[shop_key].employees), ['@name'] = VehicleShops[shop_key].name})

    TriggerClientEvent("VehicleShops:Sync",-1,VehicleShops)

  end

end



PayPlayer = function(shop_key,target_id,amount)

  local mPlayer = ESX.GetPlayerFromId(source)

  local mIdentifier = (KashCharacters[source] and KashCharacters[source]..":" or '')..mPlayer.getIdentifier()

  local shop = VehicleShops[shop_key]

  if shop and shop.owner and shop.owner == mIdentifier and shop.funds >= amount then

    amount = math.floor(amount)

    for k,v in pairs(VehicleShops[shop_key].employees) do

      if v.identifier == target_id then

        local xPlayer

        if KashPlayers[target_id] then

          xPlayer = ESX.GetPlayerFromId(KashPlayers[target_id].src)

        else

          xPlayer = ESX.GetPlayerFromIdentifier(target_id)

        end

        

        if xPlayer then

          if xPlayer.addBank then

            xPlayer.addBank(amount)

          else

            xPlayer.AddAccountMoney((Config and Config.BankAccountName or "bank"),amount)

          end

          shop.funds = shop.funds - amount

          TriggerClientEvent("esx:showNotification",source,string.format("Payed %s %s $%i.",v.identity.firstname,v.identity.lastname,amount))

          SqlExecute("UPDATE "..(Config and Config.ShopTable or "vehicle_shops").." SET funds=funds - @amount WHERE name=@name",{['@amount'] = amount, ['@name'] = VehicleShops[shop_key].name})

          TriggerClientEvent("VehicleShops:Sync",-1,VehicleShops)

        else

          TriggerClientEvent("esx:showNotification",source,"Player is not online.")

        end

        break

      end

    end

  end

end



ESX.RegisterServerCallback("VehicleShops:GetVehicleShops", GetVehicleShops)

ESX.RegisterServerCallback("VehicleShops:GetVehicleOwner", GetVehicleOwner)

ESX.RegisterServerCallback("VehicleShops:GenerateNewPlate", GenerateNewPlate)

ESX.RegisterServerCallback("VehicleShops:TryBuy", TryBuy)

ESX.RegisterServerCallback("VehicleShops:PurchaseShop", PurchaseShop)

ESX.RegisterServerCallback("VehicleShops:DriveVehicle", DriveVehicle)



RegisterNetEvent("VehicleShops:Create")

AddEventHandler("VehicleShops:Create", CreateShop)



RegisterNetEvent("VehicleShops:AddFunds")

AddEventHandler("VehicleShops:AddFunds", AddFunds)



RegisterNetEvent("VehicleShops:TakeFunds")

AddEventHandler("VehicleShops:TakeFunds", TakeFunds)



RegisterNetEvent("VehicleShops:StockedVehicle")

AddEventHandler("VehicleShops:StockedVehicle", StockedVehicle)



RegisterNetEvent("VehicleShops:SetDisplayed")

AddEventHandler("VehicleShops:SetDisplayed", SetDisplayed)



RegisterNetEvent("VehicleShops:SetPrice")

AddEventHandler("VehicleShops:SetPrice", SetPrice)



RegisterNetEvent("VehicleShops:HirePlayer")

AddEventHandler("VehicleShops:HirePlayer", HirePlayer)



RegisterNetEvent("VehicleShops:FirePlayer")

AddEventHandler("VehicleShops:FirePlayer", FirePlayer)



RegisterNetEvent("VehicleShops:PayPlayer")

AddEventHandler("VehicleShops:PayPlayer", PayPlayer)



RegisterNetEvent("VehicleShops:VehiclePurchased")

AddEventHandler("VehicleShops:VehiclePurchased", VehiclePurchased)



RegisterNetEvent("VehicleShops:RemoveDisplay")

AddEventHandler("VehicleShops:RemoveDisplay", RemoveDisplay)



RegisterNetEvent("kashactersS:CharacterChosen")

AddEventHandler("kashactersS:CharacterChosen", KashChosen)



MySQL.ready(Init)
