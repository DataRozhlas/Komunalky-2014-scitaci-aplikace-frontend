tooltip = new Tooltip!
window.ig.ObceMap = class ObceMap
  maxZoom: 13
  maxZoomWithFeatures: 11
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
      ..on \zoomend ~>
        if @map.getZoom! < @maxZoomWithFeatures
          for id, object of @displayed
            @undraw id
    @onMapMove!

  center: (data) ->
    {lat, lon, zoom} = @getView data
    @map.setView [lat, lon]#, zoom

  getView: (data) ->
    {lat, lon} = data
    zoom = @map.getBoundsZoom [[data.south, data.west], [data.north, data.east]]
    if zoom < @maxZoomWithFeatures
      zoom = @maxZoomWithFeatures
    {lat, lon, zoom}

  setHighlight: (highlightedObecId) ->
    return if @displayed[highlightedObecId]?obj.highlighted
    oldHighlight = @highlightedObecId
    @highlightedObecId = highlightedObecId
    if @displayed[highlightedObecId]
      that.obj.highlight!
    if @displayed[oldHighlight]
      that.obj.downlight!

  onMapMove: ->
    return if @map.getZoom! < @maxZoomWithFeatures
    suggestions = @suggester.suggestions
    bounds = @map.getBounds!
    bounds =
      "west"  : bounds.getWest!
      "east"  : bounds.getEast!
      "north" : bounds.getNorth!
      "south" : bounds.getSouth!
    toDisplay = suggestions.filter ~>
      (isInBounds it, bounds) and not @displayed[it.id]
    toDisplay.forEach @~draw
    for id, object of @displayed
      if not isInBounds object.obj.obec, bounds
        @undraw id

  undraw: (id) ->
    {obj, cacheItem, handler} = @displayed[id]
    return unless obj
    @map.removeLayer obj.layer
    cacheItem.off \downloaded handler
    delete @displayed[id]

  draw: (obec) ->
    cacheItem = if @displayed[obec.id] then that.cacheItem else @downloadCache.getItem obec.id
    (err, data) <~ cacheItem.get!
    return if err
    return unless data && data.geojson
    geojson = data.geojson
    vysledky = data
    obj = new ObecObj obec, geojson, vysledky, obec.id == @highlightedObecId
      ..layer
        ..addTo @map
        ..on \click (_) ~> @obec.display obec
        ..on \mouseover (_)  ~> tooltip.display obec.nazev
        ..on \mouseout ~> tooltip.hide!
    handler = (vysledky) ->
      obj.setData vysledky
    cacheItem.on \downloaded handler
    @displayed[obec.id] = {obj, cacheItem, handler}

class ObecObj
  (@obec, @geojson, vysledky, @highlighted) ->
    @id = @obec.id
    @color = @getColor vysledky
    @layer = L.geoJson @geojson, @getStyle!

  highlight: ->
    @highlighted = true
    @layer.setStyle @getStyle!

  downlight: ->
    @highlighted = false
    @layer.setStyle @getStyle!

  setData: (vysledky) ->
    @color = @getColor vysledky
    @layer.setStyle @getStyle!

  getStyle: ->
    @style =
      fill: @color
      weight: 2
      opacity: if @highlighted then 1 else 0.5
      fillOpacity: if @highlighted then 0.7 else 0.3
      color: @color
      zIndex: if @highlighted then 2 else 1

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
    if topStrana
      window.ig.strany[topStrana.id]?barva || '#aaa'
    else
      '#fff'

isInBounds = (needle, haystack) ->
  needle.north > haystack.south and needle.south < haystack.north and
    needle.east > haystack.west and needle.west < haystack.east
