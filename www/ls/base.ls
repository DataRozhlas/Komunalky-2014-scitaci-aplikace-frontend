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

  window.ig.strany = strany = {}
  for line in window.ig.data.strany.split "\n"
    [vstrana, nazev, zkratka, barva] = line.split "\t"
    strany[vstrana] = {nazev, zkratka, barva}


  container = d3.select ig.containers.base
  firstScreen =
    element: container.append \div .attr \class "firstScreen"
  downloadCache = new window.ig.DownloadCache
  pekac = new window.ig.Pekac firstScreen.element, strany
    ..redraw!
  obec = new window.ig.Obec container, strany, downloadCache
    ..element.classed \disabled yes

  displaySwitcher = new window.ig.DisplaySwitcher do
    {firstScreen, obec}
  suggesterContainer = firstScreen.element.append \div
    ..attr \class \suggester-container
  suggesterContainer.append \h2
    ..html "Zobrazit výsledky v obci"
  window.ig.suggester = suggester = new window.ig.Suggester suggesterContainer
    ..on \selected displaySwitcher~switchTo
    ..downloadSuggestions!
  senatKosti = new window.ig.SenatKosti firstScreen.element
    ..download senatKosti~redraw
  displaySwitcher.switchTo do
    id: 539694
    lat: 50.047
    lon: 14.314
    east: 14.355
    north: 50.066
    south: 50.032
    west: 14.271
    nazev: "Praha 13"
    okres:
      nazev: "Praha"
if d3?
  init!
else
  window.onload = ->
    if d3?
      init!

