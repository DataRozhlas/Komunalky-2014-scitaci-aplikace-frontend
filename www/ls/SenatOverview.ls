utils = window.ig.utils
window.ig.SenatOverview = class SenatOverview
  (@parentElement, @downloadCache, @displaySwitcher) ->
    @element = @parentElement.append \div
      ..attr \class \senat
    @scrollable = @element.append \div
      ..attr \class \scrollable
    @scrollable.append \h2
      ..html "Průběžné výsledky senátních voleb"
    @obvody_meta = window.ig.senat_obvody_meta
    @obvodyElm = @scrollable.append \div
      ..attr \class \obvody

    backbutton = utils.backbutton @element
      ..on \click ~> @displaySwitcher.switchTo \firstScreen

    (err, data) <~ @downloadCache.get "senat"
    @obvodElements = {}
    @senatObvody = for obvodId of data.obvody
      @obvodElements[obvodId] = obvodElm = @obvodyElm.append \div
        ..attr \class \obvod
      obvodElm.append \h3
        ..html "#{@obvody_meta[obvodId].nazev}"
      new window.ig.SenatObvod obvodElm, obvodId

  highlight: (obvodId) ->
    obvodId = obvodId.toString!
    for id, obvodElm of @obvodElements
      obvodElm.classed \highlight id == obvodId
      if id == obvodId
        top = obvodElm.0.0.offsetTop
        @scrollable.0.0.scrollTop = top
