-- https://modit.store
-- ModFreakz

RegisterCommand("create:vehshop", function(source,args)
  TriggerClientEvent("VehicleShops:CreateNew",source)
end,true)
