utils = window.ig.utils
console.log window.ig.utils
window.ig.Pekac = class Pekac
  (@baseElement) ->
    @element = @baseElement.append \div
      ..attr \class \pekac
    @bars = @element.append \div
      ..attr \class \bars
    @pager = @bars.append \div
      ..attr \class \pager
    @columnWidth = 60px

  redraw: ->
    <~ @download
    @hlasu = @data.hlasu
    @pager.selectAll \div.bar.active .data @data.strany, (.id)
      ..exit!remove!
      ..enter!append \div |> @initElms
    @pager.selectAll \div.bar
      ..style \left ~> "#{@columnWidth * it.index}px"
    <~ setTimeout _, 500


  download: (cb) ->
    (err, data) <~ utils.download "//smzkomunalky.blob.core.windows.net/vysledky/obce.json"
    @data = data
    @data.strany.sort (a, b) -> b.hlasu - a.hlasu
    @data.strany.forEach (d, i) -> d.index = i
    cb!

  initElms: ->
    it
      ..attr \class "bar active"
      ..append \span
        ..attr \class \name
        ..html (.nazev)
      ..append \span
        ..attr \class \result
        ..html ~> utils.percentage it.hlasu / @hlasu
