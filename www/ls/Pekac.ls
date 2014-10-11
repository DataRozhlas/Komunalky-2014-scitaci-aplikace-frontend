utils = window.ig.utils
window.ig.Pekac = class Pekac implements utils.supplementalMixin
  (@baseElement, @strany, @downloadCache) ->
    @element = @baseElement.append \div
      ..attr \class \pekac
    @heading = @element.append \h2
      ..html "Průběžné výsledky komunálních voleb"
    @bars = @element.append \div
      ..attr \class \bars
    @pager = @bars.append \div
      ..attr \class \pager
    @currentPage = 0
    @toDisplay = "hlasu"

    @drawSwitcher!
    @drawSupplemental!
    @drawPaginator!

    @columnWidth = 60px
    @y = d3.scale.linear!
      ..domain [0 1]
      ..range [1 80]

  redraw: ->
    if @data.okrsky_celkem == @data.okrsky_spocteno
      @heading.html "Celkové výsledky komunálních voleb"
    @hlasu = @data.hlasu

    @updateSupplemental!

    @pager.selectAll \div.bar.active .data @data.strany, (.id)
      ..exit!remove!
      ..enter!append \div |> @initElms
    utils.resetStranyColors!
    @pager.selectAll \div.bar.active
      ..style \left ~> "#{@columnWidth * it.index}px"
      ..attr \data-tooltip ~>
        "<b>#{it.nazev}</b><br>
        Získala #{utils.percentage it.hlasu / @hlasu}&nbsp;% hlasů a&nbsp;#{it.zastupitelu}&nbsp;zastupitelů"
      ..select \.barArea
        ..style \height ~> "#{@y it[@toDisplay]}%"
      ..select \.result
        ..html ~>
          if @toDisplay == "hlasu"
            "#{utils.percentage it.hlasu / @hlasu}&nbsp;%"
          else
            "#{it.zastupitelu}"

  init: ->
    @cacheItem = @downloadCache.getItem "obce"
    (err, data) <~ @cacheItem.get
    @cacheItem.on \downloaded @~saveData
    @saveData data

  saveData: (data) ->
    @data = data if data
    @data.strany.sort (a, b) ~> b[@toDisplay] - a[@toDisplay]
    @data.strany.forEach (d, i) ~>
      d.strana = @strany[d.id]
      d.index = i

    @y.domain [0 @data.strany.0[@toDisplay]] if @data.strany.length
    @nextPage.classed \disabled @data.strany.length == 0
    @redraw!

  initElms: ->
    it
      ..attr \class "bar active"
      ..append \div
        ..attr \class \texts
        ..append \span
          ..attr \class \name
          ..html ~>
            if it.strana?zkratka
              that
            else
              it.nazev.replace "Sdružení " "" .split " " .slice 0, 2 .join " "
        ..append \span
          ..attr \class \result
      ..append \div
        ..attr \class \barArea
        ..append \div
          ..attr \class \barColor
          ..style \background-color ~>
            utils.getStranaColor it.strana

  movePage: (dir) ->
    @currentPage -= dir
    @pager.style \left "#{@currentPage * 100}%"
    if @currentPage == 0
      @prevPage.classed \disabled true
      <~ setTimeout _, 800
      @prevPage.classed \removed true
    else
      @prevPage.classed \removed false
      <~ setTimeout _, 800
      @prevPage.classed \disabled false

  drawPaginator: ->
    @nextPage = @element.append \div
      ..attr \class "paginator next"
      ..on \click ~> @movePage +1
    @prevPage = @element.append \div
      ..attr \class "paginator prev disabled removed"
      ..on \click ~> @movePage -1

  drawSwitcher: ->
    @element.append \div
      ..attr \class \switcher
      ..selectAll \label .data ["hlasu", "zastupitelu"] .enter!append \label
        ..append \input
          ..attr \type \radio
          ..attr \name \switcher
          ..attr \checked (d, i) -> if d == "hlasu" then "checked" else void
          ..on \click ~>
            @toDisplay = it
            @saveData!
        ..append \span
          ..html ->
            | it is "hlasu" => "Řadit podle obdržených hlasů"
            | it is "zastupitelu" => "Řadit podle získaných mandátů"
