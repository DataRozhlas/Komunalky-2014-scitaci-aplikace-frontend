window.ig.ObceMap = class ObceMap
  maxZoom: 13
  (@parentElement, @downloadCache, @obec) ->
    @suggester = window.ig.suggester # HACK, use DI
    @displayed = {}

  init: ({lat, lon}:data) ->
    @map = L.map do
      * @parentElement.0.0
      * minZoom: 6
        maxZoom: @maxZoom
        zoom: @maxZoom
        center: {lat, lon}
        maxBounds: [[48.4,11.8], [51.2,18.9]]
    {zoom} = @getView data
    if zoom < @maxZoom
      @map.setView [lat, lon], zoom
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

  center: (data) ->
    {lat, lon, zoom} = @getView data
    @map.setView [lat, lon], zoom

  getView: (data) ->
    {lat, lon} = data
    zoom = @map.getBoundsZoom [[data.south, data.west], [data.north, data.east]]
    {lat, lon, zoom}

  setHighlight: (highlightedObecId) ->
    oldHighlight = @highlightedObecId
    @highlightedObecId = highlightedObecId
    if @displayed[highlightedObecId]
      that.highlight!
    if @displayed[oldHighlight]
      that.downlight!

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
      @draw it, data.geojson, data
        ..layer.on \click (_) ~>
          @obec.display it
    for id, object of @displayed
      if not isInBounds object.obec, bounds
        @map.removeLayer @displayed[id].layer
        delete @displayed[id]

  draw: (obec, geojson, vysledky) ->
    obj = new ObecObj obec, geojson, vysledky, obec.id == @highlightedObecId
      ..layer.addTo @map
    @displayed[obec.id] = obj

class ObecObj
  (@obec, @geojson, vysledky, highlighted) ->
    @id = @obec.id
    color = @getColor vysledky
    @style =
      fill: color
      opacity: if highlighted then 1 else 0.5
      fillOpacity: if highlighted then 0.7 else 0.3
      color: color
      zIndex: if highlighted then 2 else 1
    @layer = L.geoJson @geojson, @style

  highlight: ->
    @layer.setStyle do
      fillOpacity: 0.7
      opacity: 1
      zIndex: 2

  downlight: ->
    @layer.setStyle do
      fillOpacity: 0.3
      opacity: 0.5
      zIndex: 1

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
