import {h, FunctionalComponent} from 'preact'
import {HistoryItem} from './HistoryItem'
import * as Type from './types'
import {BtnGroup, BtnSpec} from './BtnGroup'
import {useState} from 'preact/hooks'

type Props = {
  caseHistory: () => Type.HistoryItem[]
}

const filterSpec: BtnSpec[] = [
  { key: 'action',
    name: 'Показать действия',
    icon: 'briefcase' },
  { key: 'comment',
    name: 'Показать комментарии',
    icon: 'bullhorn' },
  { key: 'partnerCancel',
    name: 'Показать отказы партнёров',
    icon: 'remove-circle' },
  { key: 'partnerDelay',
    name: 'Показать опоздания партнёров',
    icon: 'time' },
  { key: 'call',
    name: 'Показать звонки',
    icon: 'phone-alt' },
  { key: 'smsForPartner',
    name: 'Показать SMS партнёрам',
    icon: 'envelope' },
  { key: 'eraGlonassIncomingCallCard',
    name: 'Показать поступления «Карточек Вызова» ЭРА-ГЛОНАСС',
    icon: 'globe' },
  { key: 'locationSharingResponse',
    name: 'Показать запросы на определение координат',
    icon: 'map-marker' },
  { key: 'customerFeedback',
    name: 'Показать отзывы клиентов',
    icon: 'star' }
]

export const CaseHistory: FunctionalComponent<Props> = ({caseHistory}) => {
  const [typeFilter, setTypeFilter] = useState<Set<string>>(
    // All type filters are active by default
    new Set(filterSpec.map(f => f.key))
  )
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
        <BtnGroup
          buttons={filterSpec}
          activeButtons={typeFilter}
          onChange={toggleFilter}/>
      </div>
      <div id='case-history'>
        <div className='well history-item'>
          {filteredCaseHistory.map(i => <HistoryItem data={i}/>)}
        </div>
      </div>
    </section>
  )
}
