import {h, FunctionalComponent} from 'preact'
import {SmsForPartner} from '../../../types'

type F<T> = FunctionalComponent<T>

type Props = {
  action: SmsForPartner
}

export const CaseSmsForPartner: F<Props> = ({action: {deliverystatus, msgtext, phone, mtime}}) => {
  return (
    <div>
      <div>
        <i class='glyphicon glyphicon-envelope'/>
        <b>Партнёру отправлено SMS:{`\xa0`}</b>
        {msgtext}
      </div>
      <div>
        <b>Телефон получателя:{`\xa0`}</b>
        {phone}
      </div>
      <div>
        <b>Статус отправки:{`\xa0`}</b>
        {deliverystatus}
        (обновлено: {mtime})
      </div>
    </div>
  )
}
