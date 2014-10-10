init = ->
  new Tooltip!watchElements!
  # es = new EventSource "http://localhost:8080/sse"
  # es.onmessage = (event) ->
  #   len = event.data.length
  #   data = for i in [0 til len]
  #     event.data.charCodeAt i
  #   console.log data
  window.ig.strany = strany = {}
  for line in window.ig.data.strany.split "\n"
    [vstrana, nazev, zkratka, barva] = line.split "\t"
    strany[vstrana] = {nazev, zkratka, barva}

  window.ig.senatori = senatori = {}
  for senator in ig.data.senat.split "\n"
    [obvod, id, jmeno, prijmeni, strana, zkratka, barva] = senator.split "\t"
    senatori["#{obvod}-#{id}"] = {jmeno, prijmeni, strana, zkratka, barva}

  window.ig.senat_obvody_meta = obvody_meta = {}
  for line in window.ig.data.senat_obvody.split "\n"
    [id, nazev] = line.split "\t"
    obvody_meta[id] = {nazev}

  container = d3.select ig.containers.base
  firstScreen =
    element: container.append \div .attr \class "firstScreen"
  window.ig.downloadCache = downloadCache = new window.ig.DownloadCache
  senatKosti = new window.ig.SenatKosti firstScreen.element, downloadCache
    ..init!
  suggesterContainer = firstScreen.element.append \div
    ..attr \class \suggester-container
  pekac = new window.ig.Pekac firstScreen.element, strany
    ..redraw!
  obec = new window.ig.Obec container, strany, downloadCache
    ..element.classed \disabled yes
  senat = new window.ig.SenatOverview container, downloadCache
    ..element.classed \disabled yes
  displaySwitcher = new window.ig.DisplaySwitcher do
    {firstScreen, obec, senat}
  obec.displaySwitcher = senat.displaySwitcher = senatKosti.displaySwitcher = displaySwitcher
  suggesterContainer.append \h2
    ..html "Zobrazit výsledky v obci"
  window.ig.suggester = suggester = new window.ig.Suggester suggesterContainer
    ..on \selected displaySwitcher~switchTo
  <~ window.ig.suggester.downloadSuggestions!
  # pha = window.ig.suggester.suggestions
  #   .filter -> it.id == 539694
  #   .pop!
  # displaySwitcher.switchTo pha


if d3?
  init!
else
  window.onload = ->
    if d3?
      init!

