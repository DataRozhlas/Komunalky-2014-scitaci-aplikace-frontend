utils = window.ig.utils
kostiSort = <[mcmo mcmo_2010 obec obec_2010]>
window.ig.Obec = class Obec
  kostSide: 28
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
    topPart = @element.append \div
      ..attr \class \top-vyledky-voleb
    @downloadOldLink = @element.append \div
      ..attr \class \download-old
      ..html "Porovnat s minulými volbami"
      ..on \click @~downloadOld
    @kostiCont = topPart.append \div
      ..attr \class \kostiCont
    mapContainer = @element.append \div
      ..attr \class \map-container
      ..append \h3 .html "Okolí"
    @mapElement = mapContainer.append \div
      ..attr \class \map
    @senatContainer = topPart.append \div
      ..attr \class \senat-container
    @senatHeading = @senatContainer.append \h3 .html "Senátní volby"
    @senatElement = @senatContainer.append \div
      ..attr \class \senat-element
    @initFavouriteStrany!
    @kosti = []
    @kostiAssoc = {}

  display: ({id, okres, nazev}:data) ->
    @currentId = id
    @obecData = data
    @obecData.obvodId = (parseInt data.senatObvod, 10)
    @heading.html "Výsledky v obci #nazev"
    @subHeading.html "okres #{okres.nazev}"
    @setMap data
    @unsetData 'obec_2010'
    @unsetData 'mcmo_2010'
    @download id

  redraw: ->
    top = @drawKosti!
    @drawSenat top

  drawSenat: (top) ->
    if @obecData.obvodId
      if @senatObvod
        if @senatObvod.obvodId == @obecData.obvodId
          @senatContainer.style \top "#{top}px"
          return
        else
          @senatObvod.destroy!
      @senatHeading.html "Senátní volby &ndash; obvod #{window.ig.senat_obvody_meta[@obecData.obvodId].nazev}"
      @senatObvod = new window.ig.SenatObvod @senatElement, @obecData.obvodId
      @senatContainer.classed \hidden no
      @senatContainer.style \top "#{top}px"
    else
      @senatContainer.classed \hidden yes
      @senatElement.html ''
      if @senatObvod
        @senatObvod.destroy!
        @senatObvod = null

  drawKosti: ->
    width = @kostiCont.0.0.offsetWidth - 68
    nadpisMargin = 40px
    kostiX = Math.floor width / @kostSide
    @kosti.sort (a, b) ->
      (kostiSort.indexOf a.type) - (kostiSort.indexOf b.type)
    topCumm = 0
    @kosti.forEach ~>
      it.rows = Math.ceil it.data.zastupitele.length / kostiX
      it.fullType = @getTypeHuman it
      it.top = topCumm
      topCumm += it.rows * @kostSide + nadpisMargin

    @kostiCont.selectAll \div.typ.active .data @kosti, (.fullType)
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
    typy = @kostiCont.selectAll \div.typ.active
      ..style \top ~> it.top + "px"
      ..select \h3
        ..html (.fullType)

    @currentKosti = typy.select \.kosti
      ..style \height -> "#{it.rows * @kostSide}px"
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
    utils.resetStranyColors!
    @currentKost = @currentKosti.selectAll \.kost.active
      ..style \background-color (d) -> utils.getStranaColor d.strana.id, 'd'
      ..style "top" (d) ~>
          "#{(d.index % d.parent.rows) * @kostSide}px"
      ..style "left" (d) ~>
          "#{(Math.floor d.index / d.parent.rows) * @kostSide}px"
      ..classed \changed (d, i, ii) ->
        return false if -1 != @className.indexOf 'activating'
        current = strany[d.strana.id]?barva
        oldKostiBarvy[ii] ?= []
        old = oldKostiBarvy[ii][i]
        oldKostiBarvy[ii][i] = current
        old != current xor -1 != @className.indexOf 'changed'
      ..on \click ~> @toggleFavouriteStrana it.strana.id

      ..attr \data-tooltip ~>
        out = if it.jmeno
          "<b>#{it.jmeno} #{it.prijmeni}</b><br>
          Získal #{it.hlasu} hlasů<br />"
        else
          "<b>Zastupitel za #{@strany[it.strana.id]?.zkratka || it.strana.nazev}</b><br>"
        out += "#{@strany[it.strana.id]?.zkratka || it.strana.nazev} získala #{utils.percentage it.strana.procent} % hlasů, #{it.strana.zastupitelu} zastupitelů<br>"
        out += "<em>Klikněte pro přiřazení strany do koalice</em>"
        out

    if @favouriteStrany.length
      @redrawFifty!
    topCumm

  redrawSortOnly: ->
    width = @kostiCont.0.0.offsetWidth - 68
    kostiX = Math.floor width / @kostSide

    @kosti.forEach  ~>
      it.rows = Math.ceil it.data.zastupitele.length / kostiX
      it.fullType = @getTypeHuman it
    @currentKost
      ..style "top" (d, i, ii) ~>
            "#{(d.index % d.parent.rows) * @kostSide}px"
      ..style "left" (d, i, ii) ~>
          "#{(Math.floor d.index / d.parent.rows) * @kostSide}px"
    @redrawFifty!

  redrawFifty: ->
    @currentKosti.selectAll \div.fiftyHeadline .data (-> [it]) .enter!append \div
      ..attr \class \fiftyHeadline
      ..html "Polovina mandátů"
      ..append \div
        ..attr \class \arrow
    @currentKosti.selectAll \div.fiftyHeadline
      ..style \left (d, i, ii) ~>
        i = d.data.zastupitele.length / 2
        "#{(Math.ceil i / d.rows) * @kostSide}px"
    @currentKosti.selectAll \div.fiftyBg
      .data (-> it.data.zastupitele.slice 0, Math.ceil it.data.zastupitele.length / 2)
        ..exit!remove!
        ..enter!append \div
          ..attr \class \fiftyBg
    @currentKosti.selectAll \div.fiftyBg
      ..style "top" (d, i, ii) ~>
        "#{(i % d.parent.rows) * @kostSide}px"
      ..style "left" (d, i, ii) ~>
        "#{(Math.floor i / d.parent.rows) * @kostSide}px"

  download: (id, cb) ->
    if @cacheItem then @cacheItem.off \downloaded @processData
    @cacheItem = @downloadCache.getItem id
    (err, data) <~ @cacheItem.get!
    @cacheItem.on \downloaded @processData
    @processData data, id

  processData: (data, id) ~>
    return if id and id != @obecData.id
    @data = data
    for type in <[mcmo obec]>
      if data[type]
        @mergeData type, data[type]
      else if @kostiAssoc[type]
        @unsetData type
    @resort!
    @redraw!

  downloadOld: (cb) ->
    id = @currentId
    (err, data) <~ utils.download "//smzkomunalky.blob.core.windows.net/vysledky10/#{id}.json"
    return if err or id != @currentId
    for type in <[mcmo obec]>
      type_suff = type + "_2010"
      if data[type]
        @mergeData type_suff, data[type]
      else if @kostiAssoc[type_suff]
        @unsetData type_suff
    @resort!
    @redraw!


  mergeData: (type, data) ->
    packet = type: type
    packet.data = mergeObvody data, @kostiAssoc[type] || packet
    if @kostiAssoc[type]
      @kostiAssoc[type].data = packet.data
    else
      @kostiAssoc[type] = packet
      @kosti.push packet

  unsetData: (type) ->
    return unless @kostiAssoc[type]
    index = @kosti.indexOf @kostiAssoc[type]
    @kosti.splice index, 1 if index != -1
    delete @kostiAssoc[type]

  resort: ->
    for {data} in @kosti
      data.zastupitele.sort (a, b) ~>
        | (@favouriteStrany.indexOf b.strana.id) - (@favouriteStrany.indexOf a.strana.id) => that
        | a.strana.id - b.strana.id => that
        | a.poradi   - b.poradi   => that
        | a.prijmeni > b.prijmeni => +1
        | a.prijmeni < a.prijmeni => -1
        | otherwise               =>  0
      for zastupitel, index in data.zastupitele
        zastupitel.index = index

  getTypeHuman: ({type}) ->
    | type is "obec" && @data.mcmo => "Magistrát"
    | type is "obec" => "Obecní zastupitelstvo"
    | type is "mcmo" => "Městská část"
    | type is "obec_2010" && @data.mcmo => "Magistrát &ndash; 2010"
    | type is "obec_2010" => "Obecní zastupitelstvo &ndash; 2010"
    | type is "mcmo_2010" => "Městská část &ndash; 2010"

  setMap: (obec) ->
    if @map
      @map.center obec
    else
      @map = new window.ig.ObceMap @mapElement, @downloadCache, @
        ..init obec
    @map.setHighlight obec.id

  initFavouriteStrany: ->
    try
      if window.localStorage?smz_vlb_favStrany
        @favouriteStrany = JSON.parse window.localStorage.smz_vlb_favStrany
    @favouriteStrany ?= []

  toggleFavouriteStrana: (id) ->
    index = @favouriteStrany.indexOf id
    if @favouriteStrany.length and index == @favouriteStrany.length - 1
      @removeFavouriteStrana id
    else
      @removeFavouriteStrana id if index != -1
      @addFavouriteStrana id
    try
      window.localStorage.smz_vlb_favStrany = JSON.stringify @favouriteStrany
    @resort!
    @redrawSortOnly!

  addFavouriteStrana: (id) ->
    @favouriteStrany.push id

  removeFavouriteStrana: (id) ->
    index = @favouriteStrany.indexOf id
    @favouriteStrany.splice index, 1 if index != -1

mergeObvody = (data, parent) ->
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
            parent: parent
      else if strana.zastupitelu
        for zastupitelIndex in [0 til strana.zastupitelu]
          data.zastupitele.push do
            strana: stranaData
            poradi: zastupitelIndex + 1
            parent: parent
  data
