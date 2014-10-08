utils = window.ig.utils
window.ig.Obec = class Obec
  (@parentElement, @strany, @downloadCache) ->
    @element = @parentElement.append \div
      ..attr \class \obec
    @heading = @element.append \h2
    @subHeading = @element.append \h3
      ..attr \class \okres
    @kostiCont = @element.append \div
      ..attr \class \kostiCont
    @element.append \h3
      ..html "Okolí"
    @mapElement = @element.append \div
      ..attr \class \map

  display: ({id, okres, nazev}:data) ->
    @heading.html "Výsledky v obci #nazev"
    @subHeading.html "Okres #{okres.nazev}"
    setTimeout do
      ~> @setMap data
      0
    <~ @download id
    @drawKosti!

  drawKosti: ->
    @kostiCont.selectAll \div.typ .data @data.kosti, (.type)
      ..exit!remove!
      ..enter!append \div
        ..attr \class \typ
        ..append \h3
        ..append \div
          ..attr \class \kosti

    typy = @kostiCont.selectAll \div.typ
      ..select \h3
        ..html @~getTypeHuman

    kosti = typy.select \.kosti
      ..selectAll \.kost .data (.data.zastupitele)
        ..enter!append \div
          ..attr \class \kost
        ..exit!remove!
    kosti.selectAll \.kost
      ..style \background-color ~> @strany[it.strana.id]?barva
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

  download: (id, cb) ->
    (err, data) <~ @downloadCache.get id
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
