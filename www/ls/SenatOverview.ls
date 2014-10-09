utils = window.ig.utils
window.ig.SenatOverview = class SenatOverview
  (@parentElement, @downloadCache, @displaySwitcher) ->
    @element = @parentElement.append \div
      ..attr \class \senat
    @element.append \h2
      ..html "Průběžné výsledky senátních voleb"
    backbutton = utils.backbutton @element
      ..on \click ~> @displaySwitcher.switchTo \firstScreen
