import {h, FunctionalComponent} from 'preact'
import {PartnerDelay} from '../../../types'

type F<T> = FunctionalComponent<T>

type Props = {
  action: PartnerDelay
}

export const CasePartnerDelay: F<Props> = ({action: {delayconfirmed, delayminutes, partnername}}) => {
  return (
    <div>
      <div>
        <i class='glyphicon glyphicon-time'/>
        <b>Опоздание партнёра:{`\xa0`}</b>
       {partnername}
      </div>
      <div>
        <b>Время опоздания:{`\xa0`}</b>
        {delayminutes}
      </div>
      <div>
        <b>Опоздание согласовано:{`\xa0`}</b>
        {delayconfirmed}
      </div>
    </div>
  )
}
