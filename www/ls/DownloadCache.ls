window.ig.DownloadCache = class DownloadCache
  ->
    @items = {}
    @prefix = "//smzkomunalky.blob.core.windows.net/vysledky/"

  get: (dataType, cb) ->
    item = if @items[dataType] then that else @create dataType
    <~ item.get
    cb null, item.data

  create: (dataType) ->
    url = switch dataType
      | "senat"
        ...
      | "obce"
        ...
      | otherwise
        @prefix + dataType + ".json"
    @items[dataType] = new CacheItem url

  invalidate: (dataType) ->
    @items[dataType]?.invalidate!


class CacheItem
  (@url) ->
    window.ig.Events @
    @valid = no
    @downloading = no
    @data = null

  get: (cb) ->
    if @valid
      cb null, @data
    else
      <~ @download!
      cb null @data

  download: (cb) ->
    @downloading = yes
    (err, data) <~ window.ig.utils.download @url
    @valid = yes
    @downloading = no
    @data = data
    @emit \downloaded
    cb null data

  invalidate: ->
    ...