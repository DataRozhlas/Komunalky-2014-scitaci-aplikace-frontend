utils = window.ig.utils
window.ig.Obec = class Obec
  (@parentElement, @strany, @downloadCache, @displaySwitcher) ->
    @element = @parentElement.append \div
      ..attr \class \obec
    backbutton = utils.backbutton @element
      ..on \click ~> @displaySwitcher.switchTo \firstScreen
    headingGroup = @element.append \div
      ..attr \class \headings
    @heading = headingGroup.append \h2
    @subHeading = headingGroup.append \h3
      ..attr \class \okres
    @kostiCont = @element.append \div
      ..attr \class \kostiCont
    mapContainer = @element.append \div
      ..attr \class \map-container
      ..append \h3 .html "Okolí"
    @mapElement = mapContainer.append \div
      ..attr \class \map
    @senatContainer = @element.append \div
      ..attr \class \senat-container
      ..append \h3 .html "Senátní volby"
    @senatElement = @senatContainer.append \div
      ..attr \class \senat-element

  display: ({id, okres, nazev}:data) ->
    @obecData = data
    @heading.html "Výsledky v obci #nazev"
    @subHeading.html "okres #{okres.nazev}"
    @setMap data
    <~ @download id
    top = @drawKosti!
    @drawSenat top

  drawSenat: (top) ->
    if @obecData.senatObvod
      @senatObvod = new window.ig.SenatObvod @senatElement
      @senatContainer.classed \hidden no
      @senatContainer.style \top "#{top}px"
    else
      @senatContainer.classed \hidden yes
      @senatElement.html ''
      @senatObvod.destroy!

  drawKosti: ->
    width = @kostiCont.0.0.offsetWidth
    kostSide = 28px
    nadpisMargin = 50px
    kostiX = Math.floor width / kostSide
    @data.kosti.forEach ~>
      it.rows = Math.ceil it.data.zastupitele.length / kostiX
      it.fullType = @getTypeHuman it
    @kostiCont.selectAll \div.typ.active .data @data.kosti, (.fullType)
      ..exit!
        ..classed \active no
        ..classed \deactivating yes
        ..transition!
          ..delay 600
          ..remove!
      ..enter!append \div
        ..attr \class "typ active"
        ..append \h3
        ..append \div
          ..attr \class \kosti
    topCumm = 0
    typy = @kostiCont.selectAll \div.typ.active
      ..style \top ->
        top = topCumm
        topCumm += it.rows * kostSide + nadpisMargin
        top + "px"
      ..select \h3
        ..html (.fullType)

    kosti = typy.select \.kosti
      ..style \height -> "#{it.rows * kostSide}px"
      ..selectAll \.kost.active .data (.data.zastupitele)
        ..enter!append \div
          ..attr \class "kost active activating"
          ..transition!
            ..delay 10
            ..attr \class "kost active"
        ..exit!
          ..classed \active no
          ..classed \deactivating yes
          ..transition!
            ..delay 600
            ..remove!
    @oldKostiBarvy ?= []
    oldKostiBarvy = @oldKostiBarvy
    strany = @strany
    kosti.selectAll \.kost.active
      ..style \background-color (d) -> strany[d.strana.id]?barva
      ..style "top" (d, i, ii) ~>
          "#{(i % @data.kosti[ii].rows) * kostSide}px"
      ..style "left" (d, i, ii) ~>
          "#{(Math.floor i / @data.kosti[ii].rows) * kostSide}px"
      ..classed \changed (d, i, ii) ->
        return false if -1 != @className.indexOf 'activating'
        current = strany[d.strana.id]?barva
        oldKostiBarvy[ii] ?= []
        old = oldKostiBarvy[ii][i]
        oldKostiBarvy[ii][i] = current
        old != current xor -1 != @className.indexOf 'changed'

      ..attr \data-tooltip ~>
        if it.jmeno
          "<b>#{it.jmeno} #{it.prijmeni}</b><br>
          Získal #{it.hlasu} hlasů<br />
          #{@strany[it.strana.id]?.zkratka || it.strana.nazev} získala #{utils.percentage it.strana.procent} % hlasů, #{it.strana.zastupitelu} zastupitelů<br>
          "
        else
          "<b>Zastupitel za #{@strany[it.strana.id]?.zkratka || it.strana.nazev}<br></b>
          #{@strany[it.strana.id]?.zkratka || it.strana.nazev} získala #{utils.percentage it.strana.procent} % hlasů, #{it.strana.zastupitelu} zastupitelů<br>
          "
    topCumm

  download: (id, cb) ->
    (err, data) <~ @downloadCache.get id
    return if id != @obecData.id
    @data = data
    @data.kosti = []
    for type in <[mcmo obec]>
      if data[type]
        @data.kosti.push do
          type: type
          data: mergeObvody that
    cb?!

  getTypeHuman: ({type}) ->
    | type is "obec" && @data.mcmo => "Magistrát"
    | type is "obec" => "Obecní zastupitelstvo"
    | type is "mcmo" => "Městská část"


  setMap: (obec) ->
    if @map
      @map.center obec
    else
      @map = new window.ig.ObceMap @mapElement, @downloadCache, @
        ..init obec
    @map.setHighlight obec.id

mergeObvody = (data) ->
  data.zastupitele = []
  for obvod in data.obvody
    obvod.hlasu = 0
    for strana in obvod.strany => obvod.hlasu += strana.hlasu
    for strana in obvod.strany
      stranaData =
        id: strana.id
        nazev: strana.nazev
        hlasu: strana.hlasu
        procent: strana.hlasu / obvod.hlasu
        zastupitelu: strana.zastupitelu
      if strana.zastupitele
        for zastupitel, zastupitelIndex in strana.zastupitele
          data.zastupitele.push do
            jmeno: zastupitel.jmeno
            prijmeni: zastupitel.prijmeni
            strana: stranaData
            poradi: zastupitelIndex + 1
            hlasu: zastupitel.hlasu
      else if strana.zastupitelu
        for zastupitelIndex in [0 til strana.zastupitelu]
          data.zastupitele.push do
            strana: stranaData
            poradi: zastupitelIndex + 1
  data.zastupitele.sort (a, b) ->
    | a.strana.id - b.strana.id => that
    | a.poradi   - b.poradi   => that
    | a.prijmeni > b.prijmeni => +1
    | a.prijmeni < a.prijmeni => -1
    | otherwise               =>  0
  data
