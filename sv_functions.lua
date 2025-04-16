-- https://modit.store
-- ModFreakz

SqlFetch = function(statement,payload,callback)
  MySQL.Async.fetchAll(statement,payload,callback)
end

SqlExecute = function(statement,payload,callback)
  MySQL.Async.execute(statement,payload,callback)
end
