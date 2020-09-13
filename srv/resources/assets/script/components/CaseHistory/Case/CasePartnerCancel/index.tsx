import {h, FunctionalComponent} from 'preact'
import {PartnerCancel} from '../../../types'

type F<T> = FunctionalComponent<T>

type Props = {
  action: PartnerCancel
}

export const CasePartnerCancel: F<Props> = ({action: {refusalreason, refusalcomment,  partnername}}) => {
  return (
    <div>
      <div>
        <i class='glyphicon glyphicon-time'/>
        <b>Отказ партнёра:{`\xa0`}</b>
       {partnername}
      </div>
      <div>
        <b>Причина отказа:{`\xa0`}</b>
        { refusalreason }
        { refusalcomment && `\xa0${refusalcomment}` }
      </div>
    </div>
  )
}
