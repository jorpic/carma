import {h, FunctionalComponent} from 'preact'
import {Case} from './Case'
import {HistoryItem} from './types'
import {Filter} from './Filter'
import {useEffect, useMemo, useState} from 'preact/hooks'

type F<T> = FunctionalComponent<T>

type Props = {
  caseHistory: () => HistoryItem[]
}

export const CaseHistory: F<Props> = ({caseHistory}) => {
  const [typeFilter, setTypeFilter] = useState<Set<string>>(new Set())
  const toggleFilter = (key: string) => {
    // FIXME: Good use case for immutable data structures like `immutable.js`.
    typeFilter.has(key) ? typeFilter.delete(key) : typeFilter.add(key)
    setTypeFilter(new Set(typeFilter))
  }

  const filteredCaseHistory = caseHistory()
    .filter(([_time, _user, {type}]) => typeFilter.has(type))

  return (
    <section>
      <h4 style='float: left'> История по кейсу</h4>
      <div style='float: right'>
        <Filter onChange={toggleFilter}/>
      </div>
      <div id='case-history'>
        <div className='well history-item'>
          {filteredCaseHistory.map(data => <Case caseData={data}/>)}
        </div>
      </div>
    </section>
  )
}
