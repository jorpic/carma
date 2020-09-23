import {h, FunctionalComponent, Fragment} from 'preact'
import {useMemo, useRef} from 'preact/hooks'
import moment from 'moment'
import * as Type from '../types'

type FC<T> = FunctionalComponent<T>

type Props = {
  historyData: Type.HistoryItem
}


  const sortByTypeData = useMemo(() => {
    switch (data.type) {
      case 'action': {
        return <Action data={data}/>
      }

      case 'comment': {
        return <Comment data={data}/>
      }
export const HistoryItem: FC<Props> = ({historyData: [date, who, data]}) =>

      case 'partnerDelay': {
        return <PartnerDelay data={data}/>
      }

      case 'partnerCancel': {
        return <PartnerCancel data={data}/>
      }

      case 'call': {
        return <Call data={data}/>
      }

      case 'smsForPartner': {
        return <SmsForPartner data={data}/>
      }

      case 'locationSharingResponse': {
        return <LocationSharingResponse data={data}/>
      }

      case 'locationSharingRequest': {
        return <LocationSharingRequest data={data}/>
      }

      case 'customerFeedback': {
        return <CustomerFeedback data={data}/>
      }

      case 'eraGlonassIncomingCallCard': {
        return <EraGlonassIncomingCallCard data={data}/>
      }

      default:
        return <div>0шибка 4О4</div>
    }
  }, [caseData])

  return (
    <div class='history-body'>
      <div
        style='float: left'>{moment.utc(date).local().format('DD.MM.YYYY HH:mm:ss')}</div>
      <div style='float: right'>{who}</div>
      &nbsp;
      {sortByTypeData}
    </div>
  )
}

//CaseItem
type PropsItem = {
  name: string
  value?: string
  icon?: string
}

const NamedValueIcon: FC<PropsItem> = ({name, value, icon}) => {
  return (
    <div>
      {icon && <i class={`glyphicon glyphicon-${icon}`}/>}&nbsp;
      <b>{name}&nbsp;</b>
      {value}
    </div>
  )
}

const NamedIcon: FC<PropsItem> = ({name, icon}) => {
  return (
    <div>
      {icon && <i class={`glyphicon glyphicon-${icon}`}/>}&nbsp;
      <b>{name}&nbsp;</b>
    </div>
  )
}

const NamedValue: FC<PropsItem> = ({name, value}) => {
  return (
    <div>
      <b>{name}&nbsp;</b>
      {value}
    </div>
  )
}

const Action: F<Type.Action> = ({data: {actioncomment, actionresult, actiontype, servicelabel, tasks}}) => {
  return (
    <div class='action'>
      <NamedValueIcon name='Действие:' value={actiontype} icon='briefcase'/>
      <NamedValue name='Результат:' value={actionresult}/>
      {servicelabel && <NamedValue name='Услуга:' value={servicelabel}/>}
      {tasks &&
      <div>
        <b>Задачи:&nbsp;</b>
        {tasks.map(({isChecked, label}) =>
          <Fragment>
            <input type='checkbox' disabled={isChecked}/>
            {label}
          </Fragment>
        )}
      </div>
      }
      {actioncomment && <NamedValue name='Комментарий:' value={actioncomment}/>}
    </div>
  )
}

const Call: F<Type.Call> = ({data: {calltype}}) =>
  <NamedValueIcon name='Звонок:' value={calltype} icon='phone-alt'/>

const Comment: F<Type.Comment> = ({data: {commenttext}}) => <NamedValue name='Комментарий:' value={commenttext}/>

const CustomerFeedback: F<Type.CustomerFeedback> = ({data: {task, commenttext}}) => {
  return (
    <Fragment>
      <NamedValueIcon name='Отзыв клиента:' value={task.label} icon='star'/>
      <NamedValue name='Комментарий:' value={commenttext}/>
    </Fragment>
  )
}

const LocationSharingRequest: F<Type.LocationSharingRequest> = () =>
  <NamedIcon name='Клиенту отправлено SMS с запросом местоположения:' icon='map-marker'/>

