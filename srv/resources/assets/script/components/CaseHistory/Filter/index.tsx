import {FunctionalComponent, h} from 'preact'
import cn from 'classnames'

type F<T> = FunctionalComponent<T>

type Props = {
  onChange: (type: string) => void
}

export type Button = {
  type: string
  alt: string
  icon: string
  show: boolean
  onChange: (type: string) => void
}

export const Filter: F<Props> = ({onChange}) => {
  const buttons: Button[] = [
    {type: 'action', alt: 'Показать действия', icon: 'briefcase', show: false, onChange},
    {type: 'comment', alt: 'Показать комментарии', icon: 'bullhorn', show: false, onChange},
    {type: 'partnerCancel', alt: 'Показать отказы партнёров', icon: 'remove-circle', show: false, onChange},
    {type: 'partnerDelay', alt: 'Показать опоздания партнёров', icon: 'time', show: false, onChange},
    {type: 'call', alt: 'Показать звонки', icon: 'phone-alt', show: false, onChange},
    {type: 'smsForPartner', alt: 'Показать SMS партнёрам', icon: 'envelope', show: false, onChange},
    {type: 'eraGlonassIncomingCallCard', alt: 'Показать поступления «Карточек Вызова» ЭРА-ГЛОНАСС', icon: 'globe', show: false, onChange},
    {type: 'locationSharingResponse', alt: 'Показать запросы на определение координат', icon: 'map-marker', show: false, onChange},
    {type: 'customerFeedback', alt: 'Показать отзывы клиентов', icon: 'star', show: false, onChange},
  ]
  return (
    <div class='btn-group btn-group-sm' role='group'>
      <Buttons buttons={buttons}/>
    </div>
  )
}

type PropsButtons = {
  buttons: Button[]
}
const Buttons: F<PropsButtons> = ({buttons}) => {
  return (
    <div>{buttons.map(({alt, icon, onChange, show, type}) => <ButtonIcon alt={alt} icon={icon} onChange={onChange} show={show} type={type}/>)}</div>
  )
}

type buttonIcon = {
  type: string
  alt: string
  icon: string
  show: boolean
  onChange: (type: string) => void
}

const ButtonIcon: F<buttonIcon> = ({type, alt, icon, show, onChange}) => {
  return (
    <div class={cn('btn btn-default', {active: show})} alt={alt} onClick={(e) => {
      onChange(type)
    }}>
      <i class={`glyphicon glyphicon-${icon}`}/>
    </div>
  )
}
// .btn.btn-default(
//   title="Показать действия",
//     data-bind=`css: {active: histShowActi}, click: histToggleActi`)
// i.glyphicon.glyphicon-briefcase

type input = {}

const Input: F<input>  = () => {
  return (
    <div>

    </div>
  )
}
