import {h, FunctionalComponent, Fragment} from 'preact'
import {Data} from '../../../CaseHistory'

type F<T> = FunctionalComponent<T>

type Props = {
  data: Data
}

export const CaseAction: F<Props> = ({data}) => {

  return (
    <div class='action'>
      <div>
        <i class='glyphicon glyphicon-briefcase'/>
        <b>Действие:&nbsp;</b>
        <span>{data[2].actiontype}</span>
      </div>
      <div>
        <b>Результат:&nbsp;</b>
        <span>{data[2].actionresult}</span>
      </div>
      {data[2].servicelabel ?
        <div>
          <b>Услуга:&nbsp;</b>
          <span>{data[2].servicelabel}</span>
        </div> : null
      }
      {data[2].tasks ?
        <div>
          <b>Задачи:&nbsp;</b>
          {data[2].tasks.forEach(({isChecked, label}) =>
            <Fragment>
              <input type='checkbox' disabled={isChecked}/>
              <span>{label}</span>
            </Fragment>
          )}
        </div> : null
      }
      {data[2].actioncomment ?
        <div>
          <b>Комментарий:&nbsp;</b>
          <span>{data[2].actioncomment}</span>
        </div> : null
      }
    </div>
  )
}