const LocationSharingResponse: F<Type.LocationSharingResponse> = ({data: {lat, lon}}) => {
  const lonlat = `${lon.toPrecision(7)},${lat.toPrecision(7)}`
  const mapUrl = `https://maps.yandex.ru/?z=18&l=map&pt=${lonlat}`
  const textAreaRef = useRef(null)

  const copyToClipboard = e => {
    textAreaRef.current.select();
    document.execCommand('copy')
    e.target.focus()
  }

  return (
    <div>
      <NamedIcon name='От клиента пришёл ответ с координатами:' icon='map-marker'/>&nbsp;
      <a href={mapUrl} target='_blank'>{lonlat}</a>
      <div style='float: right'>
        <a href='#' onClick={copyToClipboard}>Скопировать в буфер обмена</a>
      </div>
      <textarea style='position: fixed; top: -999px; left: -999px' ref={textAreaRef} value={mapUrl}/>
      <div style='clear:both'/>
    </div>
  )
}
const PartnerCancel: F<Type.PartnerCancel> = ({data: {refusalreason, refusalcomment, partnername}}) => {
  return (
    <div>
      <NamedValueIcon name='Отказ партнёра:' value={partnername} icon='time'/>

      <div>
        <NamedValue name='Причина отказа:' value={refusalreason}/>
        {refusalcomment && `\xa0${refusalcomment}`}
      </div>
    </div>
  )
}
const PartnerDelay: F<Type.PartnerDelay> = ({data: {delayconfirmed, delayminutes, partnername}}) => {
  return (
    <div>
      <NamedValueIcon name='Опоздание партнёра:' value={partnername} icon='time'/>
      <NamedValue name='Время опоздания:' value={delayminutes}/>
      <NamedValue name='Опоздание согласовано:' value={delayconfirmed}/>
    </div>
  )
}
const SmsForPartner: F<Type.SmsForPartner> = ({data: {deliverystatus, msgtext, phone, mtime}}) => {
  return (
    <div>
      <NamedValueIcon name='Партнёру отправлено SMS:' value={msgtext} icon='envelope'/>
      <NamedValue name='Телефон получателя:' value={phone}/>
      <NamedValue name='Статус отправки:' value={deliverystatus}/>
      <span>(обновлено: {mtime})</span>
    </div>
  )
}
const EraGlonassIncomingCallCard: F<Type.EraGlonassIncomingCallCard> = ({data: {requestBody, ivsPhoneNumber, phoneNumber, vehicle}}) => {
  const toDegrees = x => (x / (3600 * 1000)).toLocaleString('ru-RU', {
    minimumFractionDigits: 6,
    maximumFractionDigits: 6,
  }) + '°'

  return (
    <div>
      <NamedIcon name='Поступление заявки на обслуживание от ЭРА-ГЛОНАСС.' icon='globe'/>
      <NamedValue name='Идентификатор заявки на обслуживание:' value={requestBody.requestId}/>
      <NamedValue name='Имя звонящего:' value={requestBody?.fullName || '✗'}/>
      <NamedIcon name='Номера телефонов:' icon='earphone'/>
      <ul>
        <li>Терминала авто: {ivsPhoneNumber || '✗'}</li>
        <li>Звонящий: {phoneNumber || '✗'}</li>
      </ul>
      <div>
        <b>Транспорт:</b>
        <ul>
          <li>VIN: {vehicle?.vin || '✗'}</li>
          <li>Регистрационный номер: {vehicle?.plateNumber || '✗'}</li>
        </ul>
      </div>
      <NamedValue name='Описание местонахождения:' value={requestBody?.location?.description || '✗'}/>
      <div>
        <NamedIcon name='Координаты:' icon='screenshot'/>
        <ul>
          <li><b>Широта</b> {toDegrees(requestBody?.location?.latitude)}</li>
          <li><b>Долгота</b> {toDegrees(requestBody?.location?.longitude)}</li>
        </ul>
      </div>
    </div>
  )
}
