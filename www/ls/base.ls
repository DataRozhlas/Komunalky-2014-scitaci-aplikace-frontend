init = ->
  es = new EventSource "http://localhost:8080/sse"
  es.onmessage = (event) ->
    len = event.data.length
    data = for i in [0 til len]
      event.data.charCodeAt i
    console.log data
if d3?
  init!
else
  $ window .bind \load ->
    if d3?
      init!
