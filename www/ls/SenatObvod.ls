window.ig.SenatObvod = class SenatObvod
  (@parentElement, obvodId) ->
    @resource = window.ig.downloadCache.getItem "senat" # fuck DI!
    @element = @parentElement.append \div
      ..attr \class \senat-obvod
    (err, data) <~ @resource.get
    @onDownload data
    @resource.on \downloaded @onDownload

  onDownload: (data) ~>


  destroy: ->
    @resource.off \downloaded @onDownload


