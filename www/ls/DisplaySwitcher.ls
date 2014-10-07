window.ig.DisplaySwitcher = class DisplaySwitcher
  ({@firstScreen, @obec}) ->

  switchTo: (target) ->
    switch target
    | "firstScreen"
      ...
    | "senat"
      ...
    | otherwise
      @obec.display target
      @setActive "obec"

  setActive: (activeField) ->
    for field in <[firstScreen obec]>
      continue if field is activeField
      @[field].element.classed \disabled true
    @[activeField].element.classed \disabled false
