window.ig.LiveUpdater = class LiveUpdater
  (@downloadCache) ->
    es = new EventSource "http://localhost:8080/sse"
    es.onmessage = (event) ~>
      len = event.data.length
      data = for i in [0 til len]
        event.data.charCodeAt i
      for code in data
        switch code
        | 1 => @update "obce"
        | 2 => @update "senat"
        | 4, 5 => void
        | 6 => window.location.reload!
        | otherwise =>
          @update @getObecId code

  update: (dataType) ->
    return unless dataType
    console.log dataType
    item = @downloadCache.items[dataType]
    item?invalidate!

  getObecId: (code) ->
    code -= 20
    console.log code
    if window.ig.suggester.suggestions
      obec = window.ig.suggester.suggestions[code]
      if obec
        return obec.id
    return null
