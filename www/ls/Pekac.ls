window.ig.Pekac = class Pekac
  (@baseElement) ->

  redraw: ->
    @download!

  download: ->
    (err, data) <~ window.ig.utils.download "//smzkomunalky.blob.core.windows.net/vysledky/obce.json"
