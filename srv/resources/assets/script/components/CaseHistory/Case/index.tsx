import {h, FunctionalComponent} from 'preact'

type F<T> = FunctionalComponent<T>

type Props = {
}

export const Case: F<Props> = ({children}) => {

  return (
    <div id='case-history'>
      <h4 style='float: left'>История по кейсу</h4>
      <div style='float: right'>иконки</div>
      <div className='history-datetime'>
        {children}
      </div>
    </div>
  )
}

