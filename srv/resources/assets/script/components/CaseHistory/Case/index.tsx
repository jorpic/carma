import {h, FunctionalComponent} from 'preact'
import {useMemo} from 'preact/hooks'
import moment from 'moment'
import {CaseCall} from './CaseCall'
import {CaseAction} from './CaseAction'
import {CaseComment} from './CaseComment'
import {CasePartnerDelay} from './CasePartnerDelay'
import {CaseSmsForPartner} from './CaseSmsForPartner'
import {CasePartnerCancel} from './CasePartnerCancel'
import {CaseLocationSharingRequest} from './CaseLocationSharingRequest'
import {CaseLocationSharingResponse} from './CaseLocationSharingResponse'
import {HistoryItem} from '../../types'

type F<T> = FunctionalComponent<T>

type Props = {
  caseData: HistoryItem
}

export const Case: F<Props> = ({caseData}) => {

  const [date, name, data] = caseData

  const sortByTypeData = useMemo(() => {

    switch (data.type) {
      case 'action': {
        return <CaseAction action={data}/>
      }

      case 'comment': {
        return <CaseComment action={data}/>
      }

      case 'partnerDelay': {
        return <CasePartnerDelay action={data}/>
      }

      case 'partnerCancel': {
        return <CasePartnerCancel action={data}/>
      }

      case 'call': {
        return <CaseCall action={data}/>
      }

      case 'smsForPartner': {
        return <CaseSmsForPartner action={data}/>
      }

      case 'locationSharingResponse': {
        return <CaseLocationSharingResponse action={data}/>
      }

      case 'locationSharingRequest': {
        return <CaseLocationSharingRequest action={data}/>
      }

      default:
        return <div>Error</div>
    }
  }, [caseData])

  return (
    <div class='history-body'>
      <div
        style='float: left'>{moment.utc(date).local().format('DD.MM.YYYY HH:mm:ss')}</div>
      <div style='float: right'>{name}</div>
      {`\xa0`}
      {sortByTypeData}
    </div>
  )
}

