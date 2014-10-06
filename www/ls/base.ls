init = ->
  new Tooltip!watchElements!
  # es = new EventSource "http://localhost:8080/sse"
  # es.onmessage = (event) ->
  #   len = event.data.length
  #   data = for i in [0 til len]
  #     event.data.charCodeAt i
  #   console.log data
  window.ig.utils.percentage = ->
    window.ig.utils.formatNumber it * 100, 1
  container = d3.select ig.containers.base
  pekac = new window.ig.Pekac container
    ..redraw!
  senatKosti = new window.ig.SenatKosti container
    ..download senatKosti~redraw
if d3?
  init!
else
  window.onload = ->
    if d3?
      init!

