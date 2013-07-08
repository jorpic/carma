define [], ->
  # This module maps server <-> client data types
  # c2s prefix means client  -> server
  # s2c prefix means client <-  server

  c2sDate = (fmt) -> (v) ->
    date = Date.parseExact(v, fmt)
    if date
      String(Math.round(date.getTime() / 1000))
    else
      # FIXME: really what should this do with wrong dates?
      console.error("datamap: can't parse date '#{v}' with '#{fmt}'")
      ""

  s2cDate = (fmt) -> (v) -> new Date(v * 1000).toString(fmt)

  s2cJson = (v) ->
    return null if _.isEmpty v
    JSON.parse(v)

  c2sTypes =
    checkbox : (v) -> if v then "1" else "0"
    date     : c2sDate("dd.MM.yyyy")
    datetime : c2sDate("dd.MM.yyyy HH:mm")
    json     : JSON.stringify

  s2cTypes =
    checkbox : (v) -> v == "1"
    date     : s2cDate("dd.MM.yyyy")
    datetime : s2cDate("dd.MM.yyyy HH:mm")
    json     : s2cJson

  c2s = (val, type) -> (c2sTypes[type] || _.identity)(val)
  s2c = (val, type) -> (s2cTypes[type] || _.identity)(val)

  mapObj = (mapper) -> (obj, types) ->
    r = {}
    r[k] = mapper(v, types[k]) for k, v of obj
    r

  c2s    : c2s
  s2c    : s2c
  c2sObj : mapObj(c2s)
  s2cObj : mapObj(s2c)