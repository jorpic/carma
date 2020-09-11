import {h, FunctionalComponent} from "preact"
import {Case} from './Case'
import {CaseAction} from "./Case/CaseAction";
import {CaseComment} from "./Case/CaseComment";

type F<T> = FunctionalComponent<T>

export type Data = [
  string,
  string,
  {
    caseid: number
    userid: number
    type: 'action' | 'comment' | 'partnerCancel' | 'call' | 'smsForPartner' | 'locationSharingResponse' | 'locationSharingRequest'
    datetime: string
    actioncomment?: string
    commenttext?: string
    actionresult?: string
    actiontype?: string
    servicelabel?: string
    serviceid?: number
    refusalcomment?: string
    refusalreason?: string
    partnername?: string
    calltype?: string
    deliverystatus?: string
    msgtext?: string
    phone?: string
    mtime?: string
    sender?: string
    lat?: number
    lon?: number
    accuracy?: number
    smsSent?: boolean
    tasks?: {
      isChecked: boolean
      id: number
      label: string
    }[]
  }
]

type Props = {
  data: () => Data[]
}

export const CaseHistory: F<Props> = ({data}) =>
  <section>
    <Case>
      {data().map(arr => {
        switch (arr[2].type) {
          case 'action':
            return <CaseAction data={arr}/>

          case 'comment':
            return <CaseComment commenttext={arr[2].commenttext}/>

          case 'partnerCancel':
            return <div>partnerCancel</div>

          case 'call':
            return <div>call</div>

          case 'smsForPartner':
            return <div>smsForPartner</div>

          case 'locationSharingResponse':
            return <div>locationSharingResponse</div>

          case 'locationSharingRequest':
            return <div>locationSharingRequest</div>

          default:
            return <div>Error</div>
        }
      })}
    </Case>
  </section>

