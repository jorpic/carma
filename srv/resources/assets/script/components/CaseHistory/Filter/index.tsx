import {FunctionalComponent, h} from 'preact'
import cn from 'classnames'

type F<T> = FunctionalComponent<T>

type ForButtons = {
  buttons: BtnSpec[]
  activeButtons: Set<string>
  onChange(key: string): void
}

type Props = ForButtons

export type BtnSpec = {
  key: string
  name: string
  icon: string
}

export const Filter: F<Props> = ({onChange, activeButtons, buttons}) => {
  return (
    <div class='btn-group btn-group-sm' role='group'>
      <Buttons buttons={buttons} activeButtons={activeButtons} onChange={onChange}/>
    </div>
  )
}

const Buttons: F<ForButtons> = ({buttons, activeButtons, onChange}) => {
  const btn = (b) =>
    <div class={cn('btn btn-default', {active: activeButtons.has(b.key)})} title={b.name} onClick={() => onChange(b.key)}>
      <i class={`glyphicon glyphicon-${b.icon}`}/>
    </div>

  return (
    <div class='btn-group btn-group-sm' role='group'>
      {buttons.map(btn)}
    </div>)
}
