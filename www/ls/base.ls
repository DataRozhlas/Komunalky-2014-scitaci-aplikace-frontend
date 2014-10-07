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
  firstScreen =
    element: container.append \div .attr \class "firstScreen"
  pekac = new window.ig.Pekac firstScreen.element
    ..redraw!
  obec = new window.ig.Obec container
    ..element.classed \disabled yes

  displaySwitcher = new window.ig.DisplaySwitcher do
    {firstScreen, obec}
  suggesterContainer = firstScreen.element.append \div
    ..attr \class \suggester-container
  suggesterContainer.append \h2
    ..html "Zobrazit výsledky v obci"
  suggester = new window.ig.Suggester suggesterContainer
    ..on \selected displaySwitcher~switchTo
  senatKosti = new window.ig.SenatKosti firstScreen.element
    ..download senatKosti~redraw
  displaySwitcher.switchTo do
    id: 539694
    lat: 50.047
    lon: 14.314
    nazev: "Praha 13"
if d3?
  init!
else
  window.onload = ->
    if d3?
      init!

