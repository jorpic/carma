import {h, FunctionalComponent, Fragment} from 'preact'
import {Action} from '../../../types'

type F<T> = FunctionalComponent<T>

type Props = {
  action: Action
}

export const CaseAction: F<Props> = ({action: {actioncomment, actionresult, actiontype, servicelabel, tasks}}) => {

  return (
    <div class='action'>
      <div>
        <i class='glyphicon glyphicon-briefcase'/>
        <b>Действие:</b>
        {`\xa0`}
        {actiontype}
      </div>
      <div>
        <b>Результат:</b>
        {`\xa0`}
        {actionresult}
      </div>
      {servicelabel &&
        <div>
          <b>Услуга:</b>
          {`\xa0`}
          {servicelabel}
        </div>
      }
      {tasks &&
        <div>
          <b>Задачи:</b>
          {`\xa0`}
          {tasks.map(({isChecked, label}) =>
            <Fragment>
              <input type='checkbox' disabled={isChecked}/>
              {label}
            </Fragment>
          )}
        </div>
      }
      {actioncomment &&
        <div>
          <b>Комментарий:</b>
          {`\xa0`}
          {actioncomment}
        </div>
      }
    </div>
  )
}
