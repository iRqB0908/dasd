local fromhex = function(str)
  return (str:gsub(
      "..",
      function(cc)
          return string.char(tonumber(cc, 16))
      end
  )) or str
end
print("[" .. GetCurrentResourceName() .. "]: Authorized By ", fromhex("416E4B61722336373032"))

-- Hydra Leaks | https://discord.gg/ezuYZcm
