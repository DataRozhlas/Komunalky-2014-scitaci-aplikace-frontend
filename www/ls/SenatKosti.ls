utils = window.ig.utils
window.ig.SenatKosti = class SenatKosti implements utils.supplementalMixin
  (@baseElement) ->
    @element = @baseElement.append \div
      ..attr \class \senatKosti
    @heading = @element.append \h2
      ..html "Průběžné výsledky senatních voleb"
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
      ..attr \data-tooltip (obvod) ~>
        out = "<b>Senátní obvod č. #{obvod.data.obvodId}: #{@obvody_meta[obvod.data.obvodId].nazev}</b><br>"
        out += obvod.data.kandidati.slice 0, 2
          .map (kandidat) ->
            "#{kandidat.data.jmeno} <b>#{kandidat.data.prijmeni}</b>: <b>#{utils.percentage kandidat.hlasu / obvod.data.hlasu} %</b> (#{kandidat.data.zkratka}, #{kandidat.hlasu} hl.)"
          .join "<br>"

    @kostiFirst.style \background-color -> it.data.kandidati.0.data.barva
    @kostiSecond.style \background-color -> it.data.kandidati.1.data.barva

  download: (cb) ->
    (err, data) <~ utils.download "//smzkomunalky.blob.core.windows.net/vysledky/senat.json"
    @data = data
    @data.obvody_array = for obvodId, datum of @data.obvody
      datum.obvodId = obvodId
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


  parseObvodyMeta: ->
    @obvody_meta = {}
    for line in window.ig.data.senat_obvody.split "\n"
      [id, nazev] = line.split "\t"
      @obvody_meta[id] = {nazev}
