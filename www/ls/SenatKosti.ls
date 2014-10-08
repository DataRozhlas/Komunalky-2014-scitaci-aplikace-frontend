utils = window.ig.utils
locations =
  "3": [5 46]
  "9": [10 48]
  "6": [12 33]
  "30": [16 35]
  "33": [17 10]
  "36": [21 16]
  "42": [23 41]
  "18": [16 55]
  "12": [14 72]
  "15": [23 67]
  "39": [29.5 21]
  "45": [29 34]
  "48": [33 37]
  "51": [31 62]
  "54": [31 85]
  "57": [37 73]
  "66": [38 51]
  "63": [44 61]
  "81": [42 85]
  "78": [46 73]
  "69": [49 59]
  "75": [48 47]
  "21": [59 43]
  "27": [61 28]
  "22": [66 38]
  "24": [69 29]
  "72": [79 15]
  "60": [66 73]

barvy =
  "21": 53
  "24": 53
  "27": 53
  "54": 47
defaultBarva = 7

window.ig.SenatKosti = class SenatKosti implements utils.supplementalMixin
  (@baseElement) ->
    @element = @baseElement.append \div
      ..attr \class \senatKosti
    @heading = @element.append \h2
      ..html "Průběžné výsledky senatních voleb"
    @element.append \img
      ..attr \src './img/obvody.svg'
      ..on \mousemove ->
        console.log do
          (d3.event.offsetX / @offsetWidth * 100).toFixed 2
          (d3.event.offsetY / @offsetHeight * 100).toFixed 2
    @obvody = for [0 til 27] => {data: null}
    @drawSupplemental!
    @drawEmptyBoxes!
    @parseObvodyMeta!
    @senatori = {}
    for senator in ig.data.senat.split "\n"
      [obvod, id, jmeno, prijmeni, strana, zkratka, barva] = senator.split "\t"
      @senatori["#{obvod}-#{id}"] = {jmeno, prijmeni, strana, zkratka, barva}

  redraw: ->
    if @data.okrsky_celkem == @data.okrsky_spocteno
      @heading.html "Celkové výsledky senatních voleb"
    @updateSupplemental!
    @kosti
      ..classed \decided -> it.data.obvodDecided
      ..style \left -> "#{locations[it.data.obvodId]?0}%"
      ..style \top -> "#{locations[it.data.obvodId]?1}%"
      ..attr \data-tooltip (obvod) ~>
        strana = barvy[obvod.data.obvodId] || defaultBarva
        out = "<b>Senátní obvod č. #{obvod.data.obvodId}: #{@obvody_meta[obvod.data.obvodId].nazev}</b><br>"
        out += obvod.data.kandidati.slice 0, 2
          .map (kandidat) ->
            "#{kandidat.data.jmeno} <b>#{kandidat.data.prijmeni}</b>: <b>#{utils.percentage kandidat.hlasu / obvod.data.hlasu} %</b> (#{kandidat.data.zkratka}, #{kandidat.hlasu} hl.)"
          .join "<br>"
        out += "<br>Obvod obhajuje #{window.ig.strany[strana].zkratka}"
        out

    @kostiFirst.style \background-color -> it.data.kandidati.0.data.barva
    @kostiSecond.style \background-color -> it.data.kandidati.1.data.barva
    @kostiPrevious.style \background-color ->
      strana = barvy[it.data.obvodId] || defaultBarva
      window.ig.strany[strana].barva

  download: (cb) ->
    (err, data) <~ utils.download "//smzkomunalky.blob.core.windows.net/vysledky/senat.json"
    @data = data
    @data.obvody_array = for obvodId, datum of @data.obvody
      datum.obvodId = (parseInt obvodId, 10) + 2 # HACK, remove
      datum.hlasu = 0
      for senator in datum.kandidati
        datum.hlasu += that if senator.hlasu
        senator.data = @senatori["#{obvodId}-#{senator.id}"]
      datum.kandidati.sort (a, b) -> b.hlasu - a.hlasu
      if datum.kandidati.0.hlasu > datum.hlasu / 2
        datum.obvodDecided = true
      datum
    for datum, index in @data.obvody_array
      @obvody[index].data = datum
    cb?!

  drawEmptyBoxes: ->
    container = @element.append \div
      ..attr \class \kosti
    @kosti = container.selectAll \.kost .data @obvody .enter!append \div
      ..attr \class "kost empty"
    @kostiFirst = @kosti.append \div
      ..attr \class \first
    @kostiSecond = @kosti.append \div
      ..attr \class \second
    @kostiPrevious = @kosti.append \div
      ..attr \class \previous


  parseObvodyMeta: ->
    @obvody_meta = {}
    for line in window.ig.data.senat_obvody.split "\n"
      [id, nazev] = line.split "\t"
      @obvody_meta[id] = {nazev}
