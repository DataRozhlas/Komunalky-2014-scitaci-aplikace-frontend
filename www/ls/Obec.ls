window.ig.Obec = class Obec
  (@parentElement) ->
    @element = @parentElement.append \div
      ..attr \class \obec
    @heading = @element.append \h2
      ..html "Pago"
  display: ({lat, lon, id, okres, nazev}) ->
    @heading.html "Výsledky v obci #nazev"
    console.log nazev
