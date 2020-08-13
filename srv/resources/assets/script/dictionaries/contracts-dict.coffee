{$, _} = require "carma/vendor"
m = require "carma/dictionaries/meta-dict"

debounce = (wait, fn) -> _.debounce fn, wait

class ContractsDict extends m.dict
  constructor: (@opts)->
    @kvm = @opts.kvm
    @Dict = require "carma/dictionaries"
    @carMakeDict = new @Dict.dicts.ModelDict
      dict: 'CarMake'
    @carModelDict = new @Dict.dicts.ModelDict
      dict: 'CarModel'

  find: debounce 1200, (q, cb, opt) ->
    return cb({}) if q.length < 4 and not opt?.force
    qr = q.trim().replace(/\+/g, "%2B")
    return cb({}) if qr.match /^0*$/
    params = "program=#{@kvm.program?()}&subprogram=#{@kvm.subprogram?()}"
    query = "/searchContracts/?query=#{qr}&case=#{@kvm.id?()}&#{params}"

    @orig = null
    @nonEmpty = false

    processResponse = (r) =>
      @found = []

      if _.isEmpty r
        ["<span><i class='icon-ban-circle icon-white'></i>&nbsp;Ничего не найдено :(</span>"]
      else
        for i in r
          do (i) =>
            # fields which matched search query
            fields = _.filter _.keys(i), (f) ->
              # upper-casing fixes bug when "contract identifier" is erased
              # when you select a contract from popup list while your input
              # contains at least one lowercase symbol.
              i[f] && String(i[f]).toUpperCase().indexOf(q.toUpperCase()) != -1
            @found.push
              id: i.id
              matched: _.pick(i, fields)
            @contr2html i, fields, q

    fetchResults = (d) ->
      if !d.nonEmpty
        cb [inlineSpinner "<div class='inline-spinner'></div>"]
      $.getJSON query, (res) ->
        d.nonEmpty = !_.isEmpty res
        items = processResponse res
        d.orig = _.clone items
        cb items

    # We explicitly pass dictionary object so that it is accessible
    # inside fetchResults (we can store original search response
    # this way to use later after ARC loading finishes)
    firstFetch = fetchResults this

  # returns html representation of contract
  contr2html: (c, fs = [], q = "") ->
    # make values human readable
    c.make  = @carMakeDict.getLab c.make || c.make
    c.model = @carModelDict.getLab c.model || c.model

    if c.subprogram
      subprogramDict = new @Dict.dicts.ComputedDict
        dict: "prefixedSubPrograms"
      c.subprogram = subprogramDict.getLab c.subprogram

    c._expired = do ->
      if _.isNull c._expired
        ""
      if c._expired
        "<span class='label label-danger'>Проверить участие</span>"
      else
        "<span class='label label-success'>Проверить условия</span>"

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
    return unless @found[i]
    # notify @kvm what contract was changed
    @kvm.contract(@found[i].id)
    _.chain(@found[i].matched).values().first().value()

module.exports =
  dict: ContractsDict
  name: 'ContractsDict'
