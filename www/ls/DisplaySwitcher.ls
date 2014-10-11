window.ig.DisplaySwitcher = class DisplaySwitcher
  ({@firstScreen, @obec, @senat}) ->

  switchTo: (target, ...args) ->
    switch target
    | "firstScreen"
      @setActive "firstScreen"
    | "senat"
      @setActive "senat"
      if args.length
        @senat.highlight ...args
      else
        @senat.top!
    | otherwise
      @obec.display target
      @setActive "obec"

  setActive: (activeField) ->
    for field in <[firstScreen obec senat]>
      continue if field is activeField
      @[field].element.classed \disabled true
    @[activeField].element.classed \disabled false
