import {h, FunctionalComponent} from 'preact'
import {Filter} from './Filter'
import {useEffect, useMemo, useState} from 'preact/hooks'
import {HistoryItem} from './HistoryItem'
import * as Type from './types'

type F<T> = FunctionalComponent<T>

type Props = {
  caseHistory: () => Type.HistoryItem[]
}

export const CaseHistory: F<Props> = ({caseHistory}) => {
  const [type, setType] = useState<string>('')
  const typeFilter = new Set(['comment'])

  const typeAdd = (type: string) => {
    typeFilter.add(type)
    setType('')
  }
  const typeDelete = (type: string) => {
    typeFilter.delete(type)
    setType('')
  }
  useEffect(() => {
    !!type && typeFilter.has(type) ? typeDelete(type) : typeAdd(type)
  }, [type])

  const filteredCaseHistory = caseHistory() && caseHistory().filter(x => typeFilter.has(x[2].type))
  
  return (
    <section>
      <h4 style='float: left'> История по кейсу</h4>
      <div style='float: right'>
        <Filter onChange={setType}/>
      </div>
      <div id='case-history'>
        <div className='well history-item'>
          {filteredCaseHistory.map(data => <Case caseData={data}/>)}
        </div>
      </div>
    </section>
  )
}
