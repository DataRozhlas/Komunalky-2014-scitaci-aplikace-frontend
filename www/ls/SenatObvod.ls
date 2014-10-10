utils = window.ig.utils
window.ig.SenatObvod = class SenatObvod
  (@parentElement, @obvodId) ->
    @senatori = window.ig.senatori
    @resource = window.ig.downloadCache.getItem "senat" # fuck DI!
    @element = @parentElement.append \div
      ..attr \class \senat-obvod
    @kandidatiElm = @element.append \div
      ..attr \class \kandidati
    (err, data) <~ @resource.get
    @onDownload data
    @resource.on \downloaded @onDownload

  onDownload: (data) ~>
    @data = data.obvody[@obvodId]
    return unless @data
    @kandidati = @data.kandidati
    @kandidati.sort (a, b) -> b.hlasu - a.hlasu
    @kandidatiElm.selectAll \span.kandidat .remove!
    celkemHlasu = 0
    @kandidati.forEach ~>
      it.data = @senatori["#{@obvodId}-#{it.id}"]
      celkemHlasu += it.hlasu
    @kandidatiElm.selectAll \span.kandidat .data @kandidati .enter!append \span
      ..attr \class (d, i) -> "kandidat kandidat-#i"
      ..append \span
        ..attr \class \name
        ..html ~>
          if it.data
            "#{it.data.jmeno} #{it.data.prijmeni}"
          else
            "Zatím neznámý"
      ..append \span
        ..attr \class \procent
        ..html ~> " #{utils.percentage it.hlasu / celkemHlasu} %"
      ..append \span
        ..attr \class \strana-kost
        ..style \background-color ~> it.data?barva || '#aaa'
      ..append \span
        ..attr \class \strana
        ..html ~>
          if it.data
            " (#{it.data.zkratka || it.data.strana})"
          else
            void
      ..append \span
        ..attr \class \delim
        ..html ", "

  destroy: ->
    @element.remove!
    @resource.off \downloaded @onDownload

