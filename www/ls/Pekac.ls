utils = window.ig.utils
window.ig.Pekac = class Pekac
  (@baseElement) ->
    @element = @baseElement.append \div
      ..attr \class \pekac
    @heading = @element.append \h2
      ..html "Průběžné výsledky komunálních voleb"
    @bars = @element.append \div
      ..attr \class \bars
    @pager = @bars.append \div
      ..attr \class \pager
    @drawSupplemental!

    @columnWidth = 60px
    @y = d3.scale.linear!
      ..domain [0 1]
      ..range [1 80]
    @strany = {}
    for line in window.ig.data.strany.split "\n"
      [vstrana, nazev, zkratka, barva] = line.split "\t"
      @strany[vstrana] = {nazev, zkratka, barva}

  redraw: ->
    <~ @download
    if @data.okrsky_celkem == @data.okrsky_spocteno
      @heading.html "Celkové výsledky komunálních voleb"
    @hlasu = @data.hlasu

    sectenoPerc = utils.percentage @data.okrsky_celkem / @data.okrsky_spocteno
    if sectenoPerc == "100,0" and @data.okrsky_celkem != @data.okrsky_spocteno
      sectenoPerc = "99,9"
    @sectenoValue.html "#{sectenoPerc} %"
    @sectenoFill.style \width "#{@data.okrsky_celkem / @data.okrsky_spocteno * 100}%"
    @ucastValue.html   "#{utils.percentage @data.volilo / @data.volicu} %"
    @ucastFill.style \width "#{@data.volilo / @data.volicu * 100}%"

    @pager.selectAll \div.bar.active .data @data.strany, (.id)
      ..exit!remove!
      ..enter!append \div |> @initElms
    @pager.selectAll \div.bar.active
      ..style \left ~> "#{@columnWidth * it.index}px"
      ..select \.barArea
        ..style \height ~> "#{@y it.hlasu}%"
        ..style \background-color ~>
          if it.strana?barva
            that
          else
            void
    <~ setTimeout _, 500


  download: (cb) ->
    (err, data) <~ utils.download "//smzkomunalky.blob.core.windows.net/vysledky/obce.json"
    @data = data
    @data.strany.sort (a, b) -> b.hlasu - a.hlasu
    @data.strany.forEach (d, i) ~>
      d.strana = @strany[d.id]
      d.index = i
    @y.domain [0 @data.strany.0.hlasu]
    cb!

  initElms: ->
    it
      ..attr \class "bar active"
      ..append \div
        ..attr \class \texts
        ..append \span
          ..attr \class \name
          ..html ~> it.strana?zkratka || it.nazev
        ..append \span
          ..attr \class \result
          ..html ~> utils.percentage it.hlasu / @hlasu
      ..append \div
        ..attr \class \barArea

  drawSupplemental: ->
    @supplemental = @element.append \div
      ..attr \class \supplemental
    @secteno = @supplemental.append \div
      ..attr \class \secteno
      ..append \h3 .html "Sečteno"
      ..append \span
        ..attr \class \value
      ..append \div
        ..attr \class \progress
        ..append \div
          ..attr \class \fill
    @sectenoValue = @secteno.select "span.value"
    @sectenoFill = @secteno.select "div.fill"

    @ucast = @supplemental.append \div
      ..attr \class \ucast
      ..append \h3 .html "Účast"
      ..append \span
        ..attr \class \value
      ..append \div
        ..attr \class \progress
        ..append \div
          ..attr \class \fill
    @ucastValue = @ucast.select "span.value"
    @ucastFill = @ucast.select "div.fill"
