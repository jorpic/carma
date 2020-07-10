{$, _} = require "carma/vendor"
m = require "carma/dictionaries/meta-dict"

debounce = (wait, fn) -> _.debounce fn, wait

class AddressesDict extends m.dict
  constructor: (@opts)->
    @kvm = @opts.kvm
    @Dict = require "carma/dictionaries"
    @addresses = []
    @suggestions = []
    #subscribeCallback = (newValue) -> trySetCoords(newValue)
    @kvm.caseAddress_address.subscribe(((newValue) -> this.trySetCoords(newValue)), this)

  trySetCoords: (newValue) ->
    foundExact = (x for x in @suggestions when x.value == newValue)
    if foundExact.length == 1
      exactData = foundExact[0].data
      @kvm.caseAddress_coords(exactData.geo_lat + ", " + exactData.geo_lon)

  find: debounce 1200, (q, cb, opt) ->
    # too short a query
    return cb({}) if q.length < 4 and not opt?.force

    # query is not short and not in suggestions.
    dataForDD =
           query: q
    originalThis = this # this way it will be captured.
    objForDD =
           url: "https://suggestions.dadata.ru/suggestions/api/4_1/rs/suggest/address"
           type: "post"
           contentType: "application/json"
           data: JSON.stringify(dataForDD)
           headers:
                    Authorization: "Token e0fb6d9a7a7920405c3eeefde7e7d6b529b2b2b9"
           dataType: "json"
           success:  (data) ->
                               originalThis.processAnswer data, cb
    $.ajax (objForDD)

  processAnswer: (data, cb) ->
    @addresses = (x.value for x in data.suggestions)
    @suggestions = data.suggestions
    return cb(@addresses)

#    processResponse = (r) =>
#      @found = []
#
#      if _.isEmpty r
#        ["<span><i class='icon-ban-circle icon-white'></i>&nbsp;Ничего не найдено :(</span>"]
#      else
#        for i in r
#          do (i) =>
#            # fields which matched search query
#            fields = _.filter _.keys(i), (f) ->
#              # upper-casing fixes bug when "contract identifier" is erased
#              # when you select a contract from popup list while your input
#              # contains at least one lowercase symbol.
#              i[f] && String(i[f]).toUpperCase().indexOf(q.toUpperCase()) != -1
#            @found.push
#              id: i.id
#              matched: _.pick(i, fields)
#            @contr2html i, fields, q

    fetchResults = (d) ->
      if !d.nonEmpty
        cb [inlineSpinner "<div class='inline-spinner'></div>"]
      $.getJSON query, (res) ->
        d.nonEmpty = !_.isEmpty res
        items = processResponse res
        d.orig = _.clone items
        cb items
        # Show trailing spinner if ARC query is pending
        if d.needArc
          items.push inlineSpinner "<div class='inline-spinner'></div>"
          cb items

    # We explicitly pass dictionary object so that it is accessible
    # inside fetchResults (we can store original search response
    # this way to use later after ARC loading finishes)
    firstFetch = fetchResults this

    if @needArc
      parentThis = this
      $.getJSON arcQuery
        .always () ->
          parentThis.needArc = false
        .done (ar) ->
          # New contracts? Repeat contract search.
          if ar[0] > 0
            firstFetch.done () ->
              items = parentThis.orig
              items.push inlineSpinner "<div class='inline-spinner'></div>"
              cb items
              fetchResults parentThis
          # Remove trailing spinner
          else
            if parentThis.orig?
              cb parentThis.orig

  # returns html representation of an address
  contr2html: (c, fs = [], q = "") ->
    # make values human readable
    c.make  = @carMakeDict.getLab c.make || c.make
    c.model = @carModelDict.getLab c.model || c.model

    # highlight matched search string
    if (not _.isEmpty fs) and q
      _.each fs, (f) ->
        return if f == "id"
        c[f] = "<span>#{c[f].replace(q, "<span class='finded'>#{q}</span>")}</span>"

    # required fields
    req = ["fromArc"
         , "vin"
         , "make"
         , "model"
         , "startMileage"
         , "validSince"
         , "_expired"
         , "subprogram"
         ]
    html = ""
    # show matched and required fields
    _.each _.union(req, fs), (f) ->
      if c[f]
        switch f
          when "fromArc"
            if c[f]
              html += "<span class='label'>ARC</span> "
          when "vin"
            html += "<b>#{c[f]}</b>"
          when "_expired"
            html += " #{c[f]}"
          when "startMileage"
            html += " [ #{c[f]} км ]"
          when "subprogram"
            html += "<br/>#{c[f]}<br/>"
          when "validSince"
            html += " <i>#{c[f]}</i>"
          else
            html += " #{c[f]}"
    html

  id2val: (i) ->
    return @addresses[i]
    #return unless @found[i]
    # notify @kvm what contract was changed
    #@kvm.contract(@found[i].id)
    #_.chain(@found[i].matched).values().first().value()

module.exports =
  dict: AddressesDict
  name: 'AddressesDict'