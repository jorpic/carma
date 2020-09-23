import {h, FunctionalComponent} from 'preact'
import {useState} from 'preact/hooks'
import {Filter, BtnSpec} from './Filter'
import {HistoryItem} from './HistoryItem'
import * as Type from './types'

type F<T> = FunctionalComponent<T>

type Props = {
  caseHistory: () => Type.HistoryItem[]
}

const filterSpec: BtnSpec[] = [
  {
    key: 'action',
    name: 'Показать действия',
    icon: 'briefcase'
  },
  {
    key: 'comment',
    name: 'Показать комментарии',
    icon: 'bullhorn'
  },
  {
    key: 'partnerCancel',
    name: 'Показать отказы партнёров',
    icon: 'remove-circle'
  },
  {
    key: 'partnerDelay',
    name: 'Показать опоздания партнёров',
    icon: 'time'
  },
  {
    key: 'call',
    name: 'Показать звонки',
    icon: 'phone-alt'
  },
  {
    key: 'smsForPartner',
    name: 'Показать SMS партнёрам',
    icon: 'envelope'
  },
  {
    key: 'eraGlonassIncomingCallCard',
    name: 'Показать поступления «Карточек Вызова» ЭРА-ГЛОНАСС',
    icon: 'globe'
  },
  {
    key: 'locationSharing',
    name: 'Показать запросы на определение координат',
    icon: 'map-marker'
  },
  {
    key: 'customerFeedback',
    name: 'Показать отзывы клиентов',
    icon: 'star'
  }
]

export const CaseHistory: F<Props> = ({caseHistory}) => {
  const [typeFilter, setTypeFilter] = useState<Set<string>>(
    new Set(filterSpec.map(f => f.key))
  )
  const toggleFilter = (key: string) => {
    typeFilter.has(key) ? typeFilter.delete(key) : typeFilter.add(key)
    setTypeFilter(new Set(typeFilter))
  }

  const filteredCaseHistory = caseHistory()
    .filter(([_time, _user, {type}]) =>
      (type === 'avayaEvent' && typeFilter.has('call'))
      || (type.startsWith('locationSharing') && typeFilter.has('locationSharing'))
      || typeFilter.has(type))

  return (
    <div id='case-history'>
      <h4 style='float: left'>История по кейсу</h4>
      <div style='float: right'>
        <Filter buttons={filterSpec} activeButtons={typeFilter} onChange={toggleFilter}/>
      </div>
      <div style="clear:both"/>
      {filteredCaseHistory.map(i => <HistoryItem historyData={i}/>)}
      <a class='more' href='#'>Ещё</a>
    </div>
  )
}
