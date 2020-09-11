require "carma/vendor"
require "carma-css"

{CaseHistory} = require "carma/components/CaseHistory"
{h, render} = require "preact"

data = -> require "carma/components/CaseHistory/test-data.json"

component = h CaseHistory, {data}

render component, document.getElementById("center")
