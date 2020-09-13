import {h, FunctionalComponent} from 'preact'
import {Call} from '../../../types'

type F<T> = FunctionalComponent<T>

type Props = {
  action: Call
}

export const CaseCall: F<Props> = ({action: {calltype}}) => {
  return (
    <div>
      <i class='glyphicon glyphicon-phone-alt'/>
      <b>Звонок:</b>
      {`\xa0`}
      {calltype}
    </div>
  )
}
