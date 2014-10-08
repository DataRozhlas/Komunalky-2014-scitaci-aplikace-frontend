window.ig.ObceMap = class ObceMap
  (@parentElement, @downloadCache, @obec) ->
    @suggester = window.ig.suggester # HACK, use DI
    @displayed = {}

  init: (coords) ->
    @map = L.map @parentElement.0.0, minZoom: 6, maxZoom:13, zoom:13, center: coords, maxBounds: [[48.4,11.8], [51.2,18.9]]
    @mapInited = true
    baseLayer = L.tileLayer do
      * "https://samizdat.cz/tiles/ton_b1/{z}/{x}/{y}.png"
      * zIndex: 1
        opacity: 1
        attribution: 'mapová data &copy; přispěvatelé <a target="_blank" href="http://osm.org">OpenStreetMap</a>, obrazový podkres <a target="_blank" href="http://stamen.com">Stamen</a>, <a target="_blank" href="https://samizdat.cz">Samizdat</a>'
    labelLayer = L.tileLayer do
      * "https://samizdat.cz/tiles/ton_l1/{z}/{x}/{y}.png"
      * zIndex: 3
    @map
      ..addLayer baseLayer
      ..addLayer labelLayer
      ..on \moveend @~onMapMove
    @onMapMove!

  center: (coords) ->
    @map.setView coords

  setHighlight: (@highlightedObecId) ->

  onMapMove: ->
    return if @map.getZoom! < 11
    suggestions = @suggester.suggestions
    bounds = @map.getBounds!
    bounds =
      "west"  : bounds.getWest!
      "east"  : bounds.getEast!
      "north" : bounds.getNorth!
      "south" : bounds.getSouth!
    toDisplay = suggestions.filter ~>
      (isInBounds it, bounds) and not @displayed[it.id]
    toDisplay.forEach ~>
      (err, data) <~ @downloadCache.get it.id
      return if err
      @draw it.id, data.geojson, data
        ..layer.on \click (_) ~>
          @obec.display it

  draw: (id, geojson, obec) ->
    obj = new ObecObj id, geojson, obec, id == @highlightedObecId
      ..layer.addTo @map
    @displayed[id] = obj

class ObecObj
  (@id, @geojson, obec, highlighted) ->
    color = @getColor obec
    @style =
      fill: color
      opacity: if highlighted then 1 else 0.5
      fillOpacity: if highlighted then 0.7 else 0.3
      color: color
      zIndex: if highlighted then 2 else 1
    @layer = L.geoJson @geojson, @style

  getColor: (obecData) ->
    strany_hlasy = {}
    topHlasu = 0
    topStrana = null
    field = obecData.mcmo || obecData.obec
    for obvod in field.obvody
      for strana in obvod.strany
        strany_hlasy[strana.id] ?= 0
        strany_hlasy[strana.id] += strana.hlasu
        if strany_hlasy[strana.id] > topHlasu
          topHlasu = strany_hlasy[strana.id]
          topStrana = strana
    window.ig.strany[topStrana.id]?barva || '#aaa'

isInBounds = (needle, haystack) ->
  needle.north > haystack.south and needle.south < haystack.north and
    needle.east > haystack.west and needle.west < haystack.east
