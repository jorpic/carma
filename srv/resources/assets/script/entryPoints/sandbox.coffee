require "carma/vendor"
require "carma-css"

{CaseHistory} = require "carma/components/CaseHistory"
{h, render} = require "preact"

caseHistory = -> require "carma/components/CaseHistory/test-data.json"

component = h CaseHistory, {caseHistory}

render component, document.getElementById("center")
